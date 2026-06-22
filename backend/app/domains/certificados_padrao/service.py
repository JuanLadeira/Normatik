import logging
from datetime import UTC, datetime
from typing import Annotated

import numpy as np
from fastapi import Depends, HTTPException, status
from scipy import stats

from app.core.storage import StorageService, StorageServiceDep
from app.domains.certificados_padrao.model import (
    CertificadoCalibracaoPadrao,
    CurvaCorrecao,
    FormularioMedicaoTemplate,
    PontoMedicaoCertificado,
    StatusCertificado,
    StatusCurva,
    TipoRegressao,
    UsoDePadrao,
)
from app.domains.certificados_padrao.repository import (
    CertificadoPadraoRepository,
    CertificadoPadraoRepositoryDep,
)
from app.domains.certificados_padrao.schema import (
    AnalisarRequest,
    AprovarCurvaRequest,
    CertificadoCreate,
    CertificadoUpdate,
    FormularioTemplateCreate,
    FormularioTemplateUpdate,
    PontoMedicaoCreate,
    RejeitarCurvaRequest,
    UsoPadraoCreate,
)
from app.domains.equipamentos.model import HistoricoCalibracaoPadrao, PadraoDeCalibração
from app.domains.tenants.model import Tenant
from app.domains.users.model import User, UserRole

logger = logging.getLogger(__name__)

_ROLES_APROVADORES = (UserRole.admin,)


# ── Motor de regressão ─────────────────────────────────────────────────────────


def calcular_curva(
    pontos: list[dict],
    campo_x: str,
    campo_y: str,
    tipo: TipoRegressao,
    grau: int,
) -> tuple[list[float], float, list[dict]]:
    """Calcula regressão polinomial e retorna (coeficientes, r², pontos_curva).

    coeficientes: lista [a0, a1, ...] em ordem crescente de grau.
    pontos_curva: 100 pontos {x, y} para plotagem.
    """
    xs = [p[campo_x] for p in pontos]
    ys = [p[campo_y] for p in pontos]

    if len(xs) < grau + 1:
        raise ValueError(
            f"Mínimo {grau + 1} pontos necessários para grau {grau}, "
            f"recebidos {len(xs)}"
        )

    # np.polyfit retorna coeficientes em ordem decrescente; invertemos para [a0, a1, ...]
    coeffs_desc = np.polyfit(xs, ys, grau)
    coeffs = list(reversed(coeffs_desc.tolist()))

    y_pred = [sum(c * x**i for i, c in enumerate(coeffs)) for x in xs]
    ss_res = sum((y - yp) ** 2 for y, yp in zip(ys, y_pred, strict=True))
    ss_tot = sum((y - sum(ys) / len(ys)) ** 2 for y in ys)
    r2 = 1.0 - ss_res / ss_tot if ss_tot != 0 else 1.0

    x_min, x_max = min(xs), max(xs)
    pontos_curva = [
        {
            "x": x_min + i * (x_max - x_min) / 99,
            "y": sum(
                c * (x_min + i * (x_max - x_min) / 99) ** j
                for j, c in enumerate(coeffs)
            ),
        }
        for i in range(100)
    ]

    return coeffs, r2, pontos_curva


# ── Campos derivados dos pontos ────────────────────────────────────────────────

FORMULAS_PRESETS = {
    "media": {
        "label": "Média de leituras",
        "hint": "Calcula a média aritmética das colunas selecionadas",
    },
    "erro": {
        "label": "Erro (Leitura - Padrão)",
        "hint": "Subtrai o valor de referência do valor medido",
    },
    "subtracao": {
        "label": "Subtração Simples (A - B)",
        "hint": "Diferença entre dois valores quaisquer",
    },
}


def _derivar_campos(valores: dict, campos_definicao: list[dict]) -> dict:
    """Calcula campos derivados conforme definição do template.

    Suporta presets:
    - { "calculado": "media", "origem": ["l1", "l2"] }
    - { "calculado": "erro", "origem": ["leitura", "referencia"] }
    - { "calculado": "subtracao", "origem": ["a", "b"] }
    - Retrocompatibilidade: "avg(l1,l2)" e "a-b"
    """
    resultado = dict(valores)

    # Garante que campos de entrada sejam floats se presentes
    for k, v in resultado.items():
        if v is not None and v != "":
            try:
                resultado[k] = float(v)
            except (ValueError, TypeError):
                pass

    for campo in campos_definicao:
        formula = campo.get("calculado")
        nome = campo.get("nome")
        origem = campo.get("origem") or []

        if not formula or formula is False:
            continue

        try:
            # 1. Novos Presets (Recomendado)
            if formula == "media":
                vals = [resultado.get(p) for p in origem]
                if any(v is None for v in vals):
                    resultado[nome] = None
                else:
                    resultado[nome] = sum(vals) / len(vals)

            elif formula in ["erro", "subtracao"]:
                if len(origem) >= 2:
                    a = resultado.get(origem[0])
                    b = resultado.get(origem[1])
                    resultado[nome] = (
                        (a - b) if (a is not None and b is not None) else None
                    )
                else:
                    resultado[nome] = None

            # 2. Retrocompatibilidade (Strings legadas)
            elif isinstance(formula, str) and formula.startswith("avg("):
                partes = formula[4:-1].split(",")
                vals = [resultado.get(p.strip()) for p in partes]
                if any(v is None for v in vals):
                    resultado[nome] = None
                else:
                    resultado[nome] = sum(float(v) for v in vals) / len(vals)

            elif isinstance(formula, str) and "-" in formula:
                partes = [p.strip() for p in formula.split("-", 1)]
                a = resultado.get(partes[0])
                b = resultado.get(partes[1])
                resultado[nome] = (
                    (float(a) - float(b)) if (a is not None and b is not None) else None
                )
            else:
                resultado[nome] = None
        except Exception as exc:
            logger.warning("Erro ao calcular campo '%s': %s", nome, exc)
            resultado[nome] = None

    return resultado


class CertificadoPadraoService:
    def __init__(self, repo: CertificadoPadraoRepository, storage: StorageService):
        self.repo = repo
        self.storage = storage

    # ── FormularioMedicaoTemplate ──────────────────────────────────────────────

    async def criar_template(
        self, data: FormularioTemplateCreate, current_user: User
    ) -> FormularioMedicaoTemplate:
        template = FormularioMedicaoTemplate(
            **data.model_dump(),
            criado_por=current_user.id,
        )
        return await self.repo.save(template)

    async def listar_templates(self) -> list[FormularioMedicaoTemplate]:
        return await self.repo.list_templates()

    async def get_template(self, template_id: int) -> FormularioMedicaoTemplate:
        template = await self.repo.get_template_by_id(template_id)
        if not template:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Template não encontrado",
            )
        return template

    async def atualizar_template(
        self, template_id: int, data: FormularioTemplateUpdate
    ) -> FormularioMedicaoTemplate:
        template = await self.get_template(template_id)
        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(template, key, value)
        return await self.repo.save(template)

    # ── CertificadoCalibracaoPadrao ────────────────────────────────────────────

    async def criar_certificado(
        self, data: CertificadoCreate, current_user: User
    ) -> CertificadoCalibracaoPadrao:
        u_padrao = data.U_expandida / data.k_abrangencia

        formulario_config = data.formulario_config
        if not formulario_config and data.formulario_template_id:
            tmpl = await self.repo.get_template_by_id(data.formulario_template_id)
            if tmpl:
                formulario_config = {
                    "nome": tmpl.nome,
                    "campos_pontos": tmpl.campos_pontos,
                    "tipo_regressao_default": tmpl.tipo_regressao_default,
                    "grau_polinomio_default": tmpl.grau_polinomio_default,
                }

        cert = CertificadoCalibracaoPadrao(
            **data.model_dump(exclude={"formulario_config"}),
            u_padrao=u_padrao,
            formulario_config=formulario_config,
            criado_por=current_user.id,
        )
        return await self.repo.save(cert)

    async def get_certificado(self, certificado_id: int) -> CertificadoCalibracaoPadrao:
        cert = await self.repo.get_certificado_by_id(certificado_id)
        if not cert:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Certificado não encontrado",
            )
        return cert

    async def atualizar_certificado(
        self, certificado_id: int, data: CertificadoUpdate
    ) -> CertificadoCalibracaoPadrao:
        cert = await self.get_certificado(certificado_id)
        updates = data.model_dump(exclude_unset=True)

        # Recalcula u_padrao se U_expandida ou k_abrangencia mudaram
        new_U = updates.get("U_expandida", cert.U_expandida)
        new_k = updates.get("k_abrangencia", cert.k_abrangencia)
        updates["u_padrao"] = new_U / new_k

        for key, value in updates.items():
            setattr(cert, key, value)

        return await self.repo.save(cert)

    async def listar_certificados_padrao(
        self, padrao_id: int
    ) -> list[CertificadoCalibracaoPadrao]:
        return await self.repo.list_certificados_by_padrao(padrao_id)

    async def upload_pdf(
        self, certificado_id: int, file_content: bytes, filename: str
    ) -> CertificadoCalibracaoPadrao:
        """Faz upload do PDF para o storage e vincula ao certificado."""
        cert = await self.get_certificado(certificado_id)

        # Busca o padrão para pegar o tenant
        padrao = await self.repo._session.get(PadraoDeCalibração, cert.padrao_id)
        if not padrao:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Padrão não encontrado",
            )

        # Busca o tenant para usar o slug no path
        tenant = await self.repo._session.get(Tenant, padrao.tenant_id)
        tenant_slug = tenant.slug if tenant else "global"

        # Define um nome único para o arquivo no bucket, isolado por tenant
        # Ex: labs/normatiq/certificados/123/nome_arquivo.pdf
        s3_key = f"labs/{tenant_slug}/certificados/{cert.id}/{filename}"

        path = await self.storage.upload_file(
            file_content=file_content,
            filename=s3_key,
            content_type="application/pdf",
        )

        cert.arquivo_pdf = path
        return await self.repo.save(cert)

    # ── Pontos de medição ──────────────────────────────────────────────────────

    async def salvar_pontos(
        self,
        certificado_id: int,
        pontos_data: list[PontoMedicaoCreate],
    ) -> list[PontoMedicaoCertificado]:
        """Substitui todos os pontos do certificado (replace-all)."""
        cert = await self.get_certificado(certificado_id)
        await self.repo.delete_pontos_of_certificado(cert.id)

        # Obtém definição de campos do snapshot ou do template
        campos_def: list[dict] = []
        config = cert.formulario_config
        if not config and cert.formulario_template_id:
            tmpl = await self.repo.get_template_by_id(cert.formulario_template_id)
            if tmpl:
                config = tmpl.campos_pontos

        if config:
            if isinstance(config, list):
                campos_def = config
            else:
                campos_def = config.get("colunas") or config.get("campos") or []

        novos: list[PontoMedicaoCertificado] = []
        for p in pontos_data:
            valores_completos = _derivar_campos(p.valores, campos_def)
            ponto = PontoMedicaoCertificado(
                certificado_id=cert.id,
                ordem=p.ordem,
                valores=valores_completos,
            )
            await self.repo.save(ponto)
            novos.append(ponto)

        return novos

    async def listar_pontos(self, certificado_id: int) -> list[PontoMedicaoCertificado]:
        """Lista pontos com campos calculados derivados do template."""
        cert = await self.get_certificado(certificado_id)
        pontos = await self.repo.list_pontos(certificado_id)

        # Obtém definição de campos do snapshot ou do template
        campos_def: list[dict] = []
        config = cert.formulario_config
        if not config and cert.formulario_template_id:
            tmpl = await self.repo.get_template_by_id(cert.formulario_template_id)
            if tmpl:
                config = tmpl.campos_pontos

        if config:
            if isinstance(config, list):
                campos_def = config
            else:
                campos_def = config.get("colunas") or config.get("campos") or []

        if campos_def:
            for ponto in pontos:
                ponto.valores = _derivar_campos(ponto.valores, campos_def)

        return pontos

    # ── Análise de regressão ───────────────────────────────────────────────────

    async def analisar_certificado(
        self, certificado_id: int, req: AnalisarRequest
    ) -> CurvaCorrecao:
        """Calcula regressão sobre os pontos e salva CurvaCorrecao com status=sugerida."""
        cert = await self.get_certificado(certificado_id)
        pontos = await self.repo.list_pontos(certificado_id)

        if not pontos:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="O certificado não possui pontos de medição",
            )

        pontos_vals = [p.valores for p in pontos]
        try:
            coeffs, r2, pts_curva = calcular_curva(
                pontos_vals, req.campo_x, req.campo_y, req.tipo, req.grau
            )
        except (ValueError, KeyError) as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=str(exc),
            ) from exc

        curva = CurvaCorrecao(
            certificado_id=cert.id,
            tipo=req.tipo,
            grau=req.grau,
            coeficientes=coeffs,
            r_quadrado=r2,
            pontos_curva=pts_curva,
            status=StatusCurva.sugerida,
        )
        await self.repo.save(curva)

        # Atualiza status do certificado para aguardando aprovação
        cert.status = StatusCertificado.aguardando_aprovacao_curva
        await self.repo.save(cert)

        return curva

    # ── Aprovação e Rejeição ───────────────────────────────────────────────────

    async def aprovar_curva(
        self,
        certificado_id: int,
        req: AprovarCurvaRequest,
        current_user: User,
    ) -> CurvaCorrecao:
        """Aprova a curva sugerida mais recente do certificado.

        1. Valida role do usuário (apenas admin).
        2. Seta curva.status = aprovada.
        3. Seta certificado.status = ativo.
        4. Atualiza padrao.u_expandida_atual = certificado.u_padrao.
        5. Insere registro em historico_calibracoes_padrao.
        """
        self._require_aprovador(current_user)

        cert = await self.get_certificado(certificado_id)
        curva = await self.repo.get_curva_sugerida_mais_recente(certificado_id)

        if not curva:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Nenhuma curva sugerida encontrada para este certificado",
            )

        now = datetime.now(UTC).replace(tzinfo=None)
        curva.status = StatusCurva.aprovada
        curva.aprovado_por = current_user.id
        curva.data_aprovacao = now
        await self.repo.save(curva)

        cert.status = StatusCertificado.ativo
        await self.repo.save(cert)

        # Atualiza padrão
        padrao = await self.repo._session.get(PadraoDeCalibração, cert.padrao_id)
        if padrao:
            padrao.u_expandida_atual = cert.u_padrao
            padrao.numero_certificado = cert.numero_certificado
            padrao.data_calibracao = cert.data_emissao
            padrao.validade_calibracao = cert.data_validade
            padrao.laboratorio_calibrador = cert.laboratorio_calibrador
            await self.repo.save(padrao)

            # Insere histórico para retrocompatibilidade com painel de status
            historico = HistoricoCalibracaoPadrao(
                padrao_id=cert.padrao_id,
                data_calibracao=cert.data_emissao,
                data_vencimento=cert.data_validade,
                numero_certificado=cert.numero_certificado,
                laboratorio_calibrador=cert.laboratorio_calibrador,
                u_expandida_certificado=cert.u_padrao,
                aceito=True,
                observacoes=req.observacoes,
                arquivo_pdf_url=cert.arquivo_pdf,
            )
            await self.repo.save(historico)

        return curva

    async def rejeitar_curva(
        self,
        certificado_id: int,
        req: RejeitarCurvaRequest,
        current_user: User,
    ) -> CurvaCorrecao:
        """Rejeita a curva sugerida mais recente do certificado.

        1. Valida role do usuário (apenas admin).
        2. Seta curva.status = rejeitada.
        3. Seta certificado.status = rascunho.
        """
        self._require_aprovador(current_user)

        await self.get_certificado(certificado_id)  # garante existência
        curva = await self.repo.get_curva_sugerida_mais_recente(certificado_id)

        if not curva:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Nenhuma curva sugerida encontrada para este certificado",
            )

        curva.status = StatusCurva.rejeitada
        await self.repo.save(curva)

        cert = await self.repo.get_certificado_by_id(certificado_id)
        if cert:
            cert.status = StatusCertificado.rascunho
            await self.repo.save(cert)

        return curva

    async def get_curva_ativa(self, certificado_id: int) -> CurvaCorrecao:
        await self.get_certificado(certificado_id)  # garante existência
        curva = await self.repo.get_curva_ativa(certificado_id)
        if not curva:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Nenhuma curva aprovada encontrada para este certificado",
            )
        return curva

    # ── Helpers internos ───────────────────────────────────────────────────────

    @staticmethod
    def _require_aprovador(user: User) -> None:
        if user.role not in _ROLES_APROVADORES:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Apenas administradores podem aprovar ou rejeitar curvas",
            )

    # ── UsoDePadrao ────────────────────────────────────────────────────────────

    async def deletar_certificado(self, certificado_id: int) -> None:
        cert = await self.get_certificado(certificado_id)
        await self.repo.delete(cert)

    async def registrar_uso(self, data: UsoPadraoCreate) -> UsoDePadrao:
        uso = UsoDePadrao(**data.model_dump())
        return await self.repo.save(uso)

    @staticmethod
    def aplicar_correcao(curva: CurvaCorrecao, valor: float) -> float:
        """Aplica a correção da curva a um valor medido.

        f(x) = a0 + a1*x + a2*x^2 + ...
        Onde x é o valor medido e f(x) é o erro (correção).
        """
        # coeficientes estão em ordem crescente de grau: [a0, a1, a2...]
        return sum(c * (valor**i) for i, c in enumerate(curva.coeficientes))

    @staticmethod
    def calcular_k_student(graus_liberdade: float, confianca: float = 0.95) -> float:
        """Calcula o fator de abrangência k usando a distribuição t de Student.

        Usado na fórmula de Welch-Satterthwaite para expansão da incerteza.
        """
        if graus_liberdade <= 0:
            return 2.0  # fallback seguro para infinito
        # stats.t.ppf retorna o percentil para uma cauda. Para 95% bicaudal, usamos 0.975
        alpha = (1 + confianca) / 2
        return float(stats.t.ppf(alpha, graus_liberdade))


def get_certificado_padrao_service(
    repo: CertificadoPadraoRepositoryDep,
    storage: StorageServiceDep,
) -> "CertificadoPadraoService":
    return CertificadoPadraoService(repo, storage)


CertificadoPadraoServiceDep = Annotated[
    CertificadoPadraoService, Depends(get_certificado_padrao_service)
]

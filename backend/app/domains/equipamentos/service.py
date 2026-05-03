from typing import Annotated

from fastapi import Depends, HTTPException, status

from app.domains.equipamentos.model import (
    Fabricante,
    FaixaMedicao,
    HistoricoCalibracaoPadrao,
    Instrumento,
    ModeloEquipamento,
    PadraoDeCalibração,
    TipoEquipamento,
)
from app.domains.equipamentos.repository import (
    EquipamentoRepository,
    EquipamentoRepositoryDep,
)
from app.domains.equipamentos.schema import (
    FabricanteCreate,
    FaixaMedicaoCreate,
    HistoricoCalibracaoPadraoCreate,
    HistoricoCalibracaoPadraoUpdate,
    InstrumentoCreate,
    InstrumentoUpdate,
    ModeloEquipamentoCreate,
    ModeloEquipamentoUpdate,
    PadraoCreate,
    PadraoUpdate,
    TipoEquipamentoCreate,
)


class EquipamentoService:
    def __init__(self, repo: EquipamentoRepository):
        self.repo = repo

    # ── Catálogo ──────────────────────────────────────────────────────────────

    async def get_tipos_equipamento(self, grandeza_id: int | None = None):
        return await self.repo.get_tipos_equipamento(grandeza_id)

    async def create_tipo_equipamento(
        self, data: TipoEquipamentoCreate
    ) -> TipoEquipamento:
        codigo = data.codigo or data.nome[:10].upper().replace(" ", "_")
        tipo = TipoEquipamento(
            grandeza_id=data.grandeza_id,
            codigo=codigo,
            nome=data.nome,
        )
        return await self.repo.save(tipo)

    async def get_fabricantes(self):
        return await self.repo.get_fabricantes()

    async def create_fabricante(self, data: FabricanteCreate) -> Fabricante:
        existing = await self.repo.get_fabricante_by_nome(data.nome)
        if existing:
            return existing
        fabricante = Fabricante(nome=data.nome)
        return await self.repo.save(fabricante)

    async def get_modelos(
        self, tipo_id: int | None = None, fabricante_id: int | None = None
    ):
        return await self.repo.get_modelos(tipo_id, fabricante_id)

    async def create_modelo_equipamento(
        self, data: ModeloEquipamentoCreate
    ) -> ModeloEquipamento:
        existing = await self.repo.get_modelo_by_tipo_fabricante_nome(
            data.tipo_equipamento_id, data.fabricante_id, data.nome
        )
        if existing:
            return existing
        modelo = ModeloEquipamento(**data.model_dump())
        return await self.repo.save(modelo)

    async def update_modelo_equipamento(
        self, id: int, data: ModeloEquipamentoUpdate
    ) -> ModeloEquipamento:
        modelo = await self.repo.get_modelo_by_id(id)
        if not modelo:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Modelo não encontrado",
            )
        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(modelo, key, value)
        return await self.repo.save(modelo)

    async def delete_modelo(self, id: int) -> None:
        modelo = await self.repo.get_modelo_by_id(id)
        if modelo:
            await self.repo.delete(modelo)

    # ── Helpers de Catálogo Automático ────────────────────────────────────────

    async def _ensure_catalog_entry(
        self, tipo_id: int, marca_nome: str, modelo_nome: str
    ) -> int:
        """Garante que fabricante e modelo existem no catálogo e retorna o ID do modelo."""
        # 1. Garantir Fabricante
        fabricante = await self.repo.get_fabricante_by_nome(marca_nome)
        if not fabricante:
            fabricante = Fabricante(nome=marca_nome)
            fabricante = await self.repo.save(fabricante)

        # 2. Garantir Modelo
        modelo = await self.repo.get_modelo_by_tipo_fabricante_nome(
            tipo_id, fabricante.id, modelo_nome
        )
        if not modelo:
            modelo = ModeloEquipamento(
                tipo_equipamento_id=tipo_id,
                fabricante_id=fabricante.id,
                nome=modelo_nome,
            )
            modelo = await self.repo.save(modelo)

        return modelo.id

    # ── Instrumentos ──────────────────────────────────────────────────────────

    async def get_instrumentos(self, tenant_id: int, cliente_id: int | None = None):
        return await self.repo.get_instrumentos(tenant_id, cliente_id)

    async def get_instrumento_by_id(
        self, tenant_id: int, instrumento_id: int
    ) -> Instrumento:
        instr = await self.repo.get_instrumento_by_id(tenant_id, instrumento_id)
        if not instr:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Instrumento não encontrado",
            )
        return instr

    async def create_instrumento(
        self, tenant_id: int, data: InstrumentoCreate
    ) -> Instrumento:
        # Lógica de catálogo automático
        if not data.modelo_equipamento_id:
            data.modelo_equipamento_id = await self._ensure_catalog_entry(
                data.tipo_equipamento_id, data.marca, data.modelo
            )

        instrumento = Instrumento(
            tenant_id=tenant_id, **data.model_dump(exclude={"faixas"})
        )
        await self.repo.save(instrumento)
        await self._save_faixas(instrumento.id, data.faixas)
        return await self.get_instrumento_by_id(tenant_id, instrumento.id)

    async def update_instrumento(
        self, tenant_id: int, instrumento_id: int, data: InstrumentoUpdate
    ) -> Instrumento:
        instr = await self.get_instrumento_by_id(tenant_id, instrumento_id)
        
        # Se mudar marca/modelo/tipo, podemos precisar atualizar o catálogo ou o ID do modelo
        if (data.marca or data.modelo or data.tipo_equipamento_id) and not data.modelo_equipamento_id:
            tipo_id = data.tipo_equipamento_id or instr.tipo_equipamento_id
            marca = data.marca or instr.marca
            modelo = data.modelo or instr.modelo
            data.modelo_equipamento_id = await self._ensure_catalog_entry(tipo_id, marca, modelo)

        for key, value in data.model_dump(exclude_unset=True, exclude={"faixas"}).items():
            setattr(instr, key, value)
        await self.repo.save(instr)
        if data.faixas is not None:
            await self.repo.delete_faixas_by_equipamento(instr.id)
            await self._save_faixas(instr.id, data.faixas)
        return await self.get_instrumento_by_id(tenant_id, instr.id)

    async def delete_instrumento(self, tenant_id: int, instrumento_id: int) -> None:
        instr = await self.get_instrumento_by_id(tenant_id, instrumento_id)
        await self.repo.delete(instr)

    # ── Padrões ───────────────────────────────────────────────────────────────

    async def get_padroes(self, tenant_id: int):
        return await self.repo.get_padroes(tenant_id)

    async def get_padrao_by_id(
        self, tenant_id: int, padrao_id: int
    ) -> PadraoDeCalibração:
        padrao = await self.repo.get_padrao_by_id(tenant_id, padrao_id)
        if not padrao:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Padrão não encontrado",
            )
        return padrao

    async def create_padrao(
        self, tenant_id: int, data: PadraoCreate
    ) -> PadraoDeCalibração:
        # Lógica de catálogo automático
        if not data.modelo_equipamento_id:
            data.modelo_equipamento_id = await self._ensure_catalog_entry(
                data.tipo_equipamento_id, data.marca, data.modelo
            )

        padrao = PadraoDeCalibração(
            tenant_id=tenant_id, **data.model_dump(exclude={"faixas"})
        )
        await self.repo.save(padrao)
        await self._save_faixas(padrao.id, data.faixas)
        return await self.get_padrao_by_id(tenant_id, padrao.id)

    async def update_padrao(
        self, tenant_id: int, padrao_id: int, data: PadraoUpdate
    ) -> PadraoDeCalibração:
        padrao = await self.get_padrao_by_id(tenant_id, padrao_id)

        # Se mudar marca/modelo/tipo, podemos precisar atualizar o catálogo ou o ID do modelo
        if (data.marca or data.modelo or data.tipo_equipamento_id) and not data.modelo_equipamento_id:
            tipo_id = data.tipo_equipamento_id or padrao.tipo_equipamento_id
            marca = data.marca or padrao.marca
            modelo = data.modelo or padrao.modelo
            data.modelo_equipamento_id = await self._ensure_catalog_entry(tipo_id, marca, modelo)

        for key, value in data.model_dump(exclude_unset=True, exclude={"faixas"}).items():
            setattr(padrao, key, value)
        await self.repo.save(padrao)
        if data.faixas is not None:
            await self.repo.delete_faixas_by_equipamento(padrao.id)
            await self._save_faixas(padrao.id, data.faixas)
        return await self.get_padrao_by_id(tenant_id, padrao.id)

    async def delete_padrao(self, tenant_id: int, padrao_id: int) -> None:
        padrao = await self.get_padrao_by_id(tenant_id, padrao_id)
        await self.repo.delete(padrao)

    # ── Regra de Negócio: Registro de Calibração Externa ──────────────────────

    async def registrar_calibracao_externa(
        self, tenant_id: int, padrao_id: int, data: HistoricoCalibracaoPadraoCreate
    ) -> HistoricoCalibracaoPadrao:
        padrao = await self.get_padrao_by_id(tenant_id, padrao_id)
        
        # Validação: Impedir duplicidade de certificado para o mesmo padrão
        historico_existente = await self.repo.get_historico_padrao_by_certificado(
            padrao.id, data.numero_certificado
        )
        if historico_existente:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Já existe uma calibração registrada com o certificado '{data.numero_certificado}' para este padrão.",
            )

        historico = HistoricoCalibracaoPadrao(padrao_id=padrao.id, **data.model_dump())
        await self.repo.save(historico)
        await self._refresh_padrao_mirror(padrao)
        return historico

    async def update_historico_padrao(
        self, tenant_id: int, padrao_id: int, historico_id: int, data: HistoricoCalibracaoPadraoUpdate
    ) -> HistoricoCalibracaoPadrao:
        padrao = await self.get_padrao_by_id(tenant_id, padrao_id)
        historico = await self.repo.get_historico_padrao_by_id(historico_id)
        
        if not historico or historico.padrao_id != padrao.id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Registro de calibração não encontrado.",
            )

        if data.numero_certificado and data.numero_certificado != historico.numero_certificado:
            existente = await self.repo.get_historico_padrao_by_certificado(
                padrao.id, data.numero_certificado
            )
            if existente:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Já existe uma calibração registrada com o certificado '{data.numero_certificado}' para este padrão.",
                )

        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(historico, key, value)
        
        await self.repo.save(historico)
        await self._refresh_padrao_mirror(padrao)
        return historico

    async def delete_historico_padrao(self, tenant_id: int, padrao_id: int, historico_id: int) -> None:
        padrao = await self.get_padrao_by_id(tenant_id, padrao_id)
        historico = await self.repo.get_historico_padrao_by_id(historico_id)
        
        if not historico or historico.padrao_id != padrao.id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Registro de calibração não encontrado.",
            )

        await self.repo.delete(historico)
        await self._refresh_padrao_mirror(padrao)

    async def get_historico_padrao(self, tenant_id: int, padrao_id: int):
        padrao = await self.get_padrao_by_id(tenant_id, padrao_id)
        return await self.repo.get_historico_padrao(padrao.id)

    async def _refresh_padrao_mirror(self, padrao: PadraoDeCalibração) -> None:
        """Atualiza os campos de espelho do padrão com base na calibração mais recente aceita."""
        historicos = await self.repo.get_historico_padrao(padrao.id)
        # Filtra apenas os aceitos e pega o mais recente por data de calibração
        aceitos = [h for h in historicos if h.aceito]
        if not aceitos:
            padrao.numero_certificado = None
            padrao.data_calibracao = None
            padrao.validade_calibracao = None
            padrao.laboratorio_calibrador = None
            padrao.u_expandida_atual = None
        else:
            # Ordena por data decrescente
            aceitos.sort(key=lambda x: x.data_calibracao, reverse=True)
            mais_recente = aceitos[0]
            padrao.numero_certificado = mais_recente.numero_certificado
            padrao.data_calibracao = mais_recente.data_calibracao
            padrao.validade_calibracao = mais_recente.data_vencimento
            padrao.laboratorio_calibrador = mais_recente.laboratorio_calibrador
            padrao.u_expandida_atual = mais_recente.u_expandida_certificado
        
        await self.repo.save(padrao)

    # ── Helpers ───────────────────────────────────────────────────────────────

    async def _save_faixas(
        self, equipamento_id: int, faixas: list[FaixaMedicaoCreate]
    ) -> None:
        for posicao, f in enumerate(faixas, start=1):
            faixa = FaixaMedicao(
                equipamento_id=equipamento_id,
                unidade_id=f.unidade_id,
                valor_min=f.valor_min,
                valor_max=f.valor_max,
                resolucao=f.resolucao,
                posicao=posicao,
            )
            await self.repo.save_faixa(faixa)


def get_equipamento_service(repo: EquipamentoRepositoryDep) -> EquipamentoService:
    return EquipamentoService(repo)


EquipamentoServiceDep = Annotated[EquipamentoService, Depends(get_equipamento_service)]

from fastapi import APIRouter, status

from app.auth.dependencies import CurrentUser
from app.domains.certificados_padrao.schema import (
    AnalisarRequest,
    AprovarCurvaRequest,
    CertificadoCreate,
    CertificadoPublic,
    CertificadoUpdate,
    CurvaCorrecaoPublic,
    FormularioTemplateCreate,
    FormularioTemplatePublic,
    FormularioTemplateUpdate,
    PontoMedicaoCreate,
    PontoMedicaoPublic,
    RejeitarCurvaRequest,
)
from app.domains.certificados_padrao.service import CertificadoPadraoServiceDep

router = APIRouter(
    prefix="/api/certificados-padrao",
    tags=["Metrologia — Certificados de Padrão"],
)


# ── Templates ──────────────────────────────────────────────────────────────────


@router.post(
    "/templates",
    response_model=FormularioTemplatePublic,
    status_code=status.HTTP_201_CREATED,
)
async def criar_template(
    data: FormularioTemplateCreate,
    current_user: CurrentUser,
    service: CertificadoPadraoServiceDep,
):
    """Cria um template de formulário de medição para um tipo de instrumento."""
    return await service.criar_template(data, current_user)


@router.get("/templates", response_model=list[FormularioTemplatePublic])
async def listar_templates(
    current_user: CurrentUser,
    service: CertificadoPadraoServiceDep,
):
    """Lista todos os templates de formulário de medição."""
    return await service.listar_templates()


@router.get("/templates/{id}", response_model=FormularioTemplatePublic)
async def detalhar_template(
    id: int,
    current_user: CurrentUser,
    service: CertificadoPadraoServiceDep,
):
    """Obtém detalhes de um template de formulário."""
    return await service.get_template(id)


@router.put("/templates/{id}", response_model=FormularioTemplatePublic)
async def atualizar_template(
    id: int,
    data: FormularioTemplateUpdate,
    current_user: CurrentUser,
    service: CertificadoPadraoServiceDep,
):
    """Atualiza um template de formulário de medição."""
    return await service.atualizar_template(id, data)


# ── Certificados ───────────────────────────────────────────────────────────────


@router.post(
    "/certificados",
    response_model=CertificadoPublic,
    status_code=status.HTTP_201_CREATED,
)
async def criar_certificado(
    data: CertificadoCreate,
    current_user: CurrentUser,
    service: CertificadoPadraoServiceDep,
):
    """Cria um certificado de calibração para um padrão.

    u_padrao é calculado automaticamente como U_expandida / k_abrangencia.
    """
    return await service.criar_certificado(data, current_user)


@router.get("/certificados/{id}", response_model=CertificadoPublic)
async def detalhar_certificado(
    id: int,
    current_user: CurrentUser,
    service: CertificadoPadraoServiceDep,
):
    """Obtém detalhes de um certificado de calibração."""
    return await service.get_certificado(id)


@router.put("/certificados/{id}", response_model=CertificadoPublic)
async def atualizar_certificado(
    id: int,
    data: CertificadoUpdate,
    current_user: CurrentUser,
    service: CertificadoPadraoServiceDep,
):
    """Atualiza dados de um certificado de calibração."""
    return await service.atualizar_certificado(id, data)


@router.get(
    "/padroes/{padrao_id}/certificados",
    response_model=list[CertificadoPublic],
)
async def listar_certificados_padrao(
    padrao_id: int,
    current_user: CurrentUser,
    service: CertificadoPadraoServiceDep,
):
    """Lista todos os certificados de calibração de um padrão (mais recente primeiro)."""
    return await service.listar_certificados_padrao(padrao_id)


# ── Pontos de medição ──────────────────────────────────────────────────────────


@router.post(
    "/certificados/{id}/pontos",
    response_model=list[PontoMedicaoPublic],
    status_code=status.HTTP_201_CREATED,
)
async def salvar_pontos(
    id: int,
    pontos: list[PontoMedicaoCreate],
    current_user: CurrentUser,
    service: CertificadoPadraoServiceDep,
):
    """Salva pontos de medição em batch, substituindo todos os anteriores (replace-all)."""
    return await service.salvar_pontos(id, pontos)


@router.get("/certificados/{id}/pontos", response_model=list[PontoMedicaoPublic])
async def listar_pontos(
    id: int,
    current_user: CurrentUser,
    service: CertificadoPadraoServiceDep,
):
    """Lista pontos de medição com campos calculados derivados do template."""
    return await service.listar_pontos(id)


# ── Análise e aprovação ────────────────────────────────────────────────────────


@router.post("/certificados/{id}/analisar", response_model=CurvaCorrecaoPublic)
async def analisar_certificado(
    id: int,
    req: AnalisarRequest,
    current_user: CurrentUser,
    service: CertificadoPadraoServiceDep,
):
    """Calcula regressão sobre os pontos do certificado e salva curva com status=sugerida."""
    return await service.analisar_certificado(id, req)


@router.post("/certificados/{id}/aprovar", response_model=CurvaCorrecaoPublic)
async def aprovar_curva(
    id: int,
    req: AprovarCurvaRequest,
    current_user: CurrentUser,
    service: CertificadoPadraoServiceDep,
):
    """Aprova a curva sugerida mais recente (somente admin).

    Atualiza padrão e insere registro histórico.
    """
    return await service.aprovar_curva(id, req, current_user)


@router.post("/certificados/{id}/rejeitar", response_model=CurvaCorrecaoPublic)
async def rejeitar_curva(
    id: int,
    req: RejeitarCurvaRequest,
    current_user: CurrentUser,
    service: CertificadoPadraoServiceDep,
):
    """Rejeita a curva sugerida mais recente (somente admin)."""
    return await service.rejeitar_curva(id, req, current_user)


@router.get("/certificados/{id}/curva", response_model=CurvaCorrecaoPublic)
async def get_curva_ativa(
    id: int,
    current_user: CurrentUser,
    service: CertificadoPadraoServiceDep,
):
    """Retorna a curva de correção aprovada mais recente do certificado."""
    return await service.get_curva_ativa(id)

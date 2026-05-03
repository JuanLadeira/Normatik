from fastapi import APIRouter, status

from app.auth.dependencies import CurrentUser
from app.domains.equipamentos.schema import (
    FabricanteCreate,
    FabricantePublic,
    HistoricoCalibracaoPadraoCreate,
    HistoricoCalibracaoPadraoPublic,
    HistoricoCalibracaoPadraoUpdate,
    InstrumentoCreate,
    InstrumentoPublic,
    InstrumentoUpdate,
    ModeloEquipamentoCreate,
    ModeloEquipamentoPublic,
    ModeloEquipamentoUpdate,
    PadraoCreate,
    PadraoPublic,
    PadraoUpdate,
    TipoEquipamentoCreate,
    TipoEquipamentoPublic,
)
from app.domains.equipamentos.service import EquipamentoServiceDep

router = APIRouter(prefix="/api/equipamentos", tags=["Metrologia — Equipamentos"])


# ── Catálogo ──────────────────────────────────────────────────────────────────


@router.get("/tipos", response_model=list[TipoEquipamentoPublic])
async def list_tipos(
    service: EquipamentoServiceDep, _: CurrentUser, grandeza_id: int | None = None
):
    """Lista tipos de equipamentos cadastrados."""
    return await service.get_tipos_equipamento(grandeza_id)


@router.post(
    "/tipos", response_model=TipoEquipamentoPublic, status_code=status.HTTP_201_CREATED
)
async def create_tipo(
    data: TipoEquipamentoCreate, service: EquipamentoServiceDep, _: CurrentUser
):
    """Cadastra um novo tipo de equipamento."""
    return await service.create_tipo_equipamento(data)


@router.get("/fabricantes", response_model=list[FabricantePublic])
async def list_fabricantes(service: EquipamentoServiceDep, _: CurrentUser):
    """Lista fabricantes de equipamentos."""
    return await service.get_fabricantes()


@router.post(
    "/fabricantes", response_model=FabricantePublic, status_code=status.HTTP_201_CREATED
)
async def create_fabricante(
    data: FabricanteCreate, service: EquipamentoServiceDep, _: CurrentUser
):
    """Cadastra um novo fabricante."""
    return await service.create_fabricante(data)


@router.get("/modelos", response_model=list[ModeloEquipamentoPublic])
async def list_modelos(
    service: EquipamentoServiceDep,
    _: CurrentUser,
    tipo_id: int | None = None,
    fabricante_id: int | None = None,
):
    """Lista modelos de equipamentos."""
    return await service.get_modelos(tipo_id, fabricante_id)


@router.post(
    "/modelos",
    response_model=ModeloEquipamentoPublic,
    status_code=status.HTTP_201_CREATED,
)
async def create_modelo(
    data: ModeloEquipamentoCreate, service: EquipamentoServiceDep, _: CurrentUser
):
    """Cadastra um novo modelo de equipamento."""
    return await service.create_modelo_equipamento(data)


@router.patch("/modelos/{id}", response_model=ModeloEquipamentoPublic)
async def update_modelo(
    id: int,
    data: ModeloEquipamentoUpdate,
    service: EquipamentoServiceDep,
    _: CurrentUser,
):
    """Atualiza um modelo de equipamento."""
    return await service.update_modelo_equipamento(id, data)


@router.delete("/modelos/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_modelo(id: int, service: EquipamentoServiceDep, _: CurrentUser):
    """Remove um modelo do catálogo."""
    await service.delete_modelo(id)


# ── Instrumentos ──────────────────────────────────────────────────────────────


@router.get("/instrumentos", response_model=list[InstrumentoPublic])
async def list_instrumentos(
    current_user: CurrentUser,
    service: EquipamentoServiceDep,
    cliente_id: int | None = None,
):
    """Lista instrumentos do cliente."""
    return await service.get_instrumentos(current_user.tenant_id, cliente_id)


@router.post(
    "/instrumentos",
    response_model=InstrumentoPublic,
    status_code=status.HTTP_201_CREATED,
)
async def create_instrumento(
    data: InstrumentoCreate, current_user: CurrentUser, service: EquipamentoServiceDep
):
    """Cadastra um novo instrumento de cliente."""
    return await service.create_instrumento(current_user.tenant_id, data)


@router.get("/instrumentos/{id}", response_model=InstrumentoPublic)
async def get_instrumento(
    id: int, current_user: CurrentUser, service: EquipamentoServiceDep
):
    """Obtém detalhes de um instrumento."""
    return await service.get_instrumento_by_id(current_user.tenant_id, id)


@router.patch("/instrumentos/{id}", response_model=InstrumentoPublic)
async def update_instrumento(
    id: int,
    data: InstrumentoUpdate,
    current_user: CurrentUser,
    service: EquipamentoServiceDep,
):
    """Atualiza dados de um instrumento."""
    return await service.update_instrumento(current_user.tenant_id, id, data)


@router.delete("/instrumentos/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_instrumento(
    id: int, current_user: CurrentUser, service: EquipamentoServiceDep
):
    """Remove um instrumento."""
    await service.delete_instrumento(current_user.tenant_id, id)


# ── Padrões ───────────────────────────────────────────────────────────────────


@router.get("/padroes", response_model=list[PadraoPublic])
async def list_padroes(current_user: CurrentUser, service: EquipamentoServiceDep):
    """Lista padrões de calibração do laboratório."""
    return await service.get_padroes(current_user.tenant_id)


@router.post(
    "/padroes", response_model=PadraoPublic, status_code=status.HTTP_201_CREATED
)
async def create_padrao(
    data: PadraoCreate, current_user: CurrentUser, service: EquipamentoServiceDep
):
    """Cadastra um novo padrão de calibração."""
    return await service.create_padrao(current_user.tenant_id, data)


@router.get("/padroes/{id}", response_model=PadraoPublic)
async def get_padrao(
    id: int, current_user: CurrentUser, service: EquipamentoServiceDep
):
    """Obtém detalhes de um padrão."""
    return await service.get_padrao_by_id(current_user.tenant_id, id)


@router.patch("/padroes/{id}", response_model=PadraoPublic)
async def update_padrao(
    id: int,
    data: PadraoUpdate,
    current_user: CurrentUser,
    service: EquipamentoServiceDep,
):
    """Atualiza dados de um padrão."""
    return await service.update_padrao(current_user.tenant_id, id, data)


@router.delete("/padroes/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_padrao(
    id: int, current_user: CurrentUser, service: EquipamentoServiceDep
):
    """Remove um padrão."""
    await service.delete_padrao(current_user.tenant_id, id)


@router.post(
    "/padroes/{id}/calibracoes",
    response_model=HistoricoCalibracaoPadraoPublic,
    status_code=status.HTTP_201_CREATED,
)
async def registrar_calibracao_padrao(
    id: int,
    data: HistoricoCalibracaoPadraoCreate,
    current_user: CurrentUser,
    service: EquipamentoServiceDep,
):
    """Registra uma nova calibração externa de um padrão."""
    return await service.registrar_calibracao_externa(current_user.tenant_id, id, data)


@router.get(
    "/padroes/{id}/calibracoes", response_model=list[HistoricoCalibracaoPadraoPublic]
)
async def list_historico_padrao(
    id: int, current_user: CurrentUser, service: EquipamentoServiceDep
):
    """Lista histórico de calibracoes externas de um padrão."""
    return await service.get_historico_padrao(current_user.tenant_id, id)


@router.patch(
    "/padroes/{id}/calibracoes/{historico_id}",
    response_model=HistoricoCalibracaoPadraoPublic,
)
async def update_historico_padrao(
    id: int,
    historico_id: int,
    data: HistoricoCalibracaoPadraoUpdate,
    current_user: CurrentUser,
    service: EquipamentoServiceDep,
):
    """Atualiza um registro de calibração de um padrão."""
    return await service.update_historico_padrao(
        current_user.tenant_id, id, historico_id, data
    )


@router.delete(
    "/padroes/{id}/calibracoes/{historico_id}", status_code=status.HTTP_204_NO_CONTENT
)
async def delete_historico_padrao(
    id: int,
    historico_id: int,
    current_user: CurrentUser,
    service: EquipamentoServiceDep,
):
    """Remove um registro de calibração de um padrão."""
    await service.delete_historico_padrao(current_user.tenant_id, id, historico_id)

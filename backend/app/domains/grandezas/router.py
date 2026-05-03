from fastapi import APIRouter, status

from app.auth.dependencies import CurrentUser
from app.domains.grandezas.schema import (
    GrandezaCreate,
    GrandezaPublic,
    TipoIncertezaBTemplateCreate,
    TipoIncertezaBTemplatePublic,
    UnidadeMedidaCreate,
    UnidadeMedidaPublic,
)
from app.domains.grandezas.service import GrandezaServiceDep

router = APIRouter(prefix="/api/grandezas", tags=["Metrologia — Grandezas"])


@router.get("/", response_model=list[GrandezaPublic])
async def list_grandezas(_: CurrentUser, service: GrandezaServiceDep):
    """Lista todas as grandezas físicas cadastradas no sistema."""
    return await service.get_all()


@router.get("/{grandeza_id}", response_model=GrandezaPublic)
async def get_grandeza(grandeza_id: int, _: CurrentUser, service: GrandezaServiceDep):
    """Obtém detalhes de uma grandeza específica."""
    return await service.get_by_id(grandeza_id)


@router.post("/", response_model=GrandezaPublic, status_code=status.HTTP_201_CREATED)
async def create_grandeza(
    data: GrandezaCreate, _: CurrentUser, service: GrandezaServiceDep
):
    """Cadastra uma nova grandeza (Global)."""
    return await service.create(data)


@router.post(
    "/{grandeza_id}/unidades",
    response_model=UnidadeMedidaPublic,
    status_code=status.HTTP_201_CREATED,
)
async def add_unidade(
    grandeza_id: int,
    data: UnidadeMedidaCreate,
    _: CurrentUser,
    service: GrandezaServiceDep,
):
    """Adiciona uma unidade de medida a uma grandeza."""
    return await service.add_unidade(grandeza_id, data)


@router.delete(
    "/{grandeza_id}/unidades/{unidade_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_unidade(
    grandeza_id: int,
    unidade_id: int,
    _: CurrentUser,
    service: GrandezaServiceDep,
):
    """Remove uma unidade de medida de uma grandeza."""
    await service.delete_unidade(grandeza_id, unidade_id)


@router.post(
    "/{grandeza_id}/templates-b",
    response_model=TipoIncertezaBTemplatePublic,
    status_code=status.HTTP_201_CREATED,
)
async def add_template_incerteza_b(
    grandeza_id: int,
    data: TipoIncertezaBTemplateCreate,
    _: CurrentUser,
    service: GrandezaServiceDep,
):
    """Adiciona um template de incerteza Tipo B a uma grandeza."""
    return await service.add_template_b(grandeza_id, data)


@router.delete("/{grandeza_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_grandeza(
    grandeza_id: int, _: CurrentUser, service: GrandezaServiceDep
):
    """Remove uma grandeza."""
    await service.delete(grandeza_id)

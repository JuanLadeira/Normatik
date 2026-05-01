from fastapi import APIRouter, status

from app.auth.dependencies import CurrentUser
from app.domains.ordens_servico.schema import (
    OrdemDeServicoCreate,
    OrdemDeServicoPublic,
    OrdemDeServicoUpdate,
)
from app.domains.ordens_servico.service import OSServiceDep

router = APIRouter(prefix="/api/os", tags=["Metrologia — Ordens de Serviço"])


@router.get("/", response_model=list[OrdemDeServicoPublic])
async def list_os(
    current_user: CurrentUser, service: OSServiceDep, cliente_id: int | None = None
):
    """Lista ordens de serviço do laboratório."""
    return await service.get_all(current_user.tenant_id, cliente_id)


@router.post(
    "/", response_model=OrdemDeServicoPublic, status_code=status.HTTP_201_CREATED
)
async def create_os(
    data: OrdemDeServicoCreate, current_user: CurrentUser, service: OSServiceDep
):
    """Abre uma nova ordem de serviço."""
    return await service.create(current_user.tenant_id, data)


@router.get("/{id}", response_model=OrdemDeServicoPublic)
async def get_os(id: int, current_user: CurrentUser, service: OSServiceDep):
    """Obtém detalhes de uma OS (incluindo itens)."""
    return await service.get_by_id(current_user.tenant_id, id)


@router.patch("/{id}", response_model=OrdemDeServicoPublic)
async def update_os(
    id: int,
    data: OrdemDeServicoUpdate,
    current_user: CurrentUser,
    service: OSServiceDep,
):
    """Atualiza dados de uma OS."""
    return await service.update(current_user.tenant_id, id, data)


@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_os(id: int, current_user: CurrentUser, service: OSServiceDep):
    """Remove uma OS."""
    await service.delete(current_user.tenant_id, id)

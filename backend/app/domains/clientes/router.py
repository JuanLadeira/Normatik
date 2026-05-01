from fastapi import APIRouter, status

from app.auth.dependencies import CurrentUser
from app.domains.clientes.schema import (
    ClienteLaboratorioCreate,
    ClienteLaboratorioPublic,
    ClienteLaboratorioUpdate,
)
from app.domains.clientes.service import ClienteServiceDep

router = APIRouter(prefix="/api/clientes", tags=["Metrologia — Clientes"])


@router.get("/", response_model=list[ClienteLaboratorioPublic])
async def list_clientes(current_user: CurrentUser, service: ClienteServiceDep):
    """Lista todos os clientes do laboratório logado."""
    return await service.get_all(current_user.tenant_id)


@router.post(
    "/", response_model=ClienteLaboratorioPublic, status_code=status.HTTP_201_CREATED
)
async def create_cliente(
    data: ClienteLaboratorioCreate,
    current_user: CurrentUser,
    service: ClienteServiceDep,
):
    """Cadastra um novo cliente no laboratório."""
    return await service.create(current_user.tenant_id, data)


@router.get("/{cliente_id}", response_model=ClienteLaboratorioPublic)
async def get_cliente(
    cliente_id: int, current_user: CurrentUser, service: ClienteServiceDep
):
    """Obtém detalhes de um cliente."""
    return await service.get_by_id(current_user.tenant_id, cliente_id)


@router.patch("/{cliente_id}", response_model=ClienteLaboratorioPublic)
async def update_cliente(
    cliente_id: int,
    data: ClienteLaboratorioUpdate,
    current_user: CurrentUser,
    service: ClienteServiceDep,
):
    """Atualiza dados de um cliente."""
    return await service.update(current_user.tenant_id, cliente_id, data)


@router.delete("/{cliente_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_cliente(
    cliente_id: int, current_user: CurrentUser, service: ClienteServiceDep
):
    """Remove um cliente."""
    await service.delete(current_user.tenant_id, cliente_id)

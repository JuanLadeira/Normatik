from typing import Annotated

from fastapi import Depends, HTTPException, status

from app.domains.clientes.model import ClienteLaboratorio
from app.domains.clientes.repository import ClienteRepository, ClienteRepositoryDep
from app.domains.clientes.schema import (
    ClienteLaboratorioCreate,
    ClienteLaboratorioUpdate,
)


class ClienteService:
    def __init__(self, repo: ClienteRepository):
        self.repo = repo

    async def get_all(self, tenant_id: int) -> list[ClienteLaboratorio]:
        return await self.repo.get_all(tenant_id)

    async def get_by_id(self, tenant_id: int, cliente_id: int) -> ClienteLaboratorio:
        cliente = await self.repo.get_by_id(tenant_id, cliente_id)
        if not cliente:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cliente não encontrado",
            )
        return cliente

    async def create(
        self, tenant_id: int, data: ClienteLaboratorioCreate
    ) -> ClienteLaboratorio:
        if data.cnpj:
            existing = await self.repo.get_by_cnpj(tenant_id, data.cnpj)
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Já existe um cliente com este CNPJ neste laboratório",
                )
        cliente = ClienteLaboratorio(tenant_id=tenant_id, **data.model_dump())
        return await self.repo.save(cliente)

    async def update(
        self, tenant_id: int, cliente_id: int, data: ClienteLaboratorioUpdate
    ) -> ClienteLaboratorio:
        cliente = await self.get_by_id(tenant_id, cliente_id)

        update_data = data.model_dump(exclude_unset=True)
        if "cnpj" in update_data and update_data["cnpj"] != cliente.cnpj:
            existing = await self.repo.get_by_cnpj(tenant_id, update_data["cnpj"])
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Já existe outro cliente com este CNPJ neste laboratório",
                )

        for key, value in update_data.items():
            setattr(cliente, key, value)

        return await self.repo.save(cliente)

    async def delete(self, tenant_id: int, cliente_id: int) -> None:
        cliente = await self.get_by_id(tenant_id, cliente_id)
        await self.repo.delete(cliente)


def get_cliente_service(repo: ClienteRepositoryDep) -> ClienteService:
    return ClienteService(repo)


ClienteServiceDep = Annotated[ClienteService, Depends(get_cliente_service)]

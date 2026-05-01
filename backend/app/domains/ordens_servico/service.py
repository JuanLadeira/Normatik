from typing import Annotated

from fastapi import Depends, HTTPException, status

from app.domains.ordens_servico.model import ItemOS, OrdemDeServico
from app.domains.ordens_servico.repository import OSRepository, OSRepositoryDep
from app.domains.ordens_servico.schema import OrdemDeServicoCreate, OrdemDeServicoUpdate


class OSService:
    def __init__(self, repo: OSRepository):
        self.repo = repo

    async def get_all(
        self, tenant_id: int, cliente_id: int | None = None
    ) -> list[OrdemDeServico]:
        return await self.repo.get_all(tenant_id, cliente_id)

    async def get_by_id(self, tenant_id: int, os_id: int) -> OrdemDeServico:
        os = await self.repo.get_by_id(tenant_id, os_id)
        if not os:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Ordem de Serviço não encontrada",
            )
        return os

    async def create(
        self, tenant_id: int, data: OrdemDeServicoCreate
    ) -> OrdemDeServico:
        existing = await self.repo.get_by_numero(tenant_id, data.numero)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Já existe uma OS com este número neste laboratório",
            )

        # Cria a OS e os itens
        itens = [ItemOS(**item.model_dump()) for item in data.itens]

        os = OrdemDeServico(
            tenant_id=tenant_id,
            cliente_id=data.cliente_id,
            numero=data.numero,
            status=data.status,
            data_entrada=data.data_entrada,
            data_prevista=data.data_prevista,
            observacoes=data.observacoes,
            itens=itens,
        )

        return await self.repo.save(os)

    async def update(
        self, tenant_id: int, os_id: int, data: OrdemDeServicoUpdate
    ) -> OrdemDeServico:
        os = await self.get_by_id(tenant_id, os_id)

        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(os, key, value)

        return await self.repo.save(os)

    async def delete(self, tenant_id: int, os_id: int) -> None:
        os = await self.get_by_id(tenant_id, os_id)
        await self.repo.delete(os)

    async def get_item_by_id(self, tenant_id: int, os_id: int, item_id: int) -> ItemOS:
        os = await self.get_by_id(tenant_id, os_id)
        item = await self.repo.get_item_by_id(item_id)

        if not item or item.os_id != os.id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Item de OS não encontrado nesta Ordem de Serviço",
            )
        return item


def get_os_service(repo: OSRepositoryDep) -> OSService:
    return OSService(repo)


OSServiceDep = Annotated[OSService, Depends(get_os_service)]

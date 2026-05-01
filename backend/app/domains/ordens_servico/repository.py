from typing import Annotated

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import AsyncDBSession
from app.domains.ordens_servico.model import ItemOS, OrdemDeServico


class OSRepository:
    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_all(
        self, tenant_id: int, cliente_id: int | None = None
    ) -> list[OrdemDeServico]:
        query = (
            select(OrdemDeServico)
            .where(OrdemDeServico.tenant_id == tenant_id)
            .order_by(OrdemDeServico.data_entrada.desc())
        )
        if cliente_id:
            query = query.where(OrdemDeServico.cliente_id == cliente_id)

        result = await self._session.execute(
            query.options(selectinload(OrdemDeServico.itens))
        )
        return list(result.scalars().all())

    async def get_by_id(self, tenant_id: int, os_id: int) -> OrdemDeServico | None:
        result = await self._session.execute(
            select(OrdemDeServico)
            .where(OrdemDeServico.tenant_id == tenant_id, OrdemDeServico.id == os_id)
            .options(selectinload(OrdemDeServico.itens))
        )
        return result.scalar_one_or_none()

    async def get_by_numero(self, tenant_id: int, numero: str) -> OrdemDeServico | None:
        result = await self._session.execute(
            select(OrdemDeServico)
            .where(
                OrdemDeServico.tenant_id == tenant_id, OrdemDeServico.numero == numero
            )
            .options(selectinload(OrdemDeServico.itens))
        )
        return result.scalar_one_or_none()

    async def save(self, os: OrdemDeServico) -> OrdemDeServico:
        self._session.add(os)
        await self._session.flush()
        # Recarrega com os itens carregados para o schema Public
        return await self.get_by_id(os.tenant_id, os.id)

    async def delete(self, os: OrdemDeServico) -> None:
        await self._session.delete(os)
        await self._session.flush()

    async def get_item_by_id(self, item_id: int) -> ItemOS | None:
        return await self._session.get(ItemOS, item_id)


def get_os_repository(session: AsyncDBSession) -> OSRepository:
    return OSRepository(session)


OSRepositoryDep = Annotated[OSRepository, Depends(get_os_repository)]

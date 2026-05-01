from typing import Annotated

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncDBSession
from app.domains.clientes.model import ClienteLaboratorio


class ClienteRepository:
    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_all(self, tenant_id: int) -> list[ClienteLaboratorio]:
        result = await self._session.execute(
            select(ClienteLaboratorio)
            .where(ClienteLaboratorio.tenant_id == tenant_id)
            .order_by(ClienteLaboratorio.nome)
        )
        return list(result.scalars().all())

    async def get_by_id(
        self, tenant_id: int, cliente_id: int
    ) -> ClienteLaboratorio | None:
        result = await self._session.execute(
            select(ClienteLaboratorio).where(
                ClienteLaboratorio.tenant_id == tenant_id,
                ClienteLaboratorio.id == cliente_id,
            )
        )
        return result.scalar_one_or_none()

    async def get_by_cnpj(self, tenant_id: int, cnpj: str) -> ClienteLaboratorio | None:
        result = await self._session.execute(
            select(ClienteLaboratorio).where(
                ClienteLaboratorio.tenant_id == tenant_id,
                ClienteLaboratorio.cnpj == cnpj,
            )
        )
        return result.scalar_one_or_none()

    async def save(self, cliente: ClienteLaboratorio) -> ClienteLaboratorio:
        self._session.add(cliente)
        await self._session.flush()
        await self._session.refresh(cliente)
        return cliente

    async def delete(self, cliente: ClienteLaboratorio) -> None:
        await self._session.delete(cliente)
        await self._session.flush()


def get_cliente_repository(session: AsyncDBSession) -> ClienteRepository:
    return ClienteRepository(session)


ClienteRepositoryDep = Annotated[ClienteRepository, Depends(get_cliente_repository)]

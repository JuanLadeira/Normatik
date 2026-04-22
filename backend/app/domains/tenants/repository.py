from typing import Annotated

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncDBSession
from app.domains.tenants.model import Tenant, TenantStatus


class TenantRepository:
    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_all(self) -> list[Tenant]:
        result = await self._session.execute(select(Tenant).order_by(Tenant.id))
        return list(result.scalars().all())

    async def get_by_id(self, tenant_id: int) -> Tenant | None:
        return await self._session.get(Tenant, tenant_id)

    async def get_by_slug(self, slug: str) -> Tenant | None:
        result = await self._session.execute(select(Tenant).where(Tenant.slug == slug))
        return result.scalar_one_or_none()

    async def list_by_status(self, status: TenantStatus) -> list[Tenant]:
        result = await self._session.execute(
            select(Tenant).where(Tenant.status == status).order_by(Tenant.id)
        )
        return list(result.scalars().all())

    async def save(self, tenant: Tenant) -> Tenant:
        self._session.add(tenant)
        await self._session.flush()
        await self._session.refresh(tenant)
        return tenant

    async def delete(self, tenant: Tenant) -> None:
        await self._session.delete(tenant)
        await self._session.flush()


def get_tenant_repository(session: AsyncDBSession) -> TenantRepository:
    return TenantRepository(session)


TenantRepositoryDep = Annotated[TenantRepository, Depends(get_tenant_repository)]

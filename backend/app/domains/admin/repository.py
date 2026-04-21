from typing import Annotated

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncDBSession
from app.domains.admin.model import Admin


class AdminRepository:
    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_by_id(self, admin_id: int) -> Admin | None:
        return await self._session.get(Admin, admin_id)

    async def get_by_username(self, username: str) -> Admin | None:
        result = await self._session.execute(
            select(Admin).where(Admin.username == username)
        )
        return result.scalar_one_or_none()

    async def get_all(self) -> list[Admin]:
        result = await self._session.execute(select(Admin).order_by(Admin.id))
        return list(result.scalars().all())

    async def save(self, admin: Admin) -> Admin:
        self._session.add(admin)
        await self._session.flush()
        await self._session.refresh(admin)
        return admin


def get_admin_repository(session: AsyncDBSession) -> AdminRepository:
    return AdminRepository(session)


AdminRepositoryDep = Annotated[AdminRepository, Depends(get_admin_repository)]

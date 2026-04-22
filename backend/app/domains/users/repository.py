from typing import Annotated

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncDBSession
from app.domains.users.model import User


class UserRepository:
    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_by_id(self, user_id: int) -> User | None:
        return await self._session.get(User, user_id)

    async def get_by_email(self, email: str) -> User | None:
        result = await self._session.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    async def get_by_email_and_tenant(self, email: str, tenant_id: int) -> User | None:
        result = await self._session.execute(
            select(User).where(User.email == email, User.tenant_id == tenant_id)
        )
        return result.scalar_one_or_none()

    async def get_by_invite_token(self, token: str) -> User | None:
        result = await self._session.execute(
            select(User).where(User.invite_token == token)
        )
        return result.scalar_one_or_none()

    async def list_by_tenant(self, tenant_id: int) -> list[User]:
        result = await self._session.execute(
            select(User).where(User.tenant_id == tenant_id).order_by(User.id)
        )
        return list(result.scalars().all())

    async def count_active_by_tenant(self, tenant_id: int) -> int:
        from sqlalchemy import func

        result = await self._session.execute(
            select(func.count(User.id)).where(
                User.tenant_id == tenant_id,
                User.is_active.is_(True),
            )
        )
        return result.scalar_one()

    async def save(self, user: User) -> User:
        self._session.add(user)
        await self._session.flush()
        await self._session.refresh(user)
        return user

    async def delete(self, user: User) -> None:
        await self._session.delete(user)
        await self._session.flush()


def get_user_repository(session: AsyncDBSession) -> UserRepository:
    return UserRepository(session)


UserRepositoryDep = Annotated[UserRepository, Depends(get_user_repository)]

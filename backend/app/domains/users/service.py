from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import Depends

from app.core.security import (
    create_invite_token,
    decode_invite_token,
    get_password_hash,
)
from app.domains.users.model import User
from app.domains.users.repository import UserRepository, UserRepositoryDep
from app.domains.users.schema import UserInvite, UserUpdate


class UserService:
    def __init__(self, repo: UserRepository):
        self.repo = repo

    async def get_by_id(self, user_id: int) -> User | None:
        return await self.repo.get_by_id(user_id)

    async def get_by_email(self, email: str) -> User | None:
        return await self.repo.get_by_email(email)

    async def list_by_tenant(self, tenant_id: int) -> list[User]:
        return await self.repo.list_by_tenant(tenant_id)

    async def count_active(self, tenant_id: int) -> int:
        return await self.repo.count_active_by_tenant(tenant_id)

    async def invite(self, tenant_id: int, data: UserInvite) -> User:
        """Cria o usuário com status pendente e gera o token de convite (expira em 48h)."""
        token = create_invite_token(data.email)
        user = User(
            tenant_id=tenant_id,
            email=data.email,
            nome=data.nome,
            role=data.role,
            is_active=False,
            invite_token=token,
            invite_expires_at=datetime.now(timezone.utc) + timedelta(hours=48),
        )
        return await self.repo.save(user)

    async def accept_invite(self, token: str, password: str) -> User | None:
        """Valida o token de convite, define a senha e ativa o usuário."""
        email = decode_invite_token(token)
        if not email:
            return None
        user = await self.repo.get_by_invite_token(token)
        if not user:
            return None
        if (
            user.invite_expires_at
            and datetime.now(timezone.utc) > user.invite_expires_at
        ):
            return None
        user.password = get_password_hash(password)
        user.is_active = True
        user.invite_token = None
        user.invite_expires_at = None
        return await self.repo.save(user)

    async def update(self, user_id: int, data: UserUpdate) -> User | None:
        user = await self.repo.get_by_id(user_id)
        if not user:
            return None
        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(user, key, value)
        return await self.repo.save(user)

    async def deactivate(self, user_id: int) -> User | None:
        """Soft delete — bloqueia acesso sem apagar o usuário."""
        user = await self.repo.get_by_id(user_id)
        if not user:
            return None
        user.is_active = False
        return await self.repo.save(user)

    async def update_password(self, user: User, new_password: str) -> User:
        user.password = get_password_hash(new_password)
        return await self.repo.save(user)


def get_user_service(repo: UserRepositoryDep) -> UserService:
    return UserService(repo)


UserServiceDep = Annotated[UserService, Depends(get_user_service)]

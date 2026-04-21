from typing import Annotated

from fastapi import Depends

from app.core.security import get_password_hash
from app.domains.admin.model import Admin
from app.domains.admin.repository import AdminRepository, AdminRepositoryDep
from app.domains.admin.schema import AdminCreate


class AdminService:
    def __init__(self, repo: AdminRepository):
        self.repo = repo

    async def get_by_id(self, admin_id: int) -> Admin | None:
        return await self.repo.get_by_id(admin_id)

    async def get_by_username(self, username: str) -> Admin | None:
        return await self.repo.get_by_username(username)

    async def get_all(self) -> list[Admin]:
        return await self.repo.get_all()

    async def create(self, data: AdminCreate) -> Admin:
        admin = Admin(
            username=data.username,
            email=data.email,
            password=get_password_hash(data.password),
            nome=data.nome,
        )
        return await self.repo.save(admin)

    async def set_totp_secret(self, admin_id: int, secret: str) -> Admin | None:
        admin = await self.repo.get_by_id(admin_id)
        if not admin:
            return None
        admin.totp_secret = secret
        return await self.repo.save(admin)

    async def enable_totp(self, admin_id: int) -> Admin | None:
        admin = await self.repo.get_by_id(admin_id)
        if not admin:
            return None
        admin.totp_habilitado = True
        return await self.repo.save(admin)

    async def disable_totp(self, admin_id: int) -> Admin | None:
        admin = await self.repo.get_by_id(admin_id)
        if not admin:
            return None
        admin.totp_secret = None
        admin.totp_habilitado = False
        return await self.repo.save(admin)


def get_admin_service(repo: AdminRepositoryDep) -> AdminService:
    return AdminService(repo)


AdminServiceDep = Annotated[AdminService, Depends(get_admin_service)]

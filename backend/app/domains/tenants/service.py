import re
import secrets
from datetime import UTC, datetime, timedelta
from typing import Annotated

from fastapi import Depends

from app.core.settings import Settings
from app.domains.tenants.model import Tenant, TenantStatus
from app.domains.tenants.repository import TenantRepository, TenantRepositoryDep
from app.domains.tenants.schema import TenantCreate, TenantUpdate

settings = Settings()


def _slugify(text: str) -> str:
    text = text.lower().strip()
    text = re.sub(r"[àáâãä]", "a", text)
    text = re.sub(r"[èéêë]", "e", text)
    text = re.sub(r"[ìíîï]", "i", text)
    text = re.sub(r"[òóôõö]", "o", text)
    text = re.sub(r"[ùúûü]", "u", text)
    text = re.sub(r"[ç]", "c", text)
    text = re.sub(r"[^a-z0-9\s-]", "", text)
    text = re.sub(r"[\s-]+", "-", text)
    return text.strip("-")


class TenantService:
    def __init__(self, repo: TenantRepository):
        self.repo = repo

    async def get_all(self) -> list[Tenant]:
        return await self.repo.get_all()

    async def get_by_id(self, tenant_id: int) -> Tenant | None:
        return await self.repo.get_by_id(tenant_id)

    async def create(self, data: TenantCreate) -> Tenant:
        slug = await self._unique_slug(data.nome)
        trial_expires_at = datetime.now(UTC).replace(tzinfo=None) + timedelta(
            days=data.trial_days or settings.DEFAULT_TRIAL_DAYS
        )
        tenant = Tenant(
            nome=data.nome,
            slug=slug,
            cnpj=data.cnpj,
            email_gestor=data.email_gestor,
            status=TenantStatus.trial,
            trial_expires_at=trial_expires_at,
        )
        return await self.repo.save(tenant)

    async def update(self, tenant_id: int, data: TenantUpdate) -> Tenant | None:
        tenant = await self.repo.get_by_id(tenant_id)
        if not tenant:
            return None
        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(tenant, key, value)
        return await self.repo.save(tenant)

    async def activate(self, tenant_id: int, plan_id: int) -> Tenant | None:
        tenant = await self.repo.get_by_id(tenant_id)
        if not tenant:
            return None
        tenant.status = TenantStatus.active
        tenant.plan_id = plan_id
        tenant.trial_expires_at = None
        return await self.repo.save(tenant)

    async def suspend(self, tenant_id: int) -> Tenant | None:
        tenant = await self.repo.get_by_id(tenant_id)
        if not tenant:
            return None
        tenant.status = TenantStatus.suspended
        return await self.repo.save(tenant)

    async def extend_trial(self, tenant_id: int, days: int) -> Tenant | None:
        tenant = await self.repo.get_by_id(tenant_id)
        if not tenant:
            return None
        now_naive = datetime.now(UTC).replace(tzinfo=None)
        base = max(
            tenant.trial_expires_at or now_naive,
            now_naive,
        )
        tenant.trial_expires_at = base + timedelta(days=days)
        tenant.status = TenantStatus.trial
        return await self.repo.save(tenant)

    async def delete(self, tenant_id: int) -> bool:
        tenant = await self.repo.get_by_id(tenant_id)
        if not tenant:
            return False
        await self.repo.delete(tenant)
        return True

    async def _unique_slug(self, nome: str) -> str:
        base = _slugify(nome)
        slug = base
        existing = await self.repo.get_by_slug(slug)
        if existing:
            slug = f"{base}-{secrets.token_hex(3)}"
        return slug


def get_tenant_service(repo: TenantRepositoryDep) -> TenantService:
    return TenantService(repo)


TenantServiceDep = Annotated[TenantService, Depends(get_tenant_service)]

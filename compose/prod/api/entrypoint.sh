#!/bin/bash
set -e

echo "[entrypoint] Rodando migrações Alembic..."
uv run alembic upgrade head
echo "[entrypoint] Migrações aplicadas."

echo "[entrypoint] Rodando seed inicial..."
uv run python -c "
import asyncio
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from app.core.settings import settings
from app.core.security import get_password_hash
from app.core.database import Base

from app.domains.plans.model import Plan
from app.domains.tenants.model import Tenant, TenantStatus
from app.domains.users.model import User, UserRole
from app.domains.subscriptions.model import Subscription
from app.domains.admin.model import Admin

async def main():
    engine = create_async_engine(settings.DATABASE_URL)
    Session = async_sessionmaker(engine, expire_on_commit=False)

    async with Session() as session:
        async with session.begin():
            result = await session.execute(
                select(Admin).where(Admin.username == settings.ADMIN_DEFAULT_USERNAME)
            )
            admin = result.scalar_one_or_none()

            if not admin:
                session.add(Admin(
                    username=settings.ADMIN_DEFAULT_USERNAME,
                    email=settings.OWNER_EMAIL,
                    password=get_password_hash(settings.ADMIN_DEFAULT_PASSWORD),
                    nome='Super Administrador',
                    ativo=True,
                ))
                print(f'[seed] Admin {settings.ADMIN_DEFAULT_USERNAME!r} criado.')
            else:
                admin.password = get_password_hash(settings.ADMIN_DEFAULT_PASSWORD)
                admin.email = settings.OWNER_EMAIL
                print(f'[seed] Admin {settings.ADMIN_DEFAULT_USERNAME!r} atualizado.')

            result = await session.execute(
                select(Tenant).where(Tenant.slug == settings.OWNER_TENANT_SLUG)
            )
            tenant = result.scalar_one_or_none()

            if not tenant:
                tenant = Tenant(
                    nome=settings.OWNER_TENANT_NAME,
                    slug=settings.OWNER_TENANT_SLUG,
                    email_gestor=settings.OWNER_EMAIL,
                    status=TenantStatus.active,
                )
                session.add(tenant)
                await session.flush()
                print(f'[seed] Tenant {settings.OWNER_TENANT_SLUG!r} criado.')

            result = await session.execute(
                select(User).where(User.email == settings.OWNER_EMAIL)
            )
            user = result.scalar_one_or_none()

            if not user:
                session.add(User(
                    email=settings.OWNER_EMAIL,
                    password=get_password_hash(settings.OWNER_PASSWORD),
                    nome='Dono do Laboratório',
                    role=UserRole.admin,
                    tenant_id=tenant.id,
                    is_active=True,
                ))
                print(f'[seed] Usuário {settings.OWNER_EMAIL!r} criado.')
            else:
                user.password = get_password_hash(settings.OWNER_PASSWORD)
                user.tenant_id = tenant.id
                user.is_active = True
                print(f'[seed] Usuário {settings.OWNER_EMAIL!r} atualizado.')

asyncio.run(main())
"
echo "[entrypoint] Seed concluído."

echo "[entrypoint] Iniciando servidor..."
exec "$@"

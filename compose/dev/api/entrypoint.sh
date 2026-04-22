#!/bin/bash
set -e

echo "[entrypoint] Rodando migrações Alembic..."
uv run alembic upgrade head

echo "[entrypoint] Rodando seed inicial..."
uv run python -c "
import asyncio
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

from app.core.settings import settings
from app.core.security import get_password_hash
from app.core.database import Base

# Importa todos os models para registrar no metadata
from app.domains.plans.model import Plan         # noqa
from app.domains.tenants.model import Tenant     # noqa
from app.domains.users.model import User         # noqa
from app.domains.subscriptions.model import Subscription  # noqa
from app.domains.admin.model import Admin        # noqa

async def main():
    engine = create_async_engine(settings.DATABASE_URL)
    Session = async_sessionmaker(engine, expire_on_commit=False)

    # Seed admin global
    async with Session() as session:
        async with session.begin():
            result = await session.execute(
                select(Admin).where(Admin.username == settings.ADMIN_DEFAULT_USERNAME)
            )
            if not result.scalar_one_or_none():
                session.add(Admin(
                    username=settings.ADMIN_DEFAULT_USERNAME,
                    email=f'{settings.ADMIN_DEFAULT_USERNAME}@normatiq.com.br',
                    password=get_password_hash(settings.ADMIN_DEFAULT_PASSWORD),
                    nome='Administrador',
                    ativo=True,
                ))
                print(f'[seed] Admin {settings.ADMIN_DEFAULT_USERNAME!r} criado.')
            else:
                print(f'[seed] Admin {settings.ADMIN_DEFAULT_USERNAME!r} já existe.')

asyncio.run(main())
"

echo "[entrypoint] Pronto. Iniciando servidor..."
exec "$@"

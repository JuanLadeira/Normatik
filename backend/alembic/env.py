import asyncio
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

from alembic import context

# Importa todos os models para que o autogenerate os detecte
from app.core.database import Base  # noqa: F401
from app.core.settings import settings
from app.domains.plans.model import Plan  # noqa: F401
from app.domains.tenants.model import Tenant  # noqa: F401
from app.domains.users.model import User  # noqa: F401
from app.domains.subscriptions.model import Subscription  # noqa: F401
from app.domains.admin.model import Admin  # noqa: F401
from app.domains.outbox.model import OutboxEvent  # noqa: F401
from app.domains.grandezas.model import Grandeza, TipoIncertezaBTemplate  # noqa: F401
from app.domains.clientes.model import ClienteLaboratorio  # noqa: F401
from app.domains.equipamentos.model import TipoEquipamento, Fabricante, ModeloEquipamento, Equipamento, Instrumento, PadraoDeCalibração, HistoricoCalibracaoPadrao  # noqa: F401
from app.domains.ordens_servico.model import OrdemDeServico, ItemOS  # noqa: F401
from app.domains.calibracoes.model import ServicoDeCalibração, IncertezaBFonte, PontoDeCalibração  # noqa: F401

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    context.configure(connection=connection, target_metadata=target_metadata)
    with context.begin_transaction():
        context.run_migrations()


async def run_migrations_online() -> None:
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)
    await connectable.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    asyncio.run(run_migrations_online())

import asyncio
import logging
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from app.core.settings import settings
from app.core.security import get_password_hash

# IMPORTANTE: Importar todos os models para o SQLAlchemy resolver relacionamentos
from app.domains.tenants.model import Tenant, TenantStatus
from app.domains.users.model import User, UserRole
from app.domains.admin.model import Admin

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("seed")


async def run_seed():
    logger.info(f"Conectando ao banco: {settings.DATABASE_URL}")
    engine = create_async_engine(settings.DATABASE_URL)
    Session = async_sessionmaker(engine, expire_on_commit=False)

    async with Session() as session:
        try:
            # 1. ADMIN
            logger.info("Verificando Admin...")
            result = await session.execute(
                select(Admin).where(Admin.username == settings.ADMIN_DEFAULT_USERNAME)
            )
            admin = result.scalar_one_or_none()
            if not admin:
                admin = Admin(
                    username=settings.ADMIN_DEFAULT_USERNAME,
                    email=settings.OWNER_EMAIL,
                    password=get_password_hash(settings.ADMIN_DEFAULT_PASSWORD),
                    nome="Super Administrador",
                    ativo=True,
                )
                session.add(admin)
                logger.info(f"Admin {settings.ADMIN_DEFAULT_USERNAME} criado.")
            else:
                admin.password = get_password_hash(settings.ADMIN_DEFAULT_PASSWORD)
                admin.email = settings.OWNER_EMAIL
                logger.info(
                    f"Admin {settings.ADMIN_DEFAULT_USERNAME} já existe, dados atualizados."
                )

            # 2. TENANT
            logger.info("Verificando Tenant...")
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
                logger.info(f"Tenant {settings.OWNER_TENANT_SLUG} criado.")
            else:
                logger.info(f"Tenant {settings.OWNER_TENANT_SLUG} já existe.")

            # 3. USER
            logger.info("Verificando Usuário Operacional...")
            result = await session.execute(
                select(User).where(User.email == settings.OWNER_EMAIL)
            )
            user = result.scalar_one_or_none()
            if not user:
                user = User(
                    email=settings.OWNER_EMAIL,
                    password=get_password_hash(settings.OWNER_PASSWORD),
                    nome="Dono do Laboratório",
                    role=UserRole.admin,
                    tenant_id=tenant.id,
                    is_active=True,
                )
                session.add(user)
                logger.info(f"Usuário {settings.OWNER_EMAIL} criado.")
            else:
                user.password = get_password_hash(settings.OWNER_PASSWORD)
                user.tenant_id = tenant.id
                user.is_active = True
                logger.info(
                    f"Usuário {settings.OWNER_EMAIL} já existe, dados atualizados."
                )

            await session.commit()
            logger.info("Seed finalizado com sucesso!")

        except Exception as e:
            logger.error(f"ERRO NO SEED: {e}")
            await session.rollback()
            raise e
        finally:
            await engine.dispose()


if __name__ == "__main__":
    asyncio.run(run_seed())

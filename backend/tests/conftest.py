import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

from app.core.database import Base, get_db
from app.core.security import get_password_hash
from app.core.settings import settings
from app.domains.users.model import User, UserRole
from app.main import app

# Usar o mesmo banco normatik com transações isoladas por teste.
TEST_DATABASE_URL = settings.DATABASE_URL


@pytest.fixture(scope="function", autouse=True)
async def setup_test_db():
    """Garante que todas as tabelas existem no banco de testes."""
    engine = create_async_engine(TEST_DATABASE_URL)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await engine.dispose()


@pytest.fixture
async def db_session():
    """Cria uma sessão de banco que sofre rollback após o teste."""
    engine = create_async_engine(TEST_DATABASE_URL)
    connection = await engine.connect()
    transaction = await connection.begin()
    session = AsyncSession(bind=connection, expire_on_commit=False)

    yield session

    await session.close()
    await transaction.rollback()
    await connection.close()
    await engine.dispose()


@pytest.fixture
async def client(db_session):
    """Cria um cliente HTTP que usa a sessão de banco do teste."""

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()


@pytest.fixture(autouse=True)
def reset_rate_limit():
    """Reseta o rate limit antes/depois de cada teste."""
    from app.core.rate_limit import limiter

    limiter._limiter.storage.reset()
    yield
    limiter._limiter.storage.reset()


@pytest.fixture
async def admin_user(db_session):
    """Cria um usuário admin de teste."""
    from app.domains.tenants.model import Tenant, TenantStatus

    # Cria tenant se não houver um padrão para o admin
    t = Tenant(
        nome="Lab Fixture",
        slug="lab-fixture",
        status=TenantStatus.active,
        email_gestor="admin_fixture@test.com",
        cnpj="00.000.000/0001-91",
    )
    db_session.add(t)
    await db_session.flush()

    u = User(
        email="admin_fixture@test.com",
        password=get_password_hash("password123"),
        nome="Admin Fixture",
        role=UserRole.admin,
        tenant_id=t.id,
        is_active=True,
    )
    db_session.add(u)
    await db_session.commit()
    return u


@pytest.fixture
async def admin_token(client, admin_user):
    """Retorna um token de acesso para o admin de teste."""
    login_data = {"username": admin_user.email, "password": "password123"}
    response = await client.post("/api/auth/login", data=login_data)
    return response.json()["access_token"]

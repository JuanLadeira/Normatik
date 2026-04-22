import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

from app.core.database import get_db
from app.core.settings import settings
from app.main import app

# Usar o mesmo banco normatik com transações isoladas por teste.
TEST_DATABASE_URL = settings.DATABASE_URL


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

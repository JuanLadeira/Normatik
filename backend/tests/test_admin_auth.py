import pytest
from app.domains.admin.model import Admin
from app.core.security import get_password_hash


@pytest.fixture
async def setup_admin(db_session):
    """Cria um admin de teste explicitamente."""
    admin = Admin(
        username="admin_test",
        email="admin@test.com",
        password=get_password_hash("testpassword123"),
        nome="Admin de Teste",
        ativo=True,
    )
    db_session.add(admin)
    await db_session.commit()
    return admin


@pytest.mark.asyncio
async def test_admin_login_success(client, setup_admin):
    """
    Testa se o admin criado no teste consegue logar.
    """
    # Payload para login (OAuth2 Form)
    login_data = {"username": "admin_test", "password": "testpassword123"}

    # Tenta logar
    response = await client.post("/api/admin/login", data=login_data)

    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_admin_me_requires_auth(client):
    """
    Verifica se o endpoint /me do admin exige autenticação.
    """
    response = await client.get("/api/admin/me")
    assert response.status_code == 401

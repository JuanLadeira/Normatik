import pytest


@pytest.mark.asyncio
async def test_admin_login_success(client, db_session):
    """
    Testa se o admin padrão criado no seed consegue logar.
    """
    from app.core.settings import settings

    # Payload para login (OAuth2 Form)
    login_data = {
        "username": settings.ADMIN_DEFAULT_USERNAME,
        "password": settings.ADMIN_DEFAULT_PASSWORD,
    }

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

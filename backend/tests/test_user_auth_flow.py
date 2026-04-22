import pytest
from app.domains.tenants.model import Tenant, TenantStatus
from app.domains.users.model import User, UserRole
from app.core.security import get_password_hash


@pytest.fixture
async def sample_data(db_session):
    """Cria dois tenants e usuários para testes de isolamento."""
    # Tenant A
    t1 = Tenant(
        nome="Laboratório A",
        slug="lab-a",
        status=TenantStatus.active,
        email_gestor="admin@lab-a.com",
        cnpj="11.111.111/0001-11",
    )
    db_session.add(t1)
    await db_session.flush()

    u1 = User(
        email="user_a@lab-a.com",
        password=get_password_hash("password123"),
        nome="User A",
        role=UserRole.admin,
        tenant_id=t1.id,
        is_active=True,
    )
    db_session.add(u1)

    # Tenant B
    t2 = Tenant(
        nome="Laboratório B",
        slug="lab-b",
        status=TenantStatus.active,
        email_gestor="admin@lab-b.com",
        cnpj="22.222.222/0001-22",
    )
    db_session.add(t2)
    await db_session.flush()

    u2 = User(
        email="user_b@lab-b.com",
        password=get_password_hash("password123"),
        nome="User B",
        role=UserRole.admin,
        tenant_id=t2.id,
        is_active=True,
    )
    db_session.add(u2)
    await db_session.commit()

    return {"u1": u1, "u2": u2, "t1": t1, "t2": t2}


@pytest.mark.asyncio
async def test_user_login_and_me(client, sample_data):
    """Testa login de usuário e acesso ao próprio perfil."""
    login_data = {"username": "user_a@lab-a.com", "password": "password123"}

    # Login
    response = await client.post("/api/auth/login", data=login_data)
    assert response.status_code == 200
    token = response.json()["access_token"]

    # Perfil /me
    headers = {"Authorization": f"Bearer {token}"}
    response = await client.get("/api/auth/me", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "user_a@lab-a.com"
    assert data["tenant_id"] == sample_data["t1"].id


@pytest.mark.asyncio
async def test_tenant_isolation_list_users(client, sample_data):
    """Garante que um usuário só lista usuários do seu próprio tenant."""
    # Login como User A
    login_data = {"username": "user_a@lab-a.com", "password": "password123"}
    r_login = await client.post("/api/auth/login", data=login_data)
    token = r_login.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Lista usuários
    response = await client.get("/api/users/", headers=headers)
    assert response.status_code == 200
    users = response.json()

    # Deve ver apenas usuários do Tenant A
    assert len(users) == 1
    assert users[0]["email"] == "user_a@lab-a.com"
    # Não deve haver sinal do user_b
    assert all(u["email"] != "user_b@lab-b.com" for u in users)


@pytest.mark.asyncio
async def test_login_invalid_credentials(client):
    """Garante erro em credenciais erradas."""
    login_data = {"username": "wrong@test.com", "password": "wrongpassword"}
    response = await client.post("/api/auth/login", data=login_data)
    assert response.status_code == 401

import pytest
from app.domains.tenants.model import Tenant, TenantStatus
from app.domains.users.model import User, UserRole
from app.core.security import get_password_hash
from sqlalchemy import select

@pytest.fixture
async def admin_user(db_session):
    """Cria um tenant e um usuário admin."""
    t = Tenant(
        nome="Lab Teste",
        slug="lab-teste",
        status=TenantStatus.active,
        email_gestor="admin@labteste.com",
        cnpj="12.345.678/0001-90"
    )
    db_session.add(t)
    await db_session.flush()
    
    u = User(
        email="admin@labteste.com",
        password=get_password_hash("admin123"),
        nome="Admin Lab",
        role=UserRole.admin,
        tenant_id=t.id,
        is_active=True
    )
    db_session.add(u)
    await db_session.commit()
    return u

@pytest.fixture
async def admin_token(client, admin_user):
    """Retorna o token de acesso do admin."""
    login_data = {"username": admin_user.email, "password": "admin123"}
    response = await client.post("/api/auth/login", data=login_data)
    return response.json()["access_token"]

@pytest.mark.asyncio
async def test_invite_and_accept_flow(client, admin_token, db_session):
    """Testa o fluxo completo de convite e ativação de usuário."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    
    # 1. Enviar convite
    invite_data = {
        "email": "tecnico@labteste.com",
        "nome": "Técnico Novo",
        "role": "technician"
    }
    response = await client.post("/api/users/invite", json=invite_data, headers=headers)
    assert response.status_code == 201
    
    # 2. Buscar o token no banco (simulando o e-mail)
    result = await db_session.execute(
        select(User).where(User.email == "tecnico@labteste.com")
    )
    new_user = result.scalar_one()
    assert new_user.is_active is False
    assert new_user.invite_token is not None
    
    # 3. Aceitar convite (Definir senha)
    accept_data = {
        "invite_token": new_user.invite_token,
        "password": "newpassword123"
    }
    response = await client.post("/api/auth/accept-invite", json=accept_data)
    assert response.status_code == 200
    
    # 4. Validar que agora está ativo e consegue logar
    await db_session.refresh(new_user)
    assert new_user.is_active is True
    
    login_data = {"username": "tecnico@labteste.com", "password": "newpassword123"}
    r_login = await client.post("/api/auth/login", data=login_data)
    assert r_login.status_code == 200
    assert "access_token" in r_login.json()

@pytest.mark.asyncio
async def test_non_admin_cannot_invite(client, admin_user, db_session):
    """Garante que apenas admins podem convidar novos usuários (RBAC)."""
    # Cria um técnico
    u_tech = User(
        email="tech@labteste.com",
        password=get_password_hash("tech123"),
        nome="Técnico",
        role=UserRole.technician,
        tenant_id=admin_user.tenant_id,
        is_active=True
    )
    db_session.add(u_tech)
    await db_session.commit()
    
    # Login como técnico
    login_data = {"username": "tech@labteste.com", "password": "tech123"}
    r_login = await client.post("/api/auth/login", data=login_data)
    tech_token = r_login.json()["access_token"]
    
    # Tenta convidar (deve falhar)
    headers = {"Authorization": f"Bearer {tech_token}"}
    invite_data = {"email": "hack@labteste.com", "nome": "Hacker", "role": "admin"}
    response = await client.post("/api/users/invite", json=invite_data, headers=headers)
    
    assert response.status_code == 403
    assert response.json()["detail"] == "Permissão insuficiente"

@pytest.mark.asyncio
async def test_update_user(client, admin_token, db_session, admin_user):
    """Testa a atualização de dados de um usuário."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    
    # Cria um usuário
    u = User(
        email="update@labteste.com",
        nome="Original",
        role=UserRole.technician,
        tenant_id=admin_user.tenant_id,
        is_active=True
    )
    db_session.add(u)
    await db_session.commit()
    
    # Atualiza (Patch)
    update_data = {"nome": "Alterado", "role": "admin"}
    response = await client.patch(f"/api/users/{u.id}", json=update_data, headers=headers)
    assert response.status_code == 200
    assert response.json()["nome"] == "Alterado"
    assert response.json()["role"] == "admin"

@pytest.mark.asyncio
async def test_deactivate_user(client, admin_token, db_session, admin_user):
    """Testa a desativação de um usuário."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    
    # Cria um usuário para desativar
    u = User(
        email="deletar@labteste.com",
        nome="Deletar",
        role=UserRole.technician,
        tenant_id=admin_user.tenant_id,
        is_active=True
    )
    db_session.add(u)
    await db_session.commit()
    
    # Desativa
    response = await client.post(f"/api/users/{u.id}/deactivate", headers=headers)
    assert response.status_code == 200
    
    # Verifica no banco (soft delete)
    await db_session.refresh(u)
    assert u.is_active is False

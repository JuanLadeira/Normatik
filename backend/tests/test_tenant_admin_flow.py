import pytest
from app.core.settings import settings
from app.domains.admin.model import Admin
from app.core.security import get_password_hash

@pytest.fixture
async def admin_token(client, db_session):
    """Cria um admin e retorna o token de acesso."""
    admin = Admin(
        username="testadmin",
        email="testadmin@normatik.com.br",
        password=get_password_hash("password123"),
        nome="Test Admin",
        ativo=True
    )
    db_session.add(admin)
    await db_session.commit()
    
    login_data = {"username": "testadmin", "password": "password123"}
    response = await client.post("/api/admin/login", data=login_data)
    return response.json()["access_token"]

@pytest.mark.asyncio
async def test_admin_tenant_lifecycle(client, admin_token, db_session):
    """Testa o ciclo de vida de um tenant via API administrativa."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    
    # 1. Criar Tenant
    tenant_data = {
        "nome": "Novo Lab",
        "slug": "novo-lab",
        "cnpj": "00.000.000/0001-00",
        "email_gestor": "gestor@novolab.com"
    }
    response = await client.post("/api/admin/tenants/", json=tenant_data, headers=headers)
    assert response.status_code == 201
    tenant = response.json()
    assert tenant["nome"] == "Novo Lab"
    tenant_id = tenant["id"]
    
    # 2. Listar Tenants
    response = await client.get("/api/admin/tenants/", headers=headers)
    assert response.status_code == 200
    tenants = response.json()
    assert any(t["id"] == tenant_id for t in tenants)
    
    # 3. Detalhe do Tenant
    response = await client.get(f"/api/admin/tenants/{tenant_id}", headers=headers)
    assert response.status_code == 200
    assert response.json()["nome"] == "Novo Lab"
    
    # 4. Atualizar Tenant (Patch)
    update_data = {"nome": "Novo Lab Alterado"}
    response = await client.patch(f"/api/admin/tenants/{tenant_id}", json=update_data, headers=headers)
    assert response.status_code == 200
    assert response.json()["nome"] == "Novo Lab Alterado"
    
    # 5. Suspender Tenant
    response = await client.post(f"/api/admin/tenants/{tenant_id}/suspend", headers=headers)
    assert response.status_code == 200
    assert response.json()["status"] == "suspended"
    
    # 6. Ativar Tenant (precisa de um plano)
    from app.domains.plans.model import Plan
    plan = Plan(nome="Plano Teste", preco_mensal=100.0)
    db_session.add(plan)
    await db_session.commit()
    
    activate_data = {"plan_id": plan.id}
    response = await client.post(f"/api/admin/tenants/{tenant_id}/activate", json=activate_data, headers=headers)
    assert response.status_code == 200
    assert response.json()["status"] == "active"
    
    # 7. Prorrogar Trial
    response = await client.post(f"/api/admin/tenants/{tenant_id}/extend-trial", json={"days": 15}, headers=headers)
    assert response.status_code == 200
    assert response.json()["status"] == "trial"
    
    # 8. Deletar Tenant
    response = await client.delete(f"/api/admin/tenants/{tenant_id}", headers=headers)
    assert response.status_code == 204
    
    # Verificar que sumiu
    response = await client.get(f"/api/admin/tenants/{tenant_id}", headers=headers)
    assert response.status_code == 404

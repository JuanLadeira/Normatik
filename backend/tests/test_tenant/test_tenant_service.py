import pytest
from datetime import datetime, timedelta, timezone
from sqlalchemy import select
from app.domains.tenants.model import Tenant, TenantStatus
from app.domains.tenants.repository import TenantRepository
from app.domains.tenants.service import TenantService
from app.domains.tenants.schema import TenantCreate

@pytest.mark.asyncio
async def test_create_tenant_success(db_session):
    """
    Testa a criação de um tenant com sucesso e valida o slug gerado.
    """
    repo = TenantRepository(db_session)
    service = TenantService(repo)
    data = TenantCreate(
        nome="Empresa Teste",
        email_gestor="gestor@teste.com",
        cnpj="12.345.678/0001-90"
    )
    
    tenant = await service.create(data)
    
    assert tenant.id is not None
    assert tenant.nome == "Empresa Teste"
    assert tenant.slug == "empresa-teste"
    assert tenant.status == TenantStatus.trial
    assert tenant.trial_expires_at is not None
    
    # Valida que foi persistido
    result = await db_session.execute(select(Tenant).where(Tenant.id == tenant.id))
    db_tenant = result.scalar_one()
    assert db_tenant.nome == "Empresa Teste"

@pytest.mark.asyncio
async def test_tenant_is_active_logic():
    """
    Testa a lógica da propriedade 'is_active' do model Tenant.
    """
    # Ativo
    t1 = Tenant(status=TenantStatus.active)
    assert t1.is_active is True
    
    # Inativo
    t2 = Tenant(status=TenantStatus.inactive)
    assert t2.is_active is False
    
    # Trial válido
    future = datetime.now(timezone.utc).replace(tzinfo=None) + timedelta(days=1)
    t3 = Tenant(status=TenantStatus.trial, trial_expires_at=future)
    assert t3.is_active is True
    
    # Trial expirado
    past = datetime.now(timezone.utc).replace(tzinfo=None) - timedelta(days=1)
    t4 = Tenant(status=TenantStatus.trial, trial_expires_at=past)
    assert t4.is_active is False

@pytest.mark.asyncio
async def test_create_tenant_duplicate_slug_auto_suffix(db_session):
    """
    Testa se a criação de um tenant com nome similar gera um slug único com sufixo.
    """
    repo = TenantRepository(db_session)
    service = TenantService(repo)
    
    data1 = TenantCreate(nome="Empresa Igual", email_gestor="g1@t.com")
    t1 = await service.create(data1)
    await db_session.flush()
    
    data2 = TenantCreate(nome="Empresa Igual", email_gestor="g2@t.com")
    t2 = await service.create(data2)
    
    assert t1.slug == "empresa-igual"
    assert t2.slug.startswith("empresa-igual-")
    assert len(t2.slug) > len(t1.slug)

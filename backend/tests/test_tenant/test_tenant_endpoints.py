import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
@pytest.mark.tenant
class TestTenantEndpoints:
    """Verifica que os endpoints públicos foram removidos (segurança)."""

    async def test_create_tenant_publico_removido(self, client: AsyncClient):
        r = await client.post("/api/tenants/", json={"nome": "Casa Nova"})
        assert r.status_code in (404, 405)

    async def test_get_tenant_publico_removido(self, client: AsyncClient):
        r = await client.get("/api/tenants/1")
        assert r.status_code in (404, 405)

    async def test_list_tenants_publico_removido(self, client: AsyncClient):
        r = await client.get("/api/tenants/")
        assert r.status_code in (404, 405)

    async def test_update_tenant_publico_removido(self, client: AsyncClient):
        r = await client.put("/api/tenants/1", json={"nome": "Novo"})
        assert r.status_code in (404, 405)

    async def test_delete_tenant_publico_removido(self, client: AsyncClient):
        r = await client.delete("/api/tenants/1")
        assert r.status_code in (404, 405)

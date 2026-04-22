import pytest


@pytest.mark.asyncio
async def test_health_check(client):
    """
    Testa se o endpoint de health check está respondendo 'ok' usando a fixture client.
    """
    response = await client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

import uuid

import pytest


@pytest.mark.asyncio
async def test_grandezas_api_flow(client, admin_token):
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. Criar Grandeza (nome único para evitar colisão com runs anteriores)
    nome_unico = f"Comprimento-{uuid.uuid4().hex[:8]}"
    data = {"nome": nome_unico, "simbolo": "L"}
    response = await client.post("/api/grandezas/", json=data, headers=headers)
    assert response.status_code == 201
    grandeza_id = response.json()["id"]

    # 2. Listar Grandezas
    r_list = await client.get("/api/grandezas/", headers=headers)
    assert response.status_code == 201
    assert any(g["nome"] == nome_unico for g in r_list.json())

    # 3. Adicionar Template B
    template_data = {
        "descricao": "Resolução",
        "distribuicao": "RETANGULAR",
        "graus_liberdade": 100,
    }
    r_temp = await client.post(
        f"/api/grandezas/{grandeza_id}/templates-b", json=template_data, headers=headers
    )
    assert r_temp.status_code == 201
    assert r_temp.json()["descricao"] == "Resolução"


@pytest.mark.asyncio
async def test_os_api_flow(client, admin_token):
    headers = {"Authorization": f"Bearer {admin_token}"}

    # Setup: Criar cliente primeiro
    c_data = {"nome": "Cliente API", "cnpj": "999"}
    r_c = await client.post("/api/clientes/", json=c_data, headers=headers)
    cliente_id = r_c.json()["id"]

    # 1. Abrir OS com Itens
    os_data = {
        "cliente_id": cliente_id,
        "numero": "OS-API-01",
        "data_entrada": "2024-05-01T10:00:00",
        "itens": [
            {"descricao": "Item 1", "quantidade_prevista": 2},
            {"descricao": "Item 2", "quantidade_prevista": 1},
        ],
    }
    response = await client.post("/api/os/", json=os_data, headers=headers)
    assert response.status_code == 201
    assert len(response.json()["itens"]) == 2

    # 2. Listar OS
    r_list = await client.get("/api/os/", headers=headers)
    assert len(r_list.json()) >= 1


@pytest.mark.asyncio
async def test_calibracao_api_full_math(client, admin_token):
    headers = {"Authorization": f"Bearer {admin_token}"}

    # Setup: Cliente -> OS -> Item
    r_c = await client.post("/api/clientes/", json={"nome": "C1"}, headers=headers)
    c_id = r_c.json()["id"]

    os_data = {
        "cliente_id": c_id,
        "numero": "OS-MATH",
        "data_entrada": "2024-05-01T10:00:00",
        "itens": [{"descricao": "Item Math"}],
    }
    r_os = await client.post("/api/os/", json=os_data, headers=headers)
    item_id = r_os.json()["itens"][0]["id"]

    # 1. Iniciar Serviço
    s_data = {"item_os_id": item_id, "workbook_type": "P"}
    r_s = await client.post("/api/calibracoes/", json=s_data, headers=headers)
    servico_id = r_s.json()["id"]

    # 2. Adicionar Fonte B
    f_data = {"descricao": "F1", "valor_u": 1.0, "distribuicao": "NORMAL"}
    await client.post(
        f"/api/calibracoes/{servico_id}/fontes-b", json=f_data, headers=headers
    )

    # 3. Adicionar Ponto
    p_data = {
        "posicao": 1,
        "valor_nominal": 10.0,
        "unidade": "mm",
        "leituras_instrumento": [10.0, 10.0],
        "fator_k": 2.0,
    }
    r_p = await client.post(
        f"/api/calibracoes/{servico_id}/pontos", json=p_data, headers=headers
    )

    # u_exp deve ser 2.0 (2 * 1.0)
    assert r_p.json()["u_expandida"] == 2.0

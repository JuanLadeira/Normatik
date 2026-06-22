"""Testes unitários e de integração para o domínio certificados_padrao.

Grupos:
  1. Funções puras (sem banco) — calcular_curva, _derivar_campos, schemas Pydantic
  2. Service com banco real — usando db_session + fixtures de setup
  3. API — usando fixtures client + admin_token
"""

import uuid
from datetime import date, timedelta

import pytest
from pydantic import ValidationError

from app.domains.certificados_padrao.service import (
    _derivar_campos,
    calcular_curva,
)
from app.domains.certificados_padrao.model import (
    StatusCertificado,
    StatusCurva,
    TipoRegressao,
)
from app.domains.certificados_padrao.schema import (
    AnalisarRequest,
    AprovarCurvaRequest,
    CertificadoCreate,
    PontoMedicaoCreate,
    RejeitarCurvaRequest,
)
from app.domains.users.model import UserRole


# ═══════════════════════════════════════════════════════════════════════════════
# GRUPO 1 — Funções puras
# ═══════════════════════════════════════════════════════════════════════════════


# ── calcular_curva ─────────────────────────────────────────────────────────────


def test_calcular_curva_linear_perfeita():
    """y = 2x + 1 deve gerar coeffs ≈ [1.0, 2.0], R² ≈ 1.0 e 100 pontos na curva."""
    pontos = [{"x": i, "y": 2 * i + 1} for i in range(4)]
    coeffs, r2, pts_curva = calcular_curva(pontos, "x", "y", TipoRegressao.linear, 1)

    assert coeffs[0] == pytest.approx(1.0, abs=1e-6)
    assert coeffs[1] == pytest.approx(2.0, abs=1e-6)
    assert r2 == pytest.approx(1.0, abs=1e-6)
    assert len(pts_curva) == 100


def test_calcular_curva_retorna_coeficientes_ordem_crescente():
    """coeffs[0] deve ser o termo independente (a0), não o de maior grau."""
    # y = 3x + 5 → coeffs = [5.0, 3.0]
    pontos = [{"x": float(i), "y": 3.0 * i + 5.0} for i in range(5)]
    coeffs, _r2, _pts = calcular_curva(pontos, "x", "y", TipoRegressao.linear, 1)

    # a0 (intercepto) deve ser 5.0
    assert coeffs[0] == pytest.approx(5.0, abs=1e-6)
    # a1 (inclinação) deve ser 3.0
    assert coeffs[1] == pytest.approx(3.0, abs=1e-6)


def test_calcular_curva_polinomial_grau2():
    """y = x² deve gerar coeffs[2] ≈ 1.0 com grau 2."""
    pontos = [{"x": float(i), "y": float(i**2)} for i in range(5)]
    coeffs, r2, _pts = calcular_curva(pontos, "x", "y", TipoRegressao.polinomial, 2)

    assert coeffs[2] == pytest.approx(1.0, abs=1e-6)
    assert r2 == pytest.approx(1.0, abs=1e-6)


def test_calcular_curva_pontos_insuficientes():
    """2 pontos com grau=2 deve lançar ValueError."""
    pontos = [{"x": 0.0, "y": 0.0}, {"x": 1.0, "y": 1.0}]
    with pytest.raises(ValueError, match="Mínimo"):
        calcular_curva(pontos, "x", "y", TipoRegressao.polinomial, 2)


def test_calcular_curva_r2_entre_0_e_1():
    """R² deve estar no intervalo [0, 1] com pontos com ruído."""
    pontos = [
        {"x": 0.0, "y": 0.1},
        {"x": 1.0, "y": 0.9},
        {"x": 2.0, "y": 2.2},
        {"x": 3.0, "y": 2.8},
        {"x": 4.0, "y": 4.1},
    ]
    _coeffs, r2, _pts = calcular_curva(pontos, "x", "y", TipoRegressao.linear, 1)

    assert 0.0 <= r2 <= 1.0


def test_calcular_curva_ss_tot_zero():
    """Todos os y's iguais (ss_tot = 0) não deve lançar exceção; R² deve ser 1.0."""
    pontos = [{"x": float(i), "y": 5.0} for i in range(4)]
    coeffs, r2, pts = calcular_curva(pontos, "x", "y", TipoRegressao.linear, 1)

    assert r2 == pytest.approx(1.0)
    assert len(pts) == 100


# ── _derivar_campos ────────────────────────────────────────────────────────────


def test_derivar_campos_avg():
    """avg(l1, l2) deve calcular a média entre os dois campos."""
    campos_def = [{"nome": "media", "calculado": "avg(l1,l2)"}]
    valores = {"l1": 10.0, "l2": 20.0}
    resultado = _derivar_campos(valores, campos_def)

    assert resultado["media"] == pytest.approx(15.0)


def test_derivar_campos_subtracao():
    """media - nominal deve calcular a diferença."""
    campos_def = [{"nome": "erro", "calculado": "media-nominal"}]
    valores = {"media": 10.5, "nominal": 10.0}
    resultado = _derivar_campos(valores, campos_def)

    assert resultado["erro"] == pytest.approx(0.5)


def test_derivar_campos_campo_entrada_nao_alterado():
    """Campo com calculado=False deve preservar o valor original sem alteração."""
    campos_def = [{"nome": "x", "calculado": False}]
    valores = {"x": 42.0}
    resultado = _derivar_campos(valores, campos_def)

    assert resultado["x"] == 42.0


def test_derivar_campos_formula_desconhecida():
    """Fórmula desconhecida (ex: 'max(c1)') deve retornar None para o campo sem lançar exceção."""
    campos_def = [{"nome": "valor", "calculado": "max(c1)"}]
    valores = {"c1": 5.0}
    resultado = _derivar_campos(valores, campos_def)

    assert resultado["valor"] is None


def test_derivar_campos_valor_ausente():
    """avg de campos onde um não existe nos valores deve retornar None sem lançar exceção."""
    campos_def = [{"nome": "media", "calculado": "avg(a,b)"}]
    valores = {"a": 10.0}  # "b" ausente
    resultado = _derivar_campos(valores, campos_def)

    assert resultado["media"] is None


# ── Schemas Pydantic ───────────────────────────────────────────────────────────


def test_schema_certificado_create_k_zero_invalido():
    """CertificadoCreate com k_abrangencia=0 deve lançar ValidationError."""
    with pytest.raises(ValidationError):
        CertificadoCreate(
            padrao_id=1,
            numero_certificado="CERT-001",
            laboratorio_calibrador="Lab",
            data_emissao=date.today(),
            data_validade=date.today() + timedelta(days=365),
            U_expandida=1.0,
            k_abrangencia=0,
        )


def test_schema_certificado_create_k_negativo_invalido():
    """CertificadoCreate com k_abrangencia=-2 deve lançar ValidationError."""
    with pytest.raises(ValidationError):
        CertificadoCreate(
            padrao_id=1,
            numero_certificado="CERT-002",
            laboratorio_calibrador="Lab",
            data_emissao=date.today(),
            data_validade=date.today() + timedelta(days=365),
            U_expandida=1.0,
            k_abrangencia=-2,
        )


def test_schema_rejeitar_curva_observacoes_obrigatorio():
    """RejeitarCurvaRequest sem observacoes deve lançar ValidationError."""
    with pytest.raises(ValidationError):
        RejeitarCurvaRequest()  # observacoes é obrigatório


# ═══════════════════════════════════════════════════════════════════════════════
# GRUPO 2 — Service com banco real
# ═══════════════════════════════════════════════════════════════════════════════


@pytest.fixture
async def padrao_fixture(db_session, admin_user):
    """Cria Grandeza, TipoEquipamento e PadraoDeCalibração para os testes de service."""
    from app.domains.grandezas.model import Grandeza
    from app.domains.equipamentos.model import TipoEquipamento, PadraoDeCalibração

    uid = uuid.uuid4().hex[:8]

    g = Grandeza(nome=f"Grandeza-{uid}", simbolo="G")
    db_session.add(g)
    await db_session.flush()

    tipo = TipoEquipamento(
        grandeza_id=g.id,
        codigo=f"TIPO-{uid}",
        nome=f"Tipo Equip {uid}",
    )
    db_session.add(tipo)
    await db_session.flush()

    padrao = PadraoDeCalibração(
        tenant_id=admin_user.tenant_id,
        tipo_equipamento_id=tipo.id,
        numero_serie=f"SN-{uid}",
        marca="MarcaTeste",
        modelo="ModeloTeste",
        alerta_dias_antes=30,
    )
    db_session.add(padrao)
    await db_session.flush()

    return padrao, tipo, admin_user


def _make_cert_data(padrao_id: int, suffix: str = "") -> CertificadoCreate:
    """Helper para criar um CertificadoCreate com número único."""
    uid = uuid.uuid4().hex[:8]
    return CertificadoCreate(
        padrao_id=padrao_id,
        numero_certificado=f"CERT-{uid}{suffix}",
        laboratorio_calibrador="Lab Externo",
        data_emissao=date.today(),
        data_validade=date.today() + timedelta(days=365),
        U_expandida=0.5,
        k_abrangencia=2.0,
    )


def _make_service(db_session):
    """Instancia CertificadoPadraoService com o db_session do teste."""
    from unittest.mock import MagicMock

    from app.domains.certificados_padrao.repository import CertificadoPadraoRepository
    from app.domains.certificados_padrao.service import CertificadoPadraoService

    repo = CertificadoPadraoRepository(db_session)
    storage = MagicMock()
    return CertificadoPadraoService(repo, storage)


@pytest.mark.asyncio
async def test_criar_certificado_calcula_u_padrao(db_session, padrao_fixture):
    """Criar certificado com U_expandida=0.5, k=2.0 deve persistir u_padrao ≈ 0.25."""
    padrao, _tipo, admin_user = padrao_fixture
    service = _make_service(db_session)

    data = CertificadoCreate(
        padrao_id=padrao.id,
        numero_certificado=f"CERT-{uuid.uuid4().hex[:8]}",
        laboratorio_calibrador="Lab Externo",
        data_emissao=date.today(),
        data_validade=date.today() + timedelta(days=365),
        U_expandida=0.5,
        k_abrangencia=2.0,
    )
    cert = await service.criar_certificado(data, admin_user)

    assert cert.u_padrao == pytest.approx(0.25)


@pytest.mark.asyncio
async def test_atualizar_certificado_recalcula_u_padrao(db_session, padrao_fixture):
    """Atualizar U_expandida=1.0 (k permanece 2.0) deve recalcular u_padrao para 0.5."""
    from app.domains.certificados_padrao.schema import CertificadoUpdate

    padrao, _tipo, admin_user = padrao_fixture
    service = _make_service(db_session)

    data = CertificadoCreate(
        padrao_id=padrao.id,
        numero_certificado=f"CERT-{uuid.uuid4().hex[:8]}",
        laboratorio_calibrador="Lab Externo",
        data_emissao=date.today(),
        data_validade=date.today() + timedelta(days=365),
        U_expandida=0.5,
        k_abrangencia=2.0,
    )
    cert = await service.criar_certificado(data, admin_user)

    update = CertificadoUpdate(U_expandida=1.0)
    cert_atualizado = await service.atualizar_certificado(cert.id, update)

    assert cert_atualizado.u_padrao == pytest.approx(0.5)


@pytest.mark.asyncio
async def test_salvar_pontos_replace_all(db_session, padrao_fixture):
    """Salvar 3 pontos e depois salvar 2 novos deve deixar exatamente 2 pontos no banco."""
    padrao, _tipo, admin_user = padrao_fixture
    service = _make_service(db_session)
    from app.domains.certificados_padrao.repository import CertificadoPadraoRepository

    repo = CertificadoPadraoRepository(db_session)

    cert = await service.criar_certificado(_make_cert_data(padrao.id), admin_user)

    pontos_3 = [
        PontoMedicaoCreate(ordem=i, valores={"x": float(i), "y": float(i) * 2})
        for i in range(3)
    ]
    await service.salvar_pontos(cert.id, pontos_3)

    pontos_apos_primeiro = await repo.list_pontos(cert.id)
    assert len(pontos_apos_primeiro) == 3

    pontos_2 = [
        PontoMedicaoCreate(ordem=i, valores={"x": float(i), "y": float(i) * 3})
        for i in range(2)
    ]
    await service.salvar_pontos(cert.id, pontos_2)

    pontos_final = await repo.list_pontos(cert.id)
    assert len(pontos_final) == 2


@pytest.mark.asyncio
async def test_analisar_certificado_cria_curva_sugerida(db_session, padrao_fixture):
    """Analisar certificado com pontos y=2x+1 deve criar curva com status=sugerida
    e atualizar certificado para aguardando_aprovacao_curva."""
    padrao, _tipo, admin_user = padrao_fixture
    service = _make_service(db_session)

    cert = await service.criar_certificado(_make_cert_data(padrao.id), admin_user)

    pontos = [
        PontoMedicaoCreate(ordem=i, valores={"x": float(i), "y": 2.0 * i + 1.0})
        for i in range(4)
    ]
    await service.salvar_pontos(cert.id, pontos)

    req = AnalisarRequest(campo_x="x", campo_y="y", tipo=TipoRegressao.linear, grau=1)
    curva = await service.analisar_certificado(cert.id, req)

    assert curva.status == StatusCurva.sugerida

    cert_atualizado = await service.get_certificado(cert.id)
    assert cert_atualizado.status == StatusCertificado.aguardando_aprovacao_curva


@pytest.mark.asyncio
async def test_analisar_certificado_sem_pontos_lanca_422(db_session, padrao_fixture):
    """Chamar analisar_certificado em certificado sem pontos deve lançar HTTPException(422)."""
    from fastapi import HTTPException

    padrao, _tipo, admin_user = padrao_fixture
    service = _make_service(db_session)

    cert = await service.criar_certificado(_make_cert_data(padrao.id), admin_user)

    req = AnalisarRequest(campo_x="x", campo_y="y", tipo=TipoRegressao.linear, grau=1)

    with pytest.raises(HTTPException) as exc_info:
        await service.analisar_certificado(cert.id, req)

    assert exc_info.value.status_code == 422


@pytest.mark.asyncio
async def test_aprovar_curva_atualiza_status(db_session, padrao_fixture):
    """Fluxo completo criar → pontos → analisar → aprovar deve marcar curva=aprovada,
    certificado=ativo e setar curva.aprovado_por com id do admin."""
    padrao, _tipo, admin_user = padrao_fixture
    service = _make_service(db_session)

    cert = await service.criar_certificado(_make_cert_data(padrao.id), admin_user)

    pontos = [
        PontoMedicaoCreate(ordem=i, valores={"x": float(i), "y": 2.0 * i + 1.0})
        for i in range(4)
    ]
    await service.salvar_pontos(cert.id, pontos)

    req_analisar = AnalisarRequest(
        campo_x="x", campo_y="y", tipo=TipoRegressao.linear, grau=1
    )
    await service.analisar_certificado(cert.id, req_analisar)

    req_aprovar = AprovarCurvaRequest(observacoes="Aprovado em teste")
    curva = await service.aprovar_curva(cert.id, req_aprovar, admin_user)

    assert curva.status == StatusCurva.aprovada
    assert curva.aprovado_por == admin_user.id

    cert_final = await service.get_certificado(cert.id)
    assert cert_final.status == StatusCertificado.ativo


@pytest.mark.asyncio
async def test_aprovar_curva_role_invalido_lanca_403(db_session, padrao_fixture):
    """Chamar aprovar_curva com user de role=technician deve lançar HTTPException(403)."""
    from fastapi import HTTPException
    from app.domains.users.model import User
    from app.core.security import get_password_hash

    padrao, _tipo, admin_user = padrao_fixture
    service = _make_service(db_session)

    # Cria usuário technician no mesmo tenant
    tech_user = User(
        email=f"tech-{uuid.uuid4().hex[:8]}@test.com",
        password=get_password_hash("pass"),
        nome="Técnico",
        role=UserRole.technician,
        tenant_id=admin_user.tenant_id,
        is_active=True,
    )
    db_session.add(tech_user)
    await db_session.flush()

    cert = await service.criar_certificado(_make_cert_data(padrao.id), admin_user)

    pontos = [
        PontoMedicaoCreate(ordem=i, valores={"x": float(i), "y": 2.0 * i + 1.0})
        for i in range(4)
    ]
    await service.salvar_pontos(cert.id, pontos)

    req_analisar = AnalisarRequest(
        campo_x="x", campo_y="y", tipo=TipoRegressao.linear, grau=1
    )
    await service.analisar_certificado(cert.id, req_analisar)

    req_aprovar = AprovarCurvaRequest()
    with pytest.raises(HTTPException) as exc_info:
        await service.aprovar_curva(cert.id, req_aprovar, tech_user)

    assert exc_info.value.status_code == 403


@pytest.mark.asyncio
async def test_rejeitar_curva_atualiza_status(db_session, padrao_fixture):
    """Fluxo criar → pontos → analisar → rejeitar deve marcar curva=rejeitada
    e certificado=rascunho."""
    padrao, _tipo, admin_user = padrao_fixture
    service = _make_service(db_session)

    cert = await service.criar_certificado(_make_cert_data(padrao.id), admin_user)

    pontos = [
        PontoMedicaoCreate(ordem=i, valores={"x": float(i), "y": 2.0 * i + 1.0})
        for i in range(4)
    ]
    await service.salvar_pontos(cert.id, pontos)

    req_analisar = AnalisarRequest(
        campo_x="x", campo_y="y", tipo=TipoRegressao.linear, grau=1
    )
    await service.analisar_certificado(cert.id, req_analisar)

    req_rejeitar = RejeitarCurvaRequest(observacoes="Curva fora dos critérios")
    curva = await service.rejeitar_curva(cert.id, req_rejeitar, admin_user)

    assert curva.status == StatusCurva.rejeitada

    cert_final = await service.get_certificado(cert.id)
    assert cert_final.status == StatusCertificado.rascunho


@pytest.mark.asyncio
async def test_get_curva_ativa_retorna_404_sem_curva_aprovada(
    db_session, padrao_fixture
):
    """get_curva_ativa em certificado sem curva aprovada deve lançar HTTPException(404)."""
    from fastapi import HTTPException

    padrao, _tipo, admin_user = padrao_fixture
    service = _make_service(db_session)

    cert = await service.criar_certificado(_make_cert_data(padrao.id), admin_user)

    with pytest.raises(HTTPException) as exc_info:
        await service.get_curva_ativa(cert.id)

    assert exc_info.value.status_code == 404


@pytest.mark.asyncio
async def test_aprovar_curva_atualiza_padrao(db_session, padrao_fixture):
    """Após aprovar curva, padrao.u_expandida_atual deve ser atualizado com u_padrao do certificado."""
    padrao, _tipo, admin_user = padrao_fixture
    service = _make_service(db_session)

    data = CertificadoCreate(
        padrao_id=padrao.id,
        numero_certificado=f"CERT-{uuid.uuid4().hex[:8]}",
        laboratorio_calibrador="Lab Externo",
        data_emissao=date.today(),
        data_validade=date.today() + timedelta(days=365),
        U_expandida=0.5,
        k_abrangencia=2.0,
    )
    cert = await service.criar_certificado(data, admin_user)
    u_padrao_esperado = cert.u_padrao  # 0.25

    pontos = [
        PontoMedicaoCreate(ordem=i, valores={"x": float(i), "y": 2.0 * i + 1.0})
        for i in range(4)
    ]
    await service.salvar_pontos(cert.id, pontos)

    req_analisar = AnalisarRequest(
        campo_x="x", campo_y="y", tipo=TipoRegressao.linear, grau=1
    )
    await service.analisar_certificado(cert.id, req_analisar)

    req_aprovar = AprovarCurvaRequest()
    await service.aprovar_curva(cert.id, req_aprovar, admin_user)

    await db_session.refresh(padrao)
    assert padrao.u_expandida_atual == pytest.approx(u_padrao_esperado)


# ═══════════════════════════════════════════════════════════════════════════════
# GRUPO 3 — API
# ═══════════════════════════════════════════════════════════════════════════════


@pytest.fixture
async def padrao_api_fixture(db_session, admin_user):
    """Cria PadraoDeCalibração para os testes de API (sem retornar o db_session)."""
    from app.domains.grandezas.model import Grandeza
    from app.domains.equipamentos.model import TipoEquipamento, PadraoDeCalibração

    uid = uuid.uuid4().hex[:8]

    g = Grandeza(nome=f"GrandezaAPI-{uid}", simbolo="GA")
    db_session.add(g)
    await db_session.flush()

    tipo = TipoEquipamento(
        grandeza_id=g.id,
        codigo=f"TIPOAPI-{uid}",
        nome=f"Tipo API {uid}",
    )
    db_session.add(tipo)
    await db_session.flush()

    padrao = PadraoDeCalibração(
        tenant_id=admin_user.tenant_id,
        tipo_equipamento_id=tipo.id,
        numero_serie=f"SN-API-{uid}",
        marca="MarcaAPI",
        modelo="ModeloAPI",
        alerta_dias_antes=30,
    )
    db_session.add(padrao)
    await db_session.flush()

    return padrao


@pytest.mark.asyncio
async def test_api_criar_certificado_201(client, admin_token, padrao_api_fixture):
    """POST /api/certificados-padrao/certificados com payload válido deve retornar 201
    com u_padrao calculado."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    padrao = padrao_api_fixture

    payload = {
        "padrao_id": padrao.id,
        "numero_certificado": f"CERT-API-{uuid.uuid4().hex[:8]}",
        "laboratorio_calibrador": "Lab API",
        "data_emissao": str(date.today()),
        "data_validade": str(date.today() + timedelta(days=365)),
        "U_expandida": 0.4,
        "k_abrangencia": 2.0,
    }
    response = await client.post(
        "/api/certificados-padrao/certificados", json=payload, headers=headers
    )
    assert response.status_code == 201
    body = response.json()
    assert body["u_padrao"] == pytest.approx(0.2)


@pytest.mark.asyncio
async def test_api_criar_certificado_k_zero_422(
    client, admin_token, padrao_api_fixture
):
    """POST com k_abrangencia=0 deve retornar 422."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    padrao = padrao_api_fixture

    payload = {
        "padrao_id": padrao.id,
        "numero_certificado": f"CERT-K0-{uuid.uuid4().hex[:8]}",
        "laboratorio_calibrador": "Lab",
        "data_emissao": str(date.today()),
        "data_validade": str(date.today() + timedelta(days=365)),
        "U_expandida": 1.0,
        "k_abrangencia": 0,
    }
    response = await client.post(
        "/api/certificados-padrao/certificados", json=payload, headers=headers
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_api_analisar_sem_pontos_422(client, admin_token, padrao_api_fixture):
    """POST /analisar em certificado sem pontos deve retornar 422."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    padrao = padrao_api_fixture

    # Cria certificado sem pontos via API
    payload = {
        "padrao_id": padrao.id,
        "numero_certificado": f"CERT-SEM-{uuid.uuid4().hex[:8]}",
        "laboratorio_calibrador": "Lab",
        "data_emissao": str(date.today()),
        "data_validade": str(date.today() + timedelta(days=365)),
        "U_expandida": 1.0,
        "k_abrangencia": 2.0,
    }
    r_cert = await client.post(
        "/api/certificados-padrao/certificados", json=payload, headers=headers
    )
    cert_id = r_cert.json()["id"]

    req_analisar = {"campo_x": "x", "campo_y": "y", "tipo": "linear", "grau": 1}
    response = await client.post(
        f"/api/certificados-padrao/certificados/{cert_id}/analisar",
        json=req_analisar,
        headers=headers,
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_api_aprovar_sem_autenticacao_401(client, padrao_api_fixture):
    """POST /aprovar sem header Authorization deve retornar 401."""
    response = await client.post(
        "/api/certificados-padrao/certificados/9999/aprovar",
        json={},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_api_fluxo_completo(client, admin_token, padrao_api_fixture):
    """Ciclo completo via HTTP: criar → pontos → analisar → aprovar → GET curva.
    Status final do certificado deve ser 'ativo'."""
    headers = {"Authorization": f"Bearer {admin_token}"}
    padrao = padrao_api_fixture

    # 1. Criar certificado
    payload_cert = {
        "padrao_id": padrao.id,
        "numero_certificado": f"CERT-FULL-{uuid.uuid4().hex[:8]}",
        "laboratorio_calibrador": "Lab Completo",
        "data_emissao": str(date.today()),
        "data_validade": str(date.today() + timedelta(days=365)),
        "U_expandida": 0.6,
        "k_abrangencia": 2.0,
    }
    r_cert = await client.post(
        "/api/certificados-padrao/certificados", json=payload_cert, headers=headers
    )
    assert r_cert.status_code == 201
    cert_id = r_cert.json()["id"]

    # 2. Salvar pontos (y = 2x + 1)
    pontos_payload = [
        {"ordem": i, "valores": {"x": float(i), "y": 2.0 * i + 1.0}} for i in range(4)
    ]
    r_pontos = await client.post(
        f"/api/certificados-padrao/certificados/{cert_id}/pontos",
        json=pontos_payload,
        headers=headers,
    )
    assert r_pontos.status_code == 201
    assert len(r_pontos.json()) == 4

    # 3. Analisar (gera curva sugerida)
    req_analisar = {"campo_x": "x", "campo_y": "y", "tipo": "linear", "grau": 1}
    r_analisar = await client.post(
        f"/api/certificados-padrao/certificados/{cert_id}/analisar",
        json=req_analisar,
        headers=headers,
    )
    assert r_analisar.status_code == 200
    assert r_analisar.json()["status"] == "sugerida"

    # 4. Aprovar curva
    req_aprovar = {"observacoes": "Aprovado no fluxo completo"}
    r_aprovar = await client.post(
        f"/api/certificados-padrao/certificados/{cert_id}/aprovar",
        json=req_aprovar,
        headers=headers,
    )
    assert r_aprovar.status_code == 200
    assert r_aprovar.json()["status"] == "aprovada"

    # 5. GET curva ativa
    r_curva = await client.get(
        f"/api/certificados-padrao/certificados/{cert_id}/curva",
        headers=headers,
    )
    assert r_curva.status_code == 200
    assert r_curva.json()["status"] == "aprovada"

    # 6. Verificar status do certificado
    r_cert_final = await client.get(
        f"/api/certificados-padrao/certificados/{cert_id}",
        headers=headers,
    )
    assert r_cert_final.json()["status"] == "ativo"

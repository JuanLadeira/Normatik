import pytest
from datetime import date, timedelta

from app.domains.calibracoes.model import StatusServico
from app.domains.calibracoes.repository import CalibracaoRepository
from app.domains.calibracoes.schema import (
    IncertezaBFonteCreate,
    PontoDeCalibraçãoCreate,
    ServicoDeCalibraçãoCreate,
)
from app.domains.calibracoes.service import CalibracaoService
from app.domains.clientes.repository import ClienteRepository
from app.domains.clientes.schema import ClienteLaboratorioCreate
from app.domains.clientes.service import ClienteService
from app.domains.equipamentos.model import StatusCalibracaoPadrao
from app.domains.equipamentos.repository import EquipamentoRepository
from app.domains.equipamentos.schema import (
    HistoricoCalibracaoPadraoCreate,
    PadraoCreate,
)
from app.domains.equipamentos.service import EquipamentoService
from app.domains.grandezas.model import DistribuicaoIncerteza
from app.domains.grandezas.repository import GrandezaRepository


@pytest.fixture
async def grandeza_pressao(db_session):
    from app.domains.grandezas.model import Grandeza

    repo = GrandezaRepository(db_session)
    g = Grandeza(nome="Pressão", simbolo="P", unidade_si="Pa")
    return await repo.save(g)


@pytest.mark.asyncio
async def test_cliente_service_multi_tenant(db_session):
    from app.domains.tenants.model import Tenant, TenantStatus

    # Criar Tenants Reais
    t1 = Tenant(
        nome="T1", slug="t1", status=TenantStatus.active, email_gestor="t1@t.com"
    )
    t2 = Tenant(
        nome="T2", slug="t2", status=TenantStatus.active, email_gestor="t2@t.com"
    )
    db_session.add_all([t1, t2])
    await db_session.flush()

    repo = ClienteRepository(db_session)
    service = ClienteService(repo)

    # Criar cliente para Tenant 1
    c1 = await service.create(
        t1.id, ClienteLaboratorioCreate(nome="Cliente T1", cnpj="111")
    )

    # Criar cliente para Tenant 2
    c2 = await service.create(
        t2.id, ClienteLaboratorioCreate(nome="Cliente T2", cnpj="222")
    )

    assert c1.tenant_id == t1.id
    assert c2.tenant_id == t2.id

    # Listar T1 não deve ver T2
    clientes_t1 = await service.get_all(t1.id)
    assert len(clientes_t1) == 1
    assert clientes_t1[0].nome == "Cliente T1"


@pytest.mark.asyncio
async def test_equipamento_service_registrar_calibracao(db_session, admin_user):
    from app.domains.grandezas.model import Grandeza
    from app.domains.equipamentos.model import TipoEquipamento

    tenant_id = admin_user.tenant_id
    repo = EquipamentoRepository(db_session)
    service = EquipamentoService(repo)

    # Setup: Grandeza e Tipo
    g = Grandeza(nome="Massa", simbolo="g", unidade_si="kg")
    db_session.add(g)
    await db_session.flush()

    tipo = TipoEquipamento(grandeza_id=g.id, codigo="BALANCA", nome="Balança")
    db_session.add(tipo)
    await db_session.flush()

    # 1. Criar Padrão
    padrao_data = PadraoCreate(
        tipo_equipamento_id=tipo.id,
        numero_serie="SN001",
        marca="Toledo",
        modelo="M1",
        unidade="g",
        alerta_dias_antes=30,
    )
    padrao = await service.create_padrao(tenant_id, padrao_data)
    assert padrao.status_calibracao == StatusCalibracaoPadrao.SEM_CALIBRACAO

    # 2. Registrar Calibração Aceita
    cal_data = HistoricoCalibracaoPadraoCreate(
        data_calibracao=date.today(),
        data_vencimento=date.today() + timedelta(days=365),
        numero_certificado="CERT-2024",
        laboratorio_calibrador="Lab Externo",
        u_expandida_certificado=0.01,
        aceito=True,
    )

    await service.registrar_calibracao_externa(tenant_id, padrao.id, cal_data)

    # 3. Validar se o Padrão foi atualizado (espelho)
    await db_session.refresh(padrao)
    assert padrao.numero_certificado == "CERT-2024"
    assert padrao.u_expandida_atual == 0.01
    assert padrao.status_calibracao == StatusCalibracaoPadrao.EM_DIA


@pytest.mark.asyncio
async def test_calibracao_service_recalculo_automatico(db_session, admin_user):
    from app.domains.grandezas.model import Grandeza
    from app.domains.ordens_servico.model import OrdemDeServico, ItemOS
    from app.domains.clientes.model import ClienteLaboratorio
    from datetime import datetime

    tenant_id = admin_user.tenant_id
    repo = CalibracaoRepository(db_session)
    service = CalibracaoService(repo)

    # Setup: Cliente, Grandeza e OS
    cliente = ClienteLaboratorio(tenant_id=tenant_id, nome="Cliente Teste")
    db_session.add(cliente)
    await db_session.flush()

    g = Grandeza(nome="Temperatura", simbolo="C", unidade_si="K")
    db_session.add(g)
    await db_session.flush()

    os = OrdemDeServico(
        tenant_id=tenant_id,
        cliente_id=cliente.id,
        numero="OS-001",
        data_entrada=datetime.now(),
    )
    db_session.add(os)
    await db_session.flush()

    item = ItemOS(os_id=os.id, descricao="Termômetro")
    db_session.add(item)
    await db_session.flush()

    # 1. Iniciar Serviço
    servico = await service.create(
        tenant_id,
        ServicoDeCalibraçãoCreate(
            item_os_id=item.id, workbook_type="TEMP", status=StatusServico.RASCUNHO
        ),
    )

    # 2. Adicionar Ponto (u_expandida deve ser 0 pois não há fontes B)
    ponto = await service.add_ponto(
        tenant_id,
        servico.id,
        PontoDeCalibraçãoCreate(
            posicao=1,
            valor_nominal=100.0,
            unidade="C",
            leituras_instrumento=[100.1, 100.1],
        ),
    )
    assert ponto.u_expandida == 0.0

    # 3. Adicionar Fonte Tipo B -> Deve disparar recálculo do ponto automaticamente
    await service.add_fonte_b(
        tenant_id,
        servico.id,
        IncertezaBFonteCreate(
            descricao="Incerteza Padrão",
            valor_u=0.5,
            distribuicao=DistribuicaoIncerteza.NORMAL,
            graus_liberdade=100,
        ),
    )

    await db_session.refresh(ponto)
    # u_c = sqrt(0^2 + 0.5^2) = 0.5
    # u_exp = 2 * 0.5 = 1.0
    assert ponto.u_expandida == pytest.approx(1.0)

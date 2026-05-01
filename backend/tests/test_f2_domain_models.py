from datetime import date, timedelta

import pytest

from app.domains.calibracoes.model import (
    IncertezaBFonte,
    PontoDeCalibração,
    ServicoDeCalibração,
    StatusServico,
)
from app.domains.equipamentos.model import PadraoDeCalibração, StatusCalibracaoPadrao
from app.domains.grandezas.model import DistribuicaoIncerteza
from app.domains.ordens_servico.model import ItemOS, StatusItemOS


def test_padrao_status_calibracao():
    """Testa a lógica de status de calibração de um padrão."""
    today = date.today()
    alerta = 30

    # 1. Sem calibração
    p1 = PadraoDeCalibração(validade_calibracao=None)
    assert p1.status_calibracao == StatusCalibracaoPadrao.SEM_CALIBRACAO

    # 2. Vencido
    p2 = PadraoDeCalibração(
        validade_calibracao=today - timedelta(days=1), alerta_dias_antes=alerta
    )
    assert p2.status_calibracao == StatusCalibracaoPadrao.VENCIDO

    # 3. Vencendo em breve (exatamente no limite do alerta)
    p3 = PadraoDeCalibração(
        validade_calibracao=today + timedelta(days=alerta), alerta_dias_antes=alerta
    )
    assert p3.status_calibracao == StatusCalibracaoPadrao.VENCENDO_EM_BREVE

    # 4. Em dia
    p4 = PadraoDeCalibração(
        validade_calibracao=today + timedelta(days=alerta + 1), alerta_dias_antes=alerta
    )
    assert p4.status_calibracao == StatusCalibracaoPadrao.EM_DIA


def test_item_os_quantidade_realizada():
    """Testa o contador de serviços concluídos em um item de OS."""
    item = ItemOS(
        descricao="Teste",
        status=StatusItemOS.EM_CALIBRACAO,
        servicos=[
            ServicoDeCalibração(status=StatusServico.CONCLUIDO, workbook_type="P"),
            ServicoDeCalibração(status=StatusServico.EM_ANDAMENTO, workbook_type="P"),
            ServicoDeCalibração(status=StatusServico.CONCLUIDO, workbook_type="P"),
            ServicoDeCalibração(status=StatusServico.RASCUNHO, workbook_type="P"),
        ],
    )

    assert item.quantidade_realizada == 2


def test_ponto_calibracao_calculo_simples():
    """Testa o cálculo GUM para calibração simples (só instrumento)."""
    ponto = PontoDeCalibração(
        valor_nominal=10.0,
        unidade="mm",
        leituras_instrumento=[10.1, 10.2, 10.1, 10.2],  # média = 10.15
        fator_k=2.0,
    )

    # Fonte B (ex: resolução do instrumento)
    fonte_b = IncertezaBFonte(
        descricao="Resolução",
        valor_u=0.01,
        distribuicao=DistribuicaoIncerteza.RETANGULAR,
    )

    ponto.calcular_incertezas([fonte_b])

    assert ponto.media_instrumento == pytest.approx(10.15)
    assert ponto.media_padrao is None
    assert ponto.erro == pytest.approx(0.15)  # 10.15 - 10.0
    assert ponto.correcao == pytest.approx(-0.15)

    # n = 4, media = 10.15
    # soma_sq = (10.1-10.15)^2 * 2 + (10.2-10.15)^2 * 2 = 0.0025 * 2 + 0.0025 * 2 = 0.01
    # var = 0.01 / (4-1) = 0.003333...
    # std = sqrt(0.003333) = 0.057735...
    # u_a = 0.057735 / sqrt(4) = 0.028867...
    assert ponto.u_tipo_a == pytest.approx(0.028867, abs=1e-6)

    # u_c = sqrt(u_a^2 + u_b^2) = sqrt(0.028867^2 + 0.01^2)
    # u_c = sqrt(0.0008333 + 0.0001) = sqrt(0.0009333) = 0.03055
    assert ponto.u_combinada == pytest.approx(0.03055, abs=1e-5)
    assert ponto.u_expandida == pytest.approx(0.0611, abs=1e-4)


def test_ponto_calibracao_calculo_dual():
    """Testa o cálculo GUM para calibração dual (instrumento + padrão)."""
    ponto = PontoDeCalibração(
        valor_nominal=100.0,
        unidade="kPa",
        leituras_instrumento=[100.5],
        leituras_padrao=[100.1, 100.1],  # média = 100.1 (referência)
        fator_k=2.0,
    )

    ponto.calcular_incertezas([])

    assert ponto.media_instrumento == 100.5
    assert ponto.media_padrao == 100.1
    assert ponto.erro == pytest.approx(0.4)  # 100.5 - 100.1
    assert ponto.u_tipo_a == 0.0  # apenas 1 leitura
    assert ponto.u_tipo_a_padrao == 0.0  # leituras iguais
    assert ponto.u_combinada == 0.0
    assert ponto.u_expandida == 0.0

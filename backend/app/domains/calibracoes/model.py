import enum
import math

from sqlalchemy import Float, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.domains.grandezas.model import DistribuicaoIncerteza


class StatusServico(enum.StrEnum):
    RASCUNHO = "RASCUNHO"
    EM_ANDAMENTO = "EM_ANDAMENTO"
    CONCLUIDO = "CONCLUIDO"
    CANCELADO = "CANCELADO"


class ServicoDeCalibração(Base):
    __tablename__ = "servicos_calibracao"

    item_os_id: Mapped[int] = mapped_column(
        ForeignKey("itens_os.id"), nullable=False, index=True
    )
    instrumento_id: Mapped[int | None] = mapped_column(
        ForeignKey("instrumentos.id"), nullable=True, index=True
    )
    workbook_type: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[StatusServico] = mapped_column(
        nullable=False, default=StatusServico.RASCUNHO
    )

    temperatura_ambiente: Mapped[float | None] = mapped_column(nullable=True)
    umidade_relativa: Mapped[float | None] = mapped_column(nullable=True)
    observacoes: Mapped[str | None] = mapped_column(Text, nullable=True)

    item_os: Mapped["ItemOS"] = relationship(  # noqa: F821
        back_populates="servicos", lazy="selectin"
    )
    instrumento: Mapped["Instrumento | None"] = relationship(  # noqa: F821
        lazy="selectin"
    )
    fontes_incerteza_b: Mapped[list["IncertezaBFonte"]] = relationship(
        back_populates="servico",
        lazy="noload",
        cascade="all, delete-orphan",
    )
    pontos: Mapped[list["PontoDeCalibração"]] = relationship(
        back_populates="servico",
        lazy="noload",
        cascade="all, delete-orphan",
        order_by="PontoDeCalibração.posicao",
    )


class IncertezaBFonte(Base):
    """Fonte de incerteza Tipo B de um serviço.

    Quando a fonte é um padrão registrado, padrao_id aponta para ele e
    valor_u pode ser preenchido automaticamente a partir do certificado.
    """

    __tablename__ = "incertezas_b_fontes"

    servico_id: Mapped[int] = mapped_column(
        ForeignKey("servicos_calibracao.id"), nullable=False, index=True
    )
    padrao_id: Mapped[int | None] = mapped_column(
        ForeignKey("padroes_calibracao.id"), nullable=True, index=True
    )
    descricao: Mapped[str] = mapped_column(String(200), nullable=False)
    valor_u: Mapped[float] = mapped_column(nullable=False)
    distribuicao: Mapped[DistribuicaoIncerteza] = mapped_column(nullable=False)
    graus_liberdade: Mapped[float | None] = mapped_column(nullable=True)

    servico: Mapped["ServicoDeCalibração"] = relationship(
        back_populates="fontes_incerteza_b", lazy="selectin"
    )
    padrao: Mapped["PadraoDeCalibração | None"] = relationship(lazy="selectin")  # noqa: F821


class PontoDeCalibração(Base):
    """Ponto de calibração suportando leituras do instrumento e do padrão.

    Cobre dois cenários:
    - Simples: só leituras_instrumento, referencia = valor_nominal
    - Dual (ex: manômetros): leituras_instrumento + leituras_padrao,
      referencia = media_padrao
    """

    __tablename__ = "pontos_calibracao"

    servico_id: Mapped[int] = mapped_column(
        ForeignKey("servicos_calibracao.id"), nullable=False, index=True
    )
    posicao: Mapped[int] = mapped_column(nullable=False)
    valor_nominal: Mapped[float] = mapped_column(nullable=False)
    unidade: Mapped[str] = mapped_column(String(20), nullable=False)

    # Leituras brutas
    leituras_instrumento: Mapped[list[float]] = mapped_column(
        ARRAY(Float), nullable=False, default=list
    )
    leituras_padrao: Mapped[list[float]] = mapped_column(
        ARRAY(Float), nullable=False, default=list
    )

    # Estatísticas do instrumento
    media_instrumento: Mapped[float | None] = mapped_column(nullable=True)
    desvio_padrao_instrumento: Mapped[float | None] = mapped_column(nullable=True)

    # Estatísticas do padrão (preenchidas apenas quando leituras_padrao não vazio)
    media_padrao: Mapped[float | None] = mapped_column(nullable=True)
    desvio_padrao_padrao: Mapped[float | None] = mapped_column(nullable=True)

    # Resultado metrológico
    erro: Mapped[float | None] = mapped_column(nullable=True)
    correcao: Mapped[float | None] = mapped_column(nullable=True)

    # Incertezas
    u_tipo_a: Mapped[float | None] = mapped_column(nullable=True)
    u_tipo_a_padrao: Mapped[float | None] = mapped_column(nullable=True)
    u_combinada: Mapped[float | None] = mapped_column(nullable=True)
    u_expandida: Mapped[float | None] = mapped_column(nullable=True)
    fator_k: Mapped[float] = mapped_column(nullable=False, default=2.0)

    servico: Mapped["ServicoDeCalibração"] = relationship(
        back_populates="pontos", lazy="selectin"
    )

    def calcular_incertezas(self, fontes_b: list["IncertezaBFonte"]) -> None:
        """Calcula estatísticas e incertezas GUM para este ponto.

        Suporta calibração simples (só instrumento) e dual (instrumento + padrão).
        A referência é media_padrao quando há leituras do padrão, valor_nominal caso contrário.
        """
        leituras_i = self.leituras_instrumento or []
        n_i = len(leituras_i)
        if n_i == 0:
            return

        # ── Instrumento ───────────────────────────────────────────────────────
        self.media_instrumento = sum(leituras_i) / n_i
        if n_i > 1:
            var_i = sum((x - self.media_instrumento) ** 2 for x in leituras_i) / (
                n_i - 1
            )
            self.desvio_padrao_instrumento = math.sqrt(var_i)
            self.u_tipo_a = self.desvio_padrao_instrumento / math.sqrt(n_i)
        else:
            self.desvio_padrao_instrumento = 0.0
            self.u_tipo_a = 0.0

        # ── Padrão (opcional) ─────────────────────────────────────────────────
        leituras_p = self.leituras_padrao or []
        n_p = len(leituras_p)
        self.u_tipo_a_padrao = 0.0
        referencia = self.valor_nominal

        if n_p > 0:
            self.media_padrao = sum(leituras_p) / n_p
            referencia = self.media_padrao
            if n_p > 1:
                var_p = sum((x - self.media_padrao) ** 2 for x in leituras_p) / (
                    n_p - 1
                )
                self.desvio_padrao_padrao = math.sqrt(var_p)
                self.u_tipo_a_padrao = self.desvio_padrao_padrao / math.sqrt(n_p)
            else:
                self.desvio_padrao_padrao = 0.0

        # ── Erro / Correção ───────────────────────────────────────────────────
        self.erro = self.media_instrumento - referencia
        self.correcao = -self.erro

        # ── Incerteza combinada e expandida ───────────────────────────────────
        soma_b = sum(f.valor_u**2 for f in fontes_b)
        self.u_combinada = math.sqrt(
            self.u_tipo_a**2 + self.u_tipo_a_padrao**2 + soma_b
        )
        self.u_expandida = self.fator_k * self.u_combinada

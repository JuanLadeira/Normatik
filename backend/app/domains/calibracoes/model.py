import enum
import math

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy import Float
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
        ForeignKey("itens_os.id"), nullable=False, unique=True, index=True
    )
    workbook_type: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[StatusServico] = mapped_column(
        nullable=False, default=StatusServico.RASCUNHO
    )

    temperatura_ambiente: Mapped[float | None] = mapped_column(nullable=True)
    umidade_relativa: Mapped[float | None] = mapped_column(nullable=True)
    observacoes: Mapped[str | None] = mapped_column(Text, nullable=True)

    item_os: Mapped["ItemOS"] = relationship(  # noqa: F821
        back_populates="servico", lazy="selectin"
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
    """Fonte de incerteza Tipo B instanciada para um serviço de calibração específico."""

    __tablename__ = "incertezas_b_fontes"

    servico_id: Mapped[int] = mapped_column(
        ForeignKey("servicos_calibracao.id"), nullable=False, index=True
    )
    descricao: Mapped[str] = mapped_column(String(200), nullable=False)
    valor_u: Mapped[float] = mapped_column(nullable=False)
    distribuicao: Mapped[DistribuicaoIncerteza] = mapped_column(nullable=False)
    graus_liberdade: Mapped[float | None] = mapped_column(nullable=True)

    servico: Mapped["ServicoDeCalibração"] = relationship(
        back_populates="fontes_incerteza_b", lazy="selectin"
    )


class PontoDeCalibração(Base):
    """Ponto de calibração com n leituras e incertezas calculadas automaticamente."""

    __tablename__ = "pontos_calibracao"

    servico_id: Mapped[int] = mapped_column(
        ForeignKey("servicos_calibracao.id"), nullable=False, index=True
    )
    posicao: Mapped[int] = mapped_column(nullable=False)
    valor_nominal: Mapped[float] = mapped_column(nullable=False)
    unidade: Mapped[str] = mapped_column(String(20), nullable=False)

    leituras: Mapped[list[float]] = mapped_column(
        ARRAY(Float), nullable=False, default=list
    )

    # Campos calculados — preenchidos por calcular_incertezas()
    media: Mapped[float | None] = mapped_column(nullable=True)
    desvio_padrao: Mapped[float | None] = mapped_column(nullable=True)
    correcao: Mapped[float | None] = mapped_column(nullable=True)
    u_tipo_a: Mapped[float | None] = mapped_column(nullable=True)
    u_combinada: Mapped[float | None] = mapped_column(nullable=True)
    u_expandida: Mapped[float | None] = mapped_column(nullable=True)
    fator_k: Mapped[float] = mapped_column(nullable=False, default=2.0)

    servico: Mapped["ServicoDeCalibração"] = relationship(
        back_populates="pontos", lazy="selectin"
    )

    def calcular_incertezas(self, fontes_b: list["IncertezaBFonte"]) -> None:
        """Calcula e preenche todos os campos derivados a partir das leituras e fontes B."""
        n = len(self.leituras)
        if n == 0:
            return

        self.media = sum(self.leituras) / n
        self.correcao = self.media - self.valor_nominal

        if n > 1:
            variancia = sum((x - self.media) ** 2 for x in self.leituras) / (n - 1)
            self.desvio_padrao = math.sqrt(variancia)
            self.u_tipo_a = self.desvio_padrao / math.sqrt(n)
        else:
            self.desvio_padrao = 0.0
            self.u_tipo_a = 0.0

        soma_quadrados_b = sum(f.valor_u ** 2 for f in fontes_b)
        self.u_combinada = math.sqrt(self.u_tipo_a ** 2 + soma_quadrados_b)
        self.u_expandida = self.fator_k * self.u_combinada

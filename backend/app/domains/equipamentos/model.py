import enum
from datetime import date, timedelta

from sqlalchemy import Date, ForeignKey, Index, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class TipoEquipamento(Base):
    """Tipo de equipamento (paquímetro, manômetro, termopar, etc.).

    O codigo é a chave usada pelo registry de workbooks para despachar
    a lógica de cálculo e o formulário específico de cada instrumento.
    """

    __tablename__ = "tipos_equipamento"

    grandeza_id: Mapped[int] = mapped_column(
        ForeignKey("grandezas.id"), nullable=False, index=True
    )
    codigo: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    nome: Mapped[str] = mapped_column(String(100), nullable=False)
    ativo: Mapped[bool] = mapped_column(default=True)

    grandeza: Mapped["Grandeza"] = relationship(  # noqa: F821
        back_populates="tipos_equipamento", lazy="selectin"
    )
    modelos: Mapped[list["ModeloEquipamento"]] = relationship(
        back_populates="tipo_equipamento",
        lazy="noload",
    )


class Fabricante(Base):
    """Fabricante de equipamentos — global, compartilhado entre todos os tenants."""

    __tablename__ = "fabricantes"

    nome: Mapped[str] = mapped_column(String(200), nullable=False, unique=True)
    ativo: Mapped[bool] = mapped_column(default=True)

    modelos: Mapped[list["ModeloEquipamento"]] = relationship(
        back_populates="fabricante",
        lazy="noload",
    )


class ModeloEquipamento(Base):
    """Modelo de um fabricante para um tipo de equipamento específico.

    Permite pré-cadastrar catálogo (Mitutoyo 530-118, etc.) para agilizar
    o cadastro de equipamentos: selecionado o modelo, marca/capacidade/resolucao
    são pré-preenchidos mas ainda editáveis.
    """

    __tablename__ = "modelos_equipamento"

    tipo_equipamento_id: Mapped[int] = mapped_column(
        ForeignKey("tipos_equipamento.id"), nullable=False, index=True
    )
    fabricante_id: Mapped[int] = mapped_column(
        ForeignKey("fabricantes.id"), nullable=False, index=True
    )
    nome: Mapped[str] = mapped_column(String(200), nullable=False)
    capacidade_padrao: Mapped[float | None] = mapped_column(nullable=True)
    resolucao_padrao: Mapped[float | None] = mapped_column(nullable=True)
    unidade_padrao: Mapped[str | None] = mapped_column(String(20), nullable=True)
    ativo: Mapped[bool] = mapped_column(default=True)

    tipo_equipamento: Mapped["TipoEquipamento"] = relationship(
        back_populates="modelos", lazy="selectin"
    )
    fabricante: Mapped["Fabricante"] = relationship(
        back_populates="modelos", lazy="selectin"
    )

    __table_args__ = (
        UniqueConstraint(
            "tipo_equipamento_id",
            "fabricante_id",
            "nome",
            name="uq_modelo_tipo_fabricante_nome",
        ),
    )


class Equipamento(Base):
    """Base para instrumentos do cliente e padrões do laboratório (JTI).

    A grandeza é derivada de tipo_equipamento.grandeza (sem redundância).
    modelo_equipamento_id é nullable: None indica equipamento fora do catálogo,
    cujos campos marca/modelo/capacidade/resolucao são preenchidos manualmente.
    """

    __tablename__ = "equipamentos"

    tipo: Mapped[str] = mapped_column(String(20), nullable=False)

    tenant_id: Mapped[int] = mapped_column(
        ForeignKey("tenants.id"), nullable=False, index=True
    )
    tipo_equipamento_id: Mapped[int] = mapped_column(
        ForeignKey("tipos_equipamento.id"), nullable=False, index=True
    )
    modelo_equipamento_id: Mapped[int | None] = mapped_column(
        ForeignKey("modelos_equipamento.id"), nullable=True, index=True
    )

    numero_serie: Mapped[str] = mapped_column(String(100), nullable=False)
    marca: Mapped[str] = mapped_column(String(100), nullable=False)
    modelo: Mapped[str] = mapped_column(String(100), nullable=False)
    unidade: Mapped[str] = mapped_column(String(20), nullable=False)

    capacidade: Mapped[float | None] = mapped_column(nullable=True)
    resolucao: Mapped[float | None] = mapped_column(nullable=True)
    ativo: Mapped[bool] = mapped_column(default=True)

    tipo_equipamento: Mapped["TipoEquipamento"] = relationship(lazy="selectin")
    modelo_equipamento: Mapped["ModeloEquipamento | None"] = relationship(
        lazy="selectin"
    )
    tenant: Mapped["Tenant"] = relationship(lazy="selectin")  # noqa: F821

    __mapper_args__ = {
        "polymorphic_on": "tipo",
        "polymorphic_identity": "equipamento",
    }


class Instrumento(Equipamento):
    """Instrumento do cliente enviado para calibração."""

    __tablename__ = "instrumentos"

    id: Mapped[int] = mapped_column(ForeignKey("equipamentos.id"), primary_key=True)
    cliente_id: Mapped[int] = mapped_column(
        ForeignKey("clientes_laboratorio.id"), nullable=False, index=True
    )

    cliente: Mapped["ClienteLaboratorio"] = relationship(  # noqa: F821
        back_populates="instrumentos", lazy="selectin"
    )

    __mapper_args__ = {"polymorphic_identity": "instrumento"}


class StatusCalibracaoPadrao(enum.StrEnum):
    EM_DIA = "em_dia"
    VENCENDO_EM_BREVE = "vencendo_em_breve"
    VENCIDO = "vencido"
    SEM_CALIBRACAO = "sem_calibracao"


class PadraoDeCalibração(Equipamento):
    """Padrão de medição do laboratório usado como referência nas calibrações.

    Colunas de conveniência (numero_certificado, data_calibracao,
    validade_calibracao, laboratorio_calibrador, u_expandida_atual) são
    atualizadas pelo service toda vez que um HistoricoCalibracaoPadrao
    aceito é registrado — nunca escritas diretamente.
    """

    __tablename__ = "padroes_calibracao"

    id: Mapped[int] = mapped_column(ForeignKey("equipamentos.id"), primary_key=True)

    # ── Conveniência: estado atual (espelho do último histórico aceito) ────────
    numero_certificado: Mapped[str | None] = mapped_column(String(100), nullable=True)
    data_calibracao: Mapped[date | None] = mapped_column(Date, nullable=True)
    validade_calibracao: Mapped[date | None] = mapped_column(
        Date, nullable=True, index=True
    )
    laboratorio_calibrador: Mapped[str | None] = mapped_column(
        String(200), nullable=True
    )
    u_expandida_atual: Mapped[float | None] = mapped_column(nullable=True)

    # ── Controle de calibração ─────────────────────────────────────────────────
    frequencia_calibracao_dias: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )
    alerta_dias_antes: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=30,
    )
    criterio_aceitacao: Mapped[str | None] = mapped_column(Text, nullable=True)
    u_maximo_aceito: Mapped[float | None] = mapped_column(nullable=True)

    historico: Mapped[list["HistoricoCalibracaoPadrao"]] = relationship(
        back_populates="padrao",
        lazy="noload",
        cascade="all, delete-orphan",
    )

    __mapper_args__ = {"polymorphic_identity": "padrao"}

    @property
    def status_calibracao(self) -> StatusCalibracaoPadrao:
        if self.validade_calibracao is None:
            return StatusCalibracaoPadrao.SEM_CALIBRACAO
        today = date.today()
        if today > self.validade_calibracao:
            return StatusCalibracaoPadrao.VENCIDO
        if today >= self.validade_calibracao - timedelta(days=self.alerta_dias_antes):
            return StatusCalibracaoPadrao.VENCENDO_EM_BREVE
        return StatusCalibracaoPadrao.EM_DIA


class HistoricoCalibracaoPadrao(Base):
    """Registro de cada calibração externa recebida por um padrão do laboratório.

    Quando aceito=True, o service atualiza as colunas de conveniência em
    PadraoDeCalibração (numero_certificado, data_calibracao, validade_calibracao,
    laboratorio_calibrador, u_expandida_atual) na mesma transação.
    """

    __tablename__ = "historico_calibracoes_padrao"

    padrao_id: Mapped[int] = mapped_column(
        ForeignKey("padroes_calibracao.id"), nullable=False, index=True
    )
    data_calibracao: Mapped[date] = mapped_column(Date, nullable=False)
    data_vencimento: Mapped[date] = mapped_column(Date, nullable=False)
    numero_certificado: Mapped[str] = mapped_column(String(100), nullable=False)
    laboratorio_calibrador: Mapped[str | None] = mapped_column(
        String(200), nullable=True
    )
    u_expandida_certificado: Mapped[float | None] = mapped_column(nullable=True)
    aceito: Mapped[bool] = mapped_column(nullable=False, default=True)
    observacoes: Mapped[str | None] = mapped_column(Text, nullable=True)
    arquivo_pdf_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    padrao: Mapped["PadraoDeCalibração"] = relationship(
        back_populates="historico", lazy="selectin"
    )

    __table_args__ = (
        Index("ix_historico_padrao_data", "padrao_id", "data_calibracao"),
    )

from datetime import date

from sqlalchemy import Date, ForeignKey, String, UniqueConstraint
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

    grandeza: Mapped["Grandeza"] = relationship(lazy="selectin")  # noqa: F821
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
            "tipo_equipamento_id", "fabricante_id", "nome",
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
    modelo_equipamento: Mapped["ModeloEquipamento | None"] = relationship(lazy="selectin")
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


class PadraoDeCalibração(Equipamento):
    """Padrão de medição do laboratório usado como referência nas calibrações."""

    __tablename__ = "padroes_calibracao"

    id: Mapped[int] = mapped_column(ForeignKey("equipamentos.id"), primary_key=True)

    numero_certificado: Mapped[str | None] = mapped_column(String(100), nullable=True)
    data_calibracao: Mapped[date | None] = mapped_column(Date, nullable=True)
    validade_calibracao: Mapped[date | None] = mapped_column(Date, nullable=True)
    laboratorio_calibrador: Mapped[str | None] = mapped_column(String(200), nullable=True)

    __mapper_args__ = {"polymorphic_identity": "padrao"}

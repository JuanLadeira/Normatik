import enum

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class DistribuicaoIncerteza(enum.StrEnum):
    NORMAL = "NORMAL"
    RETANGULAR = "RETANGULAR"
    TRIANGULAR = "TRIANGULAR"


class Grandeza(Base):
    __tablename__ = "grandezas"

    nome: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    simbolo: Mapped[str] = mapped_column(String(20), nullable=False)
    unidade_si: Mapped[str] = mapped_column(String(50), nullable=False)

    tipos_incerteza_b: Mapped[list["TipoIncertezaBTemplate"]] = relationship(
        back_populates="grandeza",
        lazy="noload",
        cascade="all, delete-orphan",
    )
    tipos_equipamento: Mapped[list["TipoEquipamento"]] = relationship(  # noqa: F821
        back_populates="grandeza",
        lazy="noload",
    )


class TipoIncertezaBTemplate(Base):
    """Template reutilizável de fonte de incerteza Tipo B para uma grandeza.

    Define a natureza da fonte (distribuição, graus de liberdade), mas não o
    valor — cada ServicoDeCalibração instancia a fonte com seu valor real.
    """

    __tablename__ = "tipos_incerteza_b_template"

    grandeza_id: Mapped[int] = mapped_column(
        ForeignKey("grandezas.id"),
        nullable=False,
        index=True,
    )
    descricao: Mapped[str] = mapped_column(String(200), nullable=False)
    simbolo: Mapped[str | None] = mapped_column(String(50), nullable=True)
    distribuicao: Mapped[DistribuicaoIncerteza] = mapped_column(nullable=False)
    graus_liberdade: Mapped[float | None] = mapped_column(nullable=True)
    observacao: Mapped[str | None] = mapped_column(Text, nullable=True)

    grandeza: Mapped["Grandeza"] = relationship(
        back_populates="tipos_incerteza_b",
        lazy="selectin",
    )

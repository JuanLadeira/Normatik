import enum
from datetime import datetime

from sqlalchemy import ForeignKey, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class StatusOS(enum.StrEnum):
    ABERTA = "ABERTA"
    EM_ANDAMENTO = "EM_ANDAMENTO"
    CONCLUIDA = "CONCLUIDA"
    CANCELADA = "CANCELADA"
    ENTREGUE = "ENTREGUE"


class StatusItemOS(enum.StrEnum):
    AGUARDANDO = "AGUARDANDO"
    EM_CALIBRACAO = "EM_CALIBRACAO"
    CONCLUIDO = "CONCLUIDO"
    CANCELADO = "CANCELADO"


class OrdemDeServico(Base):
    __tablename__ = "ordens_servico"

    tenant_id: Mapped[int] = mapped_column(
        ForeignKey("tenants.id"), nullable=False, index=True
    )
    numero: Mapped[str] = mapped_column(String(50), nullable=False)

    cliente_nome: Mapped[str] = mapped_column(String(200), nullable=False)
    cliente_contato: Mapped[str | None] = mapped_column(String(200), nullable=True)

    status: Mapped[StatusOS] = mapped_column(nullable=False, default=StatusOS.ABERTA)

    data_entrada: Mapped[datetime] = mapped_column(nullable=False)
    data_prevista: Mapped[datetime | None] = mapped_column(nullable=True)
    data_conclusao: Mapped[datetime | None] = mapped_column(nullable=True)

    observacoes: Mapped[str | None] = mapped_column(Text, nullable=True)

    tenant: Mapped["Tenant"] = relationship(lazy="selectin")  # noqa: F821
    itens: Mapped[list["ItemOS"]] = relationship(
        back_populates="os",
        lazy="noload",
        cascade="all, delete-orphan",
    )

    __table_args__ = (
        UniqueConstraint("tenant_id", "numero", name="uq_os_tenant_numero"),
    )


class ItemOS(Base):
    __tablename__ = "itens_os"

    os_id: Mapped[int] = mapped_column(
        ForeignKey("ordens_servico.id"), nullable=False, index=True
    )
    equipamento_id: Mapped[int] = mapped_column(
        ForeignKey("equipamentos.id"), nullable=False, index=True
    )
    posicao: Mapped[int] = mapped_column(nullable=False, default=1)
    status: Mapped[StatusItemOS] = mapped_column(
        nullable=False, default=StatusItemOS.AGUARDANDO
    )
    observacoes: Mapped[str | None] = mapped_column(Text, nullable=True)

    os: Mapped["OrdemDeServico"] = relationship(back_populates="itens", lazy="selectin")
    equipamento: Mapped["Equipamento"] = relationship(lazy="selectin")  # noqa: F821
    servico: Mapped["ServicoDeCalibração | None"] = relationship(  # noqa: F821
        back_populates="item_os",
        lazy="noload",
        uselist=False,
    )

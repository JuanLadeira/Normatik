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
    cliente_id: Mapped[int] = mapped_column(
        ForeignKey("clientes_laboratorio.id"), nullable=False, index=True
    )
    numero: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[StatusOS] = mapped_column(nullable=False, default=StatusOS.ABERTA)

    data_entrada: Mapped[datetime] = mapped_column(nullable=False)
    data_prevista: Mapped[datetime | None] = mapped_column(nullable=True)
    data_conclusao: Mapped[datetime | None] = mapped_column(nullable=True)

    observacoes: Mapped[str | None] = mapped_column(Text, nullable=True)

    tenant: Mapped["Tenant"] = relationship(lazy="selectin")  # noqa: F821
    cliente: Mapped["ClienteLaboratorio"] = relationship(  # noqa: F821
        back_populates="ordens_servico", lazy="selectin"
    )
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
    descricao: Mapped[str] = mapped_column(String(200), nullable=False)
    quantidade_prevista: Mapped[int] = mapped_column(nullable=False, default=1)
    posicao: Mapped[int] = mapped_column(nullable=False, default=1)
    status: Mapped[StatusItemOS] = mapped_column(
        nullable=False, default=StatusItemOS.AGUARDANDO
    )
    observacoes: Mapped[str | None] = mapped_column(Text, nullable=True)

    os: Mapped["OrdemDeServico"] = relationship(back_populates="itens", lazy="selectin")
    servicos: Mapped[list["ServicoDeCalibração"]] = relationship(  # noqa: F821
        back_populates="item_os",
        lazy="noload",
        cascade="all, delete-orphan",
    )

    @property
    def quantidade_realizada(self) -> int:
        """Quantidade de serviços já concluídos neste item."""
        from app.domains.calibracoes.model import StatusServico

        return sum(1 for s in self.servicos if s.status == StatusServico.CONCLUIDO)

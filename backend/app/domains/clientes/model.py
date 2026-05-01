from sqlalchemy import ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class ClienteLaboratorio(Base):
    __tablename__ = "clientes_laboratorio"

    tenant_id: Mapped[int] = mapped_column(
        ForeignKey("tenants.id"), nullable=False, index=True
    )
    nome: Mapped[str] = mapped_column(String(200), nullable=False)
    cnpj: Mapped[str | None] = mapped_column(String(18), nullable=True)
    email: Mapped[str | None] = mapped_column(String(254), nullable=True)
    telefone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    contato: Mapped[str | None] = mapped_column(String(150), nullable=True)
    ativo: Mapped[bool] = mapped_column(default=True)

    tenant: Mapped["Tenant"] = relationship(lazy="selectin")  # noqa: F821
    instrumentos: Mapped[list["Instrumento"]] = relationship(  # noqa: F821
        back_populates="cliente",
        lazy="noload",
    )
    ordens_servico: Mapped[list["OrdemDeServico"]] = relationship(  # noqa: F821
        back_populates="cliente",
        lazy="noload",
    )

    __table_args__ = (
        UniqueConstraint("tenant_id", "cnpj", name="uq_cliente_tenant_cnpj"),
    )

from sqlalchemy import ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Equipamento(Base):
    __tablename__ = "equipamentos"

    tenant_id: Mapped[int] = mapped_column(
        ForeignKey("tenants.id"), nullable=False, index=True
    )
    grandeza_id: Mapped[int] = mapped_column(
        ForeignKey("grandezas.id"), nullable=False, index=True
    )

    numero_serie: Mapped[str] = mapped_column(String(100), nullable=False)
    marca: Mapped[str] = mapped_column(String(100), nullable=False)
    modelo: Mapped[str] = mapped_column(String(100), nullable=False)
    unidade: Mapped[str] = mapped_column(String(20), nullable=False)

    capacidade: Mapped[float | None] = mapped_column(nullable=True)
    resolucao: Mapped[float | None] = mapped_column(nullable=True)

    ativo: Mapped[bool] = mapped_column(default=True)

    grandeza: Mapped["Grandeza"] = relationship(lazy="selectin")  # noqa: F821
    tenant: Mapped["Tenant"] = relationship(lazy="selectin")  # noqa: F821

    __table_args__ = (
        UniqueConstraint(
            "tenant_id", "numero_serie", name="uq_equipamento_tenant_serie"
        ),
    )

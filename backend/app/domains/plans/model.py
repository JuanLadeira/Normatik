from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import Numeric, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.domains.tenants.model import Tenant


class Plan(Base):
    __tablename__ = "plans"

    nome: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    descricao: Mapped[str] = mapped_column(String(500), default="")
    preco_mensal: Mapped[Decimal] = mapped_column(
        Numeric(10, 2), default=Decimal("0.00")
    )

    # Limites — -1 significa ilimitado
    limite_usuarios: Mapped[int] = mapped_column(default=2)
    limite_padroes: Mapped[int] = mapped_column(default=5)
    limite_calibracoes_mes: Mapped[int] = mapped_column(default=30)

    # Funcionalidades por plano
    portal_cliente: Mapped[bool] = mapped_column(default=False)
    geracao_certificado_pdf: Mapped[bool] = mapped_column(default=True)

    ativo: Mapped[bool] = mapped_column(default=True)

    tenants: Mapped[list["Tenant"]] = relationship(back_populates="plan", lazy="noload")

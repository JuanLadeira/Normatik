import enum
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.domains.tenants.model import Tenant


class UserRole(enum.StrEnum):
    admin = "admin"
    technician = "technician"
    attendant = "attendant"


class User(Base):
    __tablename__ = "users"
    __table_args__ = (
        UniqueConstraint("tenant_id", "email", name="uq_user_tenant_email"),
    )

    tenant_id: Mapped[int] = mapped_column(
        ForeignKey("tenants.id"), nullable=False, index=True
    )
    email: Mapped[str] = mapped_column(String(254), nullable=False, index=True)
    password: Mapped[str | None] = mapped_column(String(255), nullable=True)
    nome: Mapped[str] = mapped_column(String(150), nullable=False)
    role: Mapped[UserRole] = mapped_column(nullable=False)
    is_active: Mapped[bool] = mapped_column(default=True)

    # Convite — preenchido ao criar, limpo após primeiro acesso
    invite_token: Mapped[str | None] = mapped_column(String(500), nullable=True)
    invite_expires_at: Mapped[datetime | None] = mapped_column(nullable=True)

    tenant: Mapped["Tenant"] = relationship(back_populates="users", lazy="selectin")

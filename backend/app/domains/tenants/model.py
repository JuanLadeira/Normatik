import enum
from datetime import datetime, timezone
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.domains.plans.model import Plan
    from app.domains.users.model import User


class TenantStatus(str, enum.Enum):
    trial = "trial"
    active = "active"
    inactive = "inactive"
    suspended = "suspended"


class Tenant(Base):
    __tablename__ = "tenants"

    nome: Mapped[str] = mapped_column(String(150), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    cnpj: Mapped[str | None] = mapped_column(String(18), nullable=True)
    email_gestor: Mapped[str] = mapped_column(String(254), nullable=False)
    status: Mapped[TenantStatus] = mapped_column(default=TenantStatus.trial, nullable=False)
    trial_expires_at: Mapped[datetime | None] = mapped_column(nullable=True)

    plan_id: Mapped[int | None] = mapped_column(ForeignKey("plans.id"), nullable=True)

    plan: Mapped["Plan | None"] = relationship(back_populates="tenants", lazy="selectin")
    users: Mapped[list["User"]] = relationship(
        back_populates="tenant",
        cascade="all, delete-orphan",
        lazy="noload",
    )

    @property
    def is_active(self) -> bool:
        if self.status == TenantStatus.active:
            return True
        if self.status == TenantStatus.trial:
            if self.trial_expires_at is None:
                return True
            return datetime.now(timezone.utc).replace(tzinfo=None) < self.trial_expires_at
        return False

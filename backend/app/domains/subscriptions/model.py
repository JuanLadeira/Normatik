import enum
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base

if TYPE_CHECKING:
    from app.domains.plans.model import Plan
    from app.domains.tenants.model import Tenant


class SubscriptionStatus(str, enum.Enum):
    trial = "trial"
    active = "active"
    past_due = "past_due"
    cancelled = "cancelled"


class Subscription(Base):
    __tablename__ = "subscriptions"
    __table_args__ = (UniqueConstraint("tenant_id", name="uq_subscription_tenant"),)

    tenant_id: Mapped[int] = mapped_column(ForeignKey("tenants.id"), nullable=False)
    plan_id: Mapped[int] = mapped_column(ForeignKey("plans.id"), nullable=False)
    status: Mapped[SubscriptionStatus] = mapped_column(
        default=SubscriptionStatus.trial, nullable=False
    )
    current_period_start: Mapped[datetime] = mapped_column(nullable=False)
    current_period_end: Mapped[datetime] = mapped_column(nullable=False)

    stripe_subscription_id: Mapped[str | None] = mapped_column(nullable=True)
    stripe_customer_id: Mapped[str | None] = mapped_column(nullable=True)

    plan: Mapped["Plan"] = relationship(lazy="selectin")
    tenant: Mapped["Tenant"] = relationship(lazy="selectin")

import enum
import uuid
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import DateTime, Enum, Integer, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class OutboxStatus(enum.StrEnum):
    PENDING = "pending"
    PROCESSED = "processed"
    FAILED = "failed"


class OutboxEventType(enum.StrEnum):
    USER_INVITE = "user_invite"
    PASSWORD_RESET = "password_reset"


class OutboxEvent(Base):
    __tablename__ = "outbox_events"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    event_type: Mapped[OutboxEventType] = mapped_column(
        Enum(OutboxEventType), nullable=False
    )
    payload: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False)
    status: Mapped[OutboxStatus] = mapped_column(
        Enum(OutboxStatus),
        nullable=False,
        default=OutboxStatus.PENDING,
    )
    attempts: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    max_attempts: Mapped[int] = mapped_column(Integer, nullable=False, default=5)
    idempotency_key: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), unique=True, nullable=False, default=uuid.uuid4
    )
    processed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=False), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=False),
        default=lambda: datetime.now(UTC).replace(tzinfo=None),
    )
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)

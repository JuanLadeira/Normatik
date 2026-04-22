from datetime import UTC, datetime
from typing import Annotated
import uuid

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncDBSession
from app.domains.outbox.model import OutboxEvent, OutboxStatus


class OutboxRepository:
    def __init__(self, session: AsyncSession):
        self._session = session

    async def save(self, event: OutboxEvent) -> OutboxEvent:
        self._session.add(event)
        await self._session.flush()
        return event

    async def get_pending(self, limit: int = 10) -> list[OutboxEvent]:
        query = (
            select(OutboxEvent)
            .where(OutboxEvent.status == OutboxStatus.PENDING)
            .where(OutboxEvent.attempts < OutboxEvent.max_attempts)
            .order_by(OutboxEvent.created_at.asc())
            .limit(limit)
            .with_for_update(skip_locked=True)  # Evita concorrência entre workers
        )
        result = await self._session.execute(query)
        return list(result.scalars().all())

    async def mark_processed(self, event_id: uuid.UUID):
        event = await self._session.get(OutboxEvent, event_id)
        if event:
            event.status = OutboxStatus.PROCESSED
            event.processed_at = datetime.now(UTC).replace(tzinfo=None)
            await self._session.flush()

    async def mark_failed(self, event_id: uuid.UUID, error: str):
        event = await self._session.get(OutboxEvent, event_id)
        if event:
            event.attempts += 1
            event.error_message = error
            if event.attempts >= event.max_attempts:
                event.status = OutboxStatus.FAILED
            await self._session.flush()


def get_outbox_repository(session: AsyncDBSession) -> OutboxRepository:
    return OutboxRepository(session)


OutboxRepositoryDep = Annotated[OutboxRepository, Depends(get_outbox_repository)]

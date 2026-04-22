import asyncio
import logging
from celery import Celery
from app.core.settings import settings

logger = logging.getLogger("worker")

celery_app = Celery(
    "normatik",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    beat_schedule={
        "process-outbox-every-10-seconds": {
            "task": "app.core.celery.process_outbox",
            "schedule": 10.0,
        },
    },
)


@celery_app.task(name="app.core.celery.process_outbox")
def process_outbox():
    """Tarefa Celery para processar eventos de outbox pendentes."""
    return asyncio.run(_run_process_outbox())


async def _run_process_outbox():
    from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
    from app.domains.outbox.repository import OutboxRepository
    from app.domains.outbox.model import OutboxEventType
    from app.core.email import email_service

    engine = create_async_engine(settings.DATABASE_URL)
    SessionFactory = async_sessionmaker(engine, expire_on_commit=False)

    async with SessionFactory() as session:
        repo = OutboxRepository(session)
        events = await repo.get_pending(limit=5)

        if not events:
            return "No pending events"

        for event in events:
            try:
                if event.event_type == OutboxEventType.USER_INVITE:
                    email_service.send_user_invite(
                        email=event.payload["email"],
                        nome=event.payload["nome"],
                        token=event.payload["token"],
                    )

                await repo.mark_processed(event.id)
                await session.commit()
                logger.info(f"Evento {event.id} processado com sucesso.")

            except Exception as e:
                await session.rollback()
                await repo.mark_failed(event.id, str(e))
                await session.commit()
                logger.error(f"Falha ao processar evento {event.id}: {e}")

    await engine.dispose()
    return f"Processed {len(events)} events"

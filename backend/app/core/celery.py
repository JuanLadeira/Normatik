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
    """Tarefa Celery que processa eventos pendentes do outbox."""
    return asyncio.run(_run_process_outbox())


async def _run_process_outbox() -> str:
    import app.domains.outbox.handlers  # noqa: F401 — registra todos os handlers

    from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

    from app.domains.outbox.dispatcher import dispatch
    from app.domains.outbox.repository import OutboxRepository

    engine = create_async_engine(settings.DATABASE_URL)
    SessionFactory = async_sessionmaker(engine, expire_on_commit=False)

    processed = 0
    failed = 0

    async with SessionFactory() as session:
        repo = OutboxRepository(session)
        events = await repo.get_pending(limit=10)

        for event in events:
            try:
                await dispatch(event)
                await repo.mark_processed(event.id)
                await session.commit()
                logger.info("Evento %s (%s) processado.", event.id, event.event_type)
                processed += 1
            except Exception as exc:
                await session.rollback()
                await repo.mark_failed(event.id, str(exc))
                await session.commit()
                logger.error("Falha no evento %s: %s", event.id, exc)
                failed += 1

    await engine.dispose()
    return f"processed={processed} failed={failed}"

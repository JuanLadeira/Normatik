import asyncio

from app.core.email import email_service
from app.domains.outbox.dispatcher import register
from app.domains.outbox.model import OutboxEvent, OutboxEventType


@register(OutboxEventType.USER_INVITE)
async def handle_user_invite(event: OutboxEvent) -> None:
    await asyncio.to_thread(
        email_service.send_user_invite,
        email=event.payload["email"],
        nome=event.payload["nome"],
        token=event.payload["token"],
    )

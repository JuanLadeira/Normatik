from collections.abc import Awaitable, Callable
from typing import TypeAlias

from app.domains.outbox.model import OutboxEvent, OutboxEventType

Handler: TypeAlias = Callable[[OutboxEvent], Awaitable[None]]

_registry: dict[OutboxEventType, Handler] = {}


def register(event_type: OutboxEventType) -> Callable[[Handler], Handler]:
    """Decorator que registra um handler para um tipo de evento do outbox."""

    def decorator(fn: Handler) -> Handler:
        _registry[event_type] = fn
        return fn

    return decorator


async def dispatch(event: OutboxEvent) -> None:
    """Despacha um evento para o handler registrado.

    Raises:
        ValueError: se nenhum handler estiver registrado para o tipo do evento.
    """
    handler = _registry.get(event.event_type)
    if handler is None:
        raise ValueError(f"Nenhum handler registrado para {event.event_type!r}")
    await handler(event)

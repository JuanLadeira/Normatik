"""Testes unitários do dispatcher de outbox (handler registry)."""

from unittest.mock import AsyncMock, patch

import pytest

from app.domains.outbox.dispatcher import _registry, dispatch, register
from app.domains.outbox.model import OutboxEvent, OutboxEventType, OutboxStatus


@pytest.fixture(autouse=True)
def isolate_registry():
    """Restaura o registry ao estado original após cada teste."""
    snapshot = dict(_registry)
    yield
    _registry.clear()
    _registry.update(snapshot)


def _make_event(
    event_type: OutboxEventType, payload: dict | None = None
) -> OutboxEvent:
    return OutboxEvent(
        event_type=event_type,
        payload=payload or {},
        status=OutboxStatus.PENDING,
    )


# ── Dispatcher ────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_dispatch_chama_handler_registrado():
    handler = AsyncMock()
    register(OutboxEventType.USER_INVITE)(handler)

    event = _make_event(OutboxEventType.USER_INVITE)
    await dispatch(event)

    handler.assert_awaited_once_with(event)


@pytest.mark.asyncio
async def test_dispatch_levanta_para_tipo_sem_handler():
    _registry.pop(OutboxEventType.USER_INVITE, None)

    event = _make_event(OutboxEventType.USER_INVITE)
    with pytest.raises(ValueError, match="Nenhum handler registrado"):
        await dispatch(event)


@pytest.mark.asyncio
async def test_register_substitui_handler_existente():
    first = AsyncMock()
    second = AsyncMock()

    register(OutboxEventType.USER_INVITE)(first)
    register(OutboxEventType.USER_INVITE)(second)

    event = _make_event(OutboxEventType.USER_INVITE)
    await dispatch(event)

    second.assert_awaited_once_with(event)
    first.assert_not_awaited()


@pytest.mark.asyncio
async def test_dispatch_handlers_independentes_por_tipo():
    invite_handler = AsyncMock()
    reset_handler = AsyncMock()

    register(OutboxEventType.USER_INVITE)(invite_handler)
    register(OutboxEventType.PASSWORD_RESET)(reset_handler)

    invite_event = _make_event(OutboxEventType.USER_INVITE)
    reset_event = _make_event(OutboxEventType.PASSWORD_RESET)

    await dispatch(invite_event)
    await dispatch(reset_event)

    invite_handler.assert_awaited_once_with(invite_event)
    reset_handler.assert_awaited_once_with(reset_event)


# ── Handler de auth ───────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_handle_user_invite_chama_email_service():
    import app.domains.outbox.handlers.auth  # noqa: F401 — garante registro

    payload = {
        "email": "user@test.com",
        "nome": "Fulano",
        "token": "abc123",
    }
    event = _make_event(OutboxEventType.USER_INVITE, payload)

    with patch(
        "app.domains.outbox.handlers.auth.email_service.send_user_invite"
    ) as mock_send:
        await dispatch(event)

    mock_send.assert_called_once_with(
        email="user@test.com",
        nome="Fulano",
        token="abc123",
    )

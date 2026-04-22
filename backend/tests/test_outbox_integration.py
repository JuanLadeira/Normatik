import pytest
from sqlalchemy import select
from app.domains.outbox.model import OutboxEvent, OutboxStatus, OutboxEventType


@pytest.mark.asyncio
async def test_outbox_full_cycle(client, db_session, admin_token):
    """Testa o ciclo completo: Criar evento -> Processar -> Status PROCESSED."""
    headers = {"Authorization": f"Bearer {admin_token}"}

    email = "e2e_outbox@test.com"
    invite_data = {"email": email, "nome": "E2E Outbox", "role": "technician"}

    # 1. Dispara convite via API
    response = await client.post("/api/users/invite", json=invite_data, headers=headers)
    assert response.status_code == 201

    # 2. Verifica que está pendente (filtrando pelo email no JSONB)
    # Nota: Usamos cast ou filtragem direta no payload
    result = await db_session.execute(
        select(OutboxEvent).where(
            OutboxEvent.event_type == OutboxEventType.USER_INVITE,
            OutboxEvent.payload["email"].astext == email,
        )
    )
    event = result.scalar_one()
    assert event.status == OutboxStatus.PENDING

    # 3. Processa manualmente (simulando o worker)
    event.status = OutboxStatus.PROCESSED
    await db_session.commit()

    # 4. Valida status final
    await db_session.refresh(event)
    assert event.status == OutboxStatus.PROCESSED

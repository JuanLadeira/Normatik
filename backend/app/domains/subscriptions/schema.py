from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.domains.subscriptions.model import SubscriptionStatus


class SubscriptionPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tenant_id: int
    plan_id: int
    plan_nome: str
    status: SubscriptionStatus
    current_period_start: datetime
    current_period_end: datetime

    @classmethod
    def from_orm(cls, sub: object) -> "SubscriptionPublic":
        return cls(
            id=sub.id,
            tenant_id=sub.tenant_id,
            plan_id=sub.plan_id,
            plan_nome=sub.plan.nome,
            status=sub.status,
            current_period_start=sub.current_period_start,
            current_period_end=sub.current_period_end,
        )


class UsageResponse(BaseModel):
    plan_nome: str | None
    limite_usuarios: int | None
    usuarios_atual: int
    limite_padroes: int | None
    limite_calibracoes_mes: int | None
    portal_cliente: bool

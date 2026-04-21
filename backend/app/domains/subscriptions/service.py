from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import Depends

from app.domains.plans.model import Plan
from app.domains.subscriptions.model import Subscription, SubscriptionStatus
from app.domains.subscriptions.repository import (
    SubscriptionRepository,
    SubscriptionRepositoryDep,
)
from app.domains.users.repository import UserRepository, UserRepositoryDep


class SubscriptionService:
    def __init__(self, repo: SubscriptionRepository, user_repo: UserRepository):
        self.repo = repo
        self.user_repo = user_repo

    async def get_all(self) -> list[Subscription]:
        return await self.repo.get_all()

    async def get_by_tenant(self, tenant_id: int) -> Subscription | None:
        return await self.repo.get_by_tenant(tenant_id)

    async def create_or_update(self, tenant_id: int, plan: Plan) -> Subscription:
        sub = await self.repo.get_by_tenant(tenant_id)
        now = datetime.now(timezone.utc)
        if sub:
            sub.plan_id = plan.id
            sub.status = SubscriptionStatus.active
            sub.current_period_start = now
            sub.current_period_end = now + timedelta(days=30)
        else:
            sub = Subscription(
                tenant_id=tenant_id,
                plan_id=plan.id,
                status=SubscriptionStatus.active,
                current_period_start=now,
                current_period_end=now + timedelta(days=30),
            )
        return await self.repo.save(sub)

    async def check_limit(self, tenant_id: int, resource: str) -> bool:
        """
        Retorna True se o tenant ainda está dentro do limite para o recurso.
        Recursos: "usuarios", "padroes", "calibracoes_mes"
        Limite -1 = ilimitado.
        """
        sub = await self.repo.get_by_tenant(tenant_id)
        if not sub or not sub.status == SubscriptionStatus.active:
            return True  # sem assinatura ativa = acesso livre (trial sem plano)

        plan = sub.plan

        if resource == "usuarios":
            if plan.limite_usuarios == -1:
                return True
            atual = await self.user_repo.count_active_by_tenant(tenant_id)
            return atual < plan.limite_usuarios

        # padroes e calibracoes_mes são verificados nos seus respectivos services
        # quando os módulos forem implementados
        return True

    async def get_usage(self, tenant_id: int) -> dict:
        sub = await self.repo.get_by_tenant(tenant_id)
        usuarios_atual = await self.user_repo.count_active_by_tenant(tenant_id)

        if not sub:
            return {
                "plan_nome": None,
                "limite_usuarios": None,
                "usuarios_atual": usuarios_atual,
                "limite_padroes": None,
                "limite_calibracoes_mes": None,
                "portal_cliente": False,
            }

        plan = sub.plan
        return {
            "plan_nome": plan.nome,
            "limite_usuarios": plan.limite_usuarios,
            "usuarios_atual": usuarios_atual,
            "limite_padroes": plan.limite_padroes,
            "limite_calibracoes_mes": plan.limite_calibracoes_mes,
            "portal_cliente": plan.portal_cliente,
        }


def get_subscription_service(
    repo: SubscriptionRepositoryDep,
    user_repo: UserRepositoryDep,
) -> SubscriptionService:
    return SubscriptionService(repo, user_repo)


SubscriptionServiceDep = Annotated[
    SubscriptionService, Depends(get_subscription_service)
]

from typing import Annotated

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncDBSession
from app.domains.subscriptions.model import Subscription


class SubscriptionRepository:
    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_all(self) -> list[Subscription]:
        result = await self._session.execute(
            select(Subscription).order_by(Subscription.id)
        )
        return list(result.scalars().all())

    async def get_by_tenant(self, tenant_id: int) -> Subscription | None:
        result = await self._session.execute(
            select(Subscription).where(Subscription.tenant_id == tenant_id)
        )
        return result.scalar_one_or_none()

    async def save(self, subscription: Subscription) -> Subscription:
        self._session.add(subscription)
        await self._session.flush()
        await self._session.refresh(subscription)
        return subscription


def get_subscription_repository(session: AsyncDBSession) -> SubscriptionRepository:
    return SubscriptionRepository(session)


SubscriptionRepositoryDep = Annotated[
    SubscriptionRepository, Depends(get_subscription_repository)
]

from typing import Annotated

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncDBSession
from app.domains.plans.model import Plan


class PlanRepository:
    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_all(self, only_active: bool = False) -> list[Plan]:
        stmt = select(Plan).order_by(Plan.id)
        if only_active:
            stmt = stmt.where(Plan.ativo.is_(True))
        result = await self._session.execute(stmt)
        return list(result.scalars().all())

    async def get_by_id(self, plan_id: int) -> Plan | None:
        return await self._session.get(Plan, plan_id)

    async def get_by_nome(self, nome: str) -> Plan | None:
        result = await self._session.execute(select(Plan).where(Plan.nome == nome))
        return result.scalar_one_or_none()

    async def save(self, plan: Plan) -> Plan:
        self._session.add(plan)
        await self._session.flush()
        await self._session.refresh(plan)
        return plan

    async def delete(self, plan: Plan) -> None:
        await self._session.delete(plan)
        await self._session.flush()


def get_plan_repository(session: AsyncDBSession) -> PlanRepository:
    return PlanRepository(session)


PlanRepositoryDep = Annotated[PlanRepository, Depends(get_plan_repository)]

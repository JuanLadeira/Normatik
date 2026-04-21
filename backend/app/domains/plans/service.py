from typing import Annotated

from fastapi import Depends

from app.domains.plans.model import Plan
from app.domains.plans.repository import PlanRepository, PlanRepositoryDep
from app.domains.plans.schema import PlanCreate, PlanUpdate


class PlanService:
    def __init__(self, repo: PlanRepository):
        self.repo = repo

    async def get_all(self, only_active: bool = False) -> list[Plan]:
        return await self.repo.get_all(only_active=only_active)

    async def get_by_id(self, plan_id: int) -> Plan | None:
        return await self.repo.get_by_id(plan_id)

    async def create(self, data: PlanCreate) -> Plan:
        plan = Plan(**data.model_dump())
        return await self.repo.save(plan)

    async def update(self, plan_id: int, data: PlanUpdate) -> Plan | None:
        plan = await self.repo.get_by_id(plan_id)
        if not plan:
            return None
        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(plan, key, value)
        return await self.repo.save(plan)

    async def delete(self, plan_id: int) -> bool:
        plan = await self.repo.get_by_id(plan_id)
        if not plan:
            return False
        await self.repo.delete(plan)
        return True


def get_plan_service(repo: PlanRepositoryDep) -> PlanService:
    return PlanService(repo)


PlanServiceDep = Annotated[PlanService, Depends(get_plan_service)]

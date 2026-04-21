from fastapi import APIRouter, HTTPException, status

from app.auth.dependencies import CurrentAdmin
from app.domains.plans.schema import PlanCreate, PlanPublic, PlanUpdate
from app.domains.plans.service import PlanServiceDep

router = APIRouter(prefix="/api/admin/plans", tags=["Admin — Plans"])


@router.get("/", response_model=list[PlanPublic])
async def list_plans(_: CurrentAdmin, service: PlanServiceDep):
    return await service.get_all()


@router.post("/", response_model=PlanPublic, status_code=status.HTTP_201_CREATED)
async def create_plan(data: PlanCreate, _: CurrentAdmin, service: PlanServiceDep):
    return await service.create(data)


@router.patch("/{plan_id}", response_model=PlanPublic)
async def update_plan(
    plan_id: int,
    data: PlanUpdate,
    _: CurrentAdmin,
    service: PlanServiceDep,
):
    plan = await service.update(plan_id, data)
    if not plan:
        raise HTTPException(status_code=404, detail="Plano não encontrado")
    return plan


@router.delete("/{plan_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_plan(plan_id: int, _: CurrentAdmin, service: PlanServiceDep):
    deleted = await service.delete(plan_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Plano não encontrado")

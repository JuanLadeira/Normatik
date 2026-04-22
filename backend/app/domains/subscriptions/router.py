from fastapi import APIRouter, HTTPException, status

from app.auth.dependencies import CurrentAdmin, CurrentUser
from app.domains.plans.service import PlanServiceDep
from app.domains.subscriptions.schema import SubscriptionPublic, UsageResponse
from app.domains.subscriptions.service import SubscriptionServiceDep

router = APIRouter(tags=["Subscriptions"])

# ── Tenant: visualiza própria assinatura e uso ────────────────────────────────

me_router = APIRouter(prefix="/api/subscription")


@me_router.get("/me", response_model=SubscriptionPublic | None)
async def get_my_subscription(
    current_user: CurrentUser, service: SubscriptionServiceDep
):
    sub = await service.get_by_tenant(current_user.tenant_id)
    if not sub:
        return None
    return SubscriptionPublic.from_orm(sub)


@me_router.get("/me/usage", response_model=UsageResponse)
async def get_my_usage(current_user: CurrentUser, service: SubscriptionServiceDep):
    usage = await service.get_usage(current_user.tenant_id)
    return UsageResponse(**usage)


# ── Admin: gerencia assinaturas ───────────────────────────────────────────────

admin_router = APIRouter(prefix="/api/admin/subscriptions")


@admin_router.get("/", response_model=list[SubscriptionPublic])
async def list_subscriptions(_: CurrentAdmin, service: SubscriptionServiceDep):
    subs = await service.get_all()
    return [SubscriptionPublic.from_orm(s) for s in subs]


@admin_router.post(
    "/tenants/{tenant_id}",
    response_model=SubscriptionPublic,
    status_code=status.HTTP_201_CREATED,
)
async def assign_subscription(
    tenant_id: int,
    data: dict,
    _: CurrentAdmin,
    service: SubscriptionServiceDep,
    plan_service: PlanServiceDep,
):
    plan_id = data.get("plan_id")
    if not plan_id:
        raise HTTPException(status_code=422, detail="plan_id é obrigatório")
    plan = await plan_service.get_by_id(plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Plano não encontrado")
    sub = await service.create_or_update(tenant_id, plan)
    return SubscriptionPublic.from_orm(sub)


router.include_router(me_router)
router.include_router(admin_router)

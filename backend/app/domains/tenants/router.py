from fastapi import APIRouter, HTTPException, status

from app.auth.dependencies import CurrentAdmin
from app.domains.tenants.schema import TenantCreate, TenantPublic, TenantUpdate
from app.domains.tenants.service import TenantServiceDep

router = APIRouter(prefix="/api/admin/tenants", tags=["Admin — Tenants"])


@router.get("/", response_model=list[TenantPublic])
async def list_tenants(_: CurrentAdmin, service: TenantServiceDep):
    return await service.get_all()


@router.post("/", response_model=TenantPublic, status_code=status.HTTP_201_CREATED)
async def create_tenant(
    data: TenantCreate,
    _: CurrentAdmin,
    service: TenantServiceDep,
):
    return await service.create(data)


@router.get("/{tenant_id}", response_model=TenantPublic)
async def get_tenant(tenant_id: int, _: CurrentAdmin, service: TenantServiceDep):
    tenant = await service.get_by_id(tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant não encontrado")
    return tenant


@router.patch("/{tenant_id}", response_model=TenantPublic)
async def update_tenant(
    tenant_id: int,
    data: TenantUpdate,
    _: CurrentAdmin,
    service: TenantServiceDep,
):
    tenant = await service.update(tenant_id, data)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant não encontrado")
    return tenant


@router.post("/{tenant_id}/activate", response_model=TenantPublic)
async def activate_tenant(
    tenant_id: int,
    data: dict,
    _: CurrentAdmin,
    service: TenantServiceDep,
):
    plan_id = data.get("plan_id")
    if not plan_id:
        raise HTTPException(status_code=422, detail="plan_id é obrigatório")
    tenant = await service.activate(tenant_id, plan_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant não encontrado")
    return tenant


@router.post("/{tenant_id}/suspend", response_model=TenantPublic)
async def suspend_tenant(tenant_id: int, _: CurrentAdmin, service: TenantServiceDep):
    tenant = await service.suspend(tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant não encontrado")
    return tenant


@router.post("/{tenant_id}/extend-trial", response_model=TenantPublic)
async def extend_trial(
    tenant_id: int,
    data: dict,
    _: CurrentAdmin,
    service: TenantServiceDep,
):
    days = data.get("days", 30)
    tenant = await service.extend_trial(tenant_id, days)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant não encontrado")
    return tenant


@router.delete("/{tenant_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tenant(tenant_id: int, _: CurrentAdmin, service: TenantServiceDep):
    deleted = await service.delete(tenant_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Tenant não encontrado")

from fastapi import APIRouter, HTTPException, status

from app.auth.dependencies import CurrentAdmin, CurrentUser, require_roles
from app.domains.users.model import UserRole
from app.domains.users.schema import UserInvite, UserPublic, UserUpdate
from app.domains.users.service import UserServiceDep

router = APIRouter(tags=["Users"])

# ── Admin: gerencia usuários de qualquer tenant ────────────────────────────────

admin_router = APIRouter(prefix="/api/admin/tenants/{tenant_id}/users")


@admin_router.get("/", response_model=list[UserPublic])
async def list_users(tenant_id: int, _: CurrentAdmin, service: UserServiceDep):
    return await service.list_by_tenant(tenant_id)


@admin_router.post("/", response_model=UserPublic, status_code=status.HTTP_201_CREATED)
async def invite_user(
    tenant_id: int,
    data: UserInvite,
    _: CurrentAdmin,
    service: UserServiceDep,
):
    return await service.invite(tenant_id, data)


# ── Lab: gestor gerencia usuários do próprio tenant ───────────────────────────

lab_router = APIRouter(prefix="/api/users")


@lab_router.get("/", response_model=list[UserPublic])
async def list_my_users(
    current_user: CurrentUser,
    service: UserServiceDep,
    _=require_roles(UserRole.admin),
):
    return await service.list_by_tenant(current_user.tenant_id)


@lab_router.post(
    "/invite", response_model=UserPublic, status_code=status.HTTP_201_CREATED
)
async def invite_lab_user(
    data: UserInvite,
    current_user: CurrentUser,
    service: UserServiceDep,
    _=require_roles(UserRole.admin),
):
    return await service.invite(current_user.tenant_id, data)


@lab_router.patch("/{user_id}", response_model=UserPublic)
async def update_user(
    user_id: int,
    data: UserUpdate,
    current_user: CurrentUser,
    service: UserServiceDep,
    _=require_roles(UserRole.admin),
):
    target = await service.get_by_id(user_id)
    if not target or target.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    if target.id == current_user.id:
        raise HTTPException(
            status_code=400, detail="Não é possível editar o próprio usuário por aqui"
        )
    user = await service.update(user_id, data)
    return user


@lab_router.post("/{user_id}/deactivate", response_model=UserPublic)
async def deactivate_user(
    user_id: int,
    current_user: CurrentUser,
    service: UserServiceDep,
    _=require_roles(UserRole.admin),
):
    target = await service.get_by_id(user_id)
    if not target or target.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    if target.id == current_user.id:
        raise HTTPException(status_code=400, detail="Não é possível se auto-desativar")
    return await service.deactivate(user_id)


router.include_router(admin_router)
router.include_router(lab_router)

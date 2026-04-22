from http import HTTPStatus
from typing import Annotated

from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer

from app.core.security import decode_access_token, decode_admin_token
from app.domains.admin.model import Admin
from app.domains.admin.service import AdminServiceDep
from app.domains.users.model import User, UserRole
from app.domains.users.service import UserServiceDep

_oauth2_user = OAuth2PasswordBearer(tokenUrl="/api/auth/login")
_oauth2_admin = OAuth2PasswordBearer(tokenUrl="/api/admin/login")


async def get_current_user(
    service: UserServiceDep,
    token: str = Depends(_oauth2_user),
) -> User:
    credentials_exc = HTTPException(
        status_code=HTTPStatus.UNAUTHORIZED,
        detail="Credenciais inválidas",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_access_token(token)
    if not payload:
        raise credentials_exc

    user_id = payload.get("sub")
    tenant_id = payload.get("tenant_id")
    if not user_id or not tenant_id:
        raise credentials_exc

    user = await service.get_by_id(int(user_id))
    if not user:
        raise credentials_exc

    if not user.is_active:
        raise HTTPException(status_code=HTTPStatus.FORBIDDEN, detail="Usuário inativo")

    if not user.tenant.is_active:
        raise HTTPException(
            status_code=HTTPStatus.FORBIDDEN,
            detail="Laboratório com acesso suspenso ou plano expirado",
        )

    return user


CurrentUser = Annotated[User, Depends(get_current_user)]


async def _require_role(*roles: UserRole):
    async def _check(current_user: CurrentUser) -> User:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=HTTPStatus.FORBIDDEN, detail="Permissão insuficiente"
            )
        return current_user

    return _check


def require_roles(*roles: UserRole):
    async def _check(current_user: CurrentUser) -> User:
        if current_user.role not in roles:
            raise HTTPException(
                status_code=HTTPStatus.FORBIDDEN, detail="Permissão insuficiente"
            )
        return current_user

    return Depends(_check)


CurrentAdmin_ = None  # definido abaixo para evitar import circular


async def get_current_admin(
    service: AdminServiceDep,
    token: str = Depends(_oauth2_admin),
) -> Admin:
    credentials_exc = HTTPException(
        status_code=HTTPStatus.UNAUTHORIZED,
        detail="Credenciais de admin inválidas",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_admin_token(token)
    if not payload:
        raise credentials_exc

    admin_id = payload.get("sub")
    if not admin_id:
        raise credentials_exc

    admin = await service.get_by_id(int(admin_id))
    if not admin or not admin.ativo:
        raise credentials_exc

    return admin


CurrentAdmin = Annotated[Admin, Depends(get_current_admin)]

from fastapi import APIRouter, HTTPException, Request, status
from fastapi.security import OAuth2PasswordRequestForm
from fastapi import Depends

from app.auth.dependencies import CurrentUser
from app.core.rate_limit import limiter
from app.core.security import (
    create_access_token,
    verify_password,
)
from app.domains.users.schema import UserMe, UserSetPassword
from app.domains.users.service import UserServiceDep

router = APIRouter(prefix="/api/auth", tags=["Auth"])


@router.post("/login")
@limiter.limit("5/minute")
async def login(
    request: Request,
    service: UserServiceDep,
    form_data: OAuth2PasswordRequestForm = Depends(),
):
    user = await service.get_by_email(form_data.username)
    if not user or not user.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciais inválidas"
        )
    if not verify_password(form_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciais inválidas"
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Usuário inativo"
        )
    if not user.tenant.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Laboratório com acesso suspenso ou plano expirado",
        )
    token = create_access_token(
        user_id=user.id,
        tenant_id=user.tenant_id,
        role=user.role.value,
    )
    return {"access_token": token, "token_type": "bearer"}


@router.post("/accept-invite")
async def accept_invite(data: UserSetPassword, service: UserServiceDep):
    user = await service.accept_invite(data.invite_token, data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token inválido ou expirado",
        )
    return {"message": "Senha definida. Faça login para continuar."}


@router.get("/me", response_model=UserMe)
async def me(current_user: CurrentUser):
    return current_user


@router.post("/change-password")
async def change_password(
    data: dict,
    current_user: CurrentUser,
    service: UserServiceDep,
):
    current_password = data.get("current_password", "")
    new_password = data.get("new_password", "")
    if not current_user.password or not verify_password(
        current_password, current_user.password
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Senha atual incorreta"
        )
    await service.update_password(current_user, new_password)
    return {"message": "Senha alterada com sucesso"}

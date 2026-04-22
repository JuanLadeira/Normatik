from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordRequestForm

from app.auth.dependencies import CurrentAdmin
from app.auth.totp import gerar_qr_uri, gerar_secret, verificar_codigo
from app.core.rate_limit import limiter
from app.core.security import (
    create_admin_access_token,
    create_temp_2fa_token,
    decode_temp_2fa_token,
    verify_password,
)
from app.domains.admin.schema import (
    AdminCreate,
    AdminPublic,
    LoginResponse,
    TotpConfirmRequest,
    TotpSetupResponse,
    TotpStatusResponse,
    TotpVerifyRequest,
)
from app.domains.admin.service import AdminServiceDep

router = APIRouter(prefix="/api/admin", tags=["Admin — Auth"])


@router.post("/login", response_model=LoginResponse)
@limiter.limit("5/minute")
async def admin_login(
    request: Request,
    service: AdminServiceDep,
    form_data: OAuth2PasswordRequestForm = Depends(),
):
    admin = await service.get_by_username(form_data.username)
    if not admin or not verify_password(form_data.password, admin.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciais inválidas"
        )
    if not admin.ativo:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Admin inativo"
        )

    if admin.totp_habilitado:
        return LoginResponse(
            requires_2fa=True, temp_token=create_temp_2fa_token(admin.id)
        )

    return LoginResponse(
        access_token=create_admin_access_token(admin.id, admin.username)
    )


@router.post("/login/2fa", response_model=LoginResponse)
@limiter.limit("5/minute")
async def admin_login_2fa(
    request: Request,
    data: TotpVerifyRequest,
    service: AdminServiceDep,
):
    admin_id = decode_temp_2fa_token(data.temp_token)
    if admin_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token temporário inválido ou expirado",
        )

    admin = await service.get_by_id(admin_id)
    if not admin or not admin.totp_habilitado or not admin.totp_secret:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="2FA não configurado"
        )

    if not verificar_codigo(admin.totp_secret, data.codigo):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Código TOTP inválido"
        )

    return LoginResponse(
        access_token=create_admin_access_token(admin.id, admin.username)
    )


@router.get("/me", response_model=AdminPublic)
async def admin_me(current_admin: CurrentAdmin):
    return current_admin


@router.get("/2fa/setup", response_model=TotpSetupResponse)
async def setup_2fa(current_admin: CurrentAdmin, service: AdminServiceDep):
    secret = gerar_secret()
    await service.set_totp_secret(current_admin.id, secret)
    return TotpSetupResponse(
        qr_uri=gerar_qr_uri(secret, current_admin.username), secret=secret
    )


@router.post("/2fa/confirm", response_model=TotpStatusResponse)
async def confirm_2fa(
    data: TotpConfirmRequest,
    current_admin: CurrentAdmin,
    service: AdminServiceDep,
):
    admin = await service.get_by_id(current_admin.id)
    if not admin or not admin.totp_secret:
        raise HTTPException(
            status_code=400, detail="Execute GET /api/admin/2fa/setup primeiro"
        )
    if not verificar_codigo(admin.totp_secret, data.codigo):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Código TOTP inválido"
        )
    await service.enable_totp(current_admin.id)
    return TotpStatusResponse(totp_habilitado=True)


@router.delete("/2fa/disable", response_model=TotpStatusResponse)
async def disable_2fa(current_admin: CurrentAdmin, service: AdminServiceDep):
    await service.disable_totp(current_admin.id)
    return TotpStatusResponse(totp_habilitado=False)


@router.post("/admins", response_model=AdminPublic, status_code=status.HTTP_201_CREATED)
async def create_admin(
    data: AdminCreate,
    _: CurrentAdmin,
    service: AdminServiceDep,
):
    existing = await service.get_by_username(data.username)
    if existing:
        raise HTTPException(status_code=400, detail="Username já existe")
    return await service.create(data)

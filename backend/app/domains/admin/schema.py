from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr


class AdminCreate(BaseModel):
    username: str
    email: EmailStr
    password: str
    nome: str


class AdminPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    username: str
    email: str
    nome: str
    ativo: bool
    totp_habilitado: bool
    created_at: datetime


class LoginRequest(BaseModel):
    username: str
    password: str


class LoginResponse(BaseModel):
    access_token: str | None = None
    token_type: str = "bearer"
    requires_2fa: bool = False
    temp_token: str | None = None


class TotpVerifyRequest(BaseModel):
    temp_token: str
    codigo: str


class TotpConfirmRequest(BaseModel):
    codigo: str


class TotpSetupResponse(BaseModel):
    qr_uri: str
    secret: str


class TotpStatusResponse(BaseModel):
    totp_habilitado: bool

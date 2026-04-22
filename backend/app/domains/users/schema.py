from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr

from app.domains.users.model import UserRole


class UserInvite(BaseModel):
    email: EmailStr
    nome: str
    role: UserRole


class UserUpdate(BaseModel):
    nome: str | None = None
    role: UserRole | None = None
    is_active: bool | None = None


class UserSetPassword(BaseModel):
    invite_token: str
    password: str


class UserPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tenant_id: int
    email: str
    nome: str
    role: UserRole
    is_active: bool
    created_at: datetime


class UserMe(UserPublic):
    pass

from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr

from app.domains.tenants.model import TenantStatus


class TenantCreate(BaseModel):
    nome: str
    cnpj: str | None = None
    email_gestor: EmailStr
    trial_days: int = 30


class TenantUpdate(BaseModel):
    nome: str | None = None
    cnpj: str | None = None
    email_gestor: EmailStr | None = None
    status: TenantStatus | None = None
    trial_expires_at: datetime | None = None
    plan_id: int | None = None


class TenantPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    slug: str
    cnpj: str | None
    email_gestor: str
    status: TenantStatus
    trial_expires_at: datetime | None
    plan_id: int | None
    is_active: bool
    created_at: datetime

from decimal import Decimal

from pydantic import BaseModel, ConfigDict, field_validator


class PlanCreate(BaseModel):
    nome: str
    descricao: str = ""
    preco_mensal: Decimal = Decimal("0.00")
    limite_usuarios: int = 2
    limite_padroes: int = 5
    limite_calibracoes_mes: int = 30
    portal_cliente: bool = False
    geracao_certificado_pdf: bool = True

    @field_validator("limite_usuarios", "limite_padroes", "limite_calibracoes_mes")
    @classmethod
    def validate_limit(cls, v: int) -> int:
        if v != -1 and v < 1:
            raise ValueError("Limite deve ser >= 1 ou -1 (ilimitado)")
        return v


class PlanUpdate(BaseModel):
    nome: str | None = None
    descricao: str | None = None
    preco_mensal: Decimal | None = None
    limite_usuarios: int | None = None
    limite_padroes: int | None = None
    limite_calibracoes_mes: int | None = None
    portal_cliente: bool | None = None
    geracao_certificado_pdf: bool | None = None
    ativo: bool | None = None


class PlanPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nome: str
    descricao: str
    preco_mensal: Decimal
    limite_usuarios: int
    limite_padroes: int
    limite_calibracoes_mes: int
    portal_cliente: bool
    geracao_certificado_pdf: bool
    ativo: bool

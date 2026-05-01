from pydantic import BaseModel, ConfigDict


class ClienteLaboratorioBase(BaseModel):
    nome: str
    cnpj: str | None = None
    email: str | None = None
    telefone: str | None = None
    contato: str | None = None
    ativo: bool = True


class ClienteLaboratorioCreate(ClienteLaboratorioBase):
    pass


class ClienteLaboratorioUpdate(BaseModel):
    nome: str | None = None
    cnpj: str | None = None
    email: str | None = None
    telefone: str | None = None
    contato: str | None = None
    ativo: bool | None = None


class ClienteLaboratorioPublic(ClienteLaboratorioBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tenant_id: int

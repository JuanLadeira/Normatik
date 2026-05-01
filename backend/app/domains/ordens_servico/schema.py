from datetime import datetime
from pydantic import BaseModel, ConfigDict

from app.domains.ordens_servico.model import StatusItemOS, StatusOS


class ItemOSBase(BaseModel):
    descricao: str
    quantidade_prevista: int = 1
    posicao: int = 1
    status: StatusItemOS = StatusItemOS.AGUARDANDO
    observacoes: str | None = None


class ItemOSCreate(ItemOSBase):
    pass


class ItemOSPublic(ItemOSBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    os_id: int
    quantidade_realizada: int


class OrdemDeServicoBase(BaseModel):
    cliente_id: int
    numero: str
    status: StatusOS = StatusOS.ABERTA
    data_entrada: datetime
    data_prevista: datetime | None = None
    data_conclusao: datetime | None = None
    observacoes: str | None = None


class OrdemDeServicoCreate(OrdemDeServicoBase):
    itens: list[ItemOSCreate] = []


class OrdemDeServicoUpdate(BaseModel):
    status: StatusOS | None = None
    data_prevista: datetime | None = None
    data_conclusao: datetime | None = None
    observacoes: str | None = None


class OrdemDeServicoPublic(OrdemDeServicoBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    tenant_id: int
    itens: list[ItemOSPublic] = []

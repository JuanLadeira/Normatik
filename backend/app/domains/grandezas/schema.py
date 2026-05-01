from pydantic import BaseModel, ConfigDict

from app.domains.grandezas.model import DistribuicaoIncerteza


class TipoIncertezaBTemplateBase(BaseModel):
    descricao: str
    simbolo: str | None = None
    distribuicao: DistribuicaoIncerteza
    graus_liberdade: float | None = None
    observacao: str | None = None


class TipoIncertezaBTemplateCreate(TipoIncertezaBTemplateBase):
    pass


class TipoIncertezaBTemplatePublic(TipoIncertezaBTemplateBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    grandeza_id: int


class GrandezaBase(BaseModel):
    nome: str
    simbolo: str
    unidade_si: str


class GrandezaCreate(GrandezaBase):
    pass


class GrandezaPublic(GrandezaBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tipos_incerteza_b: list[TipoIncertezaBTemplatePublic] = []

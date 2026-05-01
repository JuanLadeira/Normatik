from pydantic import BaseModel, ConfigDict

from app.domains.calibracoes.model import StatusServico
from app.domains.grandezas.model import DistribuicaoIncerteza


class IncertezaBFonteBase(BaseModel):
    padrao_id: int | None = None
    descricao: str
    valor_u: float
    distribuicao: DistribuicaoIncerteza
    graus_liberdade: float | None = None


class IncertezaBFonteCreate(IncertezaBFonteBase):
    pass


class IncertezaBFontePublic(IncertezaBFonteBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    servico_id: int


class PontoDeCalibraçãoBase(BaseModel):
    posicao: int
    valor_nominal: float
    unidade: str
    leituras_instrumento: list[float] = []
    leituras_padrao: list[float] = []
    fator_k: float = 2.0


class PontoDeCalibraçãoCreate(PontoDeCalibraçãoBase):
    pass


class PontoDeCalibraçãoPublic(PontoDeCalibraçãoBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    servico_id: int

    # Resultados calculados
    media_instrumento: float | None
    desvio_padrao_instrumento: float | None
    media_padrao: float | None
    desvio_padrao_padrao: float | None
    erro: float | None
    correcao: float | None
    u_tipo_a: float | None
    u_tipo_a_padrao: float | None
    u_combinada: float | None
    u_expandida: float | None


class ServicoDeCalibraçãoBase(BaseModel):
    item_os_id: int
    instrumento_id: int | None = None
    workbook_type: str
    status: StatusServico = StatusServico.RASCUNHO
    temperatura_ambiente: float | None = None
    umidade_relativa: float | None = None
    observacoes: str | None = None


class ServicoDeCalibraçãoCreate(ServicoDeCalibraçãoBase):
    pass


class ServicoDeCalibraçãoUpdate(BaseModel):
    instrumento_id: int | None = None
    status: StatusServico | None = None
    temperatura_ambiente: float | None = None
    umidade_relativa: float | None = None
    observacoes: str | None = None


class ServicoDeCalibraçãoPublic(ServicoDeCalibraçãoBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    fontes_incerteza_b: list[IncertezaBFontePublic] = []
    pontos: list[PontoDeCalibraçãoPublic] = []

from datetime import date
from pydantic import BaseModel, ConfigDict

from app.domains.equipamentos.model import StatusCalibracaoPadrao


# ── Unidade minimal (para embutir em FaixaMedicaoPublic) ─────────────────────


class UnidadeMedidaMinimal(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    nome: str
    simbolo: str


# ── Faixas de Medição ─────────────────────────────────────────────────────────


class FaixaMedicaoCreate(BaseModel):
    unidade_id: int
    valor_min: float | None = None
    valor_max: float | None = None
    resolucao: float | None = None


class FaixaMedicaoPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    equipamento_id: int
    unidade_id: int
    unidade: UnidadeMedidaMinimal
    valor_min: float | None = None
    valor_max: float | None = None
    resolucao: float | None = None
    posicao: int


# ── Catálogo ──────────────────────────────────────────────────────────────────


class TipoEquipamentoBase(BaseModel):
    grandeza_id: int
    codigo: str
    nome: str
    ativo: bool = True


class TipoEquipamentoPublicMinimal(TipoEquipamentoBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class FabricanteBase(BaseModel):
    nome: str
    ativo: bool = True


class FabricantePublic(FabricanteBase):
    model_config = ConfigDict(from_attributes=True)
    id: int


class ModeloEquipamentoBase(BaseModel):
    tipo_equipamento_id: int
    fabricante_id: int
    nome: str
    capacidade_padrao: float | None = None
    resolucao_padrao: float | None = None
    unidade_padrao: str | None = None
    ativo: bool = True


class ModeloEquipamentoPublicMinimal(ModeloEquipamentoBase):
    """Modelo usado dentro da listagem de tipos (sem o objeto tipo_equipamento redundante)"""

    model_config = ConfigDict(from_attributes=True)
    id: int
    fabricante: FabricantePublic


class TipoEquipamentoPublic(TipoEquipamentoPublicMinimal):
    """Tipo completo com seus modelos (para a tela de configuração)"""

    modelos: list[ModeloEquipamentoPublicMinimal] = []


class TipoEquipamentoCreate(BaseModel):
    nome: str
    grandeza_id: int
    codigo: str = ""


class FabricanteCreate(BaseModel):
    nome: str


class ModeloEquipamentoCreate(BaseModel):
    tipo_equipamento_id: int
    fabricante_id: int
    nome: str


class ModeloEquipamentoUpdate(BaseModel):
    tipo_equipamento_id: int | None = None
    fabricante_id: int | None = None
    nome: str | None = None
    ativo: bool | None = None


class ModeloEquipamentoPublic(ModeloEquipamentoBase):
    """Modelo completo com objeto tipo_equipamento (para listagens de modelos)"""

    model_config = ConfigDict(from_attributes=True)
    id: int
    tipo_equipamento: TipoEquipamentoPublicMinimal
    fabricante: FabricantePublic


# ── Equipamentos Base ─────────────────────────────────────────────────────────


class EquipamentoBase(BaseModel):
    tipo_equipamento_id: int
    modelo_equipamento_id: int | None = None
    tag: str | None = None
    numero_serie: str
    marca: str
    modelo: str
    fotos: list[str] = []
    ativo: bool = True


# ── Instrumento ───────────────────────────────────────────────────────────────


class InstrumentoCreate(EquipamentoBase):
    cliente_id: int
    faixas: list[FaixaMedicaoCreate] = []


class InstrumentoUpdate(BaseModel):
    modelo_equipamento_id: int | None = None
    tag: str | None = None
    numero_serie: str | None = None
    marca: str | None = None
    modelo: str | None = None
    fotos: list[str] | None = None
    ativo: bool | None = None
    cliente_id: int | None = None
    faixas: list[FaixaMedicaoCreate] | None = None


class InstrumentoPublic(EquipamentoBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    tenant_id: int
    cliente_id: int
    tipo_equipamento: TipoEquipamentoPublicMinimal
    faixas: list[FaixaMedicaoPublic] = []


# ── Padrão de Calibração ──────────────────────────────────────────────────────


class PadraoCreate(EquipamentoBase):
    faixas: list[FaixaMedicaoCreate] = []
    frequencia_calibracao_dias: int | None = None
    alerta_dias_antes: int = 30
    criterio_aceitacao: str | None = None
    u_maximo_aceito: float | None = None


class PadraoUpdate(BaseModel):
    modelo_equipamento_id: int | None = None
    tag: str | None = None
    numero_serie: str | None = None
    marca: str | None = None
    modelo: str | None = None
    fotos: list[str] | None = None
    ativo: bool | None = None
    frequencia_calibracao_dias: int | None = None
    alerta_dias_antes: int | None = None
    criterio_aceitacao: str | None = None
    u_maximo_aceito: float | None = None
    faixas: list[FaixaMedicaoCreate] | None = None


class PadraoPublic(EquipamentoBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    tenant_id: int
    tipo_equipamento: TipoEquipamentoPublicMinimal
    faixas: list[FaixaMedicaoPublic] = []

    # Campos de conveniência (espelho)
    numero_certificado: str | None
    data_calibracao: date | None
    validade_calibracao: date | None
    laboratorio_calibrador: str | None
    u_expandida_atual: float | None

    # Controle
    frequencia_calibracao_dias: int | None
    alerta_dias_antes: int
    criterio_aceitacao: str | None
    u_maximo_aceito: float | None

    status_calibracao: StatusCalibracaoPadrao


# ── Histórico de Calibração ───────────────────────────────────────────────────


class HistoricoCalibracaoPadraoCreate(BaseModel):
    data_calibracao: date
    data_vencimento: date
    numero_certificado: str
    laboratorio_calibrador: str | None = None
    u_expandida_certificado: float | None = None
    aceito: bool = True
    observacoes: str | None = None
    arquivo_pdf_url: str | None = None


class HistoricoCalibracaoPadraoUpdate(BaseModel):
    data_calibracao: date | None = None
    data_vencimento: date | None = None
    numero_certificado: str | None = None
    laboratorio_calibrador: str | None = None
    u_expandida_certificado: float | None = None
    aceito: bool | None = None
    observacoes: str | None = None
    arquivo_pdf_url: str | None = None


class HistoricoCalibracaoPadraoPublic(HistoricoCalibracaoPadraoCreate):
    model_config = ConfigDict(from_attributes=True)
    padrao_id: int
    id: int

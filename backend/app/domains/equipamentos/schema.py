from datetime import date
from pydantic import BaseModel, ConfigDict

from app.domains.equipamentos.model import StatusCalibracaoPadrao


# ── Catálogo ──────────────────────────────────────────────────────────────────


class TipoEquipamentoBase(BaseModel):
    grandeza_id: int
    codigo: str
    nome: str
    ativo: bool = True


class TipoEquipamentoPublic(TipoEquipamentoBase):
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


class ModeloEquipamentoPublic(ModeloEquipamentoBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    tipo_equipamento: TipoEquipamentoPublic
    fabricante: FabricantePublic


# ── Equipamentos Base ─────────────────────────────────────────────────────────


class EquipamentoBase(BaseModel):
    tipo_equipamento_id: int
    modelo_equipamento_id: int | None = None
    numero_serie: str
    marca: str
    modelo: str
    unidade: str
    capacidade: float | None = None
    resolucao: float | None = None
    ativo: bool = True


# ── Instrumento ───────────────────────────────────────────────────────────────


class InstrumentoCreate(EquipamentoBase):
    cliente_id: int


class InstrumentoUpdate(BaseModel):
    modelo_equipamento_id: int | None = None
    numero_serie: str | None = None
    marca: str | None = None
    modelo: str | None = None
    unidade: str | None = None
    capacidade: float | None = None
    resolucao: float | None = None
    ativo: bool | None = None
    cliente_id: int | None = None


class InstrumentoPublic(EquipamentoBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    tenant_id: int
    cliente_id: int


# ── Padrão de Calibração ──────────────────────────────────────────────────────


class PadraoCreate(EquipamentoBase):
    frequencia_calibracao_dias: int | None = None
    alerta_dias_antes: int = 30
    criterio_aceitacao: str | None = None
    u_maximo_aceito: float | None = None


class PadraoUpdate(BaseModel):
    modelo_equipamento_id: int | None = None
    numero_serie: str | None = None
    marca: str | None = None
    modelo: str | None = None
    unidade: str | None = None
    capacidade: float | None = None
    resolucao: float | None = None
    ativo: bool | None = None
    frequencia_calibracao_dias: int | None = None
    alerta_dias_antes: int | None = None
    criterio_aceitacao: str | None = None
    u_maximo_aceito: float | None = None


class PadraoPublic(EquipamentoBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    tenant_id: int

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


class HistoricoCalibracaoPadraoPublic(HistoricoCalibracaoPadraoCreate):
    model_config = ConfigDict(from_attributes=True)
    padrao_id: int
    id: int  # Base model has ID

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, model_validator

from app.domains.certificados_padrao.model import (
    StatusCertificado,
    StatusCurva,
    TipoRegressao,
)


# ── FormularioMedicaoTemplate ──────────────────────────────────────────────────


class FormularioTemplateCreate(BaseModel):
    tipo_instrumento_id: int
    nome: str
    campos_pontos: dict | list
    tipo_regressao_default: TipoRegressao = TipoRegressao.linear
    grau_polinomio_default: int = 1
    quantidade_pontos_default: int | None = None


class FormularioTemplateUpdate(BaseModel):
    nome: str | None = None
    campos_pontos: dict | list | None = None
    tipo_regressao_default: TipoRegressao | None = None
    grau_polinomio_default: int | None = None
    quantidade_pontos_default: int | None = None


class FormularioTemplatePublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tipo_instrumento_id: int
    nome: str
    campos_pontos: dict | list
    tipo_regressao_default: TipoRegressao
    grau_polinomio_default: int
    quantidade_pontos_default: int | None
    criado_por: int
    created_at: datetime
    updated_at: datetime


# ── CertificadoCalibracaoPadrao ────────────────────────────────────────────────


class CertificadoCreate(BaseModel):
    padrao_id: int
    numero_certificado: str
    laboratorio_calibrador: str
    data_emissao: date
    data_validade: date
    arquivo_pdf: str | None = None
    U_expandida: float
    k_abrangencia: float
    formulario_template_id: int | None = None
    formulario_config: dict | None = None

    @model_validator(mode="after")
    def validate_k_positive(self) -> "CertificadoCreate":
        if self.k_abrangencia <= 0:
            raise ValueError("k_abrangencia deve ser maior que zero")
        return self


class CertificadoUpdate(BaseModel):
    laboratorio_calibrador: str | None = None
    data_emissao: date | None = None
    data_validade: date | None = None
    arquivo_pdf: str | None = None
    U_expandida: float | None = None
    k_abrangencia: float | None = None
    formulario_template_id: int | None = None
    formulario_config: dict | None = None
    status: StatusCertificado | None = None


class CertificadoPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    padrao_id: int
    numero_certificado: str
    laboratorio_calibrador: str
    data_emissao: date
    data_validade: date
    arquivo_pdf: str | None
    U_expandida: float
    k_abrangencia: float
    u_padrao: float
    formulario_template_id: int | None
    formulario_config: dict | None
    status: StatusCertificado
    criado_por: int
    created_at: datetime
    updated_at: datetime


# ── PontoMedicaoCertificado ────────────────────────────────────────────────────


class PontoMedicaoCreate(BaseModel):
    ordem: int
    valores: dict


class PontoMedicaoPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    certificado_id: int
    ordem: int
    # valores brutos + campos calculados mesclados pelo service
    valores: dict


# ── CurvaCorrecao ──────────────────────────────────────────────────────────────


class CurvaCorrecaoPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    certificado_id: int
    tipo: TipoRegressao
    grau: int
    coeficientes: list
    r_quadrado: float
    pontos_curva: list
    status: StatusCurva
    aprovado_por: int | None
    data_aprovacao: datetime | None
    created_at: datetime
    updated_at: datetime


# ── Aprovação / Rejeição ───────────────────────────────────────────────────────


class AprovarCurvaRequest(BaseModel):
    observacoes: str | None = None


class RejeitarCurvaRequest(BaseModel):
    observacoes: str  # obrigatório


# ── UsoDePadrao ────────────────────────────────────────────────────────────────


class UsoPadraoCreate(BaseModel):
    servico_calibracao_id: int
    curva_correcao_id: int
    u_padrao_snapshot: float
    aplicado_em: datetime


class UsoPadraoPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    servico_calibracao_id: int
    curva_correcao_id: int
    u_padrao_snapshot: float
    aplicado_em: datetime
    created_at: datetime
    updated_at: datetime


# ── Analisar (request) ─────────────────────────────────────────────────────────


class AnalisarRequest(BaseModel):
    campo_x: str
    campo_y: str
    tipo: TipoRegressao = TipoRegressao.linear
    grau: int = 1

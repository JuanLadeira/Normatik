import enum
from datetime import date, datetime

from sqlalchemy import Date, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class TipoRegressao(enum.StrEnum):
    linear = "linear"
    polinomial = "polinomial"


class StatusCertificado(enum.StrEnum):
    rascunho = "rascunho"
    aguardando_aprovacao_curva = "aguardando_aprovacao_curva"
    ativo = "ativo"
    expirado = "expirado"


class StatusCurva(enum.StrEnum):
    sugerida = "sugerida"
    aprovada = "aprovada"
    rejeitada = "rejeitada"


class FormularioMedicaoTemplate(Base):
    """Template de formulário de medição para um tipo de instrumento.

    Global (sem tenant) — compartilhado entre todos os laboratórios.
    Define quais campos numéricos cada ponto de medição deve ter e
    qual regressão/grau padrão usar ao analisar os dados.
    """

    __tablename__ = "formularios_medicao_template"

    tipo_instrumento_id: Mapped[int] = mapped_column(
        ForeignKey("tipos_equipamento.id"), nullable=False, index=True
    )
    nome: Mapped[str] = mapped_column(String(200), nullable=False)
    # Estrutura: lista de {nome, label, calculado: "avg(c1,c2)" | "c1-c2" | false}
    campos_pontos: Mapped[dict] = mapped_column(JSONB, nullable=False)
    tipo_regressao_default: Mapped[TipoRegressao] = mapped_column(
        nullable=False, default=TipoRegressao.linear
    )
    grau_polinomio_default: Mapped[int] = mapped_column(
        Integer, nullable=False, default=1
    )
    quantidade_pontos_default: Mapped[int | None] = mapped_column(
        Integer, nullable=True
    )
    criado_por: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)

    tipo_instrumento: Mapped["TipoEquipamento"] = relationship(lazy="selectin")  # noqa: F821
    criado_por_user: Mapped["User"] = relationship(  # noqa: F821
        foreign_keys=[criado_por], lazy="selectin"
    )


class CertificadoCalibracaoPadrao(Base):
    """Certificado de calibração recebido de laboratório externo para um padrão.

    u_padrao é calculado automaticamente como U_expandida / k_abrangencia
    no service ao criar/atualizar.
    """

    __tablename__ = "certificados_calibracao_padrao"

    padrao_id: Mapped[int] = mapped_column(
        ForeignKey("padroes_calibracao.id"), nullable=False, index=True
    )
    numero_certificado: Mapped[str] = mapped_column(
        String(150), nullable=False, unique=True
    )
    laboratorio_calibrador: Mapped[str] = mapped_column(String(200), nullable=False)
    data_emissao: Mapped[date] = mapped_column(Date, nullable=False)
    data_validade: Mapped[date] = mapped_column(Date, nullable=False)
    arquivo_pdf: Mapped[str | None] = mapped_column(String(500), nullable=True)
    U_expandida: Mapped[float] = mapped_column(Float, nullable=False)
    k_abrangencia: Mapped[float] = mapped_column(Float, nullable=False)
    # Calculado: U_expandida / k_abrangencia — preenchido pelo service
    u_padrao: Mapped[float] = mapped_column(Float, nullable=False)
    formulario_template_id: Mapped[int | None] = mapped_column(
        ForeignKey("formularios_medicao_template.id"), nullable=True
    )
    formulario_config: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    status: Mapped[StatusCertificado] = mapped_column(
        nullable=False, default=StatusCertificado.rascunho
    )
    criado_por: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)

    padrao: Mapped["PadraoDeCalibração"] = relationship(  # noqa: F821
        foreign_keys=[padrao_id],
        backref="certificados",
        lazy="selectin",
    )
    formulario_template: Mapped["FormularioMedicaoTemplate | None"] = relationship(
        lazy="selectin"
    )
    criado_por_user: Mapped["User"] = relationship(  # noqa: F821
        foreign_keys=[criado_por], lazy="selectin"
    )
    pontos: Mapped[list["PontoMedicaoCertificado"]] = relationship(
        back_populates="certificado",
        lazy="noload",
        cascade="all, delete-orphan",
        order_by="PontoMedicaoCertificado.ordem",
    )
    curvas: Mapped[list["CurvaCorrecao"]] = relationship(
        back_populates="certificado",
        lazy="noload",
        cascade="all, delete-orphan",
    )


class PontoMedicaoCertificado(Base):
    """Ponto de medição de um certificado de calibração.

    `valores` é um JSONB livre conforme o formulário do template.
    Campos calculados (médias, diferenças) são derivados dinamicamente
    pelo service ao ler/salvar.
    """

    __tablename__ = "pontos_medicao_certificado"

    certificado_id: Mapped[int] = mapped_column(
        ForeignKey("certificados_calibracao_padrao.id"), nullable=False, index=True
    )
    ordem: Mapped[int] = mapped_column(Integer, nullable=False)
    valores: Mapped[dict] = mapped_column(JSONB, nullable=False)

    certificado: Mapped["CertificadoCalibracaoPadrao"] = relationship(
        back_populates="pontos", lazy="selectin"
    )


class CurvaCorrecao(Base):
    """Curva de correção calculada por regressão polinomial sobre os pontos de medição.

    coeficientes: lista [a0, a1, ...] em ordem crescente de grau.
    pontos_curva: lista de 100 pontos {x, y} para plotagem.
    """

    __tablename__ = "curvas_correcao"

    certificado_id: Mapped[int] = mapped_column(
        ForeignKey("certificados_calibracao_padrao.id"), nullable=False, index=True
    )
    tipo: Mapped[TipoRegressao] = mapped_column(nullable=False)
    grau: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    coeficientes: Mapped[list] = mapped_column(JSONB, nullable=False)
    r_quadrado: Mapped[float] = mapped_column(Float, nullable=False)
    pontos_curva: Mapped[list] = mapped_column(JSONB, nullable=False)
    status: Mapped[StatusCurva] = mapped_column(
        nullable=False, default=StatusCurva.sugerida
    )
    aprovado_por: Mapped[int | None] = mapped_column(
        ForeignKey("users.id"), nullable=True
    )
    data_aprovacao: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    certificado: Mapped["CertificadoCalibracaoPadrao"] = relationship(
        back_populates="curvas", lazy="selectin"
    )
    aprovado_por_user: Mapped["User | None"] = relationship(  # noqa: F821
        foreign_keys=[aprovado_por], lazy="selectin"
    )


class UsoDePadrao(Base):
    """Registro do uso de um padrão (via curva de correção) em um serviço de calibração."""

    __tablename__ = "uso_de_padrao"

    servico_calibracao_id: Mapped[int] = mapped_column(
        ForeignKey("servicos_calibracao.id"), nullable=False, index=True
    )
    curva_correcao_id: Mapped[int] = mapped_column(
        ForeignKey("curvas_correcao.id"), nullable=False, index=True
    )
    u_padrao_snapshot: Mapped[float] = mapped_column(Float, nullable=False)
    aplicado_em: Mapped[datetime] = mapped_column(DateTime, nullable=False)

    servico: Mapped["ServicoDeCalibração"] = relationship(lazy="selectin")  # noqa: F821
    curva: Mapped["CurvaCorrecao"] = relationship(lazy="selectin")

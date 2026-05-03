"""certificados_padrao_curvas_correcao

Revision ID: 3b7c9d1e2f4a
Revises: fa485ee281ae
Create Date: 2026-05-03 10:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = "3b7c9d1e2f4a"
down_revision: Union[str, Sequence[str], None] = "fa485ee281ae"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # ── Enums ──────────────────────────────────────────────────────────────────
    op.execute(sa.text("DROP TYPE IF EXISTS statuscertificado CASCADE"))
    op.execute(sa.text("DROP TYPE IF EXISTS statuscurva CASCADE"))
    op.execute(sa.text("DROP TYPE IF EXISTS tiporegressao CASCADE"))
    op.execute(
        sa.text(
            "CREATE TYPE statuscertificado AS ENUM "
            "('rascunho', 'aguardando_aprovacao_curva', 'ativo', 'expirado')"
        )
    )
    op.execute(
        sa.text("CREATE TYPE statuscurva AS ENUM ('sugerida', 'aprovada', 'rejeitada')")
    )
    op.execute(
        sa.text("CREATE TYPE tiporegressao AS ENUM ('linear', 'polinomial')")
    )

    # ── formularios_medicao_template ───────────────────────────────────────────
    op.create_table(
        "formularios_medicao_template",
        sa.Column("tipo_instrumento_id", sa.Integer(), nullable=False),
        sa.Column("nome", sa.String(length=200), nullable=False),
        sa.Column(
            "campos_pontos",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=False,
        ),
        sa.Column(
            "tipo_regressao_default",
            sa.Enum("linear", "polinomial", name="tiporegressao"),
            nullable=False,
        ),
        sa.Column("grau_polinomio_default", sa.Integer(), nullable=False),
        sa.Column("criado_por", sa.Integer(), nullable=False),
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["tipo_instrumento_id"], ["tipos_equipamento.id"]),
        sa.ForeignKeyConstraint(["criado_por"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_formularios_medicao_template_tipo_instrumento_id"),
        "formularios_medicao_template",
        ["tipo_instrumento_id"],
        unique=False,
    )

    # ── certificados_calibracao_padrao ────────────────────────────────────────
    op.create_table(
        "certificados_calibracao_padrao",
        sa.Column("padrao_id", sa.Integer(), nullable=False),
        sa.Column("numero_certificado", sa.String(length=150), nullable=False),
        sa.Column("laboratorio_calibrador", sa.String(length=200), nullable=False),
        sa.Column("data_emissao", sa.Date(), nullable=False),
        sa.Column("data_validade", sa.Date(), nullable=False),
        sa.Column("arquivo_pdf", sa.String(length=500), nullable=True),
        sa.Column("U_expandida", sa.Float(), nullable=False),
        sa.Column("k_abrangencia", sa.Float(), nullable=False),
        sa.Column("u_padrao", sa.Float(), nullable=False),
        sa.Column("formulario_template_id", sa.Integer(), nullable=True),
        sa.Column(
            "formulario_config",
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=True,
        ),
        sa.Column(
            "status",
            sa.Enum(
                "rascunho",
                "aguardando_aprovacao_curva",
                "ativo",
                "expirado",
                name="statuscertificado",
            ),
            nullable=False,
        ),
        sa.Column("criado_por", sa.Integer(), nullable=False),
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["padrao_id"], ["padroes_calibracao.id"]),
        sa.ForeignKeyConstraint(
            ["formulario_template_id"], ["formularios_medicao_template.id"]
        ),
        sa.ForeignKeyConstraint(["criado_por"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("numero_certificado"),
    )
    op.create_index(
        op.f("ix_certificados_calibracao_padrao_padrao_id"),
        "certificados_calibracao_padrao",
        ["padrao_id"],
        unique=False,
    )

    # ── pontos_medicao_certificado ────────────────────────────────────────────
    op.create_table(
        "pontos_medicao_certificado",
        sa.Column("certificado_id", sa.Integer(), nullable=False),
        sa.Column("ordem", sa.Integer(), nullable=False),
        sa.Column("valores", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["certificado_id"], ["certificados_calibracao_padrao.id"]
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_pontos_medicao_certificado_certificado_id"),
        "pontos_medicao_certificado",
        ["certificado_id"],
        unique=False,
    )

    # ── curvas_correcao ────────────────────────────────────────────────────────
    op.create_table(
        "curvas_correcao",
        sa.Column("certificado_id", sa.Integer(), nullable=False),
        sa.Column(
            "tipo",
            sa.Enum("linear", "polinomial", name="tiporegressao"),
            nullable=False,
        ),
        sa.Column("grau", sa.Integer(), nullable=False),
        sa.Column(
            "coeficientes", postgresql.JSONB(astext_type=sa.Text()), nullable=False
        ),
        sa.Column("r_quadrado", sa.Float(), nullable=False),
        sa.Column(
            "pontos_curva", postgresql.JSONB(astext_type=sa.Text()), nullable=False
        ),
        sa.Column(
            "status",
            sa.Enum("sugerida", "aprovada", "rejeitada", name="statuscurva"),
            nullable=False,
        ),
        sa.Column("aprovado_por", sa.Integer(), nullable=True),
        sa.Column("data_aprovacao", sa.DateTime(), nullable=True),
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["certificado_id"], ["certificados_calibracao_padrao.id"]
        ),
        sa.ForeignKeyConstraint(["aprovado_por"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_curvas_correcao_certificado_id"),
        "curvas_correcao",
        ["certificado_id"],
        unique=False,
    )

    # ── uso_de_padrao ──────────────────────────────────────────────────────────
    op.create_table(
        "uso_de_padrao",
        sa.Column("servico_calibracao_id", sa.Integer(), nullable=False),
        sa.Column("curva_correcao_id", sa.Integer(), nullable=False),
        sa.Column("u_padrao_snapshot", sa.Float(), nullable=False),
        sa.Column("aplicado_em", sa.DateTime(), nullable=False),
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(
            ["servico_calibracao_id"], ["servicos_calibracao.id"]
        ),
        sa.ForeignKeyConstraint(["curva_correcao_id"], ["curvas_correcao.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_uso_de_padrao_servico_calibracao_id"),
        "uso_de_padrao",
        ["servico_calibracao_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_uso_de_padrao_curva_correcao_id"),
        "uso_de_padrao",
        ["curva_correcao_id"],
        unique=False,
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index(
        op.f("ix_uso_de_padrao_curva_correcao_id"), table_name="uso_de_padrao"
    )
    op.drop_index(
        op.f("ix_uso_de_padrao_servico_calibracao_id"), table_name="uso_de_padrao"
    )
    op.drop_table("uso_de_padrao")

    op.drop_index(
        op.f("ix_curvas_correcao_certificado_id"), table_name="curvas_correcao"
    )
    op.drop_table("curvas_correcao")

    op.drop_index(
        op.f("ix_pontos_medicao_certificado_certificado_id"),
        table_name="pontos_medicao_certificado",
    )
    op.drop_table("pontos_medicao_certificado")

    op.drop_index(
        op.f("ix_certificados_calibracao_padrao_padrao_id"),
        table_name="certificados_calibracao_padrao",
    )
    op.drop_table("certificados_calibracao_padrao")

    op.drop_index(
        op.f("ix_formularios_medicao_template_tipo_instrumento_id"),
        table_name="formularios_medicao_template",
    )
    op.drop_table("formularios_medicao_template")

    sa.Enum(name="statuscertificado").drop(op.get_bind(), checkfirst=True)
    sa.Enum(name="statuscurva").drop(op.get_bind(), checkfirst=True)
    sa.Enum(name="tiporegressao").drop(op.get_bind(), checkfirst=True)

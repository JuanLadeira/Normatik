"""equipamentos: substitui unidade/capacidade/resolucao por faixas_medicao

Revision ID: e5f6a7b8c9d0
Revises: c3a1f2d4e5b6
Create Date: 2026-05-02 01:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "e5f6a7b8c9d0"
down_revision: Union[str, Sequence[str], None] = "c3a1f2d4e5b6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "faixas_medicao",
        sa.Column("equipamento_id", sa.Integer(), nullable=False),
        sa.Column("unidade_id", sa.Integer(), nullable=False),
        sa.Column("valor_min", sa.Float(), nullable=True),
        sa.Column("valor_max", sa.Float(), nullable=True),
        sa.Column("resolucao", sa.Float(), nullable=True),
        sa.Column("posicao", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["equipamento_id"], ["equipamentos.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["unidade_id"], ["unidades_medida.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_faixas_medicao_equipamento_id"),
        "faixas_medicao",
        ["equipamento_id"],
        unique=False,
    )
    op.drop_column("equipamentos", "unidade")
    op.drop_column("equipamentos", "capacidade")
    op.drop_column("equipamentos", "resolucao")


def downgrade() -> None:
    op.add_column(
        "equipamentos",
        sa.Column("unidade", sa.String(length=20), nullable=False, server_default=""),
    )
    op.add_column("equipamentos", sa.Column("capacidade", sa.Float(), nullable=True))
    op.add_column("equipamentos", sa.Column("resolucao", sa.Float(), nullable=True))
    op.drop_index(op.f("ix_faixas_medicao_equipamento_id"), table_name="faixas_medicao")
    op.drop_table("faixas_medicao")

"""grandezas: substitui unidade_si por tabela unidades_medida

Revision ID: c3a1f2d4e5b6
Revises: fa485ee281ae
Create Date: 2026-05-02 00:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "c3a1f2d4e5b6"
down_revision: Union[str, Sequence[str], None] = "fa485ee281ae"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "unidades_medida",
        sa.Column("grandeza_id", sa.Integer(), nullable=False),
        sa.Column("nome", sa.String(length=100), nullable=False),
        sa.Column("simbolo", sa.String(length=20), nullable=False),
        sa.Column("is_si", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["grandeza_id"], ["grandezas.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        op.f("ix_unidades_medida_grandeza_id"),
        "unidades_medida",
        ["grandeza_id"],
        unique=False,
    )
    op.drop_column("grandezas", "unidade_si")


def downgrade() -> None:
    op.add_column(
        "grandezas",
        sa.Column("unidade_si", sa.String(length=50), nullable=False, server_default=""),
    )
    op.drop_index(op.f("ix_unidades_medida_grandeza_id"), table_name="unidades_medida")
    op.drop_table("unidades_medida")

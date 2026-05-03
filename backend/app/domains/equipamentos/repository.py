from typing import Annotated

from fastapi import Depends
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import AsyncDBSession
from app.domains.equipamentos.model import (
    Fabricante,
    FaixaMedicao,
    HistoricoCalibracaoPadrao,
    Instrumento,
    ModeloEquipamento,
    PadraoDeCalibração,
    TipoEquipamento,
)


def _load_equipamento():
    return (selectinload(Instrumento.faixas).selectinload(FaixaMedicao.unidade),)


def _load_padrao():
    return (selectinload(PadraoDeCalibração.faixas).selectinload(FaixaMedicao.unidade),)


class EquipamentoRepository:
    def __init__(self, session: AsyncSession):
        self._session = session

    # ── Catálogo ──────────────────────────────────────────────────────────────

    async def get_tipos_equipamento(
        self, grandeza_id: int | None = None
    ) -> list[TipoEquipamento]:
        query = (
            select(TipoEquipamento)
            .options(
                selectinload(TipoEquipamento.modelos).selectinload(
                    ModeloEquipamento.fabricante
                )
            )
            .order_by(TipoEquipamento.nome)
        )
        if grandeza_id:
            query = query.where(TipoEquipamento.grandeza_id == grandeza_id)
        result = await self._session.execute(query)
        return list(result.scalars().all())

    async def get_tipo_by_id(self, tipo_id: int) -> TipoEquipamento | None:
        return await self._session.get(TipoEquipamento, tipo_id)

    async def get_fabricantes(self) -> list[Fabricante]:
        result = await self._session.execute(
            select(Fabricante).order_by(Fabricante.nome)
        )
        return list(result.scalars().all())

    async def get_fabricante_by_id(self, fabricante_id: int) -> Fabricante | None:
        return await self._session.get(Fabricante, fabricante_id)

    async def get_modelos(
        self, tipo_id: int | None = None, fabricante_id: int | None = None
    ) -> list[ModeloEquipamento]:
        query = (
            select(ModeloEquipamento)
            .options(
                selectinload(ModeloEquipamento.tipo_equipamento),
                selectinload(ModeloEquipamento.fabricante),
            )
            .order_by(ModeloEquipamento.nome)
        )
        if tipo_id:
            query = query.where(ModeloEquipamento.tipo_equipamento_id == tipo_id)
        if fabricante_id:
            query = query.where(ModeloEquipamento.fabricante_id == fabricante_id)
        result = await self._session.execute(query)
        return list(result.scalars().all())

    async def get_modelo_by_id(self, modelo_id: int) -> ModeloEquipamento | None:
        return await self._session.get(ModeloEquipamento, modelo_id)

    async def get_modelo_by_id_with_relations(
        self, modelo_id: int
    ) -> ModeloEquipamento | None:
        result = await self._session.execute(
            select(ModeloEquipamento)
            .options(
                selectinload(ModeloEquipamento.tipo_equipamento),
                selectinload(ModeloEquipamento.fabricante),
            )
            .where(ModeloEquipamento.id == modelo_id)
        )
        return result.scalar_one_or_none()

    async def get_fabricante_by_nome(self, nome: str) -> Fabricante | None:
        result = await self._session.execute(
            select(Fabricante).where(Fabricante.nome == nome)
        )
        return result.scalar_one_or_none()

    async def get_modelo_by_tipo_fabricante_nome(
        self, tipo_id: int, fabricante_id: int, nome: str
    ) -> ModeloEquipamento | None:
        result = await self._session.execute(
            select(ModeloEquipamento)
            .options(
                selectinload(ModeloEquipamento.tipo_equipamento),
                selectinload(ModeloEquipamento.fabricante),
            )
            .where(
                ModeloEquipamento.tipo_equipamento_id == tipo_id,
                ModeloEquipamento.fabricante_id == fabricante_id,
                ModeloEquipamento.nome == nome,
            )
        )
        return result.scalar_one_or_none()

    # ── Instrumentos ──────────────────────────────────────────────────────────

    async def get_instrumentos(
        self, tenant_id: int, cliente_id: int | None = None
    ) -> list[Instrumento]:
        query = (
            select(Instrumento)
            .where(Instrumento.tenant_id == tenant_id)
            .options(*_load_equipamento())
            .order_by(Instrumento.id)
        )
        if cliente_id:
            query = query.where(Instrumento.cliente_id == cliente_id)
        result = await self._session.execute(query)
        return list(result.scalars().all())

    async def get_instrumento_by_id(
        self, tenant_id: int, instrumento_id: int
    ) -> Instrumento | None:
        result = await self._session.execute(
            select(Instrumento)
            .where(Instrumento.tenant_id == tenant_id, Instrumento.id == instrumento_id)
            .options(*_load_equipamento())
        )
        return result.scalar_one_or_none()

    # ── Padrões ───────────────────────────────────────────────────────────────

    async def get_padroes(self, tenant_id: int) -> list[PadraoDeCalibração]:
        result = await self._session.execute(
            select(PadraoDeCalibração)
            .where(PadraoDeCalibração.tenant_id == tenant_id)
            .options(*_load_padrao())
            .order_by(PadraoDeCalibração.id)
        )
        return list(result.scalars().all())

    async def get_padrao_by_id(
        self, tenant_id: int, padrao_id: int
    ) -> PadraoDeCalibração | None:
        result = await self._session.execute(
            select(PadraoDeCalibração)
            .where(
                PadraoDeCalibração.tenant_id == tenant_id,
                PadraoDeCalibração.id == padrao_id,
            )
            .options(*_load_padrao())
        )
        return result.scalar_one_or_none()

    # ── Faixas ────────────────────────────────────────────────────────────────

    async def save_faixa(self, faixa: FaixaMedicao) -> FaixaMedicao:
        self._session.add(faixa)
        await self._session.flush()
        await self._session.refresh(faixa, ["unidade"])
        return faixa

    async def delete_faixas_by_equipamento(self, equipamento_id: int) -> None:
        await self._session.execute(
            delete(FaixaMedicao).where(FaixaMedicao.equipamento_id == equipamento_id)
        )
        await self._session.flush()

    # ── Geral ─────────────────────────────────────────────────────────────────

    async def save(self, obj):
        self._session.add(obj)
        await self._session.flush()
        await self._session.refresh(obj)
        return obj

    async def delete(self, obj):
        await self._session.delete(obj)
        await self._session.flush()

    # ── Histórico ─────────────────────────────────────────────────────────────

    async def get_historico_padrao(
        self, padrao_id: int
    ) -> list[HistoricoCalibracaoPadrao]:
        result = await self._session.execute(
            select(HistoricoCalibracaoPadrao)
            .where(HistoricoCalibracaoPadrao.padrao_id == padrao_id)
            .order_by(HistoricoCalibracaoPadrao.data_calibracao.desc())
        )
        return list(result.scalars().all())

    async def get_historico_padrao_by_id(
        self, historico_id: int
    ) -> HistoricoCalibracaoPadrao | None:
        return await self._session.get(HistoricoCalibracaoPadrao, historico_id)

    async def get_historico_padrao_by_certificado(
        self, padrao_id: int, numero_certificado: str
    ) -> HistoricoCalibracaoPadrao | None:
        result = await self._session.execute(
            select(HistoricoCalibracaoPadrao).where(
                HistoricoCalibracaoPadrao.padrao_id == padrao_id,
                HistoricoCalibracaoPadrao.numero_certificado == numero_certificado,
            )
        )
        return result.scalar_one_or_none()


def get_equipamento_repository(session: AsyncDBSession) -> EquipamentoRepository:
    return EquipamentoRepository(session)


EquipamentoRepositoryDep = Annotated[
    EquipamentoRepository, Depends(get_equipamento_repository)
]

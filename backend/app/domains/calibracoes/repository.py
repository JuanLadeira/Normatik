from typing import Annotated

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import AsyncDBSession
from app.domains.calibracoes.model import (
    IncertezaBFonte,
    PontoDeCalibração,
    ServicoDeCalibração,
)
from app.domains.ordens_servico.model import ItemOS


class CalibracaoRepository:
    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_by_id(self, servico_id: int) -> ServicoDeCalibração | None:
        result = await self._session.execute(
            select(ServicoDeCalibração)
            .where(ServicoDeCalibração.id == servico_id)
            .options(
                selectinload(ServicoDeCalibração.fontes_incerteza_b),
                selectinload(ServicoDeCalibração.pontos),
                selectinload(ServicoDeCalibração.instrumento),
                selectinload(ServicoDeCalibração.item_os).selectinload(ItemOS.os),
            )
        )
        return result.scalar_one_or_none()

    async def save(self, obj):
        self._session.add(obj)
        await self._session.flush()
        await self._session.refresh(obj)
        return obj

    async def delete(self, obj):
        await self._session.delete(obj)
        await self._session.flush()

    async def get_ponto_by_id(self, ponto_id: int) -> PontoDeCalibração | None:
        return await self._session.get(PontoDeCalibração, ponto_id)

    async def get_fonte_by_id(self, fonte_id: int) -> IncertezaBFonte | None:
        return await self._session.get(IncertezaBFonte, fonte_id)


def get_calibracao_repository(session: AsyncDBSession) -> CalibracaoRepository:
    return CalibracaoRepository(session)


CalibracaoRepositoryDep = Annotated[
    CalibracaoRepository, Depends(get_calibracao_repository)
]

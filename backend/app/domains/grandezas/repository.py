from typing import Annotated

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import AsyncDBSession
from app.domains.grandezas.model import Grandeza, TipoIncertezaBTemplate, UnidadeMedida


def _load_grandeza():
    return selectinload(Grandeza.unidades), selectinload(Grandeza.tipos_incerteza_b)


class GrandezaRepository:
    def __init__(self, session: AsyncSession):
        self._session = session

    async def get_all(self) -> list[Grandeza]:
        result = await self._session.execute(
            select(Grandeza).options(*_load_grandeza()).order_by(Grandeza.nome)
        )
        return list(result.scalars().all())

    async def get_by_id(self, grandeza_id: int) -> Grandeza | None:
        result = await self._session.execute(
            select(Grandeza)
            .where(Grandeza.id == grandeza_id)
            .options(*_load_grandeza())
        )
        return result.scalar_one_or_none()

    async def get_by_nome(self, nome: str) -> Grandeza | None:
        result = await self._session.execute(
            select(Grandeza).where(Grandeza.nome == nome).options(*_load_grandeza())
        )
        return result.scalar_one_or_none()

    async def save(self, grandeza: Grandeza) -> Grandeza:
        self._session.add(grandeza)
        await self._session.flush()
        await self._session.refresh(grandeza, ["unidades", "tipos_incerteza_b"])
        return grandeza

    async def delete(self, grandeza: Grandeza) -> None:
        await self._session.delete(grandeza)
        await self._session.flush()

    async def add_template_b(
        self, template: TipoIncertezaBTemplate
    ) -> TipoIncertezaBTemplate:
        self._session.add(template)
        await self._session.flush()
        await self._session.refresh(template)
        return template

    async def add_unidade(self, unidade: UnidadeMedida) -> UnidadeMedida:
        self._session.add(unidade)
        await self._session.flush()
        await self._session.refresh(unidade)
        return unidade

    async def get_unidade_by_id(self, unidade_id: int) -> UnidadeMedida | None:
        result = await self._session.execute(
            select(UnidadeMedida).where(UnidadeMedida.id == unidade_id)
        )
        return result.scalar_one_or_none()

    async def delete_unidade(self, unidade: UnidadeMedida) -> None:
        await self._session.delete(unidade)
        await self._session.flush()


def get_grandeza_repository(session: AsyncDBSession) -> GrandezaRepository:
    return GrandezaRepository(session)


GrandezaRepositoryDep = Annotated[GrandezaRepository, Depends(get_grandeza_repository)]

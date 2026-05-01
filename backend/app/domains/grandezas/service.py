from typing import Annotated

from fastapi import Depends, HTTPException, status

from app.domains.grandezas.model import Grandeza, TipoIncertezaBTemplate
from app.domains.grandezas.repository import GrandezaRepository, GrandezaRepositoryDep
from app.domains.grandezas.schema import GrandezaCreate, TipoIncertezaBTemplateCreate


class GrandezaService:
    def __init__(self, repo: GrandezaRepository):
        self.repo = repo

    async def get_all(self) -> list[Grandeza]:
        return await self.repo.get_all()

    async def get_by_id(self, grandeza_id: int) -> Grandeza:
        grandeza = await self.repo.get_by_id(grandeza_id)
        if not grandeza:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Grandeza não encontrada",
            )
        return grandeza

    async def create(self, data: GrandezaCreate) -> Grandeza:
        existing = await self.repo.get_by_nome(data.nome)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Já existe uma grandeza com este nome",
            )
        grandeza = Grandeza(**data.model_dump())
        return await self.repo.save(grandeza)

    async def add_template_b(
        self, grandeza_id: int, data: TipoIncertezaBTemplateCreate
    ) -> TipoIncertezaBTemplate:
        grandeza = await self.get_by_id(grandeza_id)
        template = TipoIncertezaBTemplate(grandeza_id=grandeza.id, **data.model_dump())
        return await self.repo.add_template_b(template)

    async def delete(self, grandeza_id: int) -> None:
        grandeza = await self.get_by_id(grandeza_id)
        await self.repo.delete(grandeza)


def get_grandeza_service(repo: GrandezaRepositoryDep) -> GrandezaService:
    return GrandezaService(repo)


GrandezaServiceDep = Annotated[GrandezaService, Depends(get_grandeza_service)]

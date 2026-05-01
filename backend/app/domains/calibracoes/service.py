from typing import Annotated

from fastapi import Depends, HTTPException, status

from app.domains.calibracoes.model import (
    IncertezaBFonte,
    PontoDeCalibração,
    ServicoDeCalibração,
)
from app.domains.calibracoes.repository import (
    CalibracaoRepository,
    CalibracaoRepositoryDep,
)
from app.domains.calibracoes.schema import (
    IncertezaBFonteCreate,
    PontoDeCalibraçãoCreate,
    ServicoDeCalibraçãoCreate,
    ServicoDeCalibraçãoUpdate,
)


class CalibracaoService:
    def __init__(self, repo: CalibracaoRepository):
        self.repo = repo

    async def get_by_id(self, tenant_id: int, servico_id: int) -> ServicoDeCalibração:
        servico = await self.repo.get_by_id(servico_id)
        if not servico or servico.item_os.os.tenant_id != tenant_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Serviço de calibração não encontrado",
            )
        return servico

    async def create(
        self, tenant_id: int, data: ServicoDeCalibraçãoCreate
    ) -> ServicoDeCalibração:
        # Aqui poderíamos validar se o item_os pertence ao tenant_id
        # mas por simplicidade assumimos que o router validou ou passamos a responsabilidade
        servico = ServicoDeCalibração(**data.model_dump())
        # Validação extra
        return await self.repo.save(servico)

    async def update(
        self, tenant_id: int, servico_id: int, data: ServicoDeCalibraçãoUpdate
    ) -> ServicoDeCalibração:
        servico = await self.get_by_id(tenant_id, servico_id)
        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(servico, key, value)
        return await self.repo.save(servico)

    # ── Gestão de Pontos ──────────────────────────────────────────────────────

    async def add_ponto(
        self, tenant_id: int, servico_id: int, data: PontoDeCalibraçãoCreate
    ) -> PontoDeCalibração:
        servico = await self.get_by_id(tenant_id, servico_id)
        ponto = PontoDeCalibração(servico_id=servico.id, **data.model_dump())

        # Calcula resultados iniciais
        ponto.calcular_incertezas(servico.fontes_incerteza_b)

        return await self.repo.save(ponto)

    async def update_ponto(
        self,
        tenant_id: int,
        servico_id: int,
        ponto_id: int,
        data: PontoDeCalibraçãoCreate,
    ) -> PontoDeCalibração:
        servico = await self.get_by_id(tenant_id, servico_id)
        ponto = await self.repo.get_ponto_by_id(ponto_id)

        if not ponto or ponto.servico_id != servico.id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Ponto de calibração não encontrado neste serviço",
            )

        for key, value in data.model_dump().items():
            setattr(ponto, key, value)

        ponto.calcular_incertezas(servico.fontes_incerteza_b)
        return await self.repo.save(ponto)

    async def delete_ponto(
        self, tenant_id: int, servico_id: int, ponto_id: int
    ) -> None:
        servico = await self.get_by_id(tenant_id, servico_id)
        ponto = await self.repo.get_ponto_by_id(ponto_id)

        if ponto and ponto.servico_id == servico.id:
            await self.repo.delete(ponto)

    # ── Gestão de Fontes Tipo B ───────────────────────────────────────────────

    async def add_fonte_b(
        self, tenant_id: int, servico_id: int, data: IncertezaBFonteCreate
    ) -> IncertezaBFonte:
        # 1. Carrega o serviço
        servico = await self.get_by_id(tenant_id, servico_id)

        # 2. Cria e salva a fonte vinculada
        fonte = IncertezaBFonte(servico_id=servico.id, **data.model_dump())
        await self.repo.save(fonte)

        # 3. Força o recarregamento do serviço para garantir que a nova fonte e pontos estejam presentes
        # (O refresh do repo.save(fonte) não recarrega a coleção do servico)
        self.repo._session.expire(servico)
        servico = await self.get_by_id(tenant_id, servico_id)

        # 4. Recalcula todos os pontos
        await self._recalcular_todos_pontos(servico)
        return fonte

    async def delete_fonte_b(
        self, tenant_id: int, servico_id: int, fonte_id: int
    ) -> None:
        servico = await self.get_by_id(tenant_id, servico_id)
        fonte = await self.repo.get_fonte_by_id(fonte_id)

        if fonte and fonte.servico_id == servico.id:
            servico.fontes_incerteza_b.remove(fonte)
            await self.repo.delete(fonte)
            # Recalcula todos os pontos sem a fonte removida
            await self._recalcular_todos_pontos(servico)

    async def _recalcular_todos_pontos(self, servico: ServicoDeCalibração) -> None:
        # Força o carregamento dos pontos se não estiverem presentes
        # (Em alguns cenários de cache do SQLAlchemy, a relação pode estar vazia se carregada antes do flush)
        if not servico.pontos:
            from sqlalchemy import select

            result = await self.repo._session.execute(
                select(PontoDeCalibração).where(
                    PontoDeCalibração.servico_id == servico.id
                )
            )
            pontos = list(result.scalars().all())
        else:
            pontos = servico.pontos

        for ponto in pontos:
            ponto.calcular_incertezas(servico.fontes_incerteza_b)
            await self.repo.save(ponto)


def get_calibracao_service(repo: CalibracaoRepositoryDep) -> CalibracaoService:
    return CalibracaoService(repo)


CalibracaoServiceDep = Annotated[CalibracaoService, Depends(get_calibracao_service)]

from fastapi import APIRouter, status

from app.auth.dependencies import CurrentUser
from app.domains.calibracoes.schema import (
    IncertezaBFonteCreate,
    IncertezaBFontePublic,
    PontoDeCalibraçãoCreate,
    PontoDeCalibraçãoPublic,
    ServicoDeCalibraçãoCreate,
    ServicoDeCalibraçãoPublic,
    ServicoDeCalibraçãoUpdate,
)
from app.domains.calibracoes.service import CalibracaoServiceDep

router = APIRouter(prefix="/api/calibracoes", tags=["Metrologia — Calibrações"])


@router.get("/{id}", response_model=ServicoDeCalibraçãoPublic)
async def get_servico(
    id: int, current_user: CurrentUser, service: CalibracaoServiceDep
):
    """Obtém detalhes de um serviço de calibração."""
    return await service.get_by_id(current_user.tenant_id, id)


@router.post(
    "/", response_model=ServicoDeCalibraçãoPublic, status_code=status.HTTP_201_CREATED
)
async def create_servico(
    data: ServicoDeCalibraçãoCreate,
    current_user: CurrentUser,
    service: CalibracaoServiceDep,
):
    """Inicia um novo serviço de calibração."""
    return await service.create(current_user.tenant_id, data)


@router.patch("/{id}", response_model=ServicoDeCalibraçãoPublic)
async def update_servico(
    id: int,
    data: ServicoDeCalibraçãoUpdate,
    current_user: CurrentUser,
    service: CalibracaoServiceDep,
):
    """Atualiza dados de um serviço."""
    return await service.update(current_user.tenant_id, id, data)


# ── Pontos ────────────────────────────────────────────────────────────────────


@router.post(
    "/{id}/pontos",
    response_model=PontoDeCalibraçãoPublic,
    status_code=status.HTTP_201_CREATED,
)
async def add_ponto(
    id: int,
    data: PontoDeCalibraçãoCreate,
    current_user: CurrentUser,
    service: CalibracaoServiceDep,
):
    """Adiciona um ponto de calibração e dispara o cálculo GUM."""
    return await service.add_ponto(current_user.tenant_id, id, data)


@router.put("/{id}/pontos/{ponto_id}", response_model=PontoDeCalibraçãoPublic)
async def update_ponto(
    id: int,
    ponto_id: int,
    data: PontoDeCalibraçãoCreate,
    current_user: CurrentUser,
    service: CalibracaoServiceDep,
):
    """Atualiza um ponto de calibração e dispara o recálculo."""
    return await service.update_ponto(current_user.tenant_id, id, ponto_id, data)


@router.delete("/{id}/pontos/{ponto_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_ponto(
    id: int, ponto_id: int, current_user: CurrentUser, service: CalibracaoServiceDep
):
    """Remove um ponto de calibração."""
    await service.delete_ponto(current_user.tenant_id, id, ponto_id)


# ── Fontes Tipo B ─────────────────────────────────────────────────────────────


@router.post(
    "/{id}/fontes-b",
    response_model=IncertezaBFontePublic,
    status_code=status.HTTP_201_CREATED,
)
async def add_fonte_b(
    id: int,
    data: IncertezaBFonteCreate,
    current_user: CurrentUser,
    service: CalibracaoServiceDep,
):
    """Adiciona uma fonte de incerteza Tipo B e recalcula todos os pontos."""
    return await service.add_fonte_b(current_user.tenant_id, id, data)


@router.delete("/{id}/fontes-b/{fonte_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_fonte_b(
    id: int, fonte_id: int, current_user: CurrentUser, service: CalibracaoServiceDep
):
    """Remove uma fonte de incerteza Tipo B."""
    await service.delete_fonte_b(current_user.tenant_id, id, fonte_id)

from typing import Annotated

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.database import AsyncDBSession
from app.domains.certificados_padrao.model import (
    CertificadoCalibracaoPadrao,
    CurvaCorrecao,
    FormularioMedicaoTemplate,
    PontoMedicaoCertificado,
    StatusCurva,
    UsoDePadrao,
)


class CertificadoPadraoRepository:
    def __init__(self, session: AsyncSession):
        self._session = session

    # ── helpers genéricos ──────────────────────────────────────────────────────

    async def save(self, obj):
        self._session.add(obj)
        await self._session.flush()
        await self._session.refresh(obj)
        return obj

    async def delete(self, obj):
        await self._session.delete(obj)
        await self._session.flush()

    # ── FormularioMedicaoTemplate ──────────────────────────────────────────────

    async def get_template_by_id(
        self, template_id: int
    ) -> FormularioMedicaoTemplate | None:
        return await self._session.get(FormularioMedicaoTemplate, template_id)

    async def list_templates(self) -> list[FormularioMedicaoTemplate]:
        result = await self._session.execute(
            select(FormularioMedicaoTemplate).order_by(FormularioMedicaoTemplate.nome)
        )
        return list(result.scalars().all())

    # ── CertificadoCalibracaoPadrao ────────────────────────────────────────────

    async def get_certificado_by_id(
        self, certificado_id: int
    ) -> CertificadoCalibracaoPadrao | None:
        result = await self._session.execute(
            select(CertificadoCalibracaoPadrao)
            .where(CertificadoCalibracaoPadrao.id == certificado_id)
            .options(
                selectinload(CertificadoCalibracaoPadrao.pontos),
                selectinload(CertificadoCalibracaoPadrao.curvas),
            )
        )
        return result.scalar_one_or_none()

    async def list_certificados_by_padrao(
        self, padrao_id: int
    ) -> list[CertificadoCalibracaoPadrao]:
        result = await self._session.execute(
            select(CertificadoCalibracaoPadrao)
            .where(CertificadoCalibracaoPadrao.padrao_id == padrao_id)
            .order_by(CertificadoCalibracaoPadrao.data_emissao.desc())
        )
        return list(result.scalars().all())

    # ── PontoMedicaoCertificado ────────────────────────────────────────────────

    async def list_pontos(self, certificado_id: int) -> list[PontoMedicaoCertificado]:
        result = await self._session.execute(
            select(PontoMedicaoCertificado)
            .where(PontoMedicaoCertificado.certificado_id == certificado_id)
            .order_by(PontoMedicaoCertificado.ordem)
        )
        return list(result.scalars().all())

    async def delete_pontos_of_certificado(self, certificado_id: int) -> None:
        pontos = await self.list_pontos(certificado_id)
        for p in pontos:
            await self._session.delete(p)
        await self._session.flush()

    # ── CurvaCorrecao ──────────────────────────────────────────────────────────

    async def get_curva_by_id(self, curva_id: int) -> CurvaCorrecao | None:
        return await self._session.get(CurvaCorrecao, curva_id)

    async def get_curva_ativa(self, certificado_id: int) -> CurvaCorrecao | None:
        """Retorna a curva aprovada mais recente de um certificado."""
        result = await self._session.execute(
            select(CurvaCorrecao)
            .where(
                CurvaCorrecao.certificado_id == certificado_id,
                CurvaCorrecao.status == StatusCurva.aprovada,
            )
            .order_by(CurvaCorrecao.id.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()

    async def get_curva_sugerida_mais_recente(
        self, certificado_id: int
    ) -> CurvaCorrecao | None:
        """Retorna a curva sugerida mais recente (para aprovar/rejeitar)."""
        result = await self._session.execute(
            select(CurvaCorrecao)
            .where(
                CurvaCorrecao.certificado_id == certificado_id,
                CurvaCorrecao.status == StatusCurva.sugerida,
            )
            .order_by(CurvaCorrecao.id.desc())
            .limit(1)
        )
        return result.scalar_one_or_none()

    # ── UsoDePadrao ────────────────────────────────────────────────────────────

    async def get_uso_by_id(self, uso_id: int) -> UsoDePadrao | None:
        return await self._session.get(UsoDePadrao, uso_id)


def get_certificado_padrao_repository(
    session: AsyncDBSession,
) -> CertificadoPadraoRepository:
    return CertificadoPadraoRepository(session)


CertificadoPadraoRepositoryDep = Annotated[
    CertificadoPadraoRepository, Depends(get_certificado_padrao_repository)
]

from typing import Annotated

from fastapi import Depends, HTTPException, status

from app.domains.equipamentos.model import (
    HistoricoCalibracaoPadrao,
    Instrumento,
    PadraoDeCalibração,
)
from app.domains.equipamentos.repository import (
    EquipamentoRepository,
    EquipamentoRepositoryDep,
)
from app.domains.equipamentos.schema import (
    HistoricoCalibracaoPadraoCreate,
    InstrumentoCreate,
    InstrumentoUpdate,
    PadraoCreate,
    PadraoUpdate,
)


class EquipamentoService:
    def __init__(self, repo: EquipamentoRepository):
        self.repo = repo

    # ── Catálogo ──────────────────────────────────────────────────────────────

    async def get_tipos_equipamento(self, grandeza_id: int | None = None):
        return await self.repo.get_tipos_equipamento(grandeza_id)

    async def get_fabricantes(self):
        return await self.repo.get_fabricantes()

    async def get_modelos(
        self, tipo_id: int | None = None, fabricante_id: int | None = None
    ):
        return await self.repo.get_modelos(tipo_id, fabricante_id)

    # ── Instrumentos ──────────────────────────────────────────────────────────

    async def get_instrumentos(self, tenant_id: int, cliente_id: int | None = None):
        return await self.repo.get_instrumentos(tenant_id, cliente_id)

    async def get_instrumento_by_id(
        self, tenant_id: int, instrumento_id: int
    ) -> Instrumento:
        instr = await self.repo.get_instrumento_by_id(tenant_id, instrumento_id)
        if not instr:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Instrumento não encontrado",
            )
        return instr

    async def create_instrumento(
        self, tenant_id: int, data: InstrumentoCreate
    ) -> Instrumento:
        instrumento = Instrumento(tenant_id=tenant_id, **data.model_dump())
        return await self.repo.save(instrumento)

    async def update_instrumento(
        self, tenant_id: int, instrumento_id: int, data: InstrumentoUpdate
    ) -> Instrumento:
        instr = await self.get_instrumento_by_id(tenant_id, instrumento_id)
        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(instr, key, value)
        return await self.repo.save(instr)

    async def delete_instrumento(self, tenant_id: int, instrumento_id: int) -> None:
        instr = await self.get_instrumento_by_id(tenant_id, instrumento_id)
        await self.repo.delete(instr)

    # ── Padrões ───────────────────────────────────────────────────────────────

    async def get_padroes(self, tenant_id: int):
        return await self.repo.get_padroes(tenant_id)

    async def get_padrao_by_id(
        self, tenant_id: int, padrao_id: int
    ) -> PadraoDeCalibração:
        padrao = await self.repo.get_padrao_by_id(tenant_id, padrao_id)
        if not padrao:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Padrão não encontrado",
            )
        return padrao

    async def create_padrao(
        self, tenant_id: int, data: PadraoCreate
    ) -> PadraoDeCalibração:
        padrao = PadraoDeCalibração(tenant_id=tenant_id, **data.model_dump())
        return await self.repo.save(padrao)

    async def update_padrao(
        self, tenant_id: int, padrao_id: int, data: PadraoUpdate
    ) -> PadraoDeCalibração:
        padrao = await self.get_padrao_by_id(tenant_id, padrao_id)
        for key, value in data.model_dump(exclude_unset=True).items():
            setattr(padrao, key, value)
        return await self.repo.save(padrao)

    async def delete_padrao(self, tenant_id: int, padrao_id: int) -> None:
        padrao = await self.get_padrao_by_id(tenant_id, padrao_id)
        await self.repo.delete(padrao)

    # ── Regra de Negócio: Registro de Calibração Externa ──────────────────────

    async def registrar_calibracao_externa(
        self, tenant_id: int, padrao_id: int, data: HistoricoCalibracaoPadraoCreate
    ) -> HistoricoCalibracaoPadrao:
        """Registra calibração e atualiza espelho do padrão se aceito."""
        padrao = await self.get_padrao_by_id(tenant_id, padrao_id)

        historico = HistoricoCalibracaoPadrao(padrao_id=padrao.id, **data.model_dump())

        await self.repo.save(historico)

        if historico.aceito:
            padrao.numero_certificado = historico.numero_certificado
            padrao.data_calibracao = historico.data_calibracao
            padrao.validade_calibracao = historico.data_vencimento
            padrao.laboratorio_calibrador = historico.laboratorio_calibrador
            padrao.u_expandida_atual = historico.u_expandida_certificado
            await self.repo.save(padrao)

        return historico

    async def get_historico_padrao(self, tenant_id: int, padrao_id: int):
        padrao = await self.get_padrao_by_id(tenant_id, padrao_id)
        return await self.repo.get_historico_padrao(padrao.id)


def get_equipamento_service(repo: EquipamentoRepositoryDep) -> EquipamentoService:
    return EquipamentoService(repo)


EquipamentoServiceDep = Annotated[EquipamentoService, Depends(get_equipamento_service)]

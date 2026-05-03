"""Seed de grandezas físicas e suas unidades de medida.

Executa standalone:
    cd backend && python -m app.seed_grandezas
"""

import asyncio
import logging

from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from sqlalchemy.orm import selectinload

from app.core.settings import settings
import app._models  # noqa: F401 — resolve todos os relacionamentos do SQLAlchemy
from app.domains.grandezas.model import Grandeza, UnidadeMedida

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("seed_grandezas")

# (nome, simbolo, [(nome_unidade, simbolo_unidade, is_si), ...])
GRANDEZAS: list[tuple[str, str, list[tuple[str, str, bool]]]] = [
    (
        "Comprimento",
        "L",
        [
            ("Metro", "m", True),
            ("Milímetro", "mm", False),
            ("Centímetro", "cm", False),
            ("Micrômetro", "µm", False),
            ("Polegada", "in", False),
        ],
    ),
    (
        "Temperatura",
        "T",
        [
            ("Kelvin", "K", True),
            ("Grau Celsius", "°C", False),
            ("Grau Fahrenheit", "°F", False),
        ],
    ),
    (
        "Massa",
        "m",
        [
            ("Quilograma", "kg", True),
            ("Grama", "g", False),
            ("Miligrama", "mg", False),
            ("Micrograma", "µg", False),
            ("Libra", "lb", False),
        ],
    ),
    (
        "Pressão",
        "P",
        [
            ("Pascal", "Pa", True),
            ("Quilopascal", "kPa", False),
            ("Megapascal", "MPa", False),
            ("Bar", "bar", False),
            ("Milibar", "mbar", False),
            ("Libra-força por polegada quadrada", "psi", False),
            ("Milímetro de mercúrio", "mmHg", False),
        ],
    ),
    (
        "Força",
        "F",
        [
            ("Newton", "N", True),
            ("Quilonewton", "kN", False),
            ("Milinewton", "mN", False),
            ("Quilograma-força", "kgf", False),
        ],
    ),
    (
        "Torque",
        "M",
        [
            ("Newton-metro", "N·m", True),
            ("Newton-centímetro", "N·cm", False),
            ("Quilograma-força-metro", "kgf·m", False),
            ("Quilograma-força-centímetro", "kgf·cm", False),
        ],
    ),
    (
        "Tensão Elétrica",
        "U",
        [
            ("Volt", "V", True),
            ("Milivolt", "mV", False),
            ("Microvolt", "µV", False),
            ("Quilovolt", "kV", False),
        ],
    ),
    (
        "Corrente Elétrica",
        "I",
        [
            ("Ampere", "A", True),
            ("Miliampere", "mA", False),
            ("Microampere", "µA", False),
        ],
    ),
    (
        "Resistência Elétrica",
        "R",
        [
            ("Ohm", "Ω", True),
            ("Quilo-ohm", "kΩ", False),
            ("Megaohm", "MΩ", False),
        ],
    ),
    (
        "Ângulo Plano",
        "α",
        [
            ("Radiano", "rad", True),
            ("Grau", "°", False),
            ("Minuto de arco", "'", False),
            ("Segundo de arco", '"', False),
        ],
    ),
    (
        "Volume",
        "V",
        [
            ("Metro cúbico", "m³", True),
            ("Litro", "L", False),
            ("Mililitro", "mL", False),
            ("Microlitro", "µL", False),
        ],
    ),
    (
        "Frequência",
        "f",
        [
            ("Hertz", "Hz", True),
            ("Quilohertz", "kHz", False),
            ("Megahertz", "MHz", False),
        ],
    ),
    (
        "Umidade Relativa",
        "UR",
        [
            ("Porcentagem de umidade relativa", "%UR", True),
        ],
    ),
    (
        "Aceleração",
        "a",
        [
            ("Metro por segundo ao quadrado", "m/s²", True),
            ("Aceleração gravitacional padrão", "gₙ", False),
        ],
    ),
    (
        "Tempo",
        "t",
        [
            ("Segundo", "s", True),
            ("Milissegundo", "ms", False),
            ("Microssegundo", "µs", False),
            ("Minuto", "min", False),
            ("Hora", "h", False),
        ],
    ),
    (
        "Velocidade",
        "v",
        [
            ("Metro por segundo", "m/s", True),
            ("Quilômetro por hora", "km/h", False),
            ("Rotações por minuto", "rpm", False),
        ],
    ),
]


async def run_seed():
    logger.info(f"Conectando ao banco: {settings.DATABASE_URL}")
    engine = create_async_engine(settings.DATABASE_URL)
    Session = async_sessionmaker(engine, expire_on_commit=False)

    async with Session() as session:
        try:
            for nome, simbolo, unidades in GRANDEZAS:
                result = await session.execute(
                    select(Grandeza)
                    .where(Grandeza.nome == nome)
                    .options(selectinload(Grandeza.unidades))
                )
                grandeza = result.scalar_one_or_none()

                if not grandeza:
                    grandeza = Grandeza(nome=nome, simbolo=simbolo)
                    session.add(grandeza)
                    await session.flush()
                    logger.info(f"Grandeza criada: {nome}")
                else:
                    logger.info(f"Grandeza já existe: {nome}")

                simbolos_existentes = {u.simbolo for u in grandeza.unidades}
                for nome_u, simbolo_u, is_si in unidades:
                    if simbolo_u not in simbolos_existentes:
                        session.add(
                            UnidadeMedida(
                                grandeza_id=grandeza.id,
                                nome=nome_u,
                                simbolo=simbolo_u,
                                is_si=is_si,
                            )
                        )
                        logger.info(f"  Unidade adicionada: {simbolo_u} ({nome_u})")

            await session.commit()
            logger.info("Seed de grandezas concluído com sucesso!")

        except Exception as e:
            logger.error(f"ERRO NO SEED: {e}")
            await session.rollback()
            raise
        finally:
            await engine.dispose()


if __name__ == "__main__":
    asyncio.run(run_seed())

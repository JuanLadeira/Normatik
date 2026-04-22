import logging
import sys

from app.core.settings import settings


def setup_logging():
    # Desativa loggers barulhentos
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)

    # Configuração básica para stdout
    logging.basicConfig(
        level=logging.INFO if not settings.DEBUG else logging.DEBUG,
        format="%(asctime)s | %(levelname)-8s | %(name)s:%(funcName)s:%(lineno)d - %(message)s",
        stream=sys.stdout,
        force=True,
    )

    # Define o logger principal
    logger = logging.getLogger("normatik")
    logger.info("Logging configurado com sucesso (Fator XI).")
    return logger


logger = setup_logging()

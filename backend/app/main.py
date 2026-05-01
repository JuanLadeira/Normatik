from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.auth.router import router as auth_router
from app.core.logging import logger
from app.core.rate_limit import limiter
from app.core.settings import settings
from app.domains.admin.router import router as admin_router
from app.domains.plans.router import router as plans_router
from app.domains.subscriptions.router import router as subscriptions_router
from app.domains.tenants.router import router as tenants_router
from app.domains.users.router import router as users_router
from app.domains.grandezas.router import router as grandezas_router
from app.domains.clientes.router import router as clientes_router
from app.domains.equipamentos.router import router as equipamentos_router
from app.domains.ordens_servico.router import router as os_router
from app.domains.calibracoes.router import router as calibracoes_router

# Importa todos os models para que o Base.metadata os conheça
import app.domains.plans.model  # noqa: F401
import app.domains.tenants.model  # noqa: F401
import app.domains.users.model  # noqa: F401
import app.domains.subscriptions.model  # noqa: F401
import app.domains.admin.model  # noqa: F401
import app.domains.outbox.model  # noqa: F401
import app.domains.grandezas.model  # noqa: F401
import app.domains.clientes.model  # noqa: F401
import app.domains.equipamentos.model  # noqa: F401
import app.domains.ordens_servico.model  # noqa: F401
import app.domains.calibracoes.model  # noqa: F401


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Fator XII: Não criamos tabelas aqui — Alembic gerencia o esquema.
    logger.info(f"Iniciando {settings.PROJECT_NAME} (debug={settings.DEBUG}).")
    yield
    logger.info(f"Encerrando {settings.PROJECT_NAME} (graceful shutdown).")


app = FastAPI(
    title=settings.PROJECT_NAME,
    version="0.1.0",
    lifespan=lifespan,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(admin_router)
app.include_router(plans_router)
app.include_router(tenants_router)
app.include_router(users_router)
app.include_router(subscriptions_router)
app.include_router(grandezas_router)
app.include_router(clientes_router)
app.include_router(equipamentos_router)
app.include_router(os_router)
app.include_router(calibracoes_router)


@app.get("/health")
async def health():
    return {"status": "ok"}


# Ruff trigger

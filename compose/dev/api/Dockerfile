FROM python:3.12-slim

WORKDIR /app

# Instala uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Configurações do Python
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app

# Copia dependências (usando lockfile se existir)
COPY backend/pyproject.toml backend/uv.lock* ./

# Instala dependências (sem o projeto em si para cache)
RUN uv sync --no-dev --no-install-project

# Copia o código do backend e arquivos de migração
COPY backend/app/ ./app/
COPY backend/alembic/ ./alembic/
COPY backend/alembic.ini ./

# Sincroniza o projeto final (incluindo dependências dev para testes)
RUN uv sync --extra dev

# Copia o entrypoint da pasta de composição
COPY compose/dev/api/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/entrypoint.sh"]

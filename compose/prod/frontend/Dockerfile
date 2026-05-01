# ── Stage 1: Flutter build ────────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

ARG API_URL=https://api.z3ndocs.uk

WORKDIR /app

# Copia pacotes do monorepo antes para resolver path dependencies
COPY frontend/packages/ frontend/packages/
COPY frontend/apps/lab_app/ frontend/apps/lab_app/

WORKDIR /app/frontend/apps/lab_app

RUN flutter pub get && \
    flutter build web --release \
        --dart-define=API_URL=$API_URL

# ── Stage 2: Servir com nginx ─────────────────────────────────────────────────
FROM nginx:alpine

COPY --from=builder /app/frontend/apps/lab_app/build/web /usr/share/nginx/html
COPY compose/prod/frontend/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

.PHONY: help up down restart logs build shell db-migrate db-seed test clean

# Variáveis
DC = docker compose
APP_SERVICE = api

help: ## Mostra esta ajuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

up: ## Inicia os containers em background
	$(DC) up -d

down: ## Para e remove os containers
	$(DC) down

restart: ## Reinicia os containers
	$(DC) restart

logs: ## Exibe os logs dos containers
	$(DC) logs -f

build: ## Reconstrói as imagens do Docker
	$(DC) build

shell: ## Abre um shell interativo no container da API
	$(DC) exec $(APP_SERVICE) /bin/bash

db-migrate: ## Executa as migrações do banco de dados
	$(DC) exec $(APP_SERVICE) uv run alembic upgrade head

db-makemigrations: ## Gera uma nova migração (uso: make db-makemigrations msg="descrição")
	$(DC) exec $(APP_SERVICE) uv run alembic revision --autogenerate -m "$(msg)"

db-seed: ## Executa o script de seed inicial
	$(DC) exec $(APP_SERVICE) /entrypoint.sh

test: ## Executa os testes automatizados
	$(DC) exec $(APP_SERVICE) uv run pytest

clean: ## Remove volumes e imagens órfãs
	$(DC) down -v --remove-orphans

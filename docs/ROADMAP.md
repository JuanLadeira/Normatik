# Normatiq — ROADMAP de Desenvolvimento
> SaaS de Metrologia Multi-Tenant · FastAPI + Flutter + PostgreSQL + Celery

---

## Visão Geral das Fases

| Fase | Nome | Módulos | Branches | Entrega |
|------|------|---------|----------|---------|
| **F0** | Infraestrutura | — | `feature/f0-infra-docker` | Ambiente local completo |
| **F1** | Fundação & Auth | M01 | `feature/f1-*` | Multi-tenancy, auth, roles |
| **F1.5** | Outbox Genérico | — | `feature/f1-outbox-dispatcher` | Dispatcher extensível + handler registry |
| **F2** | Core Metrológico | M02, M03, M04 | `feature/f2-*` | Padrões, instrumentos, calibração + GUM |
| **F3** | Certificados | M05 | `feature/f3-*` | Emissão PDF ISO 17025 |
| **F4** | Operação Comercial | M06, M07, M27 | `feature/f4-*` | Orçamentos, pedidos, estoque |
| **F5** | Alertas & Manutenção | M08, M09 | `feature/f5-*` | Calendário, e-mails automáticos, Celery Beat |
| **F6** | Portal do Cliente | M10 | `feature/f6-*` | Acesso externo do cliente |
| **F7** | Negócio SaaS | M11 | `feature/f7-*` | Admin, planos, billing |
| **F8** | Motor Excel | M28 | `feature/f8-*` | Planilhas GUM por tipo de instrumento |

> **MVP funcional:** Fases F0–F3  
> **Produto completo para uso diário:** F0–F5  
> **SaaS comercializável:** F0–F8

---

## F0 · Infraestrutura — Docker Compose

**Branch:** `feature/f0-infra-docker`

### Objetivo
Ambiente de desenvolvimento local com todos os serviços necessários, pronto para rodar com um único `docker compose up`.

### Containers

| Serviço | Imagem | Porta | Função |
|---------|--------|-------|--------|
| `postgres` | `postgres:16-alpine` | 5432 | Banco de dados principal |
| `redis` | `redis:7-alpine` | 6379 | Broker do Celery + cache |
| `api` | `./backend` (build local) | 8000 | FastAPI — backend principal |
| `celery-worker` | `./backend` (build local) | — | Worker para tarefas assíncronas |
| `celery-beat` | `./backend` (build local) | — | Scheduler de tarefas recorrentes (alertas) |
| `celery-flower` | `mher/flower` | 5555 | Dashboard de monitoramento do Celery |
| `mailpit` | `axllent/mailpit` | 1025 (SMTP) / 8025 (UI) | Captura de e-mails em desenvolvimento |
| `minio` | `minio/minio` | 9000 / 9001 | S3-compatible para PDFs e uploads |
| `lab-app` | `./frontend/lab_app` (build local) | 3000 | Flutter Web — app do laboratório |
| `client-portal` | `./frontend/client_portal` (build local) | 3001 | Flutter Web — portal do cliente |
| `admin-app` | `./frontend/admin_app` (build local) | 3002 | Flutter Web — painel superadmin |

### Entregáveis F0
- `docker-compose.yml` com todos os serviços
- `docker-compose.override.yml` com volumes de hot-reload para desenvolvimento
- `.env.example` com todas as variáveis necessárias
- `Makefile` com atalhos: `make up`, `make down`, `make migrate`, `make seed`, `make logs`
- `backend/Dockerfile` com build multi-stage (dev + prod)
- `frontend/Dockerfile` base para os 3 apps Flutter Web
- Scripts de healthcheck para postgres e redis
- README de setup do ambiente local

### Estrutura de diretórios inicial

```
normatiq/
├── docker-compose.yml
├── docker-compose.override.yml
├── .env.example
├── Makefile
│
├── backend/
│   ├── Dockerfile
│   ├── pyproject.toml
│   └── app/
│       ├── main.py
│       ├── core/
│       │   ├── config.py          # settings via pydantic-settings
│       │   ├── database.py        # engine + session async
│       │   └── celery_app.py      # instância do Celery
│       └── domains/               # domínios por módulo (M01..M11)
│
└── frontend/
    ├── packages/
    │   ├── normatiq_ui/           # design system compartilhado
    │   ├── normatiq_api/          # client HTTP + models
    │   └── normatiq_domain/       # enums, constantes, lógica pura
    ├── lab_app/
    ├── client_portal/
    └── admin_app/
```

---

## F1 · Fundação & Multi-Tenancy

**Módulo:** M01  
**Histórias:** H01, H02, H03, H04

### Branches

| Branch | Escopo | Histórias |
|--------|--------|-----------|
| `feature/f1-tenant-provisioning` | Criação e ativação de laboratórios, slug único, status trial | H01 |
| `feature/f1-auth-jwt` | Login, JWT com tenant_id/role, refresh token, bloqueio de tenant inativo | H02 |
| `feature/f1-user-management` | Convite por e-mail, edição, soft delete de usuários | H03 |
| `feature/f1-rbac` | Middleware de controle de acesso por role (admin/technician/attendant) | H04 |

### Backend — domínio `tenants` + `auth`

```
app/domains/
├── tenants/
│   ├── model.py          # Tenant, TenantStatus, Plan
│   ├── schema.py         # TenantCreate, TenantOut
│   ├── repository.py
│   ├── service.py        # provisionamento, controle de trial
│   └── router.py         # POST /tenants, PATCH /tenants/:id
│
└── auth/
    ├── model.py          # User, Role
    ├── schema.py         # LoginRequest, TokenResponse, UserInvite
    ├── repository.py
    ├── service.py        # JWT, hash de senha, convite por e-mail
    ├── router.py         # POST /auth/login, /auth/refresh, /auth/invite
    └── dependencies.py   # get_current_user, require_role()
```

### Flutter — Lab App (telas)
- S01 · Tela de login (`/login`)
- S02 · Primeiro acesso / redefinição de senha (`/first-access`)
- S40 · Gerenciar usuários do laboratório (`/settings/users`)

### Decisões técnicas relevantes
- Multi-tenancy por `tenant_id` em todas as tabelas + Row Level Security (RLS) no PostgreSQL
- JWT payload: `{ tenant_id, user_id, role, exp }`
- Refresh token com validade 7 dias armazenado em tabela `refresh_tokens`
- Convite por e-mail via Celery task (não bloqueia a request) + Mailpit em dev

---

## F1.5 · Outbox Genérico — Dispatcher Extensível

**Branch:** `feature/f1-outbox-dispatcher`

### Objetivo

Transformar o outbox de um despachante de e-mails hard-coded em uma **infraestrutura de entrega garantida para qualquer tarefa assíncrona**. A partir desta fase, adicionar um novo tipo de processamento assíncrono (emissão de certificado, análise GUM, geração de PDF, webhook externo) é apenas registrar um handler — sem tocar no worker ou no modelo do outbox.

### Motivação

O worker atual (`celery.py`) contém um `if/elif` que cresce a cada novo tipo de evento e mistura a lógica de entrega com a lógica de negócio. A fase F3 (Certificados) e F5 (Alertas) precisarão despachar Celery tasks pesadas com garantia de at-least-once delivery — o outbox é o lugar certo para isso, mas precisa ser genérico primeiro.

### Estrutura após a refatoração

```
app/domains/outbox/
├── model.py           # OutboxEvent, OutboxStatus, OutboxEventType (enum cresce aqui)
├── repository.py      # sem mudança
├── dispatcher.py      # NOVO — handler registry + dispatch()
└── handlers/
    ├── __init__.py    # importa todos os módulos para forçar registro
    ├── auth.py        # USER_INVITE, PASSWORD_RESET → e-mail
    ├── certificates.py  # CERTIFICATE_EMIT → generate_certificate.apply_async()
    └── alerts.py      # STANDARD_EXPIRY_ALERT, INSTRUMENT_EXPIRY_ALERT → e-mail/task
```

### Contrato do handler

```python
# app/domains/outbox/dispatcher.py
from collections.abc import Awaitable, Callable
from typing import TypeAlias
from app.domains.outbox.model import OutboxEvent, OutboxEventType

Handler: TypeAlias = Callable[[OutboxEvent], Awaitable[None]]

_registry: dict[OutboxEventType, Handler] = {}

def register(event_type: OutboxEventType) -> Callable[[Handler], Handler]:
    def decorator(fn: Handler) -> Handler:
        _registry[event_type] = fn
        return fn
    return decorator

async def dispatch(event: OutboxEvent) -> None:
    handler = _registry.get(event.event_type)
    if handler is None:
        raise ValueError(f"Nenhum handler registrado para {event.event_type}")
    await handler(event)
```

### Handlers de auth (migração do código atual)

```python
# app/domains/outbox/handlers/auth.py
import asyncio
from app.core.email import email_service
from app.domains.outbox.dispatcher import register
from app.domains.outbox.model import OutboxEventType

@register(OutboxEventType.USER_INVITE)
async def handle_user_invite(event) -> None:
    await asyncio.to_thread(
        email_service.send_user_invite,
        email=event.payload["email"],
        nome=event.payload["nome"],
        token=event.payload["token"],
    )

@register(OutboxEventType.PASSWORD_RESET)
async def handle_password_reset(event) -> None:
    await asyncio.to_thread(
        email_service.send_password_reset,
        email=event.payload["email"],
        token=event.payload["token"],
    )
```

### Handler de Celery task (padrão para F3+)

```python
# app/domains/outbox/handlers/certificates.py
from app.domains.outbox.dispatcher import register
from app.domains.outbox.model import OutboxEventType

@register(OutboxEventType.CERTIFICATE_EMIT)
async def handle_certificate_emit(event) -> None:
    from app.domains.certificates.tasks import generate_certificate_pdf
    # idempotency_key vira task_id — Celery ignora reenvios do mesmo ID
    generate_certificate_pdf.apply_async(
        kwargs=event.payload,
        task_id=str(event.idempotency_key),
    )
```

### Worker genérico (substitui o if/elif atual)

```python
# app/core/celery.py — _run_process_outbox()
async def _run_process_outbox():
    import app.domains.outbox.handlers  # garante que os handlers estejam registrados

    from app.domains.outbox.dispatcher import dispatch

    events = await repo.get_pending(limit=10)
    for event in events:
        try:
            await dispatch(event)
            await repo.mark_processed(event.id)
            await session.commit()
        except Exception as exc:
            await session.rollback()
            await repo.mark_failed(event.id, str(exc))
            await session.commit()
```

### Como adicionar um novo tipo de evento (F3 em diante)

1. Adicionar o valor em `OutboxEventType` no `model.py`
2. Criar (ou adicionar em) um arquivo em `handlers/`
3. Decorar a função com `@register(OutboxEventType.NOVO_TIPO)`
4. Importar o módulo no `handlers/__init__.py`

O worker **não precisa de nenhuma alteração**.

### Tipos de evento planejados

| Tipo | Handler | Usado em |
|------|---------|----------|
| `USER_INVITE` | e-mail | F1 |
| `PASSWORD_RESET` | e-mail | F1 |
| `CERTIFICATE_EMIT` | Celery task `generate_certificate_pdf` | F3 |
| `CERTIFICATE_REVOKE` | Celery task `revoke_certificate_pdf` + e-mail | F3 |
| `STANDARD_EXPIRY_ALERT` | e-mail ao responsável do laboratório | F5 |
| `INSTRUMENT_EXPIRY_ALERT` | e-mail ao cliente | F5 |
| `QUOTATION_SENT` | e-mail ao cliente com PDF | F4 |

### Garantias

- **At-least-once delivery:** o evento só é marcado `PROCESSED` após o handler retornar sem exceção.
- **Idempotência em Celery tasks:** `task_id=str(event.idempotency_key)` garante que reenvios do mesmo evento não criem execuções duplicadas.
- **Skip_locked:** o `SELECT ... FOR UPDATE SKIP LOCKED` no repositório garante que múltiplos workers não processem o mesmo evento simultaneamente.
- **Max attempts:** após `max_attempts` falhas consecutivas o evento vai para `FAILED` e para de ser reprocessado automaticamente.

### Entregáveis F1.5

- `app/domains/outbox/dispatcher.py` — registry + `dispatch()`
- `app/domains/outbox/handlers/__init__.py` — ponto de importação centralizado
- `app/domains/outbox/handlers/auth.py` — migração do código atual
- `app/core/celery.py` — worker genérico (remove o `if/elif`)
- Testes unitários do dispatcher (mock dos handlers)
- Teste de integração: evento desconhecido levanta `ValueError`

---

## F2 · Core Metrológico

**Módulos:** M02, M03, M04  
**Histórias:** H05–H14

### Branches

| Branch | Escopo | Histórias |
|--------|--------|-----------|
| `feature/f2-standards` | CRUD de padrões de referência, histórico de calibrações externas, status semafórico | H05, H06, H07 |
| `feature/f2-clients-instruments` | CRUD de clientes, instrumentos, histórico de calibrações por instrumento | H08, H09, H10 |
| `feature/f2-calibration-core` | Abertura de calibração, pontos de calibração com motor GUM, conclusão | H11, H12, H13 |
| `feature/f2-calibration-review` | Visualização completa da calibração com tabela de budget de incerteza | H14 |

### Backend — domínios `standards`, `clients`, `calibrations`

```
app/domains/
├── standards/
│   ├── model.py          # Standard, StandardCalibrationRecord
│   ├── schema.py
│   ├── repository.py
│   ├── service.py        # status calculado (em_dia/vencendo/vencido), days_until_cal_due
│   └── router.py
│
├── clients/
│   ├── model.py          # Client, Instrument
│   ├── schema.py
│   ├── repository.py
│   ├── service.py
│   └── router.py
│
└── calibrations/
    ├── model.py          # Calibration, CalibrationPoint, Measurement
    ├── schema.py
    ├── repository.py
    ├── service.py        # motor GUM: u_A, u_B1, u_B2, u_c, U, erro, correção
    └── router.py
```

### Motor GUM (H12) — implementado no `calibration_service.py`

```python
# Cálculos persistidos no banco ao salvar o ponto
u_A  = s(x) / sqrt(n)                     # incerteza tipo A
u_B1 = U_cert / k_cert                    # tipo B — padrão (normal)
u_B2 = (resolucao / 2) / sqrt(3)          # tipo B — resolução (retangular)
u_c  = sqrt(u_A**2 + u_B1**2 + u_B2**2)  # combinada
U    = k * u_c                             # expandida (k=2 padrão)
erro      = media_indicacao - valor_convencional
correcao  = -erro
```

### Flutter — Lab App (telas)
- S19 · Lista de padrões (`/standards`)
- S20 · Detalhe do padrão com abas (`/standards/:id`)
- S21 · Criar/editar padrão (`/standards/new`)
- S26 · Lista de clientes (`/clients`)
- S27 · Detalhe do cliente com abas (`/clients/:id`)
- S28 · Criar/editar cliente (`/clients/new`)
- S29 · Lista de instrumentos (`/instruments`)
- S30 · Detalhe do instrumento com histórico (`/instruments/:id`)
- S31 · Criar/editar instrumento (`/instruments/new`)
- S05 · Lista de calibrações (`/calibrations`)
- S06 · Detalhe da calibração com abas (`/calibrations/:id`)
- S07 · Criar/editar calibração (`/calibrations/new`)
- S08 · Adicionar ponto de calibração (`/calibrations/:id/points/new`)
- S09 · Detalhe do ponto com budget de incerteza (`/calibrations/:id/points/:point_id`)

---

## F3 · Certificados

**Módulo:** M05  
**Histórias:** H15, H16

### Branches

| Branch | Escopo | Histórias |
|--------|--------|-----------|
| `feature/f3-certificate-emission` | Geração de PDF ISO 17025, numeração automática, armazenamento no MinIO/S3 | H15 |
| `feature/f3-certificate-revocation` | Revogação com marca d'água, notificação por e-mail via Celery | H16 |

### Backend — domínio `certificates`

```
app/domains/
└── certificates/
    ├── model.py          # Certificate, CertificateStatus
    ├── schema.py
    ├── repository.py
    ├── service.py        # geração PDF + upload S3, sequência por tenant
    ├── router.py
    └── pdf/
        ├── generator.py  # ReportLab — layout ISO 17025
        └── templates/    # estilos e assets do certificado
```

### PDF ISO 17025 — elementos obrigatórios (H15)
- Identificação do laboratório (nome, CNPJ, endereço, logo)
- Número do certificado e data de emissão (`LAB-YYYY-NNNN`)
- Identificação do cliente e instrumento (tag, fabricante, modelo, série)
- Método de calibração e condições ambientais
- Identificação do padrão rastreável
- Tabela de resultados: valor nominal | indicação média | erro | correção | U | k | nível de confiança
- Data da próxima calibração recomendada
- Nome e assinatura digital do responsável técnico

### Flutter — Lab App (telas)
- Aba "Certificado" no S06 · Detalhe da calibração (viewer PDF inline + botão "Emitir")

---

## F4 · Operação Comercial

**Módulos:** M06, M07, M27  
**Histórias:** H17–H23, H78–H87

### Branches

| Branch | Escopo | Histórias |
|--------|--------|-----------|
| `feature/f4-service-catalog` | Catálogo de serviços com preços padrão e flag de acreditação | H78 |
| `feature/f4-quotations` | Criação, versionamento e envio de orçamentos flexíveis | H79, H80, H82, H83, H84 |
| `feature/f4-quotation-review` | Análise crítica automática 7.1 e aceite do cliente por link | H81, H85 |
| `feature/f4-orders` | Abertura de pedidos, adição de itens, rastreamento orçado × produzido | H17, H18, H86 |
| `feature/f4-order-approval` | Aprovação, criação automática de calibrações, acompanhamento | H19, H20, H87 |
| `feature/f4-inventory` | Consulta de disponibilidade, reserva, baixa e alertas de estoque mínimo | H21, H22, H23 |

### Backend — domínios `quotations`, `orders`, `inventory`

```
app/domains/
├── quotations/
│   ├── model.py          # Quotation, QuotationItem, QuotationEvent, ServiceCatalog
│   ├── service.py        # análise crítica 7.1, versionamento, geração PDF, envio e-mail
│   └── router.py
│
├── orders/
│   ├── model.py          # Order, OrderItem
│   ├── service.py        # aprovação → cria calibrações, rastreia produced_quantity
│   └── router.py
│
└── inventory/
    ├── model.py          # Product, StockMovement
    ├── service.py        # reserva, baixa, estorno, alerta de estoque mínimo
    └── router.py
```

### Flutter — Lab App (telas)
- S10–S15 · Orçamentos (lista, criar, itens, detalhe, PDF)
- S16–S18 · Pedidos (lista, detalhe, item do pedido)
- S24–S25 · Catálogo de serviços

---

## F5 · Alertas & Manutenção Preventiva

**Módulos:** M08, M09  
**Histórias:** H24–H29

### Branches

| Branch | Escopo | Histórias |
|--------|--------|-----------|
| `feature/f5-expiry-calendar` | Calendário de vencimentos (padrões + instrumentos), filtros, exportação CSV | H24 |
| `feature/f5-standard-alerts` | Régua de alertas automáticos de vencimento de padrão via Celery Beat | H25 |
| `feature/f5-instrument-alerts` | Notificação automática ao cliente sobre vencimento de instrumento | H26 |
| `feature/f5-preventive-maintenance` | Agendamento e registro de execução de manutenções preventivas | H27, H28, H29 |

### Celery Beat — tarefas agendadas

```python
# app/core/celery_app.py — beat_schedule
CELERYBEAT_SCHEDULE = {
    "check-standard-expiry": {
        "task": "app.tasks.alerts.check_standard_expiry",
        "schedule": crontab(hour=8, minute=0),   # diário às 08:00
    },
    "check-instrument-expiry": {
        "task": "app.tasks.alerts.check_instrument_expiry",
        "schedule": crontab(hour=8, minute=30),
    },
    "check-maintenance-due": {
        "task": "app.tasks.alerts.check_maintenance_due",
        "schedule": crontab(hour=9, minute=0),
    },
}
```

### Régua de alertas (H25 — padrões)
- `alert_days_before` antes do vencimento (configurável por padrão, padrão 30 dias)
- 7 dias antes
- No dia do vencimento
- 1, 7, 15 e 30 dias **após** o vencimento (até renovação)
- Alertas cessam automaticamente quando nova calibração é registrada

### Backend — domínios `alerts`, `maintenance`

```
app/domains/
├── alerts/
│   ├── model.py          # AlertLog (evita reenvios duplicados)
│   ├── service.py        # lógica de régua de disparo
│   └── tasks.py          # Celery tasks consumidas pelo Beat
│
└── maintenance/
    ├── model.py          # MaintenanceSchedule, MaintenanceExecution
    ├── service.py        # agendamento, registro, atualização de maintenance_due
    └── router.py
```

### Flutter — Lab App (telas)
- S03 · Dashboard com card de alertas críticos
- S04 · Central de notificações
- Aba "Manutenções" no S20 · Detalhe do padrão

---

## F6 · Portal do Cliente

**Módulo:** M10  
**Histórias:** H30–H33

### Branches

| Branch | Escopo | Histórias |
|--------|--------|-----------|
| `feature/f6-client-auth` | Login do cliente, JWT com role:client, isolamento total por client_id | H30 |
| `feature/f6-client-instruments` | Listagem e detalhe de instrumentos com histórico de calibrações | H31, H32 |
| `feature/f6-client-certificates` | Visualização inline e download do PDF, log de acesso, indicação de revogados | H33 |

### Backend — extensão do domínio `auth` + endpoints protegidos por `role: client`

```
app/domains/
└── client_portal/
    ├── router.py         # /portal/* — rotas autenticadas com role:client
    └── service.py        # filtragem estrita por client_id (404 em vez de 403)
```

### Flutter — Client Portal App (telas)
- S41 · Login do cliente
- S42 · Meus instrumentos
- S43 · Detalhe do instrumento (linha do tempo)
- S44 · Visualizar/baixar certificado
- S45 · Aprovar/recusar orçamento por link (token sem login completo)

---

## F7 · Negócio SaaS — Admin & Planos

**Módulo:** M11  
**Histórias:** H34–H37

### Branches

| Branch | Escopo | Histórias |
|--------|--------|-----------|
| `feature/f7-superadmin-panel` | Painel de gestão de todos os laboratórios com ações de ciclo de vida | H34 |
| `feature/f7-subscription-plans` | Definição de planos com limites configuráveis, enforcement na API | H35, H36 |
| `feature/f7-billing-gateway` | Integração com Stripe/Asaas, webhooks de pagamento, histórico de faturas | H37 |

### Planos sugeridos (H35)

| Plano | Usuários | Padrões | Cal./mês | Portal | Preço |
|-------|----------|---------|----------|--------|-------|
| Starter | 3 | 5 | 30 | ❌ | R$ 197/mês |
| Pro | Ilimitado | 20 | 150 | ✅ | R$ 497/mês |
| Acreditação | Ilimitado | Ilimitado | Ilimitado | ✅ | R$ 997/mês |
| Enterprise | Ilimitado | Ilimitado | Ilimitado | ✅ | Sob consulta |

### Backend — domínios `plans`, `billing`

```
app/domains/
├── plans/
│   ├── model.py          # Plan, PlanLimits
│   ├── service.py        # check_limit() — retorna 402 quando excedido
│   └── router.py
│
└── billing/
    ├── model.py          # Invoice, PaymentEvent
    ├── service.py        # integração Stripe/Asaas, período de graça
    ├── router.py
    └── webhooks.py       # payment.succeeded, payment.failed, subscription.cancelled
```

### Flutter — Admin App (telas)
- S46 · Lista de laboratórios com filtros e ações rápidas
- S47 · Detalhe do laboratório: uso vs. limites, faturas, timeline
- S48 · Métricas da plataforma: MRR, churn, crescimento

---

## F8 · Motor de Cálculo Excel

**Módulo:** M28  
**Histórias:** H88–H93

### Branches

| Branch | Escopo | Histórias |
|--------|--------|-----------|
| `feature/f8-excel-base-workbook` | `BaseCalibrationWorkbook` com fórmulas GUM, aba de metadados com contrato de células | H88 |
| `feature/f8-excel-instrument-types` | Subclasses por tipo: `ThermometerWorkbook`, `PressureGaugeWorkbook`, `BalanceWorkbook` etc. | H89 |
| `feature/f8-excel-download` | Geração e download do `.xlsx` a partir de uma calibração | H90 |
| `feature/f8-excel-upload` | Upload da planilha modificada, leitura por contrato, validação de divergência | H91, H92 |
| `feature/f8-excel-template` | Endpoint de template em branco por tipo de instrumento | H93 |

### Estrutura Python

```
app/domains/calibrations/
└── workbooks/
    ├── __init__.py
    ├── base.py                  # BaseCalibrationWorkbook
    ├── thermometer.py           # ThermometerWorkbook
    ├── pressure_gauge.py        # PressureGaugeWorkbook
    ├── balance.py               # BalanceWorkbook
    ├── caliper.py               # CaliperWorkbook
    ├── electrical.py            # ElectricalWorkbook
    ├── volumetric.py            # VolumetricWorkbook
    ├── hygrometer.py            # HygrometerWorkbook
    └── registry.py              # WORKBOOK_REGISTRY: dict[str, type[Base]]
```

### Flutter — Lab App (telas)
- Aba "Planilha" no S06 · Detalhe da calibração (gerar / baixar / upload)

---

## Fluxo de branches

```
main
 └── develop
      ├── feature/f0-infra-docker              ← F0 — primeiro a ser mergeado
      │
      ├── feature/f1-tenant-provisioning
      ├── feature/f1-auth-jwt
      ├── feature/f1-user-management
      ├── feature/f1-rbac
      │
      ├── feature/f2-standards
      ├── feature/f2-clients-instruments
      ├── feature/f2-calibration-core
      ├── feature/f2-calibration-review
      │
      ├── feature/f3-certificate-emission
      ├── feature/f3-certificate-revocation
      │
      ├── feature/f4-service-catalog
      ├── feature/f4-quotations
      ├── feature/f4-quotation-review
      ├── feature/f4-orders
      ├── feature/f4-order-approval
      ├── feature/f4-inventory
      │
      ├── feature/f5-expiry-calendar
      ├── feature/f5-standard-alerts
      ├── feature/f5-instrument-alerts
      ├── feature/f5-preventive-maintenance
      │
      ├── feature/f6-client-auth
      ├── feature/f6-client-instruments
      ├── feature/f6-client-certificates
      │
      ├── feature/f7-superadmin-panel
      ├── feature/f7-subscription-plans
      ├── feature/f7-billing-gateway
      │
      ├── feature/f8-excel-base-workbook
      ├── feature/f8-excel-instrument-types
      ├── feature/f8-excel-download
      ├── feature/f8-excel-upload
      └── feature/f8-excel-template
```

---

## Mapa de dependências entre branches

```
f0-infra-docker
  └── TUDO depende do F0

f1-tenant-provisioning
  └── f1-auth-jwt depende de f1-tenant-provisioning
      └── f1-user-management depende de f1-auth-jwt
          └── f1-rbac depende de f1-auth-jwt

f1-outbox-dispatcher
  └── depende de f1-user-management (migra handlers existentes)
  └── f3-certificate-emission depende de f1-outbox-dispatcher
  └── f5-standard-alerts depende de f1-outbox-dispatcher

f2-standards
  └── f2-calibration-core depende de f2-standards + f2-clients-instruments

f3-certificate-emission
  └── depende de f2-calibration-core

f4-orders
  └── depende de f2-clients-instruments + f3-certificate-emission
  └── f4-order-approval depende de f4-orders + f4-quotations

f5-standard-alerts
  └── depende de f2-standards
f5-instrument-alerts
  └── depende de f2-clients-instruments + f3-certificate-emission

f6-client-auth
  └── depende de f1-auth-jwt
f6-client-certificates
  └── depende de f6-client-instruments + f3-certificate-emission

f7-subscription-plans
  └── depende de f1-tenant-provisioning

f8-excel-base-workbook
  └── depende de f2-calibration-core
```

---

## Resumo de contagem

| Fase | Branches | Histórias cobertas | Telas Flutter |
|------|----------|--------------------|---------------|
| F0 | 1 | — | — |
| F1 | 4 | H01–H04 | S01, S02, S40 |
| F1.5 | 1 | — (infra transversal) | — |
| F2 | 4 | H05–H14 | S05–S09, S19–S21, S26–S31 |
| F3 | 2 | H15–H16 | Aba Certificado no S06 |
| F4 | 6 | H17–H23, H78–H87 | S10–S18, S24–S25 |
| F5 | 4 | H24–H29 | S03, S04, Aba Manutenções |
| F6 | 3 | H30–H33 | S41–S45 |
| F7 | 3 | H34–H37 | S46–S48 |
| F8 | 5 | H88–H93 | Aba Planilha no S06 |
| **Total** | **33** | **~60 histórias** | **~48 telas** |

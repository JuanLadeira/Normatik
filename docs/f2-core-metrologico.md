# F2 · Core Metrológico — Documentação de Fase
> SaaS Normatiq · FastAPI + SQLAlchemy async + Flutter  
> Branch principal: `feature/f2-frontend-implementation`  
> Última atualização: 2026-05-02

---

## 1. Escopo original vs. realidade

O ROADMAP original previa 4 branches de F2 focadas em CRUD + motor GUM:

| Branch original (ROADMAP) | Escopo |
|---|---|
| `feature/f2-standards` | CRUD de padrões, histórico externo, status semafórico |
| `feature/f2-clients-instruments` | CRUD de clientes e instrumentos do cliente |
| `feature/f2-calibration-core` | Abertura de calibração, pontos, motor GUM |
| `feature/f2-calibration-review` | Visualização completa com budget de incerteza |

Durante o desenvolvimento dos domain models, o escopo foi **ampliado intencionalmente** com três adições relevantes que o plano original não previa — detalhadas na seção 3.

---

## 2. O que foi construído — Backend completo

### Branch `feature/f2-frontend-implementation`

**Commits relevantes:**
- `860fb48` — models iniciais (grandezas, equipamentos, OS, calibrações)
- `ec62c77` — redesign com catálogo de equipamentos (TipoEquipamento, Fabricante, ModeloEquipamento) e ClienteLaboratorio
- `11f0ee7` — controle de calibrações e histórico de padrões do laboratório
- `0a30401` — DBML em `docs/schema.md`
- `253a6db` — implementação completa: repositories, schemas, services, routers e testes

**Migration:** `fa485ee281ae` (herda de `bef60d5ac6a0` — outbox)

### Domínios e tabelas criados

#### Grandezas (catálogo global, sem tenant)
| Tabela | Descrição |
|---|---|
| `grandezas` | Grandeza física: comprimento, pressão, temperatura... |
| `tipos_incerteza_b_template` | Templates reutilizáveis de fontes de incerteza Tipo B por grandeza |

#### Catálogo de Equipamentos (global, sem tenant)
| Tabela | Descrição |
|---|---|
| `tipos_equipamento` | Paquímetro, manômetro, termopar — vinculado à grandeza e ao `codigo` do workbook registry |
| `fabricantes` | Mitutoyo, Starrett, Fluke — compartilhado entre todos os labs |
| `modelos_equipamento` | Modelos específicos (Mitutoyo 530-118) com defaults de capacidade/resolução/unidade |

#### Equipamentos (JTI — Joined Table Inheritance)
| Tabela | Descrição |
|---|---|
| `equipamentos` | Base: tenant_id, tipo_equipamento_id, modelo_equipamento_id, numero_serie, marca, modelo, unidade |
| `instrumentos` | Subtipo: instrumento do cliente (+ cliente_id) |
| `padroes_calibracao` | Subtipo: padrão do laboratório (+ controle de calibração — ver seção 3) |

#### Histórico de Calibrações de Padrões
| Tabela | Descrição |
|---|---|
| `historico_calibracoes_padrao` | Cada calibração externa recebida por um padrão do lab |

#### Clientes e OS
| Tabela | Descrição |
|---|---|
| `clientes_laboratorio` | Clientes do laboratório (multi-tenant) |
| `ordens_servico` | OS vinculada a tenant + cliente, com status e datas |
| `itens_os` | Item de uma OS — quantidade_prevista + 1:N com serviços |

#### Calibrações (motor GUM)
| Tabela | Descrição |
|---|---|
| `servicos_calibracao` | Um serviço por instrumento físico (1:N com ItemOS) |
| `incertezas_b_fontes` | Fontes de incerteza Tipo B declaradas por serviço |
| `pontos_calibracao` | Ponto com leituras brutas (instrumento + padrão) e resultados GUM calculados |

**Total: 15 tabelas novas + migration única.**

---

## 3. Adições além do plano original (e por quê)

### 3.1 Catálogo de Equipamentos: TipoEquipamento + Fabricante + ModeloEquipamento

**Por que foi adicionado:**  
O plano original não distinguia o "tipo de equipamento" do equipamento em si. Para suportar:
- Workbooks específicos por tipo (paquímetro tem cálculos diferentes de manômetro)
- Formulários distintos no Flutter dependendo do tipo
- Catálogo pré-cadastrado de fabricantes/modelos para agilizar o cadastro

O `TipoEquipamento.codigo` é a chave que o registry de workbooks (F8) usa para despachar a classe correta.

**Fluxo de cadastro de equipamento:**
```
Seleciona TipoEquipamento → grandeza já vem junto
  └── Filtra Fabricante (join via modelos_equipamento)
        └── Seleciona ModeloEquipamento → pré-preenche marca/capacidade/resolução/unidade
              └── Cria Equipamento (Instrumento ou Padrão) — campos ainda editáveis
```

### 3.2 ClienteLaboratorio como entidade própria

**Por que foi adicionado:**  
O plano original tinha `cliente_nome` como campo string na OS. Isso impediria:
- Histórico de todos os instrumentos de um cliente
- Portal do cliente (F6) — acesso por cliente_id
- Busca e filtros por cliente

`ClienteLaboratorio` tem `UniqueConstraint(tenant_id, cnpj)` para integridade multi-tenant.

### 3.3 Controle de Calibrações dos Padrões + HistoricoCalibracaoPadrao

**Por que foi adicionado:**  
Padrões de laboratório têm um ciclo de vida próprio: vão periodicamente a labs acreditados externos para serem recalibrados. O plano original apenas guardava o certificado atual (4 campos nullable). Isso impediria:
- Rastreabilidade histórica dos padrões
- Critério de aceitação específico por padrão
- Relatório semanal automático de vencimentos (F5)
- Saber se o resultado da última calibração foi aceito

**O que foi adicionado em `padroes_calibracao`:**

| Campo | Tipo | Descrição |
|---|---|---|
| `u_expandida_atual` | float | U do último cert aceito — auto-fill de IncertezaBFonte |
| `frequencia_calibracao_dias` | int | Intervalo de recalibração (ex: 365) |
| `alerta_dias_antes` | int (default 30) | Limiar de "vencendo em breve" |
| `criterio_aceitacao` | text | Descrição narrativa do critério ISO 17025 |
| `u_maximo_aceito` | float | U máxima aceita; service valida automaticamente |

**`@property status_calibracao`** (computado, não armazenado):
```
sem_calibracao → validade_calibracao é NULL
vencido        → hoje > validade_calibracao
vencendo_em_breve → hoje >= validade_calibracao - alerta_dias_antes
em_dia         → caso contrário
```

**`historico_calibracoes_padrao`** — um registro por evento de recalibração externa:
- `data_calibracao`, `data_vencimento`, `numero_certificado`, `laboratorio_calibrador`
- `u_expandida_certificado` — U extraída do certificado
- `aceito` — atende ao critério? Service atualiza as colunas de conveniência do padrão quando `aceito=True`
- `arquivo_pdf_url` — caminho S3 do PDF
- Index composto `(padrao_id, data_calibracao)` para query eficiente do histórico

### 3.4 Calibração dual (leituras de instrumento + padrão)

**Por que foi adicionado:**  
Para calibrações de manômetros e similares, o técnico faz leituras simultâneas do instrumento do cliente e do padrão. A referência é a média do padrão, não o valor nominal. `PontoDeCalibração` suporta ambos os cenários:

- `leituras_instrumento[]` — sempre presente
- `leituras_padrao[]` — vazio = calibração simples (referência = `valor_nominal`)
- `media_padrao`, `desvio_padrao_padrao`, `u_tipo_a_padrao` — preenchidos apenas quando há leituras do padrão

---

## 4. Regras de serviço críticas (implementadas em `service.py` de cada domínio)

### PadraoService.registrar_calibracao()
```
Em uma única transação:
1. Cria HistoricoCalibracaoPadrao
2. Se aceito=True:
   atualiza PadraoDeCalibração.numero_certificado
   atualiza PadraoDeCalibração.data_calibracao
   atualiza PadraoDeCalibração.validade_calibracao
   atualiza PadraoDeCalibração.laboratorio_calibrador
   atualiza PadraoDeCalibração.u_expandida_atual
```

### PontoDeCalibração.calcular_incertezas()
Já implementado no model. Chamado pelo service ao salvar/atualizar um ponto:
```
u_A = s_instrumento / √n
u_A_padrao = s_padrao / √n_padrao  (zero se sem leituras do padrão)
u_combinada = √(u_A² + u_A_padrao² + Σ u_Bi²)
u_expandida = fator_k × u_combinada
referencia = media_padrao se leituras_padrao não vazio, senão valor_nominal
erro = media_instrumento - referencia
correcao = -erro
```

---

## 5. Endpoints implementados

### `/api/grandezas`

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/` | Lista grandezas com tipos_incerteza_b_template |
| `GET` | `/{grandeza_id}` | Detalhe da grandeza |
| `POST` | `/` | Criar grandeza |
| `POST` | `/{grandeza_id}/tipos-incerteza-b` | Adicionar template de incerteza B |
| `DELETE` | `/{grandeza_id}` | Remover grandeza |

### `/api/equipamentos`

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/tipos` | Lista tipos de equipamento (filtro por grandeza) |
| `GET` | `/fabricantes` | Lista fabricantes |
| `GET` | `/modelos` | Lista modelos (filtro por tipo/fabricante) |
| `GET` | `/instrumentos` | Lista instrumentos do tenant |
| `POST` | `/instrumentos` | Cadastrar instrumento |
| `GET` | `/instrumentos/{id}` | Detalhe do instrumento |
| `PATCH` | `/instrumentos/{id}` | Editar instrumento |
| `DELETE` | `/instrumentos/{id}` | Remover instrumento |
| `GET` | `/padroes` | Lista padrões do laboratório (com status_calibracao) |
| `POST` | `/padroes` | Cadastrar padrão |
| `GET` | `/padroes/{id}` | Detalhe do padrão |
| `PATCH` | `/padroes/{id}` | Editar padrão |
| `DELETE` | `/padroes/{id}` | Remover padrão |

### `/api/clientes`

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/` | Lista clientes do tenant |
| `POST` | `/` | Cadastrar cliente |
| `GET` | `/{cliente_id}` | Detalhe do cliente |
| `PATCH` | `/{cliente_id}` | Editar cliente |
| `DELETE` | `/{cliente_id}` | Remover cliente |

### `/api/os`

| Método | Endpoint | Descrição |
|---|---|---|
| `GET` | `/` | Lista OSs do tenant |
| `POST` | `/` | Abrir OS |
| `GET` | `/{id}` | Detalhe com itens e serviços |
| `PATCH` | `/{id}` | Editar OS |
| `DELETE` | `/{id}` | Remover OS |

### `/api/calibracoes`

| Método | Endpoint | Descrição |
|---|---|---|
| `POST` | `/` | Iniciar serviço de calibração |
| `GET` | `/` | Lista serviços do tenant |
| `GET` | `/{id}` | Detalhe com pontos e fontes de incerteza |
| `PATCH` | `/{id}` | Editar cabeçalho do serviço |
| `POST` | `/{id}/pontos` | Adicionar ponto (dispara calcular_incertezas()) |
| `PUT` | `/{id}/pontos/{ponto_id}` | Atualizar leituras (recalcula) |
| `DELETE` | `/{id}/pontos/{ponto_id}` | Remover ponto |
| `POST` | `/{id}/fontes-b` | Declarar fonte Tipo B |
| `DELETE` | `/{id}/fontes-b/{fonte_id}` | Remover fonte Tipo B |

## 6. O que falta para concluir F2

**Backend:** concluído.

**Flutter — telas a implementar** (branch `feature/f2-frontend-implementation`):

| Tela | Rota | Spec |
|---|---|---|
| S19 · Lista de padrões | `/standards` | planejamento-frontend.MD |
| S20 · Detalhe do padrão (abas) | `/standards/:id` | planejamento-frontend.MD |
| S21 · Criar/editar padrão | `/standards/new` | planejamento-frontend.MD |
| S26 · Lista de clientes | `/clients` | planejamento-frontend.MD |
| S27 · Detalhe do cliente (abas) | `/clients/:id` | planejamento-frontend.MD |
| S28 · Criar/editar cliente | `/clients/new` | planejamento-frontend.MD |
| S29 · Lista de instrumentos | `/instruments` | planejamento-frontend.MD |
| S30 · Detalhe do instrumento | `/instruments/:id` | planejamento-frontend.MD |
| S31 · Criar/editar instrumento | `/instruments/new` | planejamento-frontend.MD |
| S05 · Lista de calibrações | `/calibrations` | planejamento-frontend.MD |
| S06 · Detalhe da calibração (abas) | `/calibrations/:id` | planejamento-frontend.MD |
| S07 · Criar/editar calibração | `/calibrations/new` | planejamento-frontend.MD |
| S08 · Adicionar ponto | `/calibrations/:id/points/new` | planejamento-frontend.MD |
| S09 · Detalhe do ponto + budget | `/calibrations/:id/points/:point_id` | planejamento-frontend.MD |

---

## 7. Arquitetura de domínios

```
app/domains/
├── grandezas/
│   ├── model.py        ✅ Grandeza, TipoIncertezaBTemplate
│   ├── schema.py       ✅
│   ├── repository.py   ✅
│   ├── service.py      ✅
│   └── router.py       ✅ /api/grandezas
│
├── equipamentos/
│   ├── model.py        ✅ TipoEquipamento, Fabricante, ModeloEquipamento
│   │                      Equipamento (JTI base), Instrumento, PadraoDeCalibração
│   │                      HistoricoCalibracaoPadrao, StatusCalibracaoPadrao (@property)
│   ├── schema.py       ✅
│   ├── repository.py   ✅
│   ├── service.py      ✅
│   └── router.py       ✅ /api/equipamentos
│
├── clientes/
│   ├── model.py        ✅ ClienteLaboratorio
│   ├── schema.py       ✅
│   ├── repository.py   ✅
│   ├── service.py      ✅
│   └── router.py       ✅ /api/clientes
│
├── ordens_servico/
│   ├── model.py        ✅ OrdemDeServico, ItemOS
│   ├── schema.py       ✅
│   ├── repository.py   ✅
│   ├── service.py      ✅
│   └── router.py       ✅ /api/os
│
└── calibracoes/
    ├── model.py        ✅ ServicoDeCalibração, IncertezaBFonte
    │                      PontoDeCalibração (+ calcular_incertezas())
    ├── schema.py       ✅
    ├── repository.py   ✅
    ├── service.py      ✅
    └── router.py       ✅ /api/calibracoes
```

**Status de cada camada:**

| Camada | Status |
|---|---|
| `model.py` | ✅ Todos os domínios |
| `schema.py` (Pydantic) | ✅ Todos os domínios |
| `repository.py` | ✅ Todos os domínios |
| `service.py` | ✅ Todos os domínios |
| `router.py` | ✅ Todos os domínios |
| `workbooks/` | ⬜ A fazer em F8 |
| Flutter (telas) | ⬜ Em andamento — branch `feature/f2-frontend-implementation` |

---

## 8. Schema do banco

Ver `docs/schema.md` para o DBML completo (dbdiagram.io).

**Query do relatório semanal de vencimentos (Celery Beat — F5):**
```sql
SELECT e.tenant_id, e.numero_serie, e.marca, e.modelo,
       pc.validade_calibracao, pc.alerta_dias_antes,
       pc.numero_certificado, pc.laboratorio_calibrador
FROM padroes_calibracao pc
JOIN equipamentos e ON e.id = pc.id
WHERE e.ativo = TRUE
  AND (
    pc.validade_calibracao IS NULL
    OR CURRENT_DATE >= pc.validade_calibracao - pc.alerta_dias_antes
  )
ORDER BY e.tenant_id, pc.validade_calibracao NULLS FIRST;
```

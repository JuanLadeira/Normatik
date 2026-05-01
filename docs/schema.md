# Normatiq — Database Schema (DBML)
> Cole em https://dbdiagram.io para visualizar o diagrama.
> Atualizado em: 2026-05-01 · Fase atual: F2 domain models (branch feature/f2-domain-models)
> Migration head: fa485ee281ae

```dbml
// ═══════════════════════════════════════════════════════
// PLATAFORMA — F1
// ═══════════════════════════════════════════════════════

Table plans {
  id                      integer      [pk, increment]
  nome                    varchar(100) [unique, not null]
  descricao               varchar(500)
  preco_mensal            decimal(10,2)
  limite_usuarios         integer      [default: 2,  note: '-1 = ilimitado']
  limite_padroes          integer      [default: 5,  note: '-1 = ilimitado']
  limite_calibracoes_mes  integer      [default: 30, note: '-1 = ilimitado']
  portal_cliente          boolean
  geracao_certificado_pdf boolean
  ativo                   boolean
  created_at              timestamp
  updated_at              timestamp
}

Table tenants {
  id               integer      [pk, increment]
  nome             varchar(150) [not null]
  slug             varchar(100) [unique, not null]
  cnpj             varchar(18)
  email_gestor     varchar(254) [not null]
  status           varchar      [not null, note: 'trial | active | inactive | suspended']
  trial_expires_at timestamp
  plan_id          integer      [ref: > plans.id]
  created_at       timestamp
  updated_at       timestamp
}

Table subscriptions {
  id                      integer [pk, increment]
  tenant_id               integer [not null, ref: > tenants.id]
  plan_id                 integer [not null, ref: > plans.id]
  status                  varchar [not null, note: 'trial | active | past_due | cancelled']
  current_period_start    timestamp [not null]
  current_period_end      timestamp [not null]
  stripe_subscription_id  varchar
  stripe_customer_id      varchar
  created_at              timestamp
  updated_at              timestamp

  indexes {
    (tenant_id) [unique, name: 'uq_subscription_tenant']
  }
}

Table users {
  id                integer      [pk, increment]
  tenant_id         integer      [not null, ref: > tenants.id]
  email             varchar(254) [not null]
  password          varchar(255)
  nome              varchar(150) [not null]
  role              varchar      [not null, note: 'admin | technician | attendant']
  is_active         boolean
  invite_token      varchar(500)
  invite_expires_at timestamp
  created_at        timestamp
  updated_at        timestamp

  indexes {
    (tenant_id, email) [unique, name: 'uq_user_tenant_email']
  }
}

Table admins {
  id         integer      [pk, increment]
  email      varchar(254) [unique, not null]
  password   varchar(255)
  nome       varchar(150) [not null]
  is_active  boolean
  created_at timestamp
  updated_at timestamp
}

Table outbox_events {
  id              uuid    [pk, note: 'UUID v4']
  event_type      varchar [not null, note: 'user_invite | password_reset | certificate_emit | ...']
  payload         jsonb   [not null]
  status          varchar [not null, note: 'pending | processed | failed']
  attempts        integer [default: 0]
  max_attempts    integer [default: 5]
  idempotency_key uuid    [unique, not null]
  processed_at    timestamp
  created_at      timestamp
  error_message   text
}

// ═══════════════════════════════════════════════════════
// CATÁLOGO DE GRANDEZAS — F2 (global, sem tenant)
// ═══════════════════════════════════════════════════════

Table grandezas {
  id         integer      [pk, increment]
  nome       varchar(100) [unique, not null, note: 'ex: Comprimento, Pressão, Temperatura']
  simbolo    varchar(20)  [not null]
  unidade_si varchar(50)  [not null]
  created_at timestamp
  updated_at timestamp
}

Table tipos_incerteza_b_template {
  id              integer      [pk, increment]
  grandeza_id     integer      [not null, ref: > grandezas.id]
  descricao       varchar(200) [not null, note: 'ex: Resolução do instrumento, Certificado do padrão']
  simbolo         varchar(50)
  distribuicao    varchar      [not null, note: 'NORMAL | RETANGULAR | TRIANGULAR']
  graus_liberdade float
  observacao      text
  created_at      timestamp
  updated_at      timestamp
}

// ═══════════════════════════════════════════════════════
// CATÁLOGO DE EQUIPAMENTOS — F2 (global, sem tenant)
// ═══════════════════════════════════════════════════════

Table fabricantes {
  id         integer      [pk, increment]
  nome       varchar(200) [unique, not null, note: 'ex: Mitutoyo, Starrett, Fluke']
  ativo      boolean
  created_at timestamp
  updated_at timestamp
}

Table tipos_equipamento {
  id          integer      [pk, increment]
  grandeza_id integer      [not null, ref: > grandezas.id]
  codigo      varchar(50)  [unique, not null, note: 'chave do workbook registry: paquimetro | manometro | termopar | balanca | etc.']
  nome        varchar(100) [not null]
  ativo       boolean
  created_at  timestamp
  updated_at  timestamp
}

Table modelos_equipamento {
  id                  integer      [pk, increment]
  tipo_equipamento_id integer      [not null, ref: > tipos_equipamento.id]
  fabricante_id       integer      [not null, ref: > fabricantes.id]
  nome                varchar(200) [not null, note: 'ex: 530-118, P8000, 1551A']
  capacidade_padrao   float
  resolucao_padrao    float
  unidade_padrao      varchar(20)
  ativo               boolean
  created_at          timestamp
  updated_at          timestamp

  indexes {
    (tipo_equipamento_id, fabricante_id, nome) [unique, name: 'uq_modelo_tipo_fabricante_nome']
  }
}

// ═══════════════════════════════════════════════════════
// EQUIPAMENTOS — JTI (base + subclasses) — F2
// ═══════════════════════════════════════════════════════

Table equipamentos {
  id                    integer      [pk, increment]
  tipo                  varchar(20)  [not null, note: 'instrumento | padrao  (discriminador JTI)']
  tenant_id             integer      [not null, ref: > tenants.id]
  tipo_equipamento_id   integer      [not null, ref: > tipos_equipamento.id]
  modelo_equipamento_id integer      [ref: > modelos_equipamento.id, note: 'null = equipamento fora do catálogo']
  numero_serie          varchar(100) [not null]
  marca                 varchar(100) [not null, note: 'pré-preenchido de fabricante.nome, editável']
  modelo                varchar(100) [not null, note: 'pré-preenchido de modelos_equipamento.nome, editável']
  unidade               varchar(20)  [not null]
  capacidade            float
  resolucao             float
  ativo                 boolean
  created_at            timestamp
  updated_at            timestamp
}

// Instrumento do cliente — JTI subtable (sem id próprio, compartilha com equipamentos)
Table instrumentos {
  id         integer [pk, ref: > equipamentos.id]
  cliente_id integer [not null, ref: > clientes_laboratorio.id]
}

// Padrão do laboratório — JTI subtable
Table padroes_calibracao {
  id integer [pk, ref: > equipamentos.id]

  // ── Conveniência: espelho do último historico_calibracoes_padrao aceito ──
  // Escritas exclusivamente por PadraoService.registrar_calibracao() quando aceito=True
  numero_certificado     varchar(100) [note: 'conveniência']
  data_calibracao        date         [note: 'conveniência']
  validade_calibracao    date         [note: 'conveniência — indexed para query do Celery Beat']
  laboratorio_calibrador varchar(200) [note: 'conveniência']
  u_expandida_atual      float        [note: 'conveniência — auto-fill de incertezas_b_fontes.valor_u']

  // ── Controle de calibração ───────────────────────────────────────────────
  frequencia_calibracao_dias integer [note: 'intervalo de recalibração em dias (ex: 365); null = não definido']
  alerta_dias_antes          integer [not null, default: 30, note: 'dias antes do vencimento para status vencendo_em_breve']
  criterio_aceitacao         text    [note: 'descrição narrativa do critério ISO 17025']
  u_maximo_aceito            float   [note: 'U máxima aceita; service valida ao registrar novo histórico']

  // status_calibracao → @property Python, não armazenado
  // em_dia | vencendo_em_breve | vencido | sem_calibracao
}

// Histórico de calibrações externas recebidas por um padrão do laboratório
Table historico_calibracoes_padrao {
  id                      integer      [pk, increment]
  padrao_id               integer      [not null, ref: > padroes_calibracao.id]
  data_calibracao         date         [not null]
  data_vencimento         date         [not null]
  numero_certificado      varchar(100) [not null]
  laboratorio_calibrador  varchar(200)
  u_expandida_certificado float        [note: 'U expandida extraída do certificado']
  aceito                  boolean      [not null, note: 'atende ao critério de aceitação do padrão?']
  observacoes             text         [note: 'justificativa de aceite ou recusa']
  arquivo_pdf_url         varchar(500) [note: 'caminho S3 do PDF do certificado externo']
  created_at              timestamp
  updated_at              timestamp

  indexes {
    (padrao_id, data_calibracao) [name: 'ix_historico_padrao_data']
  }
}

// ═══════════════════════════════════════════════════════
// CLIENTES DO LABORATÓRIO — F2
// ═══════════════════════════════════════════════════════

Table clientes_laboratorio {
  id         integer      [pk, increment]
  tenant_id  integer      [not null, ref: > tenants.id]
  nome       varchar(200) [not null]
  cnpj       varchar(18)
  email      varchar(254)
  telefone   varchar(20)
  contato    varchar(150)
  ativo      boolean
  created_at timestamp
  updated_at timestamp

  indexes {
    (tenant_id, cnpj) [unique, name: 'uq_cliente_tenant_cnpj']
  }
}

// ═══════════════════════════════════════════════════════
// ORDENS DE SERVIÇO — F2
// ═══════════════════════════════════════════════════════

Table ordens_servico {
  id             integer     [pk, increment]
  tenant_id      integer     [not null, ref: > tenants.id]
  cliente_id     integer     [not null, ref: > clientes_laboratorio.id]
  numero         varchar(50) [not null]
  status         varchar     [not null, note: 'ABERTA | EM_ANDAMENTO | CONCLUIDA | CANCELADA | ENTREGUE']
  data_entrada   timestamp   [not null]
  data_prevista  timestamp
  data_conclusao timestamp
  observacoes    text
  created_at     timestamp
  updated_at     timestamp

  indexes {
    (tenant_id, numero) [unique, name: 'uq_os_tenant_numero']
  }
}

// Um item representa N serviços do mesmo tipo (ex: lote de 30 paquímetros)
// quantidade_realizada = count(servicos where status = CONCLUIDO) — calculado em Python
Table itens_os {
  id                  integer      [pk, increment]
  os_id               integer      [not null, ref: > ordens_servico.id]
  descricao           varchar(200) [not null]
  quantidade_prevista integer      [not null, default: 1]
  posicao             integer      [not null]
  status              varchar      [not null, note: 'AGUARDANDO | EM_CALIBRACAO | CONCLUIDO | CANCELADO']
  observacoes         text
  created_at          timestamp
  updated_at          timestamp
}

// ═══════════════════════════════════════════════════════
// CALIBRAÇÕES — F2
// ═══════════════════════════════════════════════════════

// 1 serviço por instrumento físico; 1:N com itens_os (lote de 30 paquímetros = 30 serviços)
Table servicos_calibracao {
  id                   integer     [pk, increment]
  item_os_id           integer     [not null, ref: > itens_os.id]
  instrumento_id       integer     [ref: > instrumentos.id, note: 'null = instrumento ainda não vinculado ao serviço']
  workbook_type        varchar(50) [not null, note: 'espelha tipos_equipamento.codigo → determina classe de cálculo e formulário']
  status               varchar     [not null, note: 'RASCUNHO | EM_ANDAMENTO | CONCLUIDO | CANCELADO']
  temperatura_ambiente float
  umidade_relativa     float
  observacoes          text
  created_at           timestamp
  updated_at           timestamp
}

// Fonte de incerteza Tipo B declarada para um serviço
// padrao_id nullable: preenchido quando a fonte é um padrão registrado (auto-fill de valor_u via padrao.u_expandida_atual)
Table incertezas_b_fontes {
  id              integer      [pk, increment]
  servico_id      integer      [not null, ref: > servicos_calibracao.id]
  padrao_id       integer      [ref: > padroes_calibracao.id, note: 'null = fonte sem padrão (ex: resolução do instrumento)']
  descricao       varchar(200) [not null]
  valor_u         float        [not null]
  distribuicao    varchar      [not null, note: 'NORMAL | RETANGULAR | TRIANGULAR']
  graus_liberdade float
  created_at      timestamp
  updated_at      timestamp
}

// Ponto de calibração com leituras brutas e resultados GUM calculados
// calcular_incertezas() é chamado pelo service ao salvar/atualizar o ponto
Table pontos_calibracao {
  id            integer     [pk, increment]
  servico_id    integer     [not null, ref: > servicos_calibracao.id]
  posicao       integer     [not null]
  valor_nominal float       [not null]
  unidade       varchar(20) [not null]

  // Leituras brutas — ARRAY(Float) PostgreSQL
  leituras_instrumento "float[]" [not null, note: 'n repetições do instrumento']
  leituras_padrao      "float[]" [not null, note: 'vazio = calibração simples (referência = valor_nominal); preenchido = dual, ex: manômetro']

  // Estatísticas do instrumento
  media_instrumento         float
  desvio_padrao_instrumento float

  // Estatísticas do padrão — preenchidas apenas quando leituras_padrao não vazio
  media_padrao         float [note: 'referência usada no cálculo de erro quando há leituras do padrão']
  desvio_padrao_padrao float

  // Resultado metrológico
  erro     float [note: 'media_instrumento − referencia']
  correcao float [note: '−erro']

  // Incertezas GUM
  u_tipo_a        float [note: 's_instrumento / √n']
  u_tipo_a_padrao float [note: 's_padrao / √n_padrao — zero quando leituras_padrao vazio']
  u_combinada     float [note: '√(u_A² + u_A_padrao² + Σ u_Bi²)']
  u_expandida     float [note: 'fator_k × u_combinada']
  fator_k         float [default: 2.0]

  created_at timestamp
  updated_at timestamp
}
```

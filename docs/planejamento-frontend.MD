# Normatiq — Frontend Flutter
> Planejamento de telas · Mobile-first · FastAPI + Flutter

---

## Decisões técnicas do frontend

| # | Decisão | Justificativa |
|---|---------|---------------|
| DT-F01 | **Flutter** como único framework frontend | iOS, Android e Web a partir de uma única codebase; performance nativa; ideal para apps de campo onde o técnico calibra com o celular na mão |
| DT-F02 | **Mobile-first** em todas as telas | Técnicos usam celular durante a execução; gestores usam tablet/desktop para relatórios — todas as telas começam pelo layout 360dp e expandem para telas maiores |
| DT-F03 | **Riverpod** para gerenciamento de estado | Mais ergonômico que BLoC para equipes menores; testável; sem boilerplate excessivo |
| DT-F04 | **go_router** para navegação | Suporte a deep links, rotas nomeadas e guards de autenticação |
| DT-F05 | **dio** para HTTP | Interceptors para JWT refresh automático e tenant header |
| DT-F06 | **Três apps Flutter separados** no mesmo repositório | `lab_app` (laboratório), `client_portal` (cliente), `admin_app` (superadmin) — compartilham packages de design system e domínio |
| DT-F07 | **flutter_pdfview** para certificados | Visualização inline de PDF sem sair do app |
| DT-F08 | **file_picker + dio** para upload de planilhas | Upload do Excel de cálculo de incerteza direto do celular ou desktop |

---

## Estrutura do repositório

```
normatiq/
├── backend/                  # FastAPI
│   └── app/
│
├── frontend/
│   ├── packages/
│   │   ├── normatiq_ui/      # Design system compartilhado (cores, tipografia, componentes)
│   │   ├── normatiq_api/     # Client HTTP gerado + models (shared entre os 3 apps)
│   │   └── normatiq_domain/  # Enums, constantes, lógica de negócio pura
│   │
│   ├── lab_app/              # App do laboratório (técnicos, gestores, atendentes)
│   ├── client_portal/        # Portal do cliente
│   └── admin_app/            # Painel superadmin
```

---

## App 1 — Lab App

### Navegação raiz

O app usa **bottom navigation** com 5 abas principais no celular. No tablet/web, colapsa para um **navigation rail** lateral.

```
Bottom Nav
├── 🏠 Início          (dashboard + alertas)
├── 📋 Operações       (calibrações, pedidos, orçamentos)
├── ⚗️  Laboratório    (padrões, procedimentos, estoque)
├── 👥 Clientes        (clientes, instrumentos)
└── ☰  Mais            (qualidade, pessoal, documentos, configurações)
```

---

### Autenticação

#### S01 · Tela de login
**Rota:** `/login`  
**Elementos:**
- Logo Normatiq + nome do laboratório (quando tenant já identificado)
- Campo e-mail
- Campo senha com toggle de visibilidade
- Botão "Entrar"
- Link "Esqueci minha senha"
- Versão do app no rodapé

**Mobile-first:** teclado sobe e empurra o formulário — usar `SingleChildScrollView` + `Padding` com `MediaQuery.of(context).viewInsets`

---

#### S02 · Primeiro acesso / redefinição de senha
**Rota:** `/first-access?token=...`  
**Elementos:**
- Campo nova senha + confirmação
- Indicador de força da senha
- Botão "Definir senha e entrar"

---

### Início (Dashboard)

#### S03 · Dashboard principal
**Rota:** `/`  
**Elementos (cards em scroll vertical):**
- Card de boas-vindas com nome do usuário e data
- **Card de alertas críticos** (padrões vencidos, itens atrasados) — vermelho, no topo
- Card "Próximos vencimentos" (lista compacta dos 5 mais urgentes com contagem regressiva)
- Card "Calibrações em andamento" (meus + do laboratório)
- Card "Pedidos aguardando ação" (aprovação, execução pendente)
- Card "Orçamentos enviados aguardando resposta"
- Mini-gráfico de calibrações por status no mês

**Mobile-first:** cards em coluna única, 360dp. Tablet: grid 2 colunas. Web: grid 3 colunas.

---

#### S04 · Central de notificações
**Rota:** `/notifications`  
**Elementos:**
- Lista agrupada por data (Hoje, Ontem, Esta semana)
- Cada item com ícone de tipo, título, subtítulo e tempo relativo
- Swipe-to-dismiss para marcar como lida
- Filtro por tipo (vencimento, NC, reclamação, pedido, orçamento)
- Badge no ícone da aba quando houver novas

---

### Operações — Calibrações

#### S05 · Lista de calibrações
**Rota:** `/calibrations`  
**Elementos:**
- Barra de busca (por instrumento, cliente, técnico)
- Chips de filtro rápido: Rascunho | Em andamento | Concluída | Todas
- Lista com cards compactos: tag do instrumento, cliente, status chip, data, técnico
- FAB "Nova calibração"

**Mobile-first:** lista densa com swipe-right para "Abrir" e swipe-left para "Cancelar" (quando rascunho)

---

#### S06 · Detalhe da calibração
**Rota:** `/calibrations/:id`  
**Elementos (abas no topo):**
- **Aba Dados:** instrumento, padrão usado, procedimento, condições ambientais, técnico, datas
- **Aba Pontos:** lista de pontos de calibração com resultado resumido (erro, U); botão "Adicionar ponto"
- **Aba Certificado:** estado do certificado; botão "Emitir" (quando concluída) ou visualizador PDF inline
- **Aba Planilha:** gerar / baixar / fazer upload da planilha Excel de incerteza (M28)

**Ações no AppBar:** "Concluir calibração" (botão primário quando em andamento)

---

#### S07 · Criar / editar calibração
**Rota:** `/calibrations/new` · `/calibrations/:id/edit`  
**Elementos (formulário em steps):**
- Step 1 — Instrumento: busca e seleção do instrumento do cliente (ou cadastrar novo inline)
- Step 2 — Padrão e procedimento: seleção com validação de vigência
- Step 3 — Condições: temperatura, umidade, sala, local de execução
- Step 4 — Detalhes: técnico, data, método, próxima calibração

**Mobile-first:** `Stepper` vertical com scroll; cada step tem validação inline antes de avançar

---

#### S08 · Adicionar ponto de calibração
**Rota:** `/calibrations/:id/points/new`  
**Elementos:**
- Campo valor nominal + unidade
- Seção "Leituras" — tabela dinâmica para adicionar pares (indicado | padrão); mínimo 2 linhas; botão "+"
- Seção "Incertezas tipo B" — U do certificado do padrão (pré-preenchido), resolução do instrumento, componentes adicionais
- Fator de cobertura k (padrão: 2)
- Botão "Calcular e salvar"
- **Preview dos resultados calculados** antes de confirmar (u_A, u_B, u_c, U, erro, correção)

**Mobile-first:** tabela de leituras em scroll horizontal se necessário; teclado numérico por padrão nos campos de medição

---

#### S09 · Detalhe do ponto de calibração
**Rota:** `/calibrations/:id/points/:point_id`  
**Elementos:**
- Cabeçalho: valor nominal e unidade
- Tabela de leituras (somente leitura após salvo)
- **Tabela de budget de incerteza:** componente | valor | distribuição | divisor | u(xi)
- Resultado: u_A, u_c, U, k, nível de confiança, erro, correção
- Indicador de conformidade (quando especificação informada)
- Botão "Gerar aba desta planilha" (abre geração do Excel do ponto)

---

### Operações — Orçamentos

#### S10 · Lista de orçamentos
**Rota:** `/quotations`  
**Elementos:**
- Busca por número, cliente
- Filtro por status: Rascunho | Enviado | Aprovado | Recusado | Convertido
- Cards com: número/versão, cliente, valor total, validade, status chip colorido
- FAB "Novo orçamento"
- Indicador de alerta quando orçamento próximo da validade

---

#### S11 · Criar orçamento — Cabeçalho
**Rota:** `/quotations/new`  
**Elementos:**
- Seleção do cliente (busca inline)
- Contato do cliente (opcional)
- Validade (date picker, padrão +30 dias)
- Condições de pagamento (dropdown de templates ou campo livre)
- Observações gerais
- Botão "Adicionar itens →"

---

#### S12 · Criar orçamento — Itens
**Rota:** `/quotations/:id/items`  
**Elementos:**
- Lista de itens já adicionados (swipe-left para remover)
- Botão "Adicionar item" → abre bottom sheet S13
- Totalizador fixo no rodapé: subtotal por tipo, desconto geral, **total**
- Botão "Revisar e finalizar →"

---

#### S13 · Bottom sheet — Adicionar item ao orçamento
**Acionado por:** botão na S12  
**Elementos:**
- Busca no catálogo de serviços (campo de busca no topo)
- Lista do catálogo com: código, descrição, preço padrão, badge de acreditação
- Ao selecionar: expande campos editáveis:
  - Descrição (editável, pré-preenchida do catálogo)
  - Instrumento (opcional — campo livre ou busca no cadastro)
  - Quantidade + flag "estimada"
  - Preço unitário (editável, pré-preenchido do catálogo) — campo destacado em amarelo indicando que pode ser alterado
  - Desconto (valor ou %)
  - **Badge de acreditação**: verde "Acreditado" / amarelo "Fora do escopo" / cinza "Não acreditado" — não editável, calculado automaticamente
- Botão "Adicionar"

**Mobile-first:** bottom sheet ocupa 90% da tela; `DraggableScrollableSheet`

---

#### S14 · Detalhe do orçamento
**Rota:** `/quotations/:id`  
**Elementos:**
- Cabeçalho: número, versão, cliente, status, validade
- Lista de itens com valores e badge de acreditação por item
- Totais
- **Resultado da análise crítica 7.1**: card expandível com checklist por item
- Ações conforme status:
  - Rascunho: "Enviar ao cliente" | "Editar"
  - Enviado: "Registrar aprovação manual" | "Registrar recusa" | "Nova versão"
  - Aprovado: "Converter em pedido"
- Histórico de versões (accordion)
- Histórico de eventos (enviado em, aprovado em etc.)

---

#### S15 · Visualização do orçamento em PDF
**Rota:** `/quotations/:id/pdf`  
**Elementos:**
- Viewer PDF em tela cheia
- Botão de compartilhamento (share nativo do SO)
- Botão de download

---

### Operações — Pedidos

#### S16 · Lista de pedidos
**Rota:** `/orders`  
**Elementos:**
- Filtros: status, período, cliente
- Cards com: número, cliente, quantidade de itens, progresso (X/Y itens concluídos), valor total, prazo
- Barra de progresso por pedido
- FAB (apenas para pedidos não originados de orçamento)

---

#### S17 · Detalhe do pedido
**Rota:** `/orders/:id`  
**Elementos:**
- Cabeçalho: número, cliente, status, datas
- **Card de rastreamento orçado × produzido**: tabela com quantidade orçada vs. produzida por item — destaque vermelho em itens com desvio
- Lista de itens com status individual e link para calibração vinculada
- Timeline de eventos do pedido
- Ações: Aprovar | Iniciar execução | Concluir | Cancelar

---

#### S18 · Detalhe do item do pedido
**Rota:** `/orders/:id/items/:item_id`  
**Elementos:**
- Dados do serviço
- Instrumento vinculado (editável se ainda não calibrado)
- Quantidade orçada × produzida com indicador visual
- Link para calibração(ões) vinculada(s)
- Botão "Nova calibração para este item" (quando em execução)

---

### Laboratório — Padrões

#### S19 · Lista de padrões
**Rota:** `/standards`  
**Elementos:**
- Busca por tag, modelo
- Filtro por status: Em dia | Vencendo | Vencidos | Inativos
- Cards com: tag, descrição, status chip, dias até vencimento (negativo se vencido), mini-badge de manutenção
- FAB "Novo padrão"

**Mobile-first:** status de vencimento com cor semafórica (verde/amarelo/vermelho) facilmente legível num relance

---

#### S20 · Detalhe do padrão
**Rota:** `/standards/:id`  
**Elementos (abas):**
- **Aba Dados:** identificação, rastreabilidade atual, datas, alerta configurado
- **Aba Calibrações:** histórico de calibrações externas recebidas; botão "Registrar nova"
- **Aba Manutenções:** histórico de manutenções; botão "Agendar"
- **Aba Verificações:** histórico de verificações intermediárias; botão "Registrar"
- **Aba Carta de Controle:** gráfico de estabilidade (M18)

---

#### S21 · Criar / editar padrão
**Rota:** `/standards/new` · `/standards/:id/edit`  
**Formulário único com scroll:**
- Identificação (tag, descrição, fabricante, modelo, série)
- Rastreabilidade (certificado, laboratório emissor, datas)
- Configuração de alertas (dias de antecedência)

---

### Laboratório — Procedimentos

#### S22 · Lista de procedimentos
**Rota:** `/procedures`  
**Elementos:**
- Filtro por tipo e status
- Cards com: código, título, versão, status chip, data de aprovação
- FAB "Novo procedimento"

---

#### S23 · Detalhe do procedimento
**Rota:** `/procedures/:id`  
**Elementos:**
- Metadados: código, versão, tipo, referência normativa, aprovador
- Requisitos: padrões necessários, qualificação mínima do técnico, condições ambientais
- Viewer do PDF do documento
- Histórico de versões
- Ações: "Criar nova versão" | "Obsoleter"

---

### Laboratório — Catálogo de Serviços

#### S24 · Lista do catálogo
**Rota:** `/service-catalog`  
**Elementos:**
- Filtro por tipo de serviço
- Cards com: código, descrição, preço padrão, badge de acreditação, status ativo/inativo
- FAB "Novo serviço"

---

#### S25 · Criar / editar serviço do catálogo
**Rota:** `/service-catalog/new` · `/service-catalog/:id/edit`  
**Formulário:**
- Código, descrição, tipo
- Procedimento vinculado (seleção)
- Preço padrão, unidade de cobrança, prazo padrão
- Toggle "Dentro do escopo acreditado" (influencia a lógica do símbolo — M27/H80)

---

### Clientes — Clientes

#### S26 · Lista de clientes
**Rota:** `/clients`  
**Elementos:**
- Busca por nome, CNPJ
- Cards com: nome, CNPJ, quantidade de instrumentos, status (ativo/inativo)
- FAB "Novo cliente"

---

#### S27 · Detalhe do cliente
**Rota:** `/clients/:id`  
**Elementos (abas):**
- **Aba Dados:** nome, CNPJ, endereço, contato, credenciais do portal
- **Aba Instrumentos:** lista de instrumentos com status de calibração
- **Aba Pedidos:** histórico de pedidos
- **Aba Orçamentos:** orçamentos emitidos para este cliente

---

#### S28 · Criar / editar cliente
**Rota:** `/clients/new` · `/clients/:id/edit`  
**Formulário:**
- Dados básicos (nome, CPF/CNPJ, e-mail, telefone)
- Endereço (CEP com auto-preenchimento via ViaCEP)
- Contato principal
- Configurações do portal (ativar acesso, resetar senha)

---

### Clientes — Instrumentos

#### S29 · Lista de instrumentos
**Rota:** `/instruments` · `/clients/:id/instruments`  
**Elementos:**
- Busca por tag, modelo, série
- Filtro por status de calibração
- Cards com: tag, descrição, cliente, status chip, próxima calibração
- FAB "Novo instrumento"

---

#### S30 · Detalhe do instrumento
**Rota:** `/instruments/:id`  
**Elementos (abas):**
- **Aba Dados:** identificação completa (tag, fabricante, modelo, série, faixa, resolução)
- **Aba Histórico:** linha do tempo de calibrações com status e link para certificado
- **Aba Situação:** próxima calibração, dias restantes, alerta configurado

---

#### S31 · Criar / editar instrumento
**Rota:** `/instruments/new` · `/instruments/:id/edit`  
**Formulário:**
- Cliente vinculado
- Tag (identificador interno), descrição
- Fabricante, modelo, número de série
- Faixa de medição, resolução, unidade

---

### Mais — Qualidade

#### S32 · Lista de não conformidades
**Rota:** `/quality/non-conformities`  
**Elementos:**
- Filtro por status, gravidade, origem
- Cards com: número, descrição resumida, gravidade chip, status, prazo
- FAB "Registrar NC"
- Badge de contagem de NCs abertas na aba

---

#### S33 · Detalhe da não conformidade
**Rota:** `/quality/non-conformities/:id`  
**Elementos:**
- Dados: descrição, origem, gravidade, responsável, prazo
- Ação imediata registrada
- Vinculações: calibração, padrão, pedido relacionado
- Ações corretivas vinculadas (lista com status)
- Timeline de evolução
- Botão "Encerrar NC" (após verificação de eficácia)

---

#### S34 · Registrar não conformidade
**Rota:** `/quality/non-conformities/new`  
**Formulário:**
- Descrição (campo grande, foco no teclado imediato)
- Origem (dropdown)
- Gravidade (selector visual: Leve / Moderada / Grave)
- Vínculo (calibração, padrão, pedido — opcional)
- Ação imediata tomada
- Responsável + prazo

---

#### S35 · Dashboard de qualidade
**Rota:** `/quality/dashboard`  
**Elementos:**
- Cards de KPIs: NCs abertas, reclamações pendentes, ações atrasadas, próxima auditoria
- Gráfico de NCs por mês
- Lista de ações corretivas com prazo vencendo nos próximos 7 dias
- Score de prontidão para acreditação (gauge visual)

---

### Mais — Pessoal

#### S36 · Lista da equipe
**Rota:** `/personnel`  
**Elementos:**
- Cards com: avatar/iniciais, nome, função, status das autorizações (chip verde/vermelho)
- FAB "Adicionar membro" (apenas admin)

---

#### S37 · Perfil do colaborador
**Rota:** `/personnel/:id`  
**Elementos (abas):**
- **Aba Dados:** nome, função, e-mail
- **Aba Competências:** formação, treinamentos (lista com status de validade), upload de certificados
- **Aba Autorizações:** lista de procedimentos autorizados com validade; botão "Adicionar autorização"
- **Aba Avaliações:** histórico de avaliações de desempenho

---

### Mais — Documentos

#### S38 · Repositório de documentos
**Rota:** `/documents`  
**Elementos:**
- Filtro por tipo e status
- Lista com: código, título, versão, status chip, data de próxima revisão
- Documentos com revisão vencida em destaque
- FAB "Novo documento"

---

### Mais — Configurações

#### S39 · Configurações do laboratório
**Rota:** `/settings`  
**Agrupado em seções (list tiles):**
- Perfil do laboratório (dados legais, logo, responsável técnico)
- Escopo de acreditação
- Templates de e-mail
- Configurações de alertas (réguas de vencimento)
- Usuários e permissões
- Integrações (estoque externo, sensores ambientais)
- Plano e faturamento

---

#### S40 · Gerenciar usuários do laboratório
**Rota:** `/settings/users`  
**Elementos:**
- Lista de usuários com: nome, e-mail, role chip, status (ativo/pendente/inativo)
- Swipe-left: desativar
- FAB "Convidar usuário"
- Bottom sheet de convite: e-mail + role

---

---

## App 2 — Client Portal

> App separado, mais simples. Foco em consulta e download. O cliente vê apenas seus dados.

### Navegação raiz

```
Bottom Nav (apenas 3 abas)
├── 🔧 Meus instrumentos
├── 📄 Certificados
└── 👤 Minha conta
```

---

#### S41 · Login do cliente
**Rota:** `/login`  
**Elementos:**
- Identificação do laboratório no topo (logo + nome)
- Campo e-mail + senha
- Link "Primeiro acesso / esqueci minha senha"

---

#### S42 · Meus instrumentos
**Rota:** `/instruments`  
**Elementos:**
- Busca por tag ou descrição
- Cards com: tag, descrição, modelo, status de calibração (chip semafórico), próxima calibração
- Toque → abre detalhe

---

#### S43 · Detalhe do instrumento (portal cliente)
**Rota:** `/instruments/:id`  
**Elementos:**
- Dados do instrumento
- **Linha do tempo de calibrações:** data, resultado (conforme/não conforme), link para certificado
- Alerta de vencimento próximo ou já vencido (card vermelho proeminente)

---

#### S44 · Visualizar certificado (portal cliente)
**Rota:** `/certificates/:id`  
**Elementos:**
- Viewer PDF em tela cheia
- Botão de download e compartilhamento
- Metadados: número, data de emissão, validade, status (aprovado/revogado/emendado)
- Certificado revogado: overlay vermelho "REVOGADO" sobre o viewer

---

#### S45 · Aprovar / recusar orçamento (portal cliente)
**Rota:** `/quotations/:token` *(acesso por link sem login completo)*  
**Elementos:**
- Resumo do orçamento (sem preços de custo — apenas os valores ofertados)
- Lista de itens com descrição e valores
- Validade destacada
- Três ações com confirmação: **"Aprovar"** | **"Recusar"** | **"Solicitar alteração"**
- Campo obrigatório de observação ao recusar ou solicitar alteração

---

---

## App 3 — Admin App

> Interface de gestão da plataforma. Usada pela equipe Normatiq.

### Navegação raiz

```
Navigation Rail (sempre visível — uso predominante em desktop/tablet)
├── 🏢 Laboratórios
├── 💳 Planos e billing
├── 📊 Métricas da plataforma
└── ⚙️  Configurações
```

---

#### S46 · Lista de laboratórios
**Rota:** `/labs`  
**Elementos:**
- Busca + filtros por status e plano
- Tabela (desktop) / lista (mobile) com: nome, plano, status, usuários, calibrações no mês, expiração
- Ações rápidas: ativar/suspender, alterar plano, impersonar (acesso somente leitura ao lab)

---

#### S47 · Detalhe do laboratório
**Rota:** `/labs/:id`  
**Elementos:**
- Dados do tenant
- Uso atual vs. limites do plano (barras de progresso)
- Histórico de faturas
- Timeline de eventos (criação, suspensões, upgrades)
- Ações: alterar plano, prorrogar trial, suspender, reativar

---

#### S48 · Métricas da plataforma
**Rota:** `/metrics`  
**Elementos:**
- MRR (receita recorrente mensal)
- Novos labs no período
- Churn do período
- Calibrações totais geradas
- Certificados emitidos
- Gráficos de crescimento mês a mês

---

---

## Mapa de navegação consolidado — Lab App

```
/login
/first-access
/
  ├── /notifications
  │
  ├── /calibrations
  │   ├── /calibrations/new
  │   ├── /calibrations/:id
  │   │   ├── /calibrations/:id/edit
  │   │   ├── /calibrations/:id/points/new
  │   │   └── /calibrations/:id/points/:point_id
  │   └── /calibrations/:id/certificate
  │
  ├── /quotations
  │   ├── /quotations/new
  │   ├── /quotations/:id
  │   ├── /quotations/:id/items
  │   └── /quotations/:id/pdf
  │
  ├── /orders
  │   ├── /orders/:id
  │   └── /orders/:id/items/:item_id
  │
  ├── /standards
  │   ├── /standards/new
  │   └── /standards/:id
  │       └── /standards/:id/edit
  │
  ├── /procedures
  │   ├── /procedures/new
  │   └── /procedures/:id
  │
  ├── /service-catalog
  │   ├── /service-catalog/new
  │   └── /service-catalog/:id/edit
  │
  ├── /clients
  │   ├── /clients/new
  │   └── /clients/:id
  │       └── /clients/:id/edit
  │
  ├── /instruments
  │   ├── /instruments/new
  │   └── /instruments/:id
  │       └── /instruments/:id/edit
  │
  ├── /quality
  │   ├── /quality/dashboard
  │   ├── /quality/non-conformities
  │   │   ├── /quality/non-conformities/new
  │   │   └── /quality/non-conformities/:id
  │   ├── /quality/corrective-actions
  │   ├── /quality/complaints
  │   ├── /quality/audits
  │   └── /quality/management-review
  │
  ├── /personnel
  │   └── /personnel/:id
  │
  ├── /documents
  │   └── /documents/:id
  │
  └── /settings
      ├── /settings/users
      ├── /settings/lab-profile
      ├── /settings/scope
      └── /settings/notifications
```

---

## Total de telas planejadas

| App | Telas | Perfil de uso |
|-----|-------|--------------|
| Lab App | 40 telas (S01–S40) | Técnicos (celular), gestores (tablet/web), atendentes (celular/desktop) |
| Client Portal | 5 telas (S41–S45) | Clientes finais (celular predominante) |
| Admin App | 3 telas (S46–S48) | Equipe Normatiq (desktop predominante) |
| **Total** | **48 telas** | |


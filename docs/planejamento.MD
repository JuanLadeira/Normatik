# Normatiq — Planejamento do Sistema
> SaaS de Metrologia Multi-Tenant · Alinhado ISO/IEC 17025 · FastAPI + Flutter

---

## Sumário

1. [Visão geral](#1-visão-geral)
2. [Personas](#2-personas)
3. [Módulos e épicos](#3-módulos-e-épicos)
   - [M01 · Plataforma & Multi-Tenancy](#m01--plataforma--multi-tenancy)
   - [M02 · Gestão de Padrões](#m02--gestão-de-padrões)
   - [M03 · Clientes e Instrumentos](#m03--clientes-e-instrumentos)
   - [M04 · Calibrações e Cálculo de Incerteza](#m04--calibrações-e-cálculo-de-incerteza)
   - [M05 · Certificados](#m05--certificados)
   - [M06 · Pedidos e Ordens de Serviço](#m06--pedidos-e-ordens-de-serviço)
   - [M07 · Estoque](#m07--estoque)
   - [M08 · Calendário, Alertas e Notificações](#m08--calendário-alertas-e-notificações)
   - [M09 · Manutenção Preventiva dos Padrões](#m09--manutenção-preventiva-dos-padrões)
   - [M10 · Portal do Cliente](#m10--portal-do-cliente)
   - [M11 · Admin & Planos de Assinatura](#m11--admin--planos-de-assinatura)
4. [Mapa de dependências entre módulos](#4-mapa-de-dependências-entre-módulos)
5. [Roadmap de entregas sugerido](#5-roadmap-de-entregas-sugerido)
6. [Estratégia de negócio](#6-estratégia-de-negócio)
7. [Decisões técnicas registradas](#7-decisões-técnicas-registradas)
   - [M11 · Admin & Planos de Assinatura](#m11--admin--planos-de-assinatura)
4. [Mapa de dependências entre módulos](#4-mapa-de-dependências-entre-módulos)
5. [Roadmap de entregas sugerido](#5-roadmap-de-entregas-sugerido)
6. [Decisões técnicas registradas](#6-decisões-técnicas-registradas)

---

## 1. Visão Geral

O **Normatiq** é um SaaS de metrologia que permite que laboratórios de calibração operem de forma profissional, com rastreabilidade completa, cálculos de incerteza automatizados e emissão de certificados prontos para acreditação ISO/IEC 17025. Cada laboratório tem seu ambiente isolado (multi-tenant), seus próprios clientes e padrões. Clientes de cada laboratório acessam um portal exclusivo para visualizar seus instrumentos e certificados.

**Proposta de valor central:** o laboratório configura o procedimento e faz as medições — o sistema calcula as incertezas, gera o certificado e notifica quem precisa ser notificado.

---

## 2. Personas

| ID | Persona | Descrição |
|----|---------|-----------|
| P1 | **Superadmin** | Equipe Normatiq. Gerencia todos os laboratórios, planos e cobrança. |
| P2 | **Gestor do Lab** | Dono ou gerente do laboratório. Configura o ambiente, aprova certificados, vê relatórios. |
| P3 | **Técnico de Calibração** | Executa as calibrações, registra medições, emite certificados. |
| P4 | **Atendente / Comercial** | Abre pedidos de serviço, cadastra clientes e instrumentos. |
| P5 | **Cliente do Lab** | Empresa ou pessoa que envia instrumentos para calibração. Acessa o portal para ver certificados. |

---

## 3. Módulos e Épicos

---

### M01 · Plataforma & Multi-Tenancy

> Base técnica do SaaS. Isolamento de dados, autenticação e controle de acesso.

---

#### H01 — Registro e ativação de laboratório

**Como** superadmin,  
**quero** criar um novo laboratório no sistema informando nome, CNPJ, plano e e-mail do gestor,  
**para** que o laboratório seja provisionado e o gestor receba acesso imediatamente.

**Critérios de aceite:**
- Tenant criado com `slug` único derivado do nome
- E-mail de boas-vindas enviado ao gestor com link de primeiro acesso
- Laboratório começa em status `trial` com data de expiração configurável
- Dados de um tenant nunca aparecem para outro tenant (isolamento por `tenant_id` + RLS)

---

#### H02 — Autenticação de usuários do laboratório

**Como** usuário do laboratório (gestor, técnico ou atendente),  
**quero** fazer login com e-mail e senha,  
**para** acessar o painel do meu laboratório com as permissões corretas.

**Critérios de aceite:**
- JWT gerado com `tenant_id`, `user_id` e `role` no payload
- Roles disponíveis: `admin`, `technician`, `attendant`
- Refresh token com validade de 7 dias
- Bloqueio de acesso se tenant estiver inativo ou com plano expirado (HTTP 403 com mensagem clara)

---

#### H03 — Gestão de usuários do laboratório

**Como** gestor do laboratório,  
**quero** convidar, editar e desativar usuários do meu laboratório,  
**para** controlar quem tem acesso e com qual nível de permissão.

**Critérios de aceite:**
- Convite por e-mail com link de ativação (expira em 48h)
- Possível atribuir role no momento do convite
- Desativação não apaga o usuário (soft delete), apenas bloqueia o acesso
- Gestor não consegue se auto-remover

---

#### H04 — Controle de permissões por role

**Como** sistema,  
**quero** aplicar regras de acesso baseadas no role do usuário autenticado,  
**para** que técnicos não acessem configurações financeiras e atendentes não editem calibrações concluídas.

**Critérios de aceite:**

| Ação | Admin | Técnico | Atendente |
|------|-------|---------|-----------|
| Configurar laboratório | ✅ | ❌ | ❌ |
| Criar/editar calibração | ✅ | ✅ | ❌ |
| Emitir certificado | ✅ | ✅ | ❌ |
| Abrir pedido | ✅ | ✅ | ✅ |
| Ver relatórios | ✅ | ❌ | ❌ |
| Gerenciar usuários | ✅ | ❌ | ❌ |

---

### M02 · Gestão de Padrões

> Padrões são os equipamentos de referência do laboratório usados para calibrar os instrumentos dos clientes. Precisam ter sua própria rastreabilidade gerenciada.

---

#### H05 — Cadastro de padrão de referência

**Como** gestor ou técnico,  
**quero** cadastrar um padrão de referência com seus dados técnicos e de rastreabilidade,  
**para** que ele possa ser vinculado às calibrações e ter sua situação monitorada.

**Critérios de aceite:**
- Campos obrigatórios: tag (identificador interno), descrição, fabricante, modelo, número de série
- Campos de rastreabilidade: número do certificado atual, laboratório emissor, data de calibração, data de vencimento
- Campo `alert_days_before` (padrão: 30 dias) para configurar antecedência dos alertas
- Padrão pode ser marcado como inativo sem ser excluído

---

#### H06 — Histórico de calibrações do padrão

**Como** técnico,  
**quero** registrar cada nova calibração recebida pelo padrão (feita por laboratório externo acreditado),  
**para** manter o histórico completo de rastreabilidade do padrão ao longo do tempo.

**Critérios de aceite:**
- Cada registro contém: data de calibração, data de vencimento, número do certificado, laboratório emissor, notas
- Upload do arquivo PDF do certificado externo
- Ao registrar, as datas do padrão são atualizadas automaticamente com as datas do novo registro
- Histórico ordenado do mais recente para o mais antigo

---

#### H07 — Indicadores visuais de situação dos padrões

**Como** gestor ou técnico,  
**quero** ver rapidamente quais padrões estão vencidos, próximos do vencimento ou em dia,  
**para** priorizar ações e garantir que apenas padrões rastreáveis sejam usados em calibrações.

**Critérios de aceite:**
- Status calculado em tempo real: `em_dia` / `vencendo_em_breve` / `vencido`
- Listagem filtrável por status
- Campo calculado `days_until_cal_due` exposto na API
- Padrão vencido não pode ser vinculado a uma nova calibração (bloqueio no service)

---

### M03 · Clientes e Instrumentos

---

#### H08 — Cadastro de cliente do laboratório

**Como** atendente ou gestor,  
**quero** cadastrar um cliente (empresa ou pessoa física) no laboratório,  
**para** vincular seus instrumentos e pedidos a ele.

**Critérios de aceite:**
- Campos: nome, CPF/CNPJ, e-mail, telefone, endereço
- E-mail do cliente usado para notificações e acesso ao portal
- Cliente pertence exclusivamente ao tenant que o cadastrou
- Busca por nome, CNPJ/CPF e e-mail

---

#### H09 — Cadastro de instrumento do cliente

**Como** atendente ou técnico,  
**quero** cadastrar um instrumento pertencente a um cliente,  
**para** registrar suas calibrações e manter o histórico de rastreabilidade.

**Critérios de aceite:**
- Campos: tag (código interno), descrição, fabricante, modelo, número de série, faixa de medição, resolução, unidade
- Instrumento vinculado obrigatoriamente a um cliente
- Possível editar dados do instrumento sem perder o histórico de calibrações
- Listagem de instrumentos filtrável por cliente

---

#### H10 — Histórico de calibrações do instrumento

**Como** técnico ou cliente (portal),  
**quero** ver todas as calibrações já realizadas em um instrumento específico,  
**para** acompanhar a evolução e verificar a situação atual de rastreabilidade.

**Critérios de aceite:**
- Calibrações ordenadas da mais recente para a mais antiga
- Cada entrada mostra: data, status, padrão utilizado, se tem certificado emitido
- Próxima data de calibração calculada e exibida
- Indicação visual se a calibração mais recente está vencida

---

### M04 · Calibrações e Cálculo de Incerteza

> Módulo central do sistema. Implementa o motor de cálculo conforme o GUM (ISO/IEC Guide 98-3).

---

#### H11 — Abertura de registro de calibração

**Como** técnico,  
**quero** abrir um registro de calibração para um instrumento,  
**para** iniciar o processo de documentação e inserção de medições.

**Critérios de aceite:**
- Vinculado a: instrumento do cliente, padrão de referência utilizado
- Campos: método (procedimento), temperatura e umidade do ambiente, responsável técnico, data de execução
- Status inicial: `rascunho`
- Padrão com calibração vencida não pode ser selecionado (validação no service)
- Possível ter múltiplas calibrações abertas em paralelo para instrumentos diferentes

---

#### H12 — Inserção de pontos de calibração com medições

**Como** técnico,  
**quero** adicionar pontos de calibração ao registro, informando o valor nominal e as leituras individuais do instrumento e do padrão,  
**para** que o sistema calcule automaticamente os resultados e as incertezas.

**Critérios de aceite:**
- Cada ponto tem: valor nominal, unidade, lista de medições (mínimo 2 leituras por ponto)
- Cada medição tem: número da leitura, valor indicado pelo instrumento, valor do padrão correspondente
- Técnico informa as incertezas tipo B: `U` do certificado do padrão (expandida) e resolução do instrumento
- O sistema calcula automaticamente ao salvar o ponto (sem ação manual):
  - Média das indicações
  - Desvio padrão experimental `s(x)`
  - Incerteza tipo A: `u_A = s(x) / √n`
  - Incerteza tipo B do padrão: `u_B1 = U_cert / k` (distribuição normal)
  - Incerteza tipo B da resolução: `u_B2 = (res/2) / √3` (distribuição retangular)
  - Incerteza combinada: `u_c = √(u_A² + u_B1² + u_B2²)`
  - Incerteza expandida: `U = k × u_c` (k=2 por padrão, configurável)
  - Erro: `E = indicação_média - valor_convencional`
  - Correção: `C = -E`
- Resultados persistidos no banco com 2 algarismos significativos na incerteza
- Múltiplos pontos por calibração (sem limite fixo)
- Pontos só podem ser adicionados/removidos enquanto calibração estiver em `rascunho` ou `em_andamento`

---

#### H13 — Conclusão da calibração

**Como** técnico,  
**quero** marcar uma calibração como concluída após revisar todos os pontos,  
**para** liberar a emissão do certificado.

**Critérios de aceite:**
- Calibração precisa ter ao menos um ponto para ser concluída
- Status muda de `em_andamento` para `concluida`
- Após conclusão, nenhum ponto pode ser adicionado, editado ou removido
- Data de próxima calibração do instrumento atualizada com base na `next_calibration_date` informada

---

#### H14 — Revisão e visualização completa da calibração

**Como** gestor ou técnico,  
**quero** visualizar o registro completo de uma calibração com todos os pontos, medições e resultados calculados,  
**para** revisar antes de emitir o certificado.

**Critérios de aceite:**
- Exibe: dados do instrumento, dados do padrão, condições ambientais, todos os pontos com medições e resultados de incerteza
- Tabela de resultados mostrando por ponto: valor nominal, média, erro, correção, `u_A`, `u_B`, `u_c`, `U`, `k`
- Exibição clara das unidades em todos os campos numéricos

---

### M05 · Certificados

---

#### H15 — Emissão do certificado de calibração

**Como** técnico ou gestor,  
**quero** emitir o certificado de calibração ao concluir o registro,  
**para** entregar ao cliente um documento rastreável e conforme a ISO/IEC 17025.

**Critérios de aceite:**
- Disponível apenas para calibrações com status `concluida`
- Número do certificado gerado automaticamente com sequência por tenant (ex: `LAB-2024-0042`)
- Apenas um certificado por calibração; tentativa de segunda emissão retorna erro
- PDF gerado com os seguintes elementos obrigatórios 17025:
  - Identificação do laboratório (nome, endereço, CNPJ, logo)
  - Número do certificado e data de emissão
  - Identificação do cliente e do instrumento (tag, fabricante, modelo, série)
  - Método de calibração utilizado
  - Condições ambientais (temperatura e umidade)
  - Identificação do padrão rastreável (tag, certificado, laboratório emissor)
  - Tabela de resultados por ponto: valor nominal, indicação média, erro, correção, incerteza expandida, `k`, nível de confiança
  - Data da próxima calibração recomendada
  - Nome e assinatura digital do responsável técnico
- PDF armazenado em storage (S3) com URL gerada
- Status do certificado: `aprovado` ou `revogado`

---

#### H16 — Revogação de certificado

**Como** gestor,  
**quero** revogar um certificado já emitido informando o motivo,  
**para** invalidar um documento com erro sem apagá-lo do histórico.

**Critérios de aceite:**
- Certificado revogado permanece no histórico com status `revogado` e motivo registrado
- PDF do certificado revogado exibe marca d'água "REVOGADO"
- Cliente notificado por e-mail sobre a revogação
- Uma nova calibração pode ser aberta para o mesmo instrumento para reemissão

---

### M06 · Pedidos e Ordens de Serviço

---

#### H17 — Abertura de pedido

**Como** atendente ou gestor,  
**quero** abrir um pedido de serviço vinculado a um cliente,  
**para** registrar formalmente os serviços solicitados antes de iniciar a execução.

**Critérios de aceite:**
- Pedido vinculado a um cliente
- Número do pedido gerado automaticamente
- Status: `rascunho` → `aprovado` → `em_execução` → `concluído` → `cancelado`
- Campo de observações gerais

---

#### H18 — Adição de itens ao pedido

**Como** atendente ou técnico,  
**quero** adicionar itens ao pedido, sendo cada item um serviço de calibração ou a venda de um produto do estoque,  
**para** compor o escopo completo do trabalho a ser executado.

**Critérios de aceite:**
- Tipos de item:
  - `calibracao`: vinculado a um instrumento do cliente; cria automaticamente um registro de calibração em `rascunho` ao ser aprovado
  - `produto`: vinculado a um produto do estoque; valida disponibilidade no momento da aprovação
- Cada item tem: tipo, descrição, quantidade, preço unitário
- Total do pedido calculado automaticamente
- Itens podem ser adicionados/removidos enquanto pedido estiver em `rascunho`

---

#### H19 — Aprovação do pedido e criação das calibrações

**Como** gestor,  
**quero** aprovar um pedido revisado,  
**para** disparar a criação dos registros de calibração e a reserva dos produtos do estoque.

**Critérios de aceite:**
- Para cada item do tipo `calibracao`: cria registro de calibração em `rascunho` vinculado ao instrumento do item e ao pedido
- Para cada item do tipo `produto`: reserva a quantidade no estoque (decrementa estoque disponível)
- Se algum produto não tiver estoque suficiente, o pedido não é aprovado e a validação aponta quais itens falharam
- Status do pedido muda para `aprovado`

---

#### H20 — Acompanhamento do andamento do pedido

**Como** gestor ou atendente,  
**quero** ver o status consolidado de um pedido, incluindo o progresso das calibrações vinculadas,  
**para** saber o que já foi concluído e o que ainda está pendente.

**Critérios de aceite:**
- Visão do pedido com cada item e seu status atual
- Item de calibração mostra: status da calibração (`rascunho`, `em_andamento`, `concluida`) e se certificado foi emitido
- Pedido muda automaticamente para `concluído` quando todos os itens estiverem finalizados

---

### M07 · Estoque

> O laboratório já possui um app de estoque. A integração deve aproveitar ao máximo o que existe.

---

#### H21 — Consulta de disponibilidade de produto

**Como** sistema (pedidos),  
**quero** consultar o estoque disponível de um produto ao montar um pedido,  
**para** validar se a venda pode ser realizada antes da aprovação.

**Critérios de aceite:**
- Endpoint/serviço interno que retorna `{ product_id, available_qty, unit_price }` para um produto
- Isolado por tenant
- Se o app de estoque existente tiver API própria: wrapper de integração criado no domínio `inventory`
- Se não tiver: CRUD básico de produtos e movimentações implementado aqui

---

#### H22 — Reserva e baixa de estoque

**Como** sistema (aprovação de pedido),  
**quero** reservar produtos ao aprovar um pedido e dar baixa definitiva ao concluí-lo,  
**para** manter o estoque atualizado e evitar venda de produtos indisponíveis.

**Critérios de aceite:**
- Reserva: decrementa `available_qty` sem alterar `total_qty`
- Baixa definitiva: decrementa `total_qty` e remove a reserva
- Cancelamento de pedido: estorna a reserva
- Histórico de movimentações (entrada, saída, reserva, estorno) por produto

---

#### H23 — Alertas de estoque baixo

**Como** gestor,  
**quero** ser notificado quando um produto atingir o estoque mínimo configurado,  
**para** providenciar reposição sem afetar as operações.

**Critérios de aceite:**
- Campo `min_stock_qty` por produto
- Notificação por e-mail quando `available_qty <= min_stock_qty` após uma baixa
- Notificação enviada apenas uma vez por evento (não repetir enquanto continuar abaixo)

---

### M08 · Calendário, Alertas e Notificações

---

#### H24 — Calendário de vencimentos

**Como** gestor ou técnico,  
**quero** visualizar um calendário com todas as datas de vencimento de calibração dos padrões e dos instrumentos dos clientes,  
**para** planejar a agenda do laboratório e antecipar ações.

**Critérios de aceite:**
- Visão mensal e de lista
- Filtros: tipo (padrão / instrumento do cliente), status (vencido, vencendo, em dia)
- Cada entrada mostra: nome/tag, tipo, data de vencimento, dias restantes (negativo se vencido)
- Exportável como CSV

---

#### H25 — Notificação automática de vencimento de padrão

**Como** gestor do laboratório,  
**quero** receber e-mails automáticos quando um padrão estiver próximo do vencimento ou já vencido,  
**para** providenciar uma nova calibração externa e não interromper as operações.

**Critérios de aceite:**
- E-mails disparados automaticamente pelo scheduler (Celery Beat) com as seguintes réguas:
  - `alert_days_before` antes do vencimento (configurável por padrão, padrão 30 dias)
  - 7 dias antes do vencimento
  - No dia do vencimento
  - 1, 7, 15 e 30 dias após o vencimento (enquanto não renovado)
- Destinatários: gestor do lab + usuários com role `admin`
- E-mail contém: nome do padrão, data de vencimento, dias restantes/vencidos, link para o padrão no sistema
- Alertas cessam automaticamente quando uma nova calibração é registrada para o padrão

---

#### H26 — Notificação automática de vencimento de calibração do instrumento do cliente

**Como** sistema,  
**quero** notificar o cliente do laboratório quando a calibração de um seu instrumento estiver vencendo,  
**para** que ele providencie o envio do instrumento para nova calibração.

**Critérios de aceite:**
- Régua configurável por laboratório (padrão: 30 dias antes, 7 dias antes, dia do vencimento, 7 e 30 dias após)
- Destinatário: e-mail do cliente (cadastrado no laboratório)
- E-mail contém: identificação do instrumento (tag, descrição), data de vencimento, orientações do laboratório
- Template de e-mail personalizável por laboratório (logo, texto de rodapé)
- Logs de todos os envios por instrumento

---

### M09 · Manutenção Preventiva dos Padrões

---

#### H27 — Planejamento de manutenção preventiva

**Como** gestor ou técnico,  
**quero** agendar manutenções preventivas para os padrões do laboratório,  
**para** garantir que estejam em perfeito estado operacional entre uma calibração e outra.

**Critérios de aceite:**
- Campos: tipo (`preventiva` / `corretiva`), data agendada, responsável, descrição do serviço
- Ao criar, informa-se a data da próxima manutenção; o campo `maintenance_due` do padrão é atualizado automaticamente
- Listagem por padrão com histórico completo

---

#### H28 — Registro de execução da manutenção

**Como** técnico,  
**quero** registrar a execução de uma manutenção agendada,  
**para** fechar o evento e documentar o que foi feito.

**Critérios de aceite:**
- Campos: data de execução, quem realizou, observações e resultado
- Ao registrar execução, campo `done_date` preenchido e status muda para `realizada`
- Campo `next_maintenance_date` atualiza o `maintenance_due` do padrão
- Manutenção não realizada na data não é apagada — fica como `atrasada` até ser executada ou cancelada

---

#### H29 — Notificação automática de manutenção agendada

**Como** gestor,  
**quero** receber alertas automáticos quando uma manutenção preventiva de um padrão estiver próxima ou atrasada,  
**para** não deixar passar sem ação.

**Critérios de aceite:**
- Mesma lógica de régua do H25, mas para datas de manutenção
- Destinatários configuráveis por laboratório
- Alerta de manutenção e alerta de calibração são fluxos independentes

---

### M10 · Portal do Cliente

> Área exclusiva onde cada cliente do laboratório acessa apenas seus próprios dados.

---

#### H30 — Acesso do cliente ao portal

**Como** cliente do laboratório,  
**quero** acessar um portal exclusivo com meu login,  
**para** visualizar meus instrumentos e certificados sem precisar contatar o laboratório.

**Critérios de aceite:**
- Login com e-mail e senha (credenciais distintas das do laboratório)
- JWT do cliente contém `tenant_id` + `client_id` + `role: client`
- Cliente enxerga **apenas** seus dados; qualquer tentativa de acessar dados de outro cliente retorna 404
- URL do portal é subdomínio ou rota do tenant (ex: `app.normatiq.com/portal/lab-xyz`)

---

#### H31 — Visualização de instrumentos no portal

**Como** cliente,  
**quero** ver a lista de todos os meus instrumentos cadastrados no laboratório,  
**para** ter visibilidade do que está sendo gerenciado.

**Critérios de aceite:**
- Lista com: tag, descrição, fabricante, modelo, status da calibração mais recente, próxima data de calibração
- Indicador visual de situação: em dia / vencendo / vencido
- Busca por tag ou descrição

---

#### H32 — Detalhe do instrumento e histórico de calibrações no portal

**Como** cliente,  
**quero** clicar em um instrumento e ver o histórico completo de calibrações realizadas,  
**para** acompanhar a rastreabilidade ao longo do tempo.

**Critérios de aceite:**
- Exibe dados do instrumento
- Lista de calibrações com data, resultado e status do certificado
- Cada calibração com certificado emitido exibe botão de download do PDF

---

#### H33 — Visualização e download do certificado no portal

**Como** cliente,  
**quero** acessar o certificado de calibração de um instrumento diretamente pelo portal,  
**para** ter o documento disponível sem precisar solicitar ao laboratório.

**Critérios de aceite:**
- Visualização inline do PDF no navegador
- Botão de download direto
- Certificados revogados exibidos com indicação clara de "REVOGADO" e não disponíveis para download padrão
- Log de acesso registrado (quem acessou e quando)

---

### M11 · Admin & Planos de Assinatura

---

#### H34 — Painel de administração geral (Superadmin)

**Como** superadmin,  
**quero** ter um painel para visualizar e gerenciar todos os laboratórios cadastrados na plataforma,  
**para** operar o SaaS com visibilidade total.

**Critérios de aceite:**
- Listagem de tenants com: nome, plano, status, data de criação, data de expiração, número de usuários e calibrações
- Ações disponíveis: ativar, suspender, alterar plano, prorrogar trial
- Busca e filtros por status e plano
- Acesso restrito: superadmin nunca acessa dados operacionais de um tenant (isolamento mantido)

---

#### H35 — Planos de assinatura

**Como** superadmin,  
**quero** definir planos com diferentes limites e funcionalidades,  
**para** oferecer opções de preço acessível com escalabilidade.

**Critérios de aceite:**
- Planos configuráveis com os seguintes limites:
  - Número máximo de usuários do laboratório
  - Número máximo de padrões ativos
  - Número máximo de calibrações por mês
  - Acesso ao portal do cliente (sim/não)
  - Geração de certificados PDF (sim/não)
- Sugestão inicial de planos:

| Plano | Usuários | Padrões | Cal./mês | Portal | Preço sugerido |
|-------|----------|---------|----------|--------|----------------|
| Starter | 2 | 5 | 30 | ❌ | R$ 97/mês |
| Pro | 5 | 20 | 150 | ✅ | R$ 197/mês |
| Enterprise | Ilimitado | Ilimitado | Ilimitado | ✅ | Sob consulta |

---

#### H36 — Controle de uso e limites do plano

**Como** sistema,  
**quero** verificar os limites do plano antes de permitir certas ações,  
**para** garantir que o laboratório não ultrapasse o contratado.

**Critérios de aceite:**
- Ao criar calibração: verificar limite mensal; retornar HTTP 402 com mensagem orientando upgrade se excedido
- Ao convidar usuário: verificar limite de usuários
- Ao cadastrar padrão: verificar limite de padrões ativos
- Mensagens de limite exibidas de forma amigável com link para upgrade
- Gestor do lab recebe alerta por e-mail ao atingir 80% de qualquer limite

---

#### H37 — Integração com gateway de pagamento

**Como** superadmin,  
**quero** integrar o sistema com um gateway de pagamento para cobrar as assinaturas automaticamente,  
**para** não precisar de cobrança manual.

**Critérios de aceite:**
- Suporte a cartão de crédito e boleto (foco mercado BR: Stripe ou Asaas)
- Webhook processa eventos: `payment.succeeded`, `payment.failed`, `subscription.cancelled`
- Pagamento confirmado → tenant ativado/renovado automaticamente
- Pagamento com falha → notificação por e-mail + período de graça de 5 dias antes de suspensão
- Histórico de faturas acessível pelo gestor do lab

---

## 4. Mapa de Dependências entre Módulos

```
M01 (Plataforma)
  └── todos os módulos dependem de M01

M02 (Padrões)
  └── M04 (Calibrações) depende de M02

M03 (Clientes e Instrumentos)
  └── M04 (Calibrações) depende de M03
  └── M06 (Pedidos) depende de M03
  └── M10 (Portal) depende de M03

M04 (Calibrações)
  └── M05 (Certificados) depende de M04
  └── M08 (Notificações) depende de M04
  └── M10 (Portal) depende de M04 e M05

M06 (Pedidos)
  └── M07 (Estoque) depende de M06

M02 + M09 (Padrões + Manutenção)
  └── M08 (Notificações) depende de M02 e M09

M11 (Admin)
  └── M01 depende de M11 para controle de planos
```

---

## 5. Roadmap de Entregas Sugerido

| Fase | Módulos | Histórias | Foco |
|------|---------|-----------|------|
| **Fase 1** — Fundação | M01 | H01–H04 | Multi-tenancy, auth, roles |
| **Fase 2** — Core metrológico | M02, M03, M04 | H05–H14 | Padrões, instrumentos, calibração + GUM |
| **Fase 3** — Certificados | M05 | H15–H16 | Emissão PDF 17025 |
| **Fase 4** — Operação comercial | M06, M07 | H17–H23 | Pedidos e estoque |
| **Fase 5** — Alertas | M08, M09 | H24–H29 | Calendário, e-mails automáticos, manutenção |
| **Fase 6** — Portal do cliente | M10 | H30–H33 | Acesso externo ao cliente |
| **Fase 7** — Negócio SaaS | M11 | H34–H37 | Admin, planos, billing |

> Fases 1–3 formam o MVP funcional do laboratório.  
> Fases 4–5 completam o produto para uso diário real.  
> Fases 6–7 transformam em SaaS comercializável.

---

## 6. Decisões Técnicas Registradas

| # | Decisão | Justificativa |
|---|---------|---------------|
| DT01 | FastAPI + SQLAlchemy async + Alembic | Performance, ecossistema Python científico (NumPy/SciPy para GUM), migrations versionadas |
| DT02 | Multi-tenancy por `tenant_id` + RLS no PostgreSQL | Isolamento garantido em nível de banco, sem risco de vazamento por bug no código |
| DT03 | Arquitetura por domínio: `model / schema / repository / service / router` | Separação clara de responsabilidades; repository isola SQL; service isola regra de negócio |
| DT04 | Repositórios como classes concretas sem ABC | Código mais enxuto; ABC só traria valor se múltiplas implementações de banco fossem planejadas |
| DT05 | Cálculo GUM no service, resultados persistidos no banco | Certificado pode ser gerado a qualquer momento sem recalcular; auditoria dos valores é garantida |
| DT06 | Celery + Redis para notificações e jobs agendados | Processamento assíncrono de e-mails sem bloquear a API; Celery Beat para scheduler de alertas |
| DT07 | Certificados PDF gerados server-side com ReportLab | Controle total do layout 17025; sem dependência de serviços externos |
| DT08 | Storage S3 para arquivos (PDFs, certificados de padrões) | URLs assinadas para acesso seguro; arquivos não no banco |
| DT09 | Portal do cliente como app Flutter separado | Isolamento completo da UX do cliente vs. UX do laboratório; mesma API backend |
| DT10 | Tenant logic reutilizada do app existente | Não reinventar; importar como dependência interna ou módulo `core` |
| DT11 | **Flutter** como único framework frontend | iOS, Android e Web a partir de uma única codebase; técnicos usam celular em campo |
| DT12 | **Mobile-first** em todas as telas | Layout base em 360dp expandindo para tablet e web; técnicos calibram com celular na mão |
| DT13 | **Três apps Flutter** no monorepo | `lab_app`, `client_portal`, `admin_app` — compartilham packages de design system e domínio |
| DT14 | **Riverpod** para gerenciamento de estado | Ergonômico, testável, sem boilerplate excessivo em relação ao BLoC |
| DT15 | **go_router** para navegação | Deep links, rotas nomeadas, guards de autenticação e redirecionamento por role |
| DT16 | Motor Excel com `openpyxl` + herança de classes Python | Geração de planilhas GUM por tipo de instrumento; contrato de células garante leitura no upload |

---

## 6. Estratégia de negócio

### Mercado-alvo

O Brasil tem ~1.800 laboratórios acreditados pelo CGCRE/INMETRO e estima-se entre **8.000–15.000 laboratórios não acreditados** que prestam calibração de alguma forma. Esse segundo grupo é o mercado primário — têm dor imediata, urgência real e não têm sistema, processo nem dinheiro para consultorias caras.

> Consultores de acreditação cobram R$ 15.000–50.000 para preparar um laboratório para a visita do INMETRO. O Normatiq entrega parte relevante desse valor de forma contínua por uma fração do preço. Essa comparação é o argumento de venda principal — "menos do que uma hora de consultoria, o mês inteiro."

---

### Pricing

| Plano | Preço | Limites | Diferenciais |
|-------|-------|---------|--------------|
| **Starter** | R$ 197/mês | 3 usuários, 5 padrões, 30 cal./mês | Sem portal do cliente, sem Excel engine |
| **Pro** | R$ 497/mês | Ilimitado, 20 padrões, 150 cal./mês | Portal do cliente, Excel engine, todos os módulos de qualidade |
| **Acreditação** | R$ 997/mês | Ilimitado em tudo | Tudo do Pro + suporte prioritário + checklist de prontidão CGCRE + onboarding guiado |
| **Enterprise** | Sob consulta | Ilimitado | SLA dedicado, customizações, expansão América Latina |

**Regra:** sem plano gratuito. Free trial de 30 dias com cartão cadastrado — labs gratuitos não usam com seriedade e não convertem.

---

### Go-to-market em fases

**GTM-1 · Validação (meses 1–6) — primeiros 10 labs:**
Contato direto com labs em processo de acreditação ou que perderam acreditação recentemente. Oferecer 3 meses gratuitos em troca de feedback semanal, caso de estudo e depoimento em vídeo. Fontes: lista pública CGCRE (labs com acreditação suspensa), grupos de metrologia no LinkedIn/WhatsApp, ABRALAB, RBLE.

**GTM-2 · Canal indireto (meses 4–12) — programa de consultores parceiros:**
Consultores de acreditação são o melhor canal — já têm confiança dos labs e incentivo para indicar uma ferramenta que aumenta a taxa de aprovação dos clientes deles.
- Comissão recorrente de 25% do MRR enquanto o cliente indicado permanecer ativo
- Acesso gratuito ao plano Acreditação enquanto for parceiro ativo
- Badge "Consultor Certificado Normatiq" para LinkedIn e site
- Meta: 15 consultores parceiros ativos até o mês 12

**GTM-3 · Conteúdo e comunidade (meses 3–18) — autoridade no nicho:**
Metrologia tem pouquíssimo conteúdo de qualidade em português. Quem está aprendendo sobre acreditação já é o cliente ideal.
- Newsletter semanal "Normatiq Técnico": GUM, cláusulas da 17025, budget de incerteza, erros comuns em auditorias. Meta: 2.000 assinantes em 12 meses
- YouTube/LinkedIn: vídeos curtos (3–5min) de conceitos práticos, um por semana
- Templates gratuitos (planilhas de incerteza, checklist de pré-auditoria, modelo de procedimento) como isca de captura de e-mail com régua de nutrição de 15 dias até o trial

**GTM-4 · América Latina (a partir do mês 18):**
Chile (INACAL), Colômbia (ONAC), México (EMA), Argentina (OAA). Pré-requisito: MRR Brasil > R$ 50.000 e produto com i18n em espanhol. Mesmo modelo de consultores parceiros adaptado para cada organismo local.

---

### Expansão de receita (após produto maduro)

**Marketplace de procedimentos:** quando o Normatiq tiver 50+ labs ativos, criar marketplace onde labs vendem/licenciam procedimentos validados para outros labs do mesmo segmento. Normatiq fica com 30% de cada transação — receita nova sem desenvolvimento adicional relevante. Cria efeito de rede: mais labs = mais procedimentos = mais valor para todos.

**Onboarding pago:** R$ 1.500–3.000 de setup (configuração, importação de dados, treinamento). Não é infinitamente escalável mas financia o desenvolvimento inicial e garante adoção real.

**Relatórios de benchmark do setor:** com dados agregados e anonimizados de dezenas de labs, o Normatiq terá informações únicas sobre incertezas típicas por tipo de instrumento, taxas de NC, tempos de calibração. Relatório anual pago para associações e para os próprios labs.

---

### Métricas e metas financeiras

| Métrica | Mês 6 | Mês 12 | Mês 24 |
|---------|-------|--------|--------|
| Labs pagantes | 10 | 50 | 200 |
| MRR | R$ 5.000 | R$ 25.000 | R$ 100.000 |
| Churn mensal | < 5% | < 4% | < 3% |
| Parceiros consultores | 3 | 15 | 30 |
| NPS | — | > 40 | > 50 |
| Tempo até 1º certificado emitido | < 7 dias | < 5 dias | < 3 dias |

**Marco de sustentabilidade:** 200 clientes no plano Pro a R$ 497/mês = R$ 99.400/mês de MRR (~R$ 1,2M/ano). Alcançável em 18–24 meses com o canal de consultores funcionando.

---

### Posicionamento e mensagem principal

**Para quem:** laboratórios de calibração que querem se acreditar pela ISO/IEC 17025 sem depender exclusivamente de consultores caros.

**O que entrega:** automatiza os cálculos de incerteza, organiza toda a documentação exigida pela norma e guia o laboratório passo a passo até a acreditação.

**Prova diferencial:** checklist de prontidão em tempo real que mostra exatamente o que está conforme e o que falta — nenhum concorrente entrega isso.

**Frase que converte:** *"Menos do que uma hora de consultoria. O mês inteiro."*

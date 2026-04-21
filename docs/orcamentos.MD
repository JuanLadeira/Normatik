# Normatiq — M27 · Orçamentos
> Módulo de orçamentação com conformidade ISO/IEC 17025:2017 cláusula 7.1

---

## Contexto normativo

A cláusula **7.1 — Análise Crítica de Pedidos, Propostas e Contratos** da ISO 17025 exige que o laboratório analise criticamente toda proposta comercial **antes** de comprometer-se com o cliente. Essa análise deve garantir:

- Que o laboratório tem capacidade técnica para o serviço ofertado
- Que os métodos disponíveis são adequados e atendem aos requisitos do cliente
- Que os recursos (padrões, pessoal, instalações) estão disponíveis e aptos
- Que **o símbolo de acreditação só aparece em serviços que estão dentro do escopo acreditado** — aplicar o símbolo em serviços fora do escopo é infração grave e pode resultar em suspensão da acreditação
- Que diferenças entre o que foi proposto e o que será executado são comunicadas ao cliente

O módulo de orçamento é o ponto de entrada desse controle: é onde o laboratório formaliza o que vai fazer e com qual selo.

---

## Fluxo geral do módulo

```
Catálogo de serviços
(preços padrão + escopo)
        ↓
  Novo orçamento
  (cliente + itens)
        ↓
  Análise crítica
  automática (7.1)
        ↓
  Orçamento enviado
  ao cliente (PDF)
        ↓
  Cliente aprova?
  ┌──── Sim ────┐
  ↓             ↓
Gera pedido   Revisão/
 (M06)        negociação
              ↓
           Nova versão
           do orçamento
```

---

## Histórias de usuário

---

### H78 — Catálogo de serviços com preços padrão

**Como** gestor,  
**quero** manter um catálogo de serviços do laboratório com preços padrão pré-configurados,  
**para** agilizar a criação de orçamentos sem precisar digitar valores do zero a cada vez.

**Critérios de aceite:**
- Cada serviço no catálogo tem:
  - Código interno (ex: `CAL-TEMP-001`)
  - Descrição (ex: "Calibração de termômetro digital — faixa -10 a 110°C")
  - Tipo: `calibracao` / `manutencao` / `venda_equipamento` / `consultoria` / `outro`
  - Preço padrão (unitário)
  - Unidade de cobrança: `por instrumento` / `por ponto` / `por hora` / `unitário`
  - Prazo padrão de execução (dias úteis)
  - Procedimento vinculado (quando tipo `calibracao`) — herdado do M12
  - Flag `dentro_do_escopo_acreditado`: sim/não — controla se o símbolo de acreditação pode aparecer
  - Flag `ativo`: serviços inativos não aparecem na seleção do orçamento
- Serviços filtrável por tipo e por grandeza
- Preço padrão é apenas o ponto de partida — pode ser sobrescrito item a item no orçamento

---

### H79 — Criação de orçamento

**Como** atendente, técnico ou gestor,  
**quero** criar um orçamento para um cliente selecionando serviços do catálogo,  
**para** formalizar a proposta comercial antes de qualquer execução.

**Critérios de aceite:**
- Orçamento vinculado a um cliente (obrigatório) e a um contato do cliente (opcional)
- Número gerado automaticamente com prefixo configurável (ex: `ORC-2024-0015`)
- Campos de cabeçalho:
  - Data de emissão (automática)
  - Validade do orçamento (dias — configurável, padrão 30 dias)
  - Condições de pagamento (texto livre ou template pré-configurado)
  - Observações gerais
- Cada item do orçamento tem:
  - Serviço selecionado do catálogo (pré-preenche todos os campos abaixo)
  - Descrição editável (pode detalhar além do catálogo)
  - Instrumento do cliente vinculado (quando tipo `calibracao`) — selecionado do cadastro ou descrito livremente se ainda não cadastrado
  - Quantidade
  - Preço unitário **editável** — começa com o preço padrão do catálogo, pode ser alterado livremente
  - Desconto por item (valor fixo ou percentual)
  - Preço final calculado automaticamente
  - Flag `usar_simbolo_acreditacao` por item — controlada pelas regras do H80
- Total do orçamento calculado com subtotais por tipo de serviço
- Orçamento salvo como `rascunho` até ser enviado

---

### H80 — Controle do símbolo de acreditação por item

**Como** sistema,  
**quero** controlar rigorosamente quando o símbolo de acreditação pode ou não aparecer em cada item do orçamento,  
**para** garantir conformidade com os requisitos do INMETRO e evitar uso indevido do selo.

**Critérios de aceite:**

**Regras automáticas (aplicadas ao selecionar o serviço):**
- `usar_simbolo_acreditacao` = `true` automaticamente **somente se**:
  - Serviço marcado como `dentro_do_escopo_acreditado = true` no catálogo, **E**
  - Laboratório tem acreditação ativa (data de validade da acreditação não vencida), **E**
  - O instrumento/faixa declarada no item está dentro do escopo cadastrado (M26)
- Em qualquer outra situação: `usar_simbolo_acreditacao` = `false` automaticamente

**Controle manual:**
- Usuário pode manualmente setar `usar_simbolo_acreditacao = false` em qualquer item (remover o selo voluntariamente é sempre permitido)
- Usuário **não pode** setar `usar_simbolo_acreditacao = true` em item que falhou nas regras automáticas — campo desabilitado com tooltip explicando o motivo

**Alertas visuais no orçamento:**
- Item com símbolo ativo: badge verde "Acreditado INMETRO"
- Item sem símbolo por estar fora do escopo: badge amarelo "Fora do escopo acreditado"
- Item sem símbolo por serviço não acreditado: badge cinza "Não acreditado"
- Item com símbolo ativo mas acreditação do lab vencida: badge vermelho "Atenção: acreditação vencida"

**No PDF do orçamento:**
- Símbolo de acreditação (logo CGCRE/INMETRO) aparece **apenas nos itens** com `usar_simbolo_acreditacao = true`
- Rodapé diferenciado: "Os serviços marcados com o símbolo são realizados em conformidade com a acreditação CGCRE n° [número]"
- Itens sem símbolo não têm nenhuma menção à acreditação

---

### H81 — Análise crítica automática no orçamento (cláusula 7.1)

**Como** sistema,  
**quero** executar automaticamente a análise crítica da cláusula 7.1 ao finalizar um orçamento,  
**para** identificar se o laboratório tem capacidade de atender cada item antes de enviar a proposta ao cliente.

**Critérios de aceite:**

Para cada item de calibração, o sistema verifica:

| Verificação | Resultado possível |
|-------------|-------------------|
| Procedimento vigente disponível para o serviço? | ✅ OK / ❌ Sem procedimento aprovado |
| Padrão necessário (definido no procedimento) calibrado e dentro do prazo? | ✅ OK / ⚠️ Vencendo em X dias / ❌ Vencido |
| Técnico autorizado para o procedimento disponível? | ✅ OK / ⚠️ Sem técnico autorizado |
| Instrumento dentro do escopo de acreditação (quando símbolo ativo)? | ✅ OK / ❌ Fora do escopo |
| Prazo de entrega é realista dado o backlog atual? | ✅ OK / ⚠️ Backlog elevado |

- Resultado consolidado por item: `aprovado` / `aprovado_com_ressalva` / `reprovado`
- Resultado geral do orçamento: `aprovado` / `aprovado_com_ressalvas` / `requer_atenção`
- Orçamento com item `reprovado` pode ser enviado, mas exige justificativa registrada do responsável
- Registro da análise crítica salvo no orçamento (quem aprovou, data, resultado, ressalvas)
- Este registro é a evidência documental exigida pela cláusula 7.1.1

---

### H82 — Versionamento do orçamento

**Como** atendente ou gestor,  
**quero** poder revisar um orçamento já enviado criando uma nova versão,  
**para** negociar condições sem perder o histórico das versões anteriores.

**Critérios de aceite:**
- Orçamento tem número base + versão (ex: `ORC-2024-0015 v1`, `v2`, `v3`)
- Nova versão criada a partir da versão anterior (clone editável)
- Versão anterior automaticamente marcada como `substituída`
- Apenas a versão mais recente pode ser `aprovada` ou `recusada`
- Histórico de todas as versões acessível com diff dos campos alterados
- Cliente notificado por e-mail ao receber nova versão com indicação do que mudou

---

### H83 — Envio do orçamento ao cliente

**Como** atendente ou gestor,  
**quero** enviar o orçamento ao cliente por e-mail diretamente pelo sistema,  
**para** manter o registro formal de envio e evitar uso de e-mail externo sem rastreabilidade.

**Critérios de aceite:**
- PDF gerado com o layout do orçamento (H84)
- E-mail enviado para o contato do cliente com PDF em anexo e link para visualização online
- Status do orçamento muda para `enviado` com registro de data/hora e usuário que enviou
- Registro de todos os envios (incluindo reenvios) com destinatário, data e versão enviada
- Orçamento com validade expirada não pode ser enviado — exige criação de nova versão com nova validade

---

### H84 — PDF do orçamento

**Como** atendente,  
**quero** gerar o PDF do orçamento com layout profissional e todas as informações necessárias,  
**para** entregar uma proposta com aparência corporativa ao cliente.

**Critérios de aceite:**

**Cabeçalho:**
- Logo e dados do laboratório (razão social, CNPJ, endereço, telefone, e-mail)
- Número e versão do orçamento
- Data de emissão e validade
- Dados do cliente (razão social, CNPJ, endereço, contato)

**Tabela de itens:**
- Código | Descrição | Instrumento/Tag | Qtd | Preço unitário | Desconto | Total
- Símbolo de acreditação ao lado da descrição quando aplicável (H80)
- Agrupamento opcional por tipo de serviço (calibrações / vendas / outros)

**Rodapé da tabela:**
- Subtotal por grupo
- Total geral
- Condições de pagamento
- Prazo de execução estimado

**Rodapé do documento:**
- Validade da proposta
- Observações gerais
- Nota sobre acreditação (quando houver itens acreditados)
- Campo de aceite com espaço para assinatura (versão impressa) ou link de aceite online (versão digital)

---

### H85 — Aceite do orçamento pelo cliente

**Como** cliente,  
**quero** aceitar ou recusar um orçamento diretamente pelo portal ou por link enviado por e-mail,  
**para** formalizar a aprovação sem precisar assinar e escanear documentos.

**Critérios de aceite:**
- Link de aceite enviado no e-mail do orçamento — funciona sem login (token de acesso temporário)
- Página de aceite exibe o orçamento completo com opções: "Aprovar" / "Recusar" / "Solicitar alteração"
- Aprovação registra: IP, timestamp, nome confirmado pelo cliente
- Recusa registra motivo (campo livre)
- Solicitação de alteração registra a observação e notifica o laboratório para criar nova versão (H82)
- Status do orçamento atualizado: `aprovado_pelo_cliente` / `recusado`
- Laboratório notificado por e-mail imediatamente ao cliente interagir

---

### H86 — Conversão de orçamento aprovado em pedido

**Como** atendente ou gestor,  
**quero** converter um orçamento aprovado em um pedido de serviço com um clique,  
**para** evitar retrabalho de redigitar os mesmos itens no módulo de pedidos.

**Critérios de aceite:**
- Disponível apenas para orçamentos com status `aprovado_pelo_cliente` ou `aprovado_internamente`
- Pedido criado com todos os itens do orçamento já preenchidos (preços, quantidades, descrições)
- Para itens do tipo `calibracao`: instrumento vinculado automaticamente ao item do pedido
- Orçamento marcado como `convertido` com link para o pedido gerado
- Não é possível converter o mesmo orçamento duas vezes
- Análise crítica do pedido (M16 / H52) re-executada no momento da conversão com os dados atuais (padrões podem ter vencido desde o orçamento)

---

### H87 — Relatório de orçamentos e taxa de conversão

**Como** gestor,  
**quero** visualizar relatórios sobre os orçamentos emitidos e a taxa de conversão em pedidos,  
**para** entender o desempenho comercial e identificar padrões (serviços recusados, preços fora de mercado etc.).

**Critérios de aceite:**
- Filtros: período, cliente, tipo de serviço, status, responsável
- Indicadores:
  - Total de orçamentos emitidos no período
  - Valor total orçado vs. valor convertido em pedidos
  - Taxa de aprovação (%)
  - Tempo médio entre emissão e decisão do cliente
  - Principais motivos de recusa
  - Serviços mais orçados vs. mais convertidos
  - Itens com símbolo de acreditação vs. sem símbolo (monitoramento de uso do selo)
- Exportável em CSV

---

## Modelo de dados do módulo

```
Quotation
├── id
├── tenant_id
├── client_id
├── number                    -- ORC-2024-0015
├── version                   -- 1, 2, 3...
├── status                    -- rascunho | enviado | aprovado_pelo_cliente |
│                                aprovado_internamente | recusado | substituído | convertido | expirado
├── issued_at
├── valid_until
├── payment_terms
├── notes
├── critical_review_result    -- aprovado | aprovado_com_ressalvas | requer_atenção
├── critical_review_by        -- user_id
├── critical_review_at
├── converted_to_order_id     -- FK para Order quando convertido
│
├── items[] → QuotationItem
│   ├── id
│   ├── quotation_id
│   ├── catalog_service_id    -- FK para ServiceCatalog (pode ser null se serviço avulso)
│   ├── service_type          -- calibracao | manutencao | venda | consultoria | outro
│   ├── description
│   ├── instrument_id         -- FK para Instrument (quando calibracao)
│   ├── instrument_description -- para instrumentos ainda não cadastrados
│   ├── quantity
│   ├── unit_price            -- editável, começa com o padrão do catálogo
│   ├── discount_type         -- percentual | fixo
│   ├── discount_value
│   ├── total_price           -- calculado
│   ├── delivery_days
│   ├── use_accreditation_symbol  -- bool, controlado pelas regras do H80
│   ├── accreditation_block_reason -- motivo quando símbolo bloqueado
│   └── critical_review_result    -- por item
│
└── events[] → QuotationEvent
    ├── id
    ├── quotation_id
    ├── event_type  -- criado | enviado | aprovado | recusado | alteracao_solicitada | convertido
    ├── performed_by
    ├── performed_at
    └── notes

ServiceCatalog
├── id
├── tenant_id
├── code
├── description
├── service_type
├── unit_price
├── billing_unit
├── delivery_days
├── procedure_id              -- FK para Procedure (M12)
├── within_accredited_scope   -- bool
└── active
```

---

## Relação com outros módulos

| Módulo | Relação |
|--------|---------|
| M03 · Clientes e Instrumentos | Orçamento vinculado a cliente; instrumento selecionado por item |
| M06 · Pedidos | Orçamento aprovado → gera pedido automaticamente (H86) |
| M12 · Procedimentos | Serviço do catálogo vinculado a procedimento; análise crítica verifica procedimento vigente |
| M16 · Análise Crítica de Contratos | Orçamento executa análise crítica (7.1) — é o ponto de entrada do processo |
| M26 · Escopo de Acreditação | Verificação automática se instrumento/faixa está no escopo para liberar o símbolo |
| M10 · Portal do Cliente | Cliente aprova ou recusa pelo portal/link sem precisar fazer login completo |

---

## Conformidade ISO 17025 — cláusula 7.1

| Requisito da norma | Como o módulo atende |
|-------------------|---------------------|
| 7.1.1 — Análise crítica antes de aceitar o trabalho | H81 executa checklist automático ao fechar o orçamento |
| 7.1.2 — Garantia de capacidade e recursos | Checklist verifica procedimento, padrão, pessoal e escopo |
| 7.1.3 — Comunicação de desvios ao cliente | Ressalvas da análise crítica incluídas no PDF e no e-mail (H83) |
| 7.1.4 — Registro da análise crítica | Resultado salvo com data, responsável e evidências (H81) |
| 7.1.5 — Controle de alterações de contrato | Versionamento com diff e notificação ao cliente (H82) |
| Uso correto do símbolo de acreditação | Regras automáticas por item com rastreabilidade (H80) |

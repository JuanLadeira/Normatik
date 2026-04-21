# Normatiq — Revisões e Adições ao Planejamento

---

## Parte 1 — Orçamento Flexível (revisão do M27)

### Problema identificado

O vendedor que cria o orçamento frequentemente **não tem acesso aos dados do instrumento** no momento da proposta. Ele sabe apenas:
- Que tipo de serviço o cliente quer
- A quantidade aproximada de instrumentos
- A categoria/grandeza (termômetros, manômetros etc.)

Vincular o orçamento a instrumentos cadastrados nessa etapa seria um bloqueio desnecessário ao fluxo comercial.

### Revisão do modelo de item do orçamento

O item do orçamento passa a ter dois modos:

**Modo simples (sem instrumento vinculado)** — para uso pelo vendedor:
- Tipo de serviço + descrição livre
- Quantidade
- Preço unitário (do catálogo ou manual)
- Prazo estimado

**Modo detalhado (com instrumento vinculado)** — preenchido depois, ao gerar o pedido:
- Todos os campos acima +
- Instrumento do cliente selecionado do cadastro
- Procedimento de calibração vinculado

O item pode começar no modo simples e ser detalhado em qualquer momento antes da execução.

---

### H79 — revisada: Criação de orçamento flexível

**Como** vendedor ou atendente,  
**quero** criar um orçamento informando apenas tipo de serviço, quantidade e valor, sem precisar vincular instrumentos específicos,  
**para** fechar propostas comerciais com agilidade mesmo quando não tenho acesso ao cadastro técnico do cliente.

**Critérios de aceite:**
- Campo `instrument_id` é **opcional** no item do orçamento
- Quando não vinculado: campo `item_description` livre (ex: "Calibração de termômetros de máx/mín — aprox. 8 unidades")
- Quantidade pode ser informada com flag `is_estimated` para indicar que é uma estimativa
- Análise crítica automática (H81) roda em modo reduzido quando sem instrumento: verifica apenas se o laboratório tem procedimento e padrão para aquele tipo de serviço

---

### H86 — revisada: Conversão de orçamento em pedido com rastreamento de produção

**Como** gestor ou atendente,  
**quero** converter um orçamento aprovado em pedido e, ao longo da execução, rastrear se o que foi produzido corresponde ao que foi orçado,  
**para** ter controle completo entre o que foi vendido e o que foi entregue.

**Critérios de aceite:**

**Na conversão (orçamento → pedido):**
- Para cada item do orçamento é criado um item de pedido correspondente
- Item de pedido herda: serviço, descrição, quantidade orçada, preço aprovado
- Campo `quoted_quantity` no item do pedido registra a quantidade aprovada no orçamento (imutável após conversão)
- Campo `produced_quantity` começa em 0 e é incrementado conforme calibrações são concluídas
- Itens sem instrumento vinculado no orçamento precisam ter o instrumento informado no pedido antes de iniciar a calibração
- O preço do item do pedido **não pode ser alterado** — é o que foi aprovado no orçamento

**Durante a execução:**
- Cada calibração concluída vinculada a um item de pedido incrementa `produced_quantity`
- Status calculado por item:
  - `em_andamento` — `produced_quantity < quoted_quantity`
  - `concluído` — `produced_quantity == quoted_quantity`
  - `excedido` — `produced_quantity > quoted_quantity` (alerta automático — requer aprovação)

**No encerramento do pedido:**
- Relatório de fechamento mostra por item: quantidade orçada × quantidade produzida × desvio
- Pedido só pode ser marcado como `concluído` se todos os itens estiverem `concluído` ou com desvio justificado
- Desvio com justificativa registrado cria automaticamente um `contract_amendment` (H53) para rastreabilidade

**Alertas:**
- Produção excedendo o orçado: notificação ao gestor antes de continuar
- Produção abaixo do orçado próximo ao prazo: alerta ao atendente responsável

---

### Modelo de dados revisado

```
QuotationItem (revisado)
├── id
├── quotation_id
├── catalog_service_id        -- opcional
├── service_type
├── description               -- sempre livre, mesmo quando catálogo vinculado
├── instrument_id             -- OPCIONAL na criação do orçamento
├── instrument_description    -- campo livre quando sem instrument_id
├── quantity
├── is_quantity_estimated     -- bool: estimativa ou quantidade firme
├── unit_price
├── discount_type / discount_value
├── total_price               -- calculado
├── delivery_days
├── use_accreditation_symbol
└── critical_review_result

OrderItem (revisado)
├── id
├── order_id
├── quotation_item_id         -- FK: rastreabilidade total até o orçamento
├── service_type
├── description
├── instrument_id             -- obrigatório antes de iniciar calibração
├── quoted_quantity           -- imutável: vem do orçamento aprovado
├── produced_quantity         -- incrementado conforme execução
├── unit_price                -- imutável: vem do orçamento aprovado
├── status                    -- em_andamento | concluído | excedido | cancelado
└── calibrations[]            -- calibrações vinculadas a este item
```

---

---

## Parte 2 — Motor de Cálculo de Incerteza em Excel (M28)

### Visão geral

O sistema adota uma arquitetura **híbrida** de cálculo de incerteza:

1. **Servidor calcula** os resultados e os persiste no banco (motor GUM existente — M04)
2. **Sistema gera** uma planilha Excel com as fórmulas injetadas nas células corretas
3. **Técnico pode** baixar, revisar e eventualmente modificar os cálculos na planilha
4. **Técnico pode** reenviar a planilha modificada e o sistema lê os resultados das células definidas pelo contrato da classe
5. Isso cria um fluxo de **conferência e auditoria** independente do motor interno

**Por que gerar planilhas em vez de apenas mostrar na tela?**
- Planilhas são o formato nativo de trabalho de laboratórios metrológicos
- Auditores da ISO 17025 aceitam e entendem planilhas como evidência técnica
- O técnico pode adicionar colunas, gráficos e análises extras sem afetar o sistema
- Laboratórios que já têm seus próprios modelos podem comparar resultado a resultado
- O upload de volta fecha o ciclo: o que entrou no certificado é o que o técnico verificou

---

### Arquitetura da classe de planilha

```
BaseCalibrationWorkbook          ← classe pai: comportamentos comuns
    │
    ├── ThermometerWorkbook       ← calibração de termômetros
    ├── PressureGaugeWorkbook     ← calibração de manômetros
    ├── BalanceWorkbook           ← calibração de balanças/massas
    ├── CaliperWorkbook           ← calibração de paquímetros/micrômetros
    ├── ElectricalWorkbook        ← multímetros, mV, mA, Ohm
    ├── VolumetricWorkbook        ← vidraria volumétrica, bureta
    ├── HygrometerWorkbook        ← calibração de higrômetros
    └── (extensível por herança)
```

**Regra fundamental:** o sistema nunca faz o contrário sem o contrato estar definido. Cada classe define exatamente quais células são de entrada e quais são de saída — isso garante reprodutibilidade total na leitura do upload.

---

### Estrutura da planilha gerada

Cada workbook gerado tem no mínimo estas abas:

| Aba | Conteúdo |
|-----|----------|
| `Formulário` | Dados de entrada: instrumento, padrão, condições, operador |
| `Ponto_N` | Uma aba por ponto de calibração com as leituras e cálculos |
| `Resumo` | Tabela consolidada de todos os pontos: erro, correção, U, k |
| `Budget_N` | Budget de incerteza detalhado por ponto (opcional, ativado por configuração) |
| `Metadados` | Aba oculta com contrato da classe: versão, células de entrada/saída, hash |

---

### H88 — BaseCalibrationWorkbook: comportamentos da classe pai

**Como** sistema,  
**quero** que a classe base implemente todos os comportamentos comuns às planilhas de calibração,  
**para** que as subclasses precisem apenas definir o que é específico ao seu tipo de instrumento.

**Responsabilidades da classe base:**

**Construção da aba `Formulário`:**
- Cabeçalho com logo e nome do laboratório (injetado via imagem)
- Identificação do instrumento (tag, fabricante, modelo, série, faixa, resolução)
- Identificação do padrão (tag, certificado, U do certificado, k do certificado)
- Condições ambientais (temperatura, umidade)
- Operador, data de calibração, método (procedimento)
- Próxima data de calibração

**Construção de cada aba `Ponto_N`:**
- Seção de leituras: tabela n × 2 (valor indicado | valor do padrão) com células editáveis
- Fórmulas Excel injetadas nas células de resultado:
  - Média das indicações: `=AVERAGE(B5:B{n+4})`
  - Desvio padrão: `=STDEV(B5:B{n+4})`
  - Incerteza tipo A: `=STDEV(B5:B{n+4})/SQRT(COUNT(B5:B{n+4}))`
  - Incerteza tipo B padrão: `=Formulário!$U_cert / Formulário!$k_cert`
  - Incerteza tipo B resolução: `=(Formulário!$resolução/2)/SQRT(3)`
  - Incerteza combinada: `=SQRT(u_A^2 + u_B1^2 + u_B2^2 + ...)`
  - Incerteza expandida: `=k * u_c`
  - Erro: `=média_indicação - valor_convencional`
  - Correção: `= -erro`
- Componentes adicionais de incerteza tipo B: linhas extras inseridas dinamicamente conforme componentes configuradas
- Formatação condicional: célula vermelha se erro > tolerância especificada

**Construção da aba `Resumo`:**
- Tabela consolidada referenciando os resultados de cada aba `Ponto_N`
- Colunas: Ponto | Valor nominal | Indicação média | Erro | Correção | u_A | u_B | u_c | U | k | Nível de confiança
- Formatação profissional com cores do laboratório
- Gráfico de erros × pontos gerado automaticamente

**Aba `Metadados` (oculta, para leitura no upload):**
```json
{
  "class": "ThermometerWorkbook",
  "version": "1.2.0",
  "generated_at": "2024-03-15T10:30:00Z",
  "calibration_id": "uuid-aqui",
  "contract": {
    "inputs": {
      "Ponto_1.readings": "B5:B{n}",
      "Ponto_1.standard_values": "C5:C{n}"
    },
    "outputs": {
      "Ponto_1.mean": "F5",
      "Ponto_1.error": "F8",
      "Ponto_1.correction": "F9",
      "Ponto_1.u_a": "F12",
      "Ponto_1.u_c": "F16",
      "Ponto_1.U": "F18",
      "Ponto_1.k": "F19"
    }
  }
}
```

**Critérios de aceite:**
- Planilha gerada em < 3s para calibrações com até 20 pontos e 10 leituras por ponto
- Fórmulas realmente calculáveis no Excel e LibreOffice Calc (sem macros VBA — apenas fórmulas nativas)
- Planilha protegida: células de fórmula bloqueadas para edição acidental; células de entrada destacadas em amarelo; proteção removível com senha que o técnico pode retirar se quiser editar
- Gerada com `openpyxl` — sem dependência de Excel instalado no servidor

---

### H89 — Subclasses específicas por tipo de instrumento

**Como** sistema,  
**quero** que cada tipo de instrumento tenha sua subclasse com comportamentos específicos,  
**para** que a planilha gerada seja adequada à natureza metrológica de cada grandeza.

**Exemplo — ThermometerWorkbook:**
- Aba de leituras com colunas: Leitura # | T indicada (°C) | T padrão (°C) | Diferença
- Gráfico de perfil de temperatura (indicado vs padrão ao longo dos pontos)
- Campo de histerese: leituras em subida e descida de temperatura
- Cálculo de histerese como componente adicional de incerteza tipo B
- Coluna de correção com sinal correto para cada faixa

**Exemplo — BalanceWorkbook:**
- Suporte a múltiplas cargas (pontos de calibração)
- Cálculo de erros de indicação, repetibilidade e excentricidade
- Incerteza por resolução da balança
- Incerteza das massas padrão como tipo B
- Gráfico de erros vs carga

**Exemplo — PressureGaugeWorkbook:**
- Leituras em subida e descida de pressão (histerese)
- Cálculo de histerese e erro de span
- Campo para pressão atmosférica local (influência na calibração de manômetros relativos)

**Regras para criar uma subclasse:**
```python
class ThermometerWorkbook(BaseCalibrationWorkbook):
    instrument_type = "termometro"
    version = "1.0.0"

    # Define colunas extras da aba de leituras
    extra_reading_columns = [
        {"header": "T subida (°C)", "col": "D"},
        {"header": "T descida (°C)", "col": "E"},
    ]

    # Define componentes adicionais de incerteza tipo B
    extra_uncertainty_components = [
        {"name": "Histerese", "source_cell": "E_histerese", "distribution": "retangular"}
    ]

    # Define fórmulas extras específicas do termômetro
    def inject_extra_formulas(self, ws, point_index):
        # histerese = max(subida) - min(descida) / 2
        ws["E_histerese"] = f"=(MAX(D5:D{n})-MIN(E5:E{n}))/2"

    # Define contrato de células de saída (merge com o base)
    extra_output_contract = {
        "hysteresis": "E_histerese"
    }
```

---

### H90 — Geração e download da planilha

**Como** técnico,  
**quero** gerar e baixar a planilha de cálculo de incerteza de uma calibração em qualquer momento,  
**para** revisar os cálculos, adicionar análises e usar como documento de trabalho.

**Critérios de aceite:**
- Disponível para calibrações com status `em_andamento` ou `concluída`
- Botão "Gerar planilha de cálculo" na tela da calibração
- Sistema identifica automaticamente qual subclasse usar pelo tipo do instrumento
- Se o tipo de instrumento não tiver subclasse específica: usa `BaseCalibrationWorkbook` com aviso ao técnico
- Planilha gerada com os dados já inseridos no sistema (leituras, valores do padrão, condições)
- Se nenhum dado foi inserido ainda: planilha gerada com estrutura vazia (para preenchimento externo)
- Download imediato do arquivo `.xlsx`
- Registro de que a planilha foi gerada (quem gerou, quando, versão da classe) vinculado à calibração

---

### H91 — Upload da planilha preenchida/modificada

**Como** técnico,  
**quero** fazer upload de uma planilha preenchida ou modificada para que o sistema leia os resultados,  
**para** usar os valores calculados na planilha (que podem ter sido ajustados) como base do certificado.

**Critérios de aceite:**

**Leitura do arquivo:**
- Sistema lê a aba `Metadados` para identificar a classe e o contrato de células
- Usando o contrato, lê exatamente as células de saída definidas (nunca adivinha posições)
- Se a aba `Metadados` estiver ausente ou corrompida: erro com mensagem clara ("Planilha não reconhecida — use a planilha gerada pelo sistema")
- Se a versão da classe mudou desde a geração: aviso ao técnico com diff das mudanças

**Validações:**
- Valores lidos são comparados com os calculados pelo motor interno do servidor
- Se divergência > threshold configurável (ex: 5%): alerta destacado ao técnico antes de confirmar
- Técnico pode confirmar mesmo com divergência, mas precisa justificar (campo obrigatório)
- Se divergência < threshold: aceito automaticamente

**Resultado do upload:**
- Valores da planilha sobrescrevem os valores calculados pelo servidor nos campos correspondentes
- Registro de auditoria: "Resultados substituídos por planilha — motivo: [justificativa]"
- Planilha armazenada no S3 vinculada à calibração (evidência documental permanente)
- Técnico pode reverter para os valores calculados pelo servidor a qualquer momento (enquanto calibração não estiver concluída)

**O que NÃO pode ser alterado via upload:**
- Leituras brutas (measurements) — essas são imutáveis após inserção
- Dados do instrumento e do padrão
- Condições ambientais

---

### H92 — Registro de qual fonte foi usada nos resultados

**Como** sistema,  
**quero** registrar claramente em cada ponto de calibração se os resultados vieram do motor interno ou de uma planilha enviada pelo técnico,  
**para** garantir rastreabilidade total e transparência no certificado.

**Critérios de aceite:**
- Campo `result_source` no `CalibrationPoint`: `system_calculated` | `spreadsheet_upload`
- Se `spreadsheet_upload`: campos adicionais com referência ao arquivo e à justificativa
- Certificado PDF indica nos rodapé técnico qual foi a fonte dos cálculos:
  - Motor interno: "Incertezas calculadas pelo sistema Normatiq v{versão}"
  - Planilha: "Incertezas calculadas em planilha de trabalho — arquivo disponível para consulta"
- Auditores podem solicitar o arquivo da planilha pelo portal do laboratório

---

### Estrutura de classes Python (referência de implementação)

```
app/
└── domains/
    └── calibrations/
        ├── workbooks/
        │   ├── __init__.py
        │   ├── base.py                  ← BaseCalibrationWorkbook
        │   ├── thermometer.py           ← ThermometerWorkbook(Base)
        │   ├── pressure_gauge.py        ← PressureGaugeWorkbook(Base)
        │   ├── balance.py               ← BalanceWorkbook(Base)
        │   ├── caliper.py               ← CaliperWorkbook(Base)
        │   ├── electrical.py            ← ElectricalWorkbook(Base)
        │   ├── volumetric.py            ← VolumetricWorkbook(Base)
        │   └── registry.py              ← mapa instrument_type → classe
        ├── workbook_service.py          ← geração e leitura de planilhas
        └── workbook_reader.py           ← parsing do upload com contrato
```

**Registry (sem if/elif):**
```python
# registry.py
WORKBOOK_REGISTRY: dict[str, type[BaseCalibrationWorkbook]] = {
    "termometro":       ThermometerWorkbook,
    "manometro":        PressureGaugeWorkbook,
    "balanca":          BalanceWorkbook,
    "paquimetro":       CaliperWorkbook,
    "multimetro":       ElectricalWorkbook,
    "vidraria":         VolumetricWorkbook,
}

def get_workbook_class(instrument_type: str) -> type[BaseCalibrationWorkbook]:
    return WORKBOOK_REGISTRY.get(instrument_type, BaseCalibrationWorkbook)
```

---

### H93 — Geração de planilha em branco como template

**Como** técnico,  
**quero** gerar uma planilha em branco para um tipo de instrumento mesmo antes de ter uma calibração aberta,  
**para** usar como modelo de trabalho em campo ou mostrar ao cliente o formato dos cálculos.

**Critérios de aceite:**
- Endpoint: `GET /api/v1/workbooks/template/{instrument_type}`
- Parâmetros: número de pontos desejados, número de leituras por ponto
- Planilha gerada sem calibration_id na aba de metadados (marcada como `template`)
- Template não pode ser usado no upload — precisa ser convertido em calibração real primeiro
- Útil para treinamento de novos técnicos e para apresentações ao cliente

---

## Modelo de dados revisado — CalibrationPoint

```
CalibrationPoint (revisado)
├── id
├── calibration_id
├── nominal_value
├── unit
├── order_index
│
├── -- resultados (calculados ou vindos de planilha) --
├── mean_indication
├── error
├── correction
├── uncertainty_a
├── uncertainty_b_standard
├── uncertainty_b_resolution
├── combined_uncertainty
├── expanded_uncertainty
├── coverage_factor
├── confidence_level
│
├── -- rastreabilidade da fonte --
├── result_source              -- system_calculated | spreadsheet_upload
├── spreadsheet_file_url       -- S3 URL quando result_source = spreadsheet_upload
├── spreadsheet_class_version  -- versão da classe usada na geração
├── spreadsheet_override_reason -- justificativa quando divergência > threshold
│
└── measurements[]
```

---

## Resumo das histórias adicionadas

| ID | Título | Módulo |
|----|--------|--------|
| H79 rev. | Orçamento flexível sem instrumento vinculado | M27 |
| H86 rev. | Pedido rastreia quantidade orçada vs. produzida | M27 |
| H88 | BaseCalibrationWorkbook — classe base | M28 |
| H89 | Subclasses por tipo de instrumento | M28 |
| H90 | Geração e download da planilha | M28 |
| H91 | Upload da planilha modificada | M28 |
| H92 | Rastreabilidade da fonte dos resultados | M28 |
| H93 | Template de planilha em branco | M28 |

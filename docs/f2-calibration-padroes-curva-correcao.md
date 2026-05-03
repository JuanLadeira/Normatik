# F2 · Certificado de Calibração de Padrões e Curva de Correção

> SaaS Normatiq · FastAPI + Flutter  
> Branch: `feature/f2-frontend-implementation`  
> Criado: 2026-05-03

---

## 1. Contexto e motivação

Padrões de laboratório precisam ser periodicamente calibrados por laboratórios externos. O certificado resultante traz os resultados das medições (erro por ponto) e a incerteza expandida (U) com fator de abrangência (k). Com esses dados, o sistema deve:

1. Armazenar o certificado PDF e os metadados de rastreabilidade
2. Permitir o registro dos pontos de medição do certificado
3. Calcular a curva de correção via regressão (linear ou polinomial)
4. Exigir aprovação da curva por coordenador ou metrologista signatário antes de ativá-la
5. Usar a curva e a incerteza do padrão (`u_padrão = U/k`) em calibrações de cliente

---

## 2. Modelo de dados

### 2.1 `FormularioMedicaoTemplate`

Template configurável por tipo de instrumento. Definido uma vez, reutilizado em todos os certificados do mesmo tipo, mas pode ser sobrescrito por instância.

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | UUID | PK |
| `tipo_instrumento_id` | FK | Tipo de instrumento ao qual se aplica |
| `nome` | String | Nome descritivo do template |
| `campos_pontos` | JSONB | Definição das colunas da tabela de medição |
| `tipo_regressao_default` | Enum | `linear` \| `polinomial` |
| `grau_polinomio_default` | Int | Default 1 |
| `criado_por` | FK User | |
| `criado_em` / `atualizado_em` | DateTime | |

**Exemplo de `campos_pontos`:**
```json
{
  "colunas": [
    { "nome": "valor_nominal", "label": "Padrão (°C)", "tipo": "float", "calculado": false },
    { "nome": "leitura_1",     "label": "Leitura 1",   "tipo": "float", "calculado": false },
    { "nome": "leitura_2",     "label": "Leitura 2",   "tipo": "float", "calculado": false },
    { "nome": "media",         "label": "Média",        "tipo": "float", "calculado": "avg(leitura_1, leitura_2)" },
    { "nome": "erro",          "label": "Erro",         "tipo": "float", "calculado": "media - valor_nominal" }
  ],
  "campo_regressao_x": "valor_nominal",
  "campo_regressao_y": "erro"
}
```

---

### 2.2 `CertificadoCalibracaoPadrao`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | UUID | PK |
| `padrao_id` | FK | Padrão do laboratório ao qual pertence |
| `numero_certificado` | String (unique) | Número do certificado externo |
| `laboratorio_calibrador` | String | Nome do laboratório que emitiu |
| `data_emissao` | Date | |
| `data_validade` | Date | |
| `arquivo_pdf` | String | Path/URL do arquivo |
| `U_expandida` | Float | Incerteza expandida do certificado |
| `k_abrangencia` | Float | Fator de abrangência do certificado |
| `u_padrao` | Float | Calculado: `U/k`, gravado para auditoria |
| `formulario_template_id` | FK (nullable) | Template de origem (rastreabilidade) |
| `formulario_config` | JSONB | Snapshot editável do template no momento da criação |
| `status` | Enum | `rascunho` \| `aguardando_aprovacao_curva` \| `ativo` \| `expirado` |
| `criado_por` / `criado_em` | | |

---

### 2.3 `PontoMedicaoCertificado`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | UUID | PK |
| `certificado_id` | FK | |
| `ordem` | Int | Sequência do ponto na tabela |
| `valores` | JSONB | `{ "valor_nominal": 0.0, "leitura_1": 0.01, ... }` |

Os campos calculados (média, erro) são derivados no backend na leitura, conforme definição em `formulario_config`.

---

### 2.4 `CurvaCorrecao`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | UUID | PK |
| `certificado_id` | FK | |
| `tipo` | Enum | `linear` \| `polinomial` |
| `grau` | Int | 1 para linear, n para polinomial |
| `coeficientes` | JSONB | `[a0, a1, a2...]` → `f(x) = a0 + a1·x + a2·x²` |
| `r_quadrado` | Float | Qualidade do ajuste |
| `pontos_curva` | JSONB | `[{x, y_ajustado}]` pré-calculados (~100 pontos) para o gráfico |
| `status` | Enum | `sugerida` \| `aprovada` \| `rejeitada` |
| `aprovada_por` | FK User (nullable) | Coordenador ou metrologista signatário |
| `aprovada_em` | DateTime (nullable) | |
| `observacoes_aprovacao` | Text (nullable) | |
| `criado_em` | DateTime | |

---

### 2.5 `UsoDePatrao` (na calibração de cliente)

Garante rastreabilidade histórica: calibrações antigas ficam vinculadas à curva e à incerteza do padrão que estava ativa no momento.

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | UUID | PK |
| `calibracao_cliente_id` | FK | |
| `padrao_id` | FK | |
| `curva_correcao_id` | FK | Snapshot da curva ativa na época |
| `u_padrao_snapshot` | Float | Snapshot de `u_padrao` na época |

---

## 3. Fluxo completo

```
1. Técnico abre tela do Padrão → cria novo CertificadoCalibracaoPadrao
   ├── seleciona TipoInstrumento → sistema carrega template e faz snapshot em formulario_config
   ├── preenche metadados (número, lab, datas, U, k)
   ├── faz upload do PDF
   └── sistema calcula e salva u_padrao = U/k

2. Técnico preenche tabela de pontos
   ├── formulário dinâmico renderizado pelo formulario_config
   └── campos calculados derivados em tempo real no frontend

3. Técnico clica "Analisar Curva"
   └── POST /certificados/{id}/analisar
       ├── backend lê pontos + formulario_config (campo_regressao_x/y)
       ├── roda numpy.polyfit(x, y, grau)
       ├── calcula R²
       ├── gera ~100 pontos da curva para o gráfico
       └── salva CurvaCorrecao com status "sugerida"

4. Técnico vê gráfico (pontos reais + curva ajustada) + R² + coeficientes
   └── encaminha para aprovação

5. Coordenador ou Metrologista signatário revisa e:
   ├── POST /curvas/{id}/aprovar  → status = "aprovada", CertificadoCalibracao = "ativo"
   └── POST /curvas/{id}/rejeitar → status = "rejeitada", observação obrigatória

6. Padrão com curva aprovada é usado em calibração de cliente:
   ├── sistema aplica f(x) = a0 + a1·x + ... em cada ponto de medição
   ├── u_padrao entra no orçamento de incerteza (fonte: "Padrão <nome>")
   ├── u_combinada = √(Σui²)
   └── U_cliente = k_novo · u_combinada (k calculado pela distribuição t de Student)
```

---

## 4. API endpoints

| Método | Rota | Descrição | Papel mínimo |
|---|---|---|---|
| GET | `/templates-formulario` | Lista templates por tipo de instrumento | Técnico |
| POST | `/templates-formulario` | Cria template | Coordenador |
| PUT | `/templates-formulario/{id}` | Atualiza template | Coordenador |
| GET | `/padroes/{id}/certificados` | Lista certificados do padrão | Técnico |
| POST | `/padroes/{id}/certificados` | Cria certificado | Técnico |
| PUT | `/certificados/{id}` | Atualiza certificado (rascunho) | Técnico |
| POST | `/certificados/{id}/upload-pdf` | Faz upload do PDF | Técnico |
| GET | `/certificados/{id}/pontos` | Lista pontos | Técnico |
| PUT | `/certificados/{id}/pontos` | Salva/substitui pontos (batch) | Técnico |
| POST | `/certificados/{id}/analisar` | Roda regressão → retorna curva sugerida | Técnico |
| POST | `/curvas/{id}/aprovar` | Aprova curva | Coordenador / Metrologista |
| POST | `/curvas/{id}/rejeitar` | Rejeita curva com observação | Coordenador / Metrologista |
| GET | `/certificados/{id}/curva-ativa` | Retorna curva aprovada atual | Técnico |

---

## 5. Telas (Flutter)

### 5.1 Admin — Template de Formulário
- Listagem de templates por tipo de instrumento
- Editor do `campos_pontos` (adicionar/remover/reordenar colunas, definir fórmulas de cálculo)
- Seleção de tipo de regressão default e grau

### 5.2 Certificado de Calibração do Padrão
- Header: metadados + status (chip colorido)
- Upload do PDF com preview
- Campos U, k com cálculo automático de `u_padrão`
- Tabela dinâmica de pontos (colunas geradas pelo `formulario_config`)
- Botão "Analisar Curva" → navega para tela de análise

### 5.3 Análise da Curva
- Gráfico de dispersão (pontos reais) + linha de regressão (pontos_curva)
- Exibição de coeficientes, grau e R²
- Selector de tipo/grau de regressão para re-analisar
- Botão "Enviar para Aprovação"
- (Para coordenador/metrologista) Botões "Aprovar" / "Rejeitar" + campo de observação

---

## 6. Motor de regressão (backend)

```python
import numpy as np

def calcular_curva(pontos: list[dict], campo_x: str, campo_y: str, grau: int):
    x = np.array([p[campo_x] for p in pontos])
    y = np.array([p[campo_y] for p in pontos])

    coeficientes = np.polyfit(x, y, grau)  # ordem decrescente → inverter para [a0, a1, ...]
    polinomio = np.poly1d(coeficientes)

    # R²
    y_pred = polinomio(x)
    ss_res = np.sum((y - y_pred) ** 2)
    ss_tot = np.sum((y - np.mean(y)) ** 2)
    r_quadrado = 1 - (ss_res / ss_tot) if ss_tot != 0 else 1.0

    # Pontos da curva para o gráfico
    x_curva = np.linspace(x.min(), x.max(), 100)
    pontos_curva = [{"x": float(xi), "y_ajustado": float(polinomio(xi))} for xi in x_curva]

    return {
        "coeficientes": coeficientes[::-1].tolist(),  # [a0, a1, a2...]
        "r_quadrado": float(r_quadrado),
        "pontos_curva": pontos_curva,
    }
```

---

## 7. Propagação de incerteza do padrão

Na calibração de cliente, a contribuição do padrão é:

```
u_padrão = U_certificado / k_certificado   (gravado em u_padrao_snapshot)

u_combinada = √(u_resolução² + u_repetibilidade² + u_padrão² + ...)

U_cliente = k_novo × u_combinada
```

onde `k_novo` é calculado pela distribuição t de Student com os graus de liberdade efetivos (Welch-Satterthwaite).

---

## 8. Plano de implementação

### Backend
- [ ] Migration: `formularios_medicao_template`
- [ ] Migration: `certificados_calibracao_padrao`
- [ ] Migration: `pontos_medicao_certificado`
- [ ] Migration: `curvas_correcao`
- [ ] Migration: `uso_de_padrao` (relação com calibração de cliente)
- [ ] Models SQLAlchemy
- [ ] Schemas Pydantic (request/response)
- [ ] Repository: CRUD para todas as entidades
- [ ] Service: cálculo de campos derivados dos pontos
- [ ] Service: motor de regressão (`calcular_curva`)
- [ ] Service: lógica de aprovação (validação de papel)
- [ ] Service: propagação de incerteza (uso em calibração de cliente)
- [ ] Router: todos os endpoints da seção 4

### Frontend
- [ ] Tela: admin de templates de formulário
- [ ] Tela: criação/edição de certificado (header + upload PDF + U/k)
- [ ] Widget: tabela dinâmica de pontos (colunas por `formulario_config`)
- [ ] Tela: análise da curva (gráfico + coeficientes + aprovação)
- [ ] Integração: uso do padrão na calibração de cliente (aplicar correção + budget)

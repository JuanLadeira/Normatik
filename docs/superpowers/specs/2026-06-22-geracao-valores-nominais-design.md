# Geração automática de valores nominais nos pontos de medição

> Normatiq · F2.1 · Branch `feature/f2-1-certificado-padrao`
> Criado: 2026-06-22

## 1. Problema

Ao registrar os pontos de medição de um certificado de padrão, o usuário
preenche manualmente o valor nominal (coluna de referência / Eixo X) de cada
ponto. É repetitivo e propenso a erro. Queremos gerar esses valores
automaticamente a partir da faixa de medição do padrão e da quantidade de
pontos definida no template, mantendo tudo editável depois.

## 2. Decisões de design (aprovadas)

- **Origem da faixa:** vem do padrão/instrumento sendo calibrado, via o modelo
  já existente `FaixaMedicao` (`valor_min`, `valor_max`, `unidade`, `posicao`).
  Um equipamento pode ter várias faixas.
- **Distribuição:** N pontos igualmente espaçados, inclusive as duas pontas:
  `valor_nominal[i] = valor_min + i·(valor_max − valor_min)/(N − 1)`, para
  `i = 0..N−1`. Respeita o `valor_min` real da faixa.
  - Ex: faixa 10–100, N=4 → 10, 40, 70, 100.
  - Ex: faixa 0–150, N=4 → 0, 50, 100, 150.
  - N=1 → único ponto = `valor_max`.
- **Quantidade (N):** pré-preenchida com `quantidade_pontos_default` do template;
  editável no momento de gerar. Reusa campo existente — sem novo campo no template.
- **Coluna alvo:** a definida como `campo_regressao_x` (Eixo X) do template. Se
  ausente, a primeira coluna de entrada (`calculado == false`).
- **Sobrescrever:** se já houver pontos com qualquer valor preenchido, abre
  diálogo de confirmação antes de substituir. Caso contrário, gera direto.
- **Editável:** após gerar, todas as células permanecem editáveis; botões de
  adicionar/remover ponto continuam funcionando. Cálculos derivados (média/erro)
  já são recalculados ao vivo (fix anterior em `pontos_medicao_widget.dart`).

## 3. Componentes

### 3.1 Backend
Nenhuma mudança. A geração é client-side. As faixas do padrão já são retornadas
pelo `GET /api/.../padroes/{id}` (consumido hoje em `padrao_detail_page` /
`padrao_form_page`). O salvamento dos pontos é inalterado — o backend re-deriva
as colunas calculadas em `_derivar_campos`.

### 3.2 `certificado_detail_page.dart`
- Já possui `padraoId`. Buscar o padrão (faixas inclusas) ao montar a página de
  pontos e repassar `List<FaixaMedicaoModel> faixas` ao `PontosMedicaoWidget`.
- Reusar o `FaixaMedicaoModel` existente (`faixas_medicao_editor.dart` /
  provider de padrões).

### 3.3 `pontos_medicao_widget.dart`
- Novo parâmetro opcional: `List<FaixaMedicaoModel> faixas` (default `[]`).
- Bloco "Gerar pontos automaticamente" (exibido só se `faixas` não vazio):
  - Dropdown **Faixa** — itens das faixas do padrão (rótulo `valor_min–valor_max unidade`),
    default a primeira (menor `posicao`).
  - Campo **Qtd. pontos** — `int`, default `config['quantidade_pontos_default']`
    ou o nº de linhas atual; validação > 0.
  - Botão **Gerar**.
- `_gerarPontos(faixa, n)`:
  - Resolve a coluna alvo X: `config['campo_regressao_x']`, senão a 1ª coluna
    de entrada.
  - Calcula os N nominais pela fórmula da seção 2.
  - Monta N novas linhas (demais colunas nulas), atribui o nominal na coluna X,
    chama `_recalcLinha` em cada uma.
  - Se houver dado preenchido, confirma antes de substituir `_pontos`.

## 4. Casos de borda

- `valor_min`/`valor_max` nulos na faixa → desabilita "Gerar" para aquela faixa
  (ou ignora a faixa no dropdown).
- `valor_max == valor_min` → todas as linhas com o mesmo nominal.
- N = 1 → um ponto = `valor_max` (evita divisão por zero usando o caso especial).
- Padrão sem faixas → bloco de geração não aparece; entrada manual normal.
- `campo_regressao_x` aponta para coluna inexistente → fallback 1ª entrada.

## 5. Fora de escopo (YAGNI)

- Estratégias alternativas de distribuição (logarítmica, pontos customizados).
- Persistir a faixa escolhida no certificado.
- Geração no editor de template (a faixa é por instrumento, não por template).

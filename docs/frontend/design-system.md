# 🎨 Design System (Normatiq UI)

A interface visual do projeto é fundamentada em um Design System proprietário, implementado através de constantes e componentes padronizados que estendem o **Material Design 3**. Esta abordagem garante a consistência estética e a agilidade no desenvolvimento de novas telas.

## 🧱 Primitivas de Estilo

O uso de valores literais de design deve ser evitado, priorizando-se as constantes definidas no sistema:

### 1. Paleta de Cores (`NormatiqColors`)
As cores são organizadas por semântica para facilitar a aplicação correta em diferentes contextos:
- **`primary`**: Utilizada em elementos de destaque e ações principais.
- **`neutral`**: Tons de cinza para textos, bordas e superfícies secundárias.
- **`success`**, **`warning`**, **`danger`**: Cores de sinalização para estados operacionais.

### 2. Espaçamentos (`NormatiqSpacing`)
O sistema adota uma grade baseada em 4 pixels, garantindo o alinhamento matemático entre os componentes:
- `s1`: 4px | `s2`: 8px | `s3`: 12px | `s4`: 16px | `s5`: 20px | `s6`: 24px.

### 3. Raios de Borda (`NormatiqRadius`)
Define a curvatura padrão de cantos para superfícies e botões:
- `sm`: 4px | `md`: 8px | `lg`: 12px | `full`: 999px.

## 🛠️ Componentes Padronizados

Para assegurar a identidade visual, são utilizados widgets customizados que já incorporam as regras de estilo:
- **Botões**: Incorporam estados de carregamento e feedback visual.
- **Cards**: Possuem elevações e preenchimentos pré-configurados.
- **Campos de Entrada**: Estilizados com foco em legibilidade e usabilidade.

## 🌗 Gerenciamento de Temas

O sistema suporta nativamente os modos **Claro (Light)** e **Escuro (Dark)**. As definições de tema em `lib/core/theme/` mapeiam automaticamente as cores do Design System para as propriedades do `ThemeData` do Flutter, permitindo que a interface se adapte às preferências do sistema operacional sem necessidade de lógica adicional nos widgets de visualização.

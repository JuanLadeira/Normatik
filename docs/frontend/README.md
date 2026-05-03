# 🟢 Documentação Técnica Frontend

Esta documentação descreve a arquitetura, padrões e tecnologias utilizadas no desenvolvimento do frontend do **Normatik**. O objetivo é fornecer uma visão clara da organização do código e servir como guia para manutenção e evolução do sistema.

## 📑 Índice de Tópicos

1.  **[Arquitetura Geral](./arquitetura-geral.md)**
    *   Princípios fundamentais e blocos de construção (Core e Features).
2.  **[Estrutura de Diretórios](./estrutura-pastas.md)**
    *   Organização física dos arquivos e anatomia de uma funcionalidade.
3.  **[Gerenciamento de Estado com Riverpod](./gerenciamento-estado.md)**
    *   Uso de Providers, Notifiers e fluxo de dados reativo.
4.  **[Comunicação com a API](./comunicacao-api.md)**
    *   Integração com serviços backend através da biblioteca Dio.
5.  **[Navegação com GoRouter](./navegacao.md)**
    *   Gestão de rotas, navegação declarativa e parâmetros.
6.  **[Design System (Normatiq UI)](./design-system.md)**
    *   Constantes de design e componentes padronizados.

---

## 🛠️ Padrões de Código

Para garantir a qualidade e manutenibilidade do código-fonte, devem ser seguidos os seguintes princípios:

*   **Tipagem Forte:** Todas as declarações de variáveis, parâmetros e retornos de funções devem ser explicitamente tipadas.
*   **Composição de Widgets:** Priorizar a criação de pequenos widgets especializados em vez de classes de interface extensas e complexas.
*   **Imutabilidade de Modelos:** Os modelos de dados devem ser imutáveis sempre que possível, utilizando métodos de cópia para atualizações.
*   **Separação de Lógica:** A lógica de interface (UI) deve ser mantida estritamente separada da lógica de negócio e persistência de dados.

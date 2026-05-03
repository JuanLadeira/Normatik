# 📂 Estrutura de Diretórios (`lab_app`)

O código-fonte do aplicativo principal está organizado seguindo uma arquitetura modular por funcionalidades (Features), o que permite o isolamento de regras de negócio e facilita a escalabilidade do projeto.

```text
lib/
├── core/               # Componentes e lógica compartilhada
│   ├── api/            # Configuração do cliente Dio e interceptadores
│   ├── providers/      # Providers de estado global
│   ├── theme/          # Definições de estilos, cores e fontes
│   ├── utils/          # Funções utilitárias e formatadores
│   └── widgets/        # Widgets reutilizáveis em múltiplos módulos
│
├── features/           # Módulos organizados por domínio de negócio
│   ├── auth/           # Fluxos de autenticação e autorização
│   ├── clientes/       # Cadastro e gestão de clientes
│   ├── home/           # Dashboard e estrutura principal de navegação
│   ├── instrumentos/   # Gestão de equipamentos de clientes
│   ├── padroes/        # Gestão de padrões de referência
│   └── settings/       # Configurações administrativas do laboratório
│
└── main.dart           # Ponto de entrada e configuração global
```

## 🔍 Descrição dos Componentes Fundamentais

### `lib/main.dart`
Atua como o orquestrador do aplicativo. Responsável pela inicialização das rotas do **GoRouter**, aplicação do tema global via **ThemeData** e injeção de dependências inicial do Riverpod.

### `lib/core/api/client.dart`
Centraliza a configuração da camada de rede. Define timeouts, a URL base do backend e os interceptadores necessários para o tratamento de autenticação e logs.

### Arquitetura de Features
Cada módulo dentro da pasta `features` é projetado para ser autossuficiente, geralmente contendo:
1.  **`page.dart`**: Implementação da interface do usuário.
2.  **`provider.dart`**: Implementação da lógica de estado, chamadas à API e transformações de dados.
3.  **`widgets/`**: Componentes visuais específicos e exclusivos do módulo.

## ⚙️ Fluxo de Desenvolvimento Sugerido

A implementação de novas funcionalidades deve seguir o padrão de fluxo definido para manter a consistência arquitetural:
1.  Definição do modelo de dados no domínio.
2.  Implementação do `provider` para gestão de estado e comunicação assíncrona.
3.  Desenvolvimento da interface de usuário (`page`).
4.  Registro da nova rota no sistema central de navegação.

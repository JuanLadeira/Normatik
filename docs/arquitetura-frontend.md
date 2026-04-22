# Arquitetura Frontend — Normatiq

Este documento descreve as decisões técnicas e a estrutura do frontend Flutter do projeto Normatiq.

## 📋 Visão Geral
O frontend é estruturado como um monorepo de pacotes Flutter, permitindo o compartilhamento de código entre os diferentes perfis de acesso (Laboratório, Cliente e Admin).

## 🛠 stack Tecnológica
- **Linguagem:** Dart 3.x
- **Framework:** Flutter (Web, Android, iOS)
- **Gerenciamento de Estado:** [Riverpod](https://riverpod.dev/) (DT-F03)
- **Navegação:** [go_router](https://pub.dev/packages/go_router) (DT-F04)
- **Cliente HTTP:** [Dio](https://pub.dev/packages/dio) (DT-F05)
- **Persistence:** Flutter Secure Storage (para tokens JWT)

## 📂 Estrutura de Diretórios
```
frontend/
├── packages/
│   ├── normatiq_ui/      # Design System (Cores do preview, componentes customizados)
│   ├── normatiq_api/     # Cliente HTTP gerado, interceptors e modelos DTO
│   └── normatiq_domain/  # Regras de negócio puras, Enums (ex: TenantStatus)
└── apps/
    ├── lab_app/          # App principal para técnicos e gestores
    ├── client_portal/    # Portal simplificado para clientes
    └── admin_app/        # Gestão interna da plataforma (SaaS)
```

## 🔒 Segurança e Autenticação
A autenticação é baseada em **OAuth2 (Password Flow)** fornecido pelo FastAPI.

- **Fluxo de Login:** A `LoginPage` dispara o `authProvider`, que utiliza o `ApiClient` (Dio) para obter um token JWT.
- **Persistência:** O token é armazenado localmente usando `flutter_secure_storage`.
- **Interceptors:** O `ApiClient` injeta automaticamente o cabeçalho `Authorization: Bearer <token>` em todas as requisições se o token existir.
- **Navegação Protegida (Auth Guard):** Utilizamos a propriedade `redirect` do `GoRouter` em conjunto com o estado do `authProvider`. Qualquer tentativa de acesso a rotas privadas sem um token válido redireciona o usuário para `/login`.

## 🧠 Gerenciamento de Estado
- **Riverpod:** Escolhido pela sua robustez e facilidade de Injeção de Dependências.
- **Providers:**
    - `apiClientProvider`: Singleton do cliente HTTP.
    - `authProvider`: StateNotifier que gerencia o ciclo de vida da sessão.
    - `_routerProvider`: Centraliza a configuração de rotas e lógica de redirecionamento.
1. Alterações em modelos de dados devem ser refletidas primeiro em `normatiq_domain`.
2. Componentes visuais novos entram no `normatiq_ui`.
3. Telas e lógica de navegação ficam dentro dos respectivos `apps/`.

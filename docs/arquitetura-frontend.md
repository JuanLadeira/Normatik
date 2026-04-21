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

## 🎨 Design & UI (Baseado no UI Kit)
O design segue as especificações encontradas em `ui_kits/lab_app`. 
- **Mobile-first:** Layouts otimizados para 360dp.
- **Tokens:** Cores e tipografia definidas em `colors_and_type.css` serão transpostas para o `normatiq_ui`.

## 🔄 Fluxo de Desenvolvimento
1. Alterações em modelos de dados devem ser refletidas primeiro em `normatiq_domain`.
2. Componentes visuais novos entram no `normatiq_ui`.
3. Telas e lógica de navegação ficam dentro dos respectivos `apps/`.

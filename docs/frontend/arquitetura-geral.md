# 🏛️ Arquitetura do Projeto (`lab_app`)

O projeto adota uma estrutura modular e direta, organizada por responsabilidades dentro do aplicativo principal. Esta abordagem prioriza a clareza na separação de conceitos e a facilidade de manutenção.

## 🧱 Divisão Principal

O código-fonte está centralizado em `frontend/apps/lab_app/lib/`, estruturado em dois blocos fundamentais:

### 1. 🏗️ Core (O Alicerce)
Localizado em `lib/core/`, aqui fica tudo o que é **compartilhado** por todo o aplicativo. Se algo não pertence a uma tela específica, ele mora aqui.

- **`api/`**: Configuração do cliente de rede (Dio). É onde definimos como o app conversa com o servidor Python.
- **`providers/`**: Dados globais que cruzam várias telas (ex: o catálogo de equipamentos que usamos em vários formulários).
- **`theme/`**: A identidade visual. Cores, fontes e estilos de botões que garantem que o app seja bonito e consistente.
- **`widgets/`**: Componentes genéricos, como campos de texto customizados ou cards que usamos em diversos lugares.

### 2. 🚀 Features (As Funcionalidades)
Localizado em `lib/features/`, o app é separado por "módulos" de negócio. Cada pasta aqui representa uma parte do que o usuário faz no sistema.

- **`auth/`**: Tudo sobre Login e segurança.
- **`clientes/`**: Cadastro e visualização de clientes do laboratório.
- **`padroes/`**: Gestão dos instrumentos de referência (JTI).
- **`instrumentos/`**: Gestão dos equipamentos dos clientes.
- **`settings/`**: Configurações gerais do sistema.

---

## 📄 Anatomia de uma Feature

Cada funcionalidade costuma ter três tipos de arquivos:

1.  **`..._page.dart`**: O arquivo da interface (UI). É onde desenhamos os botões e listas.
2.  **`..._provider.dart`**: A lógica por trás da tela. É quem busca os dados na API e guarda na memória usando o **Riverpod**.
3.  **`..._widgets/`**: (Opcional) Se uma tela for muito grande, quebramos ela em pedaços menores dentro desta subpasta.

## ✨ Por que essa simplicidade é boa?
- **Fácil de encontrar:** Quer mudar o Login? Pasta `auth`. Quer mudar a cor do app? Pasta `core/theme`.
- **Rápido de aprender:** Você não precisa lidar com múltiplos pacotes ou configurações complexas de projeto. Tudo o que o Flutter precisa está em um só lugar.

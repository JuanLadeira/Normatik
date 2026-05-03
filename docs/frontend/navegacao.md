# 🛤️ Navegação com GoRouter

O sistema de navegação do aplicativo é gerenciado pelo **GoRouter**, uma solução baseada em rotas declarativas que permite a navegação através de caminhos de URL, facilitando a gestão de estados profundos e a compatibilidade com a web.

## 📁 Configuração de Rotas

As rotas e sub-rotas são definidas de forma centralizada em `lib/main.dart`:

```dart
final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/padroes',
      builder: (context, state) => const PadroesListPage(),
      routes: [
        GoRoute(
          path: ':id', // Parâmetro dinâmico de caminho
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return PadraoDetailPage(padraoId: id);
          },
        ),
      ],
    ),
  ],
);
```

## 🚀 Métodos de Navegação

A transição entre telas é realizada através da extensão de métodos no `BuildContext`:

*   **`context.go('/caminho')`:** Substitui a rota atual na pilha de navegação. Recomendado para transições de módulos principais.
*   **`context.push('/caminho')`:** Adiciona uma nova rota sobre a pilha atual, permitindo o retorno à tela anterior através do botão nativo de "voltar".
*   **`context.pop()`:** Remove a rota atual da pilha, retornando à tela precedente.

## 📦 Transferência de Dados entre Rotas

O GoRouter oferece três mecanismos principais para a passagem de informações:
1.  **Path Parameters:** Utilizados para IDs e identificadores únicos (ex: `/padroes/15`).
2.  **Query Parameters:** Ideais para filtros e buscas (ex: `/clientes?status=ativo`).
3.  **Extra Object:** Permite a passagem de objetos complexos, embora deva ser utilizado com cautela para garantir a persistência da navegação em reinicializações do app.

# 🧠 Gerenciamento de Estado com Riverpod

O **Riverpod** é utilizado como a solução principal para o gerenciamento de estado do aplicativo, sendo responsável pela persistência temporária de dados e pela sincronização entre a lógica de negócio e a interface de usuário.

## 🛠️ Conceito de Provider

Os Providers atuam como fontes de dados reativas e centralizadas, acessíveis por qualquer componente da árvore de widgets.

### Exemplo: `padroesProvider`

No arquivo `lib/features/padroes/padroes_provider.dart`, o provider é definido da seguinte forma:

```dart
final padroesProvider = StateNotifierProvider<PadroesNotifier, AsyncValue<List<PadraoCalibracaoModel>>>(
  (ref) => PadroesNotifier(ref.watch(apiClientProvider)),
);
```

1.  **StateNotifierProvider:** Gerencia um estado que pode ser modificado através de métodos definidos em uma classe `Notifier`.
2.  **AsyncValue:** Encapsula o estado de dados assíncronos em três estados possíveis:
    *   `loading`: Indica que a requisição está em andamento.
    *   `data`: Contém os dados retornados com sucesso.
    *   `error`: Armazena informações sobre falhas na obtenção dos dados.

## 📺 Consumo de Dados na UI

Para interagir com os Providers, os widgets devem estender `ConsumerWidget` ou utilizar o widget `Consumer`:

```dart
class PadroesView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observando as mudanças no provider
    final padroesAsync = ref.watch(padroesProvider);

    return padroesAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Erro: $err'),
      data: (lista) => ListView.builder(
        itemCount: lista.length,
        itemBuilder: (context, index) => ListTile(title: Text(lista[index].modelo)),
      ),
    );
  }
}
```

## 🔄 Gerenciamento de Cache e Invalidação

A atualização de dados após operações de escrita (POST, PATCH, DELETE) é realizada através do método `ref.invalidate(provider)`. Este comando descarta o estado atual em cache e força uma nova requisição na próxima leitura, garantindo a consistência dos dados exibidos.

## 🔑 Estrutura do StateNotifier

As classes que estendem `StateNotifier` centralizam a lógica de manipulação de estado e comunicação com a API:
- `fetch()`: Realiza a consulta inicial dos dados.
- `create()`/`update()`/`delete()`: Executam as operações de mutação e atualizam o estado local ou invalidam o cache conforme necessário.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import 'clientes_provider.dart';

class ClientesListPage extends ConsumerStatefulWidget {
  const ClientesListPage({super.key});

  @override
  ConsumerState<ClientesListPage> createState() => _ClientesListPageState();
}

class _ClientesListPageState extends ConsumerState<ClientesListPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou CNPJ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(NormatiqRadius.md)),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: clientesAsync.when(
              data: (clientes) {
                final filtered = clientes
                    .where((c) =>
                        c.nome.toLowerCase().contains(_search) ||
                        (c.cnpj ?? '').contains(_search))
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline,
                            size: 48, color: NormatiqColors.neutral400),
                        const SizedBox(height: 12),
                        Text(_search.isEmpty
                            ? 'Nenhum cliente cadastrado.'
                            : 'Nenhum cliente encontrado.'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(clientesProvider.notifier).fetchClientes(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final c = filtered[i];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          onTap: () => context.push('/clientes/${c.id}'),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            child: Text(
                              c.nome[0].toUpperCase(),
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(c.nome,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: c.cnpj != null
                              ? Text('CNPJ: ${c.cnpj}',
                                  style: const TextStyle(fontSize: 12))
                              : (c.email != null
                                  ? Text(c.email!,
                                      style: const TextStyle(fontSize: 12))
                                  : null),
                          trailing: _AtivoChip(ativo: c.ativo),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: NormatiqColors.danger700),
                    const SizedBox(height: 8),
                    const Text('Erro ao carregar clientes.'),
                    TextButton(
                      onPressed: () =>
                          ref.read(clientesProvider.notifier).fetchClientes(),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/clientes/novo'),
        icon: const Icon(Icons.add),
        label: const Text('Novo cliente'),
      ),
    );
  }
}

class _AtivoChip extends StatelessWidget {
  final bool ativo;
  const _AtivoChip({required this.ativo});

  @override
  Widget build(BuildContext context) {
    final color =
        ativo ? NormatiqColors.success700 : NormatiqColors.neutral500;
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(NormatiqRadius.full),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        ativo ? 'Ativo' : 'Inativo',
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

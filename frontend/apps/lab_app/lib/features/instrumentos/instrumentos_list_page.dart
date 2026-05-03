import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../clientes/clientes_provider.dart';
import 'instrumentos_provider.dart';

class InstrumentosListPage extends ConsumerStatefulWidget {
  final int? clienteIdFiltro;
  const InstrumentosListPage({super.key, this.clienteIdFiltro});

  @override
  ConsumerState<InstrumentosListPage> createState() =>
      _InstrumentosListPageState();
}

class _InstrumentosListPageState
    extends ConsumerState<InstrumentosListPage> {
  String _search = '';
  int? _clienteFiltro;

  @override
  void initState() {
    super.initState();
    _clienteFiltro = widget.clienteIdFiltro;
  }

  @override
  Widget build(BuildContext context) {
    final instrAsync = ref.watch(instrumentosProvider);
    final clientesAsync = ref.watch(clientesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instrumentos',
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
                hintText: 'Buscar por marca, modelo, série ou tag...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(NormatiqRadius.md)),
                isDense: true,
              ),
            ),
          ),
          // Filtro por cliente
          clientesAsync.whenData((clientes) {
            if (clientes.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: DropdownButtonFormField<int?>(
                value: _clienteFiltro,
                decoration: InputDecoration(
                  labelText: 'Filtrar por cliente',
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(NormatiqRadius.md)),
                  suffixIcon: _clienteFiltro != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () =>
                              setState(() => _clienteFiltro = null),
                        )
                      : null,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ...clientes.map((c) =>
                      DropdownMenuItem(value: c.id, child: Text(c.nome))),
                ],
                onChanged: (v) => setState(() => _clienteFiltro = v),
              ),
            );
          }).value ??
              const SizedBox.shrink(),
          Expanded(
            child: instrAsync.when(
              data: (instrumentos) {
                final filtered = instrumentos.where((i) {
                  final matchSearch =
                      i.marca.toLowerCase().contains(_search) ||
                          i.modelo.toLowerCase().contains(_search) ||
                          i.numeroSerie.toLowerCase().contains(_search) ||
                          (i.tag ?? '').toLowerCase().contains(_search);
                  final matchCliente = _clienteFiltro == null ||
                      i.clienteId == _clienteFiltro;
                  return matchSearch && matchCliente;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.build_outlined,
                            size: 48, color: NormatiqColors.neutral400),
                        const SizedBox(height: 12),
                        Text(_search.isEmpty && _clienteFiltro == null
                            ? 'Nenhum instrumento cadastrado.'
                            : 'Nenhum instrumento encontrado.'),
                      ],
                    ),
                  );
                }

                final clientes =
                    ref.watch(clientesProvider).valueOrNull ?? [];

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(instrumentosProvider.notifier)
                      .fetchInstrumentos(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final instr = filtered[idx];
                      final cliente = clientes
                          .where((c) => c.id == instr.clienteId)
                          .firstOrNull;
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          onTap: () =>
                              context.push('/instrumentos/${instr.id}'),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(NormatiqRadius.md),
                            ),
                            child: Icon(Icons.build_outlined,
                                color:
                                    Theme.of(context).colorScheme.primary,
                                size: 20),
                          ),
                          title: Text(
                            '${instr.marca} ${instr.modelo}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('S/N: ${instr.numeroSerie}',
                                  style: const TextStyle(fontSize: 12)),
                              if (cliente != null)
                                Text('Cliente: ${cliente.nome}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: NormatiqColors.neutral500)),
                            ],
                          ),
                          isThreeLine: cliente != null,
                          trailing: instr.tag != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(
                                        NormatiqRadius.full),
                                  ),
                                  child: Text(instr.tag!,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w600)),
                                )
                              : null,
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
                    const Text('Erro ao carregar instrumentos.'),
                    TextButton(
                      onPressed: () => ref
                          .read(instrumentosProvider.notifier)
                          .fetchInstrumentos(),
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
        onPressed: () => context.push('/instrumentos/novo'),
        icon: const Icon(Icons.add),
        label: const Text('Novo instrumento'),
      ),
    );
  }
}

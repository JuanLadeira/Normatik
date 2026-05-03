import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import 'clientes_provider.dart';
import '../instrumentos/instrumentos_provider.dart';

class ClienteDetailPage extends ConsumerStatefulWidget {
  final int clienteId;
  const ClienteDetailPage({super.key, required this.clienteId});

  @override
  ConsumerState<ClienteDetailPage> createState() =>
      _ClienteDetailPageState();
}

class _ClienteDetailPageState extends ConsumerState<ClienteDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesProvider);

    return clientesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(appBar: AppBar(), body: Center(child: Text('Erro: $e'))),
      data: (clientes) {
        final cliente =
            clientes.where((c) => c.id == widget.clienteId).firstOrNull;
        if (cliente == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Cliente não encontrado.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(cliente.nome,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            actions: [
              TextButton.icon(
                onPressed: () =>
                    context.push('/clientes/${cliente.id}/editar'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Dados'),
                Tab(text: 'Instrumentos'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _DadosTab(cliente: cliente),
              _InstrumentosTab(clienteId: cliente.id),
            ],
          ),
        );
      },
    );
  }
}

class _DadosTab extends StatelessWidget {
  final ClienteLaboratorio cliente;
  const _DadosTab({required this.cliente});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(NormatiqSpacing.s4),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(NormatiqSpacing.s4),
            child: Column(
              children: [
                _InfoRow(label: 'Nome', value: cliente.nome),
                if (cliente.cnpj != null)
                  _InfoRow(label: 'CNPJ', value: cliente.cnpj!),
                if (cliente.contato != null)
                  _InfoRow(label: 'Contato', value: cliente.contato!),
                if (cliente.email != null)
                  _InfoRow(label: 'E-mail', value: cliente.email!),
                if (cliente.telefone != null)
                  _InfoRow(label: 'Telefone', value: cliente.telefone!),
                _InfoRow(
                  label: 'Status',
                  value: cliente.ativo ? 'Ativo' : 'Inativo',
                  valueColor: cliente.ativo
                      ? NormatiqColors.success700
                      : NormatiqColors.neutral500,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InstrumentosTab extends ConsumerWidget {
  final int clienteId;
  const _InstrumentosTab({required this.clienteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instrAsync = ref.watch(instrumentosPorClienteProvider(clienteId));

    return instrAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (instrumentos) {
        if (instrumentos.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.build_outlined,
                    size: 48, color: NormatiqColors.neutral400),
                const SizedBox(height: 12),
                const Text('Nenhum instrumento cadastrado.',
                    style: TextStyle(color: NormatiqColors.neutral500)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/instrumentos/novo?clienteId=$clienteId'),
                  icon: const Icon(Icons.add),
                  label: const Text('Novo instrumento'),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: ListView.separated(
            padding: const EdgeInsets.all(NormatiqSpacing.s4),
            itemCount: instrumentos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final instr = instrumentos[i];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  onTap: () => context.push('/instrumentos/${instr.id}'),
                  leading: const Icon(Icons.build_outlined),
                  title: Text('${instr.marca} ${instr.modelo}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('S/N: ${instr.numeroSerie}',
                      style: const TextStyle(fontSize: 12)),
                  trailing: instr.tag != null
                      ? Text(instr.tag!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: NormatiqColors.neutral500))
                      : null,
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                context.push('/instrumentos/novo?clienteId=$clienteId'),
            icon: const Icon(Icons.add),
            label: const Text('Novo instrumento'),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

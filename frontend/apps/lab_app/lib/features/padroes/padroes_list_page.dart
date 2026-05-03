import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import 'padroes_provider.dart';

class PadroesListPage extends ConsumerStatefulWidget {
  const PadroesListPage({super.key});

  @override
  ConsumerState<PadroesListPage> createState() => _PadroesListPageState();
}

class _PadroesListPageState extends ConsumerState<PadroesListPage> {
  String _search = '';
  String _filtroStatus = 'todos';

  static const _filtros = [
    ('todos', 'Todos'),
    (PadraoCalibracaoStatus.emDia, 'Em dia'),
    (PadraoCalibracaoStatus.vencendoEmBreve, 'Vencendo'),
    (PadraoCalibracaoStatus.vencido, 'Vencidos'),
    (PadraoCalibracaoStatus.semCalibracao, 'Sem calibração'),
  ];

  @override
  Widget build(BuildContext context) {
    final padroesAsync = ref.watch(padroesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Padrões',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por marca, modelo ou série...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(NormatiqRadius.md)),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtros.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (value, label) = _filtros[i];
                final selected = _filtroStatus == value;
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _filtroStatus = value),
                  selectedColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: padroesAsync.when(
              data: (padroes) {
                final filtered = padroes.where((p) {
                  final matchSearch =
                      p.marca.toLowerCase().contains(_search) ||
                          p.modelo.toLowerCase().contains(_search) ||
                          p.numeroSerie.toLowerCase().contains(_search) ||
                          (p.tag ?? '').toLowerCase().contains(_search);
                  final matchStatus = _filtroStatus == 'todos' ||
                      p.statusCalibracao == _filtroStatus;
                  return matchSearch && matchStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.science_outlined,
                            size: 48, color: NormatiqColors.neutral400),
                        const SizedBox(height: 12),
                        Text(_search.isEmpty && _filtroStatus == 'todos'
                            ? 'Nenhum padrão cadastrado.'
                            : 'Nenhum padrão encontrado.'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(padroesProvider.notifier).fetchPadroes(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          onTap: () => context.push('/padroes/${p.id}'),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: statusCalibracaoColor(p.statusCalibracao)
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(NormatiqRadius.md),
                            ),
                            child: Icon(Icons.science_outlined,
                                color: statusCalibracaoColor(p.statusCalibracao),
                                size: 20),
                          ),
                          title: Text(
                            '${p.tag ?? 'S/T'} - ${p.tipoEquipamentoNome ?? 'Equipamento'} - ${p.modelo} / ${p.marca}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'S/N: ${p.numeroSerie}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: StatusCalibracaoChip(
                              status: p.statusCalibracao,
                              validade: p.validadeCalibracao),
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
                    const Text('Erro ao carregar padrões.'),
                    TextButton(
                      onPressed: () =>
                          ref.read(padroesProvider.notifier).fetchPadroes(),
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
        onPressed: () => context.push('/padroes/novo'),
        icon: const Icon(Icons.add),
        label: const Text('Novo padrão'),
      ),
    );
  }
}

Color statusCalibracaoColor(String status) {
  switch (status) {
    case PadraoCalibracaoStatus.emDia:
      return NormatiqColors.success700;
    case PadraoCalibracaoStatus.vencendoEmBreve:
      return NormatiqColors.warning700;
    case PadraoCalibracaoStatus.vencido:
      return NormatiqColors.danger700;
    default:
      return NormatiqColors.neutral500;
  }
}

class StatusCalibracaoChip extends StatelessWidget {
  final String status;
  final String? validade;
  const StatusCalibracaoChip({super.key, required this.status, this.validade});

  @override
  Widget build(BuildContext context) {
    final color = statusCalibracaoColor(status);
    final label = switch (status) {
      PadraoCalibracaoStatus.emDia => 'Em dia',
      PadraoCalibracaoStatus.vencendoEmBreve => 'Vencendo',
      PadraoCalibracaoStatus.vencido => 'Vencido',
      _ => 'Sem calibração',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(NormatiqRadius.full),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        if (validade != null) ...[
          const SizedBox(height: 2),
          Text(validade!,
              style: const TextStyle(
                  fontSize: 10, color: NormatiqColors.neutral500)),
        ],
      ],
    );
  }
}

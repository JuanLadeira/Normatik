import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../../core/widgets/faixas_medicao_editor.dart';
import '../clientes/clientes_provider.dart';
import 'instrumentos_provider.dart';

class InstrumentoDetailPage extends ConsumerStatefulWidget {
  final int instrumentoId;
  const InstrumentoDetailPage({super.key, required this.instrumentoId});

  @override
  ConsumerState<InstrumentoDetailPage> createState() =>
      _InstrumentoDetailPageState();
}

class _InstrumentoDetailPageState
    extends ConsumerState<InstrumentoDetailPage>
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
    final instrAsync = ref.watch(instrumentosProvider);

    return instrAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(appBar: AppBar(), body: Center(child: Text('Erro: $e'))),
      data: (instrumentos) {
        final instr = instrumentos
            .where((i) => i.id == widget.instrumentoId)
            .firstOrNull;
        if (instr == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(
                  child: Text('Instrumento não encontrado.')));
        }

        final clientes = ref.watch(clientesProvider).valueOrNull ?? [];
        final cliente =
            clientes.where((c) => c.id == instr.clienteId).firstOrNull;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${instr.marca} ${instr.modelo}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            actions: [
              TextButton.icon(
                onPressed: () =>
                    context.push('/instrumentos/${instr.id}/editar'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Dados'),
                Tab(text: 'Histórico'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _DadosTab(instr: instr, nomeCliente: cliente?.nome),
              _HistoricoTab(instrumentoId: instr.id),
            ],
          ),
        );
      },
    );
  }
}

class _DadosTab extends StatelessWidget {
  final InstrumentoModel instr;
  final String? nomeCliente;
  const _DadosTab({required this.instr, this.nomeCliente});

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
                _InfoRow('Marca', instr.marca),
                _InfoRow('Modelo', instr.modelo),
                _InfoRow('N° de série', instr.numeroSerie),
                if (instr.tag != null) _InfoRow('Tag', instr.tag!),
                if (nomeCliente != null)
                  _InfoRow('Cliente', nomeCliente!),
                _InfoRow(
                  'Status',
                  instr.ativo ? 'Ativo' : 'Inativo',
                  valueColor: instr.ativo
                      ? NormatiqColors.success700
                      : NormatiqColors.neutral500,
                ),
                if (instr.faixas.isNotEmpty) ...[
                  const Divider(height: 24),
                  _FaixasSection(faixas: instr.faixas),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoricoTab extends StatelessWidget {
  final int instrumentoId;
  const _HistoricoTab({required this.instrumentoId});

  @override
  Widget build(BuildContext context) {
    // Será preenchido quando calibrações de clientes forem implementadas (OS flow)
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history_outlined,
              size: 48, color: NormatiqColors.neutral400),
          const SizedBox(height: 12),
          const Text('Histórico de calibrações',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Disponível após implementação do fluxo de OS.',
            style: TextStyle(
                color: NormatiqColors.neutral500, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FaixasSection extends StatelessWidget {
  final List<FaixaMedicaoModel> faixas;
  const _FaixasSection({required this.faixas});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Faixas de medição',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        ...faixas.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: NormatiqColors.primary600.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(NormatiqRadius.sm),
                    ),
                    child: Text(f.unidadeSimbolo,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: NormatiqColors.primary600)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(f.label,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5))),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: valueColor)),
          ),
        ],
      ),
    );
  }
}

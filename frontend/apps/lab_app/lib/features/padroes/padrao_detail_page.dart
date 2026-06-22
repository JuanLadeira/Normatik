import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../../core/api/client.dart';
import '../../core/widgets/faixas_medicao_editor.dart';
import 'padroes_provider.dart';
import 'padroes_list_page.dart' show StatusCalibracaoChip, statusCalibracaoColor;
import 'certificados_padrao_provider.dart';

class PadraoDetailPage extends ConsumerStatefulWidget {
  final int padraoId;
  const PadraoDetailPage({super.key, required this.padraoId});

  @override
  ConsumerState<PadraoDetailPage> createState() => _PadraoDetailPageState();
}

class _PadraoDetailPageState extends ConsumerState<PadraoDetailPage>
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
    final padroesAsync = ref.watch(padroesProvider);

    return padroesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(appBar: AppBar(), body: Center(child: Text('Erro: $e'))),
      data: (padroes) {
        final padrao =
            padroes.where((p) => p.id == widget.padraoId).firstOrNull;
        if (padrao == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Padrão não encontrado.')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${padrao.tag != null ? '${padrao.tag} | ' : ''}${padrao.tipoEquipamentoNome ?? ''} ${padrao.marca} (S/N: ${padrao.numeroSerie})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            actions: [
              TextButton.icon(
                onPressed: () =>
                    context.push('/padroes/${padrao.id}/editar'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Dados'),
                Tab(text: 'Certificados'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _DadosTab(padrao: padrao),
              _CertificadosPadraoTab(padraoId: padrao.id),
            ],
          ),
        );
      },
    );
  }
}

class _DadosTab extends StatelessWidget {
  final PadraoCalibracaoModel padrao;
  const _DadosTab({required this.padrao});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(NormatiqSpacing.s4),
      children: [
        // Status card
        Card(
          margin: const EdgeInsets.only(bottom: NormatiqSpacing.s4),
          child: Padding(
            padding: const EdgeInsets.all(NormatiqSpacing.s4),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusCalibracaoColor(padrao.statusCalibracao)
                        .withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(NormatiqRadius.md),
                  ),
                  child: Icon(Icons.science_outlined,
                      color: statusCalibracaoColor(padrao.statusCalibracao)),
                ),
                const SizedBox(width: NormatiqSpacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status de calibração',
                          style: TextStyle(
                              fontSize: 12,
                              color: NormatiqColors.neutral500)),
                      StatusCalibracaoChip(
                          status: padrao.statusCalibracao,
                          validade: padrao.validadeCalibracao),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Identificação
        _SectionCard(title: 'Identificação', rows: [
          _Row('Marca', padrao.marca),
          _Row('Modelo', padrao.modelo),
          _Row('N° de série', padrao.numeroSerie),
          if (padrao.tag != null) _Row('Tag', padrao.tag!),
        ]),

        if (padrao.fotos.isNotEmpty) ...[
          const SizedBox(height: NormatiqSpacing.s4),
          _PhotosCard(fotos: padrao.fotos),
        ],

        if (padrao.faixas.isNotEmpty) ...[
          const SizedBox(height: NormatiqSpacing.s4),
          _FaixasCard(faixas: padrao.faixas),
        ],

        const SizedBox(height: NormatiqSpacing.s4),

        // Rastreabilidade atual
        _SectionCard(title: 'Rastreabilidade atual', rows: [
          if (padrao.numeroCertificado != null)
            _Row('Certificado', padrao.numeroCertificado!),
          if (padrao.laboratorioCalibrador != null)
            _Row('Lab. calibrador', padrao.laboratorioCalibrador!),
          if (padrao.validadeCalibracao != null)
            _Row('Validade', padrao.validadeCalibracao!),
          if (padrao.uExpandidaAtual != null)
            _Row('U expandida', '${padrao.uExpandidaAtual}'),
          if (padrao.numeroCertificado == null)
            const _Row('Situação', 'Sem certificado registrado'),
        ]),

        const SizedBox(height: NormatiqSpacing.s4),

        // Controle
        _SectionCard(title: 'Controle', rows: [
          if (padrao.frequenciaCalibracaoDias != null)
            _Row('Frequência', '${padrao.frequenciaCalibracaoDias} dias'),
          _Row('Alerta antecedência', '${padrao.alertaDiasAntes} dias'),
          if (padrao.uMaximoAceito != null)
            _Row('U máxima aceita', '${padrao.uMaximoAceito}'),
          if (padrao.criterioAceitacao != null)
            _Row('Critério', padrao.criterioAceitacao!),
        ]),
      ],
    );
  }
}

// ── Aba de Certificados (F2) ───────────────────────────────────────────────────

Color _certStatusColor(String status) {
  switch (status) {
    case 'ativo':
      return NormatiqColors.success700;
    case 'aguardando_aprovacao_curva':
      return NormatiqColors.warning700;
    case 'expirado':
      return NormatiqColors.danger700;
    default:
      return NormatiqColors.neutral500;
  }
}

String _certStatusLabel(String status) {
  switch (status) {
    case 'ativo':
      return 'Ativo';
    case 'aguardando_aprovacao_curva':
      return 'Aguardando Aprov.';
    case 'expirado':
      return 'Expirado';
    default:
      return 'Rascunho';
  }
}

class _CertificadosPadraoTab extends ConsumerWidget {
  final int padraoId;
  const _CertificadosPadraoTab({required this.padraoId});

  Future<void> _excluir(BuildContext context, WidgetRef ref, int certId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Certificado'),
        content: const Text(
            'Todos os pontos de medição e curvas associadas serão excluídos permanentemente. Confirmar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: NormatiqColors.danger700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final client = ref.read(apiClientProvider);
      await client.dio.delete('/api/certificados-padrao/certificados/$certId');
      ref.invalidate(certificadosPadraoProvider(padraoId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: NormatiqColors.danger700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certsAsync = ref.watch(certificadosPadraoProvider(padraoId));

    return Scaffold(
      body: certsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar certificados: $e')),
        data: (certs) {
          if (certs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_outlined,
                      size: 48, color: NormatiqColors.neutral400),
                  const SizedBox(height: 12),
                  const Text(
                    'Nenhum certificado registrado.',
                    style: TextStyle(color: NormatiqColors.neutral500),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        context.push('/padroes/$padraoId/certificados/novo'),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo Certificado'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(NormatiqSpacing.s4),
            itemCount: certs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: NormatiqSpacing.s2),
            itemBuilder: (context, i) {
              final cert = certs[i];
              final statusColor = _certStatusColor(cert.status);
              return Card(
                margin: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(NormatiqRadius.md),
                  onTap: () => context.push(
                      '/padroes/$padraoId/certificados/${cert.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(NormatiqSpacing.s4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cert. #${cert.numeroCertificado}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cert.laboratorioCalibrador,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: NormatiqColors.neutral500),
                              ),
                              Text(
                                'Validade: ${cert.dataValidade}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: NormatiqColors.neutral500),
                              ),
                              if (cert.uPadrao != null)
                                Text(
                                  'u = ${cert.uPadrao!.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: NormatiqColors.neutral500),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: NormatiqSpacing.s3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(NormatiqRadius.full),
                            border: Border.all(
                                color: statusColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            _certStatusLabel(cert.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert,
                              color: NormatiqColors.neutral400),
                          onSelected: (v) {
                            if (v == 'delete') {
                              _excluir(context, ref, cert.id);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      color: NormatiqColors.danger700,
                                      size: 18),
                                  SizedBox(width: 8),
                                  Text('Excluir',
                                      style: TextStyle(
                                          color: NormatiqColors.danger700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/padroes/$padraoId/certificados/novo'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Certificado'),
      ),
    );
  }
}

// ── Widgets auxiliares reutilizáveis ───────────────────────────────────────────

class _PhotosCard extends StatelessWidget {
  final List<String> fotos;
  const _PhotosCard({required this.fotos});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(NormatiqSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FOTOS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.4),
                  letterSpacing: 1),
            ),
            const SizedBox(height: NormatiqSpacing.s3),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: fotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(NormatiqRadius.md),
                    child: Image.network(
                      fotos[i],
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        color: NormatiqColors.neutral100,
                        child: const Icon(Icons.broken_image_outlined, color: NormatiqColors.neutral400),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaixasCard extends StatelessWidget {
  final List<FaixaMedicaoModel> faixas;
  const _FaixasCard({required this.faixas});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(NormatiqSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FAIXAS DE MEDIÇÃO',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.4),
                  letterSpacing: 1),
            ),
            const SizedBox(height: NormatiqSpacing.s3),
            ...faixas.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: NormatiqColors.primary600.withOpacity(0.08),
                          borderRadius:
                              BorderRadius.circular(NormatiqRadius.sm),
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
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<_Row> rows;
  const _SectionCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(NormatiqSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.4),
                  letterSpacing: 1),
            ),
            const SizedBox(height: NormatiqSpacing.s3),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

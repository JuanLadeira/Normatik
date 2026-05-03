import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../../core/widgets/faixas_medicao_editor.dart';
import 'padroes_provider.dart';
import 'padroes_list_page.dart' show StatusCalibracaoChip, statusCalibracaoColor;

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
            title: Text('${padrao.marca} ${padrao.modelo}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
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
                Tab(text: 'Calibrações'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _DadosTab(padrao: padrao),
              _CalibracoesPadraoTab(padraoId: padrao.id),
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

class _CalibracoesPadraoTab extends ConsumerStatefulWidget {
  final int padraoId;
  const _CalibracoesPadraoTab({required this.padraoId});

  @override
  ConsumerState<_CalibracoesPadraoTab> createState() =>
      _CalibracoesPadraoTabState();
}

class _CalibracoesPadraoTabState
    extends ConsumerState<_CalibracoesPadraoTab> {
  @override
  Widget build(BuildContext context) {
    final historicoAsync =
        ref.watch(historicoCalibracaoPadraoProvider(widget.padraoId));

    return Scaffold(
      body: historicoAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (historico) {
          if (historico.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_outlined,
                      size: 48, color: NormatiqColors.neutral400),
                  const SizedBox(height: 12),
                  const Text('Nenhuma calibração registrada.',
                      style:
                          TextStyle(color: NormatiqColors.neutral500)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(NormatiqSpacing.s4),
            itemCount: historico.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: NormatiqSpacing.s2),
            itemBuilder: (context, i) {
              final h = historico[i];
              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(NormatiqSpacing.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Cert. ${h.numeroCertificado}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showRegistrarCalibracaoSheet(context,
                                    historico: h);
                              } else if (val == 'delete') {
                                _showDeleteHistoricoConfirm(context, h);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined, size: 20),
                                  title: Text('Editar'),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline,
                                      size: 20, color: NormatiqColors.danger700),
                                  title: Text('Excluir',
                                      style: TextStyle(
                                          color: NormatiqColors.danger700)),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: h.aceito
                                  ? NormatiqColors.success700
                                      .withOpacity(0.1)
                                  : NormatiqColors.danger700
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  NormatiqRadius.full),
                            ),
                            child: Text(
                              h.aceito ? 'Aceito' : 'Recusado',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: h.aceito
                                      ? NormatiqColors.success700
                                      : NormatiqColors.danger700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Calibrado: ${h.dataCalibracao} · Vencimento: ${h.dataVencimento}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: NormatiqColors.neutral500),
                      ),
                      if (h.laboratorioCalibrador != null)
                        Text(
                          'Lab: ${h.laboratorioCalibrador}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: NormatiqColors.neutral500),
                        ),
                      if (h.uExpandidaCertificado != null)
                        Text(
                          'U = ${h.uExpandidaCertificado}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: NormatiqColors.neutral500),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegistrarCalibracaoSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Registrar calibração'),
      ),
    );
  }

  void _showDeleteHistoricoConfirm(
      BuildContext context, HistoricoCalibracaoPadrao h) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir registro'),
        content:
            const Text('Deseja realmente excluir este registro de calibração?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(padroesProvider.notifier)
                    .deleteHistorico(widget.padraoId, h.id);
                if (mounted) {
                  ref.invalidate(
                      historicoCalibracaoPadraoProvider(widget.padraoId));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erro ao excluir: $e'),
                    backgroundColor: NormatiqColors.danger700,
                  ));
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: NormatiqColors.danger700,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showRegistrarCalibracaoSheet(BuildContext context, {HistoricoCalibracaoPadrao? historico}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _RegistrarCalibracaoSheet(
        padraoId: widget.padraoId,
        historico: historico,
        onSaved: () {
          if (mounted) {
            ref.invalidate(
                historicoCalibracaoPadraoProvider(widget.padraoId));
          }
        },
      ),
    );
  }
}

class _RegistrarCalibracaoSheet extends ConsumerStatefulWidget {
  final int padraoId;
  final HistoricoCalibracaoPadrao? historico;
  final VoidCallback onSaved;
  const _RegistrarCalibracaoSheet(
      {required this.padraoId, this.historico, required this.onSaved});

  @override
  ConsumerState<_RegistrarCalibracaoSheet> createState() =>
      _RegistrarCalibracaoSheetState();
}

class _RegistrarCalibracaoSheetState
    extends ConsumerState<_RegistrarCalibracaoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _certCtrl = TextEditingController();
  final _labCtrl = TextEditingController();
  final _uCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  DateTime? _dataCalib;
  DateTime? _dataVenc;
  bool _aceito = true;
  bool _isLoading = false;

  bool get _isEdit => widget.historico != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final h = widget.historico!;
      _certCtrl.text = h.numeroCertificado;
      _labCtrl.text = h.laboratorioCalibrador ?? '';
      _uCtrl.text = h.uExpandidaCertificado?.toString() ?? '';
      _obsCtrl.text = h.observacoes ?? '';
      _aceito = h.aceito;
      try {
        _dataCalib = DateTime.parse(h.dataCalibracao);
        _dataVenc = DateTime.parse(h.dataVencimento);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _certCtrl.dispose();
    _labCtrl.dispose();
    _uCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isCalib) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isCalib) {
          _dataCalib = picked;
        } else {
          _dataVenc = picked;
        }
      });
    }
  }

  String _fmt(DateTime? d) =>
      d == null ? 'Selecionar' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtIso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataCalib == null || _dataVenc == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Informe as datas de calibração e vencimento.')));
      return;
    }

    // Captura o notifier antes do gap assíncrono para evitar usar 'ref' depois
    final notifier = ref.read(padroesProvider.notifier);
    final data = {
      'data_calibracao': _fmtIso(_dataCalib!),
      'data_vencimento': _fmtIso(_dataVenc!),
      'numero_certificado': _certCtrl.text.trim(),
      'laboratorio_calibrador':
          _labCtrl.text.trim().isEmpty ? null : _labCtrl.text.trim(),
      'u_expandida_certificado': double.tryParse(_uCtrl.text.trim()),
      'observacoes': _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
      'aceito': _aceito,
    };

    setState(() => _isLoading = true);
    try {
      if (_isEdit) {
        await notifier.updateHistorico(
            widget.padraoId, widget.historico!.id, data);
      } else {
        await notifier.registrarCalibracao(widget.padraoId, data);
      }

      if (!mounted) return;

      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao registrar: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir registro'),
        content: const Text('Deseja realmente excluir este registro de calibração?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: NormatiqColors.danger700),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await ref.read(padroesProvider.notifier).deleteHistorico(widget.padraoId, widget.historico!.id);
        if (mounted) {
          widget.onSaved();
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao excluir: $e'),
            backgroundColor: NormatiqColors.danger700,
          ));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: NormatiqSpacing.s4,
          right: NormatiqSpacing.s4,
          top: NormatiqSpacing.s4),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(_isEdit ? 'Editar calibração' : 'Registrar calibração',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  if (_isEdit)
                    IconButton(
                        onPressed: _isLoading ? null : _confirmDelete,
                        icon: const Icon(Icons.delete_outline,
                            color: NormatiqColors.danger700)),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: NormatiqSpacing.s4),
              TextFormField(
                controller: _certCtrl,
                decoration:
                    const InputDecoration(labelText: 'Número do certificado *'),
                enabled: !_isLoading,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Informe o certificado' : null,
              ),
              const SizedBox(height: NormatiqSpacing.s3),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text('Calibrado: ${_fmt(_dataCalib)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(false),
                      icon: const Icon(Icons.event_available, size: 16),
                      label: Text('Vencimento: ${_fmt(_dataVenc)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: NormatiqSpacing.s3),
              TextFormField(
                controller: _labCtrl,
                decoration: const InputDecoration(
                    labelText: 'Laboratório calibrador'),
                enabled: !_isLoading,
              ),
              const SizedBox(height: NormatiqSpacing.s3),
              TextFormField(
                controller: _uCtrl,
                decoration: const InputDecoration(
                    labelText: 'U expandida do certificado'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: !_isLoading,
              ),
              const SizedBox(height: NormatiqSpacing.s3),
              TextFormField(
                controller: _obsCtrl,
                decoration:
                    const InputDecoration(labelText: 'Observações'),
                maxLines: 2,
                enabled: !_isLoading,
              ),
              const SizedBox(height: NormatiqSpacing.s3),
              SwitchListTile(
                title: const Text('Resultado aceito'),
                value: _aceito,
                onChanged: _isLoading
                    ? null
                    : (v) => setState(() => _aceito = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: NormatiqSpacing.s4),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isEdit ? 'Salvar' : 'Registrar'),
              ),
              const SizedBox(height: NormatiqSpacing.s4),
            ],
          ),
        ),
      ),
    );
  }
}

// Widgets auxiliares reutilizáveis

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

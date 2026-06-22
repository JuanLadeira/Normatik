import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import 'package:dio/dio.dart';
import '../../core/api/client.dart';
import 'certificados_padrao_provider.dart';

class CertificadoAnalisePage extends ConsumerStatefulWidget {
  final int certId;
  final List<dynamic> campos;
  final String? campoXDefault;
  final String? campoYDefault;
  final String tipoDefault;
  final int grauDefault;

  const CertificadoAnalisePage({
    super.key,
    required this.certId,
    required this.campos,
    this.campoXDefault,
    this.campoYDefault,
    required this.tipoDefault,
    required this.grauDefault,
  });

  @override
  ConsumerState<CertificadoAnalisePage> createState() =>
      _CertificadoAnalisePageState();
}

class _CertificadoAnalisePageState
    extends ConsumerState<CertificadoAnalisePage> {
  CurvaCorrecaoModel? _curva;
  bool _loading = true;

  late String _campoX;
  late String _campoY;
  late String _tipo;
  late int _grau;

  // ── Helpers de default de campo ────────────────────────────────────────────

  String _defaultCampoX() {
    if (widget.campoXDefault != null) return widget.campoXDefault!;
    
    final nonCalc =
        widget.campos.where((c) => c['calculado'] == false).toList();
    if (nonCalc.isNotEmpty) return nonCalc.first['nome'] as String;
    if (widget.campos.isNotEmpty) return widget.campos.first['nome'] as String;
    return 'x';
  }

  String _defaultCampoY() {
    if (widget.campoYDefault != null) return widget.campoYDefault!;

    final calc = widget.campos
        .where((c) => c['calculado'] != false && c['calculado'] != null)
        .toList();
    if (calc.isNotEmpty) return calc.first['nome'] as String;
    if (widget.campos.length > 1) {
      return widget.campos.last['nome'] as String;
    }
    return 'y';
  }

  @override
  void initState() {
    super.initState();
    _campoX = _defaultCampoX();
    _campoY = _defaultCampoY();
    _tipo = widget.tipoDefault;
    _grau = widget.grauDefault;
    _analisar();
  }

  // ── Chamadas de API ────────────────────────────────────────────────────────

  Future<void> _analisar() async {
    setState(() => _loading = true);
    try {
      final client = ref.read(apiClientProvider);
      final r = await client.dio.post(
        '/api/certificados-padrao/certificados/${widget.certId}/analisar',
        data: {
          'campo_x': _campoX,
          'campo_y': _campoY,
          'tipo': _tipo,
          'grau': _grau,
        },
      );
      if (mounted) {
        setState(() {
          _curva = CurvaCorrecaoModel.fromJson(r.data);
          _loading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        final msg = e.response?.data?['detail'] ?? 'Erro na análise';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg.toString()),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    }
  }

  Future<void> _aprovar() async {
    final obsCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aprovar Curva'),
        content: TextField(
          controller: obsCtrl,
          decoration: const InputDecoration(
            labelText: 'Observações (opcional)',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: NormatiqColors.success700),
            child: const Text('Aprovar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final client = ref.read(apiClientProvider);
      final body = <String, dynamic>{};
      final obs = obsCtrl.text.trim();
      if (obs.isNotEmpty) body['observacoes'] = obs;

      await client.dio.post(
        '/api/certificados-padrao/certificados/${widget.certId}/aprovar',
        data: body,
      );
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data?['detail'] ?? 'Erro ao aprovar';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg.toString()),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    }
  }

  Future<void> _rejeitar() async {
    final obsCtrl = TextEditingController();
    final observacoes = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeitar Curva'),
        content: TextField(
          controller: obsCtrl,
          decoration:
              const InputDecoration(labelText: 'Motivo da rejeição *'),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (obsCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, obsCtrl.text.trim());
            },
            style: FilledButton.styleFrom(
                backgroundColor: NormatiqColors.danger700),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );

    if (observacoes == null || !mounted) return;

    try {
      final client = ref.read(apiClientProvider);
      await client.dio.post(
        '/api/certificados-padrao/certificados/${widget.certId}/rejeitar',
        data: {'observacoes': observacoes},
      );
      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data?['detail'] ?? 'Erro ao rejeitar';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg.toString()),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise da Curva'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(NormatiqSpacing.s4),
              children: [
                if (_curva != null) ...[
                  _buildGrafico(),
                  const SizedBox(height: NormatiqSpacing.s6),
                  _buildInfoCurva(),
                  const SizedBox(height: NormatiqSpacing.s4),
                ] else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(NormatiqSpacing.s4),
                      child: Text(
                        'Nenhuma curva gerada. Ajuste os parâmetros abaixo e tente novamente.',
                      ),
                    ),
                  ),
                const Divider(),
                const SizedBox(height: NormatiqSpacing.s3),
                _buildSettings(),
                const SizedBox(height: NormatiqSpacing.s6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _rejeitar,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NormatiqColors.danger700,
                          side: const BorderSide(
                              color: NormatiqColors.danger700),
                        ),
                        child: const Text('REJEITAR'),
                      ),
                    ),
                    const SizedBox(width: NormatiqSpacing.s4),
                    Expanded(
                      child: FilledButton(
                        onPressed: _curva != null ? _aprovar : null,
                        style: FilledButton.styleFrom(
                            backgroundColor: NormatiqColors.success700),
                        child: const Text('APROVAR CURVA'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NormatiqSpacing.s4),
              ],
            ),
    );
  }

  Widget _buildGrafico() {
    final spots = _curva!.pontosCurva
        .map((p) => FlSpot(p['x']!, p['y']!))
        .toList();

    return SizedBox(
      height: 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(NormatiqSpacing.s4),
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: NormatiqColors.primary600,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: NormatiqColors.primary600.withOpacity(0.07),
                  ),
                ),
              ],
              titlesData: const FlTitlesData(show: true),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCurva() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(NormatiqSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'R² = ${_curva!.rQuadrado.toStringAsFixed(6)}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: NormatiqSpacing.s3),
            const Text('Coeficientes:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ..._curva!.coeficientes.asMap().entries.map(
                  (e) => Text(
                    'a${e.key}: ${e.value.toStringAsExponential(4)}',
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    final nomesCampos =
        widget.campos.map((c) => c['nome'] as String).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONFIGURAÇÕES DA REGRESSÃO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: NormatiqSpacing.s3),

        // Dropdowns de campo X e Y (somente se houver campos)
        if (widget.campos.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: nomesCampos.contains(_campoX) ? _campoX : null,
                  decoration: const InputDecoration(labelText: 'Campo X'),
                  items: nomesCampos
                      .map((n) =>
                          DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _campoX = v);
                    _analisar();
                  },
                ),
              ),
              const SizedBox(width: NormatiqSpacing.s4),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: nomesCampos.contains(_campoY) ? _campoY : null,
                  decoration: const InputDecoration(labelText: 'Campo Y'),
                  items: nomesCampos
                      .map((n) =>
                          DropdownMenuItem(value: n, child: Text(n)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _campoY = v);
                    _analisar();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: NormatiqSpacing.s3),
        ],

        // Tipo de regressão e grau
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _tipo,
                decoration:
                    const InputDecoration(labelText: 'Tipo de Regressão'),
                items: const [
                  DropdownMenuItem(value: 'linear', child: Text('Linear')),
                  DropdownMenuItem(
                      value: 'polinomial', child: Text('Polinomial')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _tipo = v);
                  _analisar();
                },
              ),
            ),
            if (_tipo == 'polinomial') ...[
              const SizedBox(width: NormatiqSpacing.s4),
              Expanded(
                child: TextFormField(
                  initialValue: _grau.toString(),
                  decoration: const InputDecoration(labelText: 'Grau'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed > 0) {
                      _grau = parsed;
                      _analisar();
                    }
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: NormatiqSpacing.s3),

        // Botão re-analisar manual
        TextButton.icon(
          onPressed: _loading ? null : _analisar,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Reanalisar'),
        ),
      ],
    );
  }
}

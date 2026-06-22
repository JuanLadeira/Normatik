import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../api/client.dart';

/// Widget de tabela de pontos de medição — Consome o backend para cálculos.
class PontosMedicaoWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic> config;
  final List<Map<String, dynamic>> pontosIniciais;
  final Function(List<Map<String, dynamic>>) onSaved;
  final int? certificadoId; 

  const PontosMedicaoWidget({
    super.key,
    required this.config,
    this.pontosIniciais = const [],
    required this.onSaved,
    this.certificadoId,
  });

  @override
  ConsumerState<PontosMedicaoWidget> createState() => _PontosMedicaoWidgetState();
}

class _PontosMedicaoWidgetState extends ConsumerState<PontosMedicaoWidget> {
  late List<Map<String, dynamic>> _pontos;
  late List<dynamic> _colunas;
  bool _calculating = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _colunas = widget.config['colunas'] ?? [];
    _pontos = widget.pontosIniciais
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    if (_pontos.isEmpty) {
      _addLinha();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _addLinha() {
    setState(() {
      final novaLinha = <String, dynamic>{};
      for (var col in _colunas) {
        novaLinha[col['nome']] = null;
      }
      _pontos.add(novaLinha);
    });
  }

  void _removeLinha(int index) {
    setState(() {
      _pontos.removeAt(index);
    });
  }

  void _updateValor(int rowIndex, String colNome, String value) {
    setState(() {
      _pontos[rowIndex][colNome] = double.tryParse(value);
    });
    
    // Se temos o ID do certificado, podemos disparar o cálculo real no backend
    if (widget.certificadoId != null) {
      _triggerLiveCalculation();
    }
  }

  void _triggerLiveCalculation() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () => _doCalculate());
  }

  Future<void> _doCalculate() async {
    if (widget.certificadoId == null || !mounted) return;
    setState(() => _calculating = true);

    try {
      final client = ref.read(apiClientProvider);
      final r = await client.dio.post(
        '/api/certificados-padrao/certificados/${widget.certificadoId}/calcular-pontos',
        data: _pontos,
      );

      if (mounted) {
        setState(() {
          _pontos = (r.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
          _calculating = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _calculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_calculating)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 12,
            columnSpacing: 24,
            columns: [
              ..._colunas.map((col) => DataColumn(
                    label: Text(
                      col['label'] as String? ?? col['nome'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  )),
              const DataColumn(label: Text('')),
            ],
            rows: _pontos.asMap().entries.map((entry) {
              final idx = entry.key;
              final row = entry.value;
              return DataRow(
                cells: [
                  ..._colunas.map((col) {
                    final key = col['nome'] as String;
                    final isCalc = col['calculado'] != false && col['calculado'] != null;
                    final val = row[key];

                    return DataCell(
                      isCalc
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: NormatiqColors.neutral100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                val != null ? (val as num).toDouble().toStringAsFixed(4) : '-',
                                style: const TextStyle(fontSize: 13, color: NormatiqColors.neutral600),
                              ),
                            )
                          : SizedBox(
                              width: 80,
                              child: TextFormField(
                                key: ValueKey('${idx}_$key'),
                                initialValue: val?.toString() ?? '',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: '0.0',
                                ),
                                style: const TextStyle(fontSize: 13),
                                onChanged: (v) => _updateValor(idx, key, v),
                              ),
                            ),
                    );
                  }),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20, color: NormatiqColors.danger700),
                      onPressed: () => _removeLinha(idx),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: NormatiqSpacing.s4),
        OutlinedButton.icon(
          onPressed: _addLinha,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('ADICIONAR PONTO'),
        ),
        const SizedBox(height: NormatiqSpacing.s6),
        FilledButton(
          onPressed: _calculating ? null : () => widget.onSaved(_pontos),
          child: const Text('SALVAR PONTOS'),
        ),
      ],
    );
  }
}

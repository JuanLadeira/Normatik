import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:normatiq_ui/normatiq_ui.dart';

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

  @override
  void initState() {
    super.initState();
    // Aceita o formato novo ('colunas') e o legado ('campos').
    _colunas = (widget.config['colunas'] ?? widget.config['campos'] ?? []) as List;
    _pontos = widget.pontosIniciais
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    if (_pontos.isEmpty) {
      _pontos.add(_novaLinha());
    }
    // Garante que colunas calculadas já apareçam preenchidas ao abrir.
    for (final row in _pontos) {
      _recalcLinha(row);
    }
  }

  Map<String, dynamic> _novaLinha() {
    final linha = <String, dynamic>{};
    for (var col in _colunas) {
      linha[col['nome']] = null;
    }
    return linha;
  }

  void _addLinha() {
    setState(() => _pontos.add(_novaLinha()));
  }

  void _removeLinha(int index) {
    setState(() => _pontos.removeAt(index));
  }

  void _updateValor(int rowIndex, String colNome, String value) {
    setState(() {
      _pontos[rowIndex][colNome] = double.tryParse(value);
      _recalcLinha(_pontos[rowIndex]);
    });
  }

  /// Recalcula as colunas derivadas de uma linha localmente, replicando o
  /// `_derivar_campos` do backend. Suporta o formato novo (calculado ∈
  /// {media, erro, subtracao} + origem) e o legado (fórmulas avg(...) e a-b).
  /// Duas passadas para resolver cálculos que dependem de outra coluna
  /// calculada (ex: erro = media - nominal).
  void _recalcLinha(Map<String, dynamic> row) {
    for (var pass = 0; pass < 2; pass++) {
      for (final col in _colunas) {
        final calc = col['calculado'];
        if (calc == false || calc == null) continue;
        row[col['nome']] = _calcularCampo(calc, col['origem'], row);
      }
    }
  }

  double? _calcularCampo(dynamic calc, dynamic origemRaw, Map<String, dynamic> row) {
    double? num2(dynamic v) => (v is num) ? v.toDouble() : null;
    final origem = (origemRaw is List) ? origemRaw : const [];

    if (calc == 'media') {
      final vals = origem.map((o) => num2(row[o])).whereType<double>().toList();
      if (vals.isEmpty) return null;
      return vals.reduce((a, b) => a + b) / vals.length;
    }
    if (calc == 'erro' || calc == 'subtracao') {
      if (origem.length < 2) return null;
      final a = num2(row[origem[0]]);
      final b = num2(row[origem[1]]);
      return (a != null && b != null) ? a - b : null;
    }
    // Formato legado: fórmula em string.
    if (calc is String) {
      final s = calc.replaceAll(' ', '');
      final avg = RegExp(r'^avg\((.*)\)$').firstMatch(s);
      if (avg != null) {
        final args = avg.group(1)!.split(',').where((e) => e.isNotEmpty);
        final vals = args.map((o) => num2(row[o])).whereType<double>().toList();
        if (vals.isEmpty) return null;
        return vals.reduce((a, b) => a + b) / vals.length;
      }
      final parts = s.split('-');
      if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        final a = num2(row[parts[0]]);
        final b = num2(row[parts[1]]);
        return (a != null && b != null) ? a - b : null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          onPressed: () => widget.onSaved(_pontos),
          child: const Text('SALVAR PONTOS'),
        ),
      ],
    );
  }
}

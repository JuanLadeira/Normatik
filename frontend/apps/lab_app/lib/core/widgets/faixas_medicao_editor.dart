import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../providers/equipment_catalog_provider.dart';
import '../providers/grandeza_provider.dart';

// ── Modelo de leitura (response da API) ───────────────────────────────────────

class FaixaMedicaoModel {
  final int id;
  final int equipamentoId;
  final int unidadeId;
  final String unidadeNome;
  final String unidadeSimbolo;
  final double? valorMin;
  final double? valorMax;
  final double? resolucao;
  final int posicao;

  FaixaMedicaoModel({
    required this.id,
    required this.equipamentoId,
    required this.unidadeId,
    required this.unidadeNome,
    required this.unidadeSimbolo,
    this.valorMin,
    this.valorMax,
    this.resolucao,
    required this.posicao,
  });

  factory FaixaMedicaoModel.fromJson(Map<String, dynamic> json) =>
      FaixaMedicaoModel(
        id: json['id'],
        equipamentoId: json['equipamento_id'],
        unidadeId: json['unidade_id'],
        unidadeNome: json['unidade']['nome'],
        unidadeSimbolo: json['unidade']['simbolo'],
        valorMin: (json['valor_min'] as num?)?.toDouble(),
        valorMax: (json['valor_max'] as num?)?.toDouble(),
        resolucao: (json['resolucao'] as num?)?.toDouble(),
        posicao: json['posicao'],
      );

  String get label {
    final partes = <String>[];
    if (valorMin != null || valorMax != null) {
      final min = valorMin != null ? _fmt(valorMin!) : '?';
      final max = valorMax != null ? _fmt(valorMax!) : '?';
      partes.add('$min – $max $unidadeSimbolo');
    } else {
      partes.add(unidadeSimbolo);
    }
    if (resolucao != null) partes.add('res. ${_fmt(resolucao!)} $unidadeSimbolo');
    return partes.join('  ·  ');
  }

  static String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();
}

// ── Estado interno de uma linha no formulário ─────────────────────────────────

class _FaixaInput {
  int? unidadeId;
  final TextEditingController valorMinCtrl;
  final TextEditingController valorMaxCtrl;
  final TextEditingController resolucaoCtrl;

  _FaixaInput({this.unidadeId})
      : valorMinCtrl = TextEditingController(),
        valorMaxCtrl = TextEditingController(),
        resolucaoCtrl = TextEditingController();

  void dispose() {
    valorMinCtrl.dispose();
    valorMaxCtrl.dispose();
    resolucaoCtrl.dispose();
  }

  Map<String, dynamic>? toJson() {
    if (unidadeId == null) return null;
    return {
      'unidade_id': unidadeId!,
      if (valorMinCtrl.text.trim().isNotEmpty)
        'valor_min': double.tryParse(valorMinCtrl.text.trim()),
      if (valorMaxCtrl.text.trim().isNotEmpty)
        'valor_max': double.tryParse(valorMaxCtrl.text.trim()),
      if (resolucaoCtrl.text.trim().isNotEmpty)
        'resolucao': double.tryParse(resolucaoCtrl.text.trim()),
    };
  }
}

// ── Widget público ─────────────────────────────────────────────────────────────

class FaixasMedicaoEditor extends ConsumerStatefulWidget {
  final int? tipoEquipamentoId;
  final List<FaixaMedicaoModel> initialFaixas;
  final bool enabled;

  const FaixasMedicaoEditor({
    super.key,
    this.tipoEquipamentoId,
    this.initialFaixas = const [],
    this.enabled = true,
  });

  @override
  ConsumerState<FaixasMedicaoEditor> createState() => FaixasMedicaoEditorState();
}

class FaixasMedicaoEditorState extends ConsumerState<FaixasMedicaoEditor> {
  final List<_FaixaInput> _faixas = [];

  @override
  void initState() {
    super.initState();
    for (final f in widget.initialFaixas) {
      final input = _FaixaInput(unidadeId: f.unidadeId);
      if (f.valorMin != null) input.valorMinCtrl.text = f.valorMin!.toString();
      if (f.valorMax != null) input.valorMaxCtrl.text = f.valorMax!.toString();
      if (f.resolucao != null) input.resolucaoCtrl.text = f.resolucao!.toString();
      _faixas.add(input);
    }
  }

  /// Retorna a lista de faixas prontas para o payload da API.
  /// Faixas sem unidade selecionada são ignoradas.
  List<Map<String, dynamic>> getData() =>
      _faixas.map((f) => f.toJson()).whereType<Map<String, dynamic>>().toList();

  bool get hasValidFaixa => _faixas.any((f) => f.unidadeId != null);

  @override
  void dispose() {
    for (final f in _faixas) f.dispose();
    super.dispose();
  }

  List<UnidadeMedida> _unidades() {
    if (widget.tipoEquipamentoId == null) return [];
    final tipos = ref.watch(tiposEquipamentoProvider).valueOrNull ?? [];
    final tipo = tipos.where((t) => t.id == widget.tipoEquipamentoId).firstOrNull;
    if (tipo == null) return [];
    final grandezas = ref.watch(grandezasProvider).valueOrNull ?? [];
    final grandeza = grandezas.where((g) => g.id == tipo.grandezaId).firstOrNull;
    return grandeza?.unidades ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final unidades = _unidades();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FAIXAS DE MEDIÇÃO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            letterSpacing: 1,
          ),
        ),
        if (widget.tipoEquipamentoId == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Selecione o tipo de equipamento para adicionar faixas.',
              style: TextStyle(fontSize: 13, color: NormatiqColors.neutral500),
            ),
          )
        else ...[
          if (_faixas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhuma faixa cadastrada.',
                style: TextStyle(fontSize: 13, color: NormatiqColors.neutral500),
              ),
            ),
          ..._faixas.asMap().entries.map(
                (e) => _FaixaRow(
                  key: ValueKey(e.key),
                  faixa: e.value,
                  unidades: unidades,
                  enabled: widget.enabled,
                  onRemove: () => setState(() {
                    e.value.dispose();
                    _faixas.removeAt(e.key);
                  }),
                  onChanged: () => setState(() {}),
                ),
              ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: widget.enabled
                ? () => setState(() => _faixas.add(_FaixaInput()))
                : null,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar faixa'),
            style: TextButton.styleFrom(
              foregroundColor: NormatiqColors.primary600,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Linha individual de faixa ──────────────────────────────────────────────────

class _FaixaRow extends StatelessWidget {
  final _FaixaInput faixa;
  final List<UnidadeMedida> unidades;
  final bool enabled;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _FaixaRow({
    super.key,
    required this.faixa,
    required this.unidades,
    required this.enabled,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dropdown de unidade
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<int>(
              value: faixa.unidadeId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Unidade *',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              items: unidades
                  .map((u) => DropdownMenuItem(
                        value: u.id,
                        child: Text('${u.simbolo}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: enabled
                  ? (v) {
                      faixa.unidadeId = v;
                      onChanged();
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          // Valor mínimo
          Expanded(
            flex: 3,
            child: TextField(
              controller: faixa.valorMinCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Mín',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              enabled: enabled,
            ),
          ),
          const SizedBox(width: 6),
          // Valor máximo
          Expanded(
            flex: 3,
            child: TextField(
              controller: faixa.valorMaxCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Máx',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              enabled: enabled,
            ),
          ),
          const SizedBox(width: 6),
          // Resolução
          Expanded(
            flex: 3,
            child: TextField(
              controller: faixa.resolucaoCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Res.',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              enabled: enabled,
            ),
          ),
          // Remover
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              color: NormatiqColors.danger700,
              onPressed: enabled ? onRemove : null,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

}

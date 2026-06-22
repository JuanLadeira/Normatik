import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import 'package:dio/dio.dart';
import '../../../core/api/client.dart';
import '../../../core/providers/equipment_catalog_provider.dart';
import '../certificados_padrao_provider.dart';

class TemplateSelectorField extends ConsumerWidget {
  final FormularioTemplateModel? selectedTemplate;
  final Function(FormularioTemplateModel?) onSelected;
  final bool isLoading;

  const TemplateSelectorField({
    super.key,
    required this.selectedTemplate,
    required this.onSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Template de Medição',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: NormatiqColors.neutral500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: isLoading ? null : () => _showSelector(context, ref),
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: NormatiqSpacing.s3,
              vertical: NormatiqSpacing.s3,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: NormatiqColors.neutral300),
              borderRadius: BorderRadius.circular(NormatiqRadius.md),
              color: isLoading ? NormatiqColors.neutral100 : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  size: 20,
                  color: selectedTemplate != null
                      ? NormatiqColors.primary600
                      : NormatiqColors.neutral400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedTemplate?.nome ?? 'Selecionar template...',
                    style: TextStyle(
                      color: selectedTemplate != null
                          ? Theme.of(context).colorScheme.onSurface
                          : NormatiqColors.neutral500,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: NormatiqColors.neutral400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _TemplateSelectionSheet(
        selectedTemplate: selectedTemplate,
        onSelected: onSelected,
      ),
    );
  }
}

class _TemplateSelectionSheet extends ConsumerWidget {
  final FormularioTemplateModel? selectedTemplate;
  final Function(FormularioTemplateModel?) onSelected;

  const _TemplateSelectionSheet({
    required this.selectedTemplate,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesCertificadoProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NormatiqColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Selecionar Template',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: templatesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
                data: (templates) {
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: templates.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          leading: const Icon(Icons.block, color: NormatiqColors.neutral500),
                          title: const Text('Nenhum template'),
                          selected: selectedTemplate == null,
                          onTap: () {
                            onSelected(null);
                            Navigator.pop(context);
                          },
                        );
                      }
                      final t = templates[index - 1];
                      return ListTile(
                        leading: const Icon(Icons.table_chart_outlined, color: NormatiqColors.primary600),
                        title: Text(t.nome),
                        subtitle: Text('${t.campos.length} colunas | ${t.tipoRegressaoDefault}'),
                        selected: selectedTemplate?.id == t.id,
                        onTap: () {
                          onSelected(t);
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('CRIAR NOVO TEMPLATE'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CreateTemplateDialog(
        onCreated: (newTemplate) {
          onSelected(newTemplate);
          Navigator.pop(context); // Close sheet
        },
      ),
    );
  }
}

class _CreateTemplateDialog extends StatefulWidget {
  final Function(FormularioTemplateModel) onCreated;

  const _CreateTemplateDialog({required this.onCreated});

  @override
  State<_CreateTemplateDialog> createState() => _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends State<_CreateTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  int? _tipoId;
  String _tipoRegressao = 'linear';
  int _grau = 1;
  int? _quantidadePontos = 10;
  bool _loading = false;

  List<Map<String, dynamic>> _colunas = [
    {'nome': 'valor_nominal', 'label': 'Padrão', 'calculado': false, 'origem': []},
    {'nome': 'erro', 'label': 'Erro', 'calculado': 'erro', 'origem': []},
  ];

  String? _campoX = 'valor_nominal';
  String? _campoY = 'erro';

  void _addColuna() {
    setState(() {
      _colunas.add({'nome': '', 'label': '', 'calculado': false, 'origem': []});
    });
  }

  void _removeColuna(int index) {
    if (_colunas.length <= 1) return;
    setState(() {
      _colunas.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final tiposAsync = ref.watch(tiposEquipamentoProvider);

        return AlertDialog(
          title: const Text('Novo Template'),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nomeCtrl,
                      decoration: const InputDecoration(labelText: 'Nome do Template *'),
                      validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    tiposAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Erro: $e'),
                      data: (tipos) => DropdownButtonFormField<int>(
                        value: _tipoId,
                        decoration: const InputDecoration(labelText: 'Tipo de Instrumento *'),
                        items: tipos
                            .map((t) => DropdownMenuItem(value: t.id, child: Text(t.nome)))
                            .toList(),
                        onChanged: (v) => setState(() => _tipoId = v),
                        validator: (v) => v == null ? 'Obrigatório' : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('COLUNAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const Divider(),
                    ...List.generate(_colunas.length, (index) => _buildColunaRow(index)),
                    TextButton.icon(
                      onPressed: _addColuna,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Adicionar Coluna'),
                    ),
                    const SizedBox(height: 20),
                    const Text('REGRESSÃO E REGRAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _tipoRegressao,
                            decoration: const InputDecoration(labelText: 'Tipo'),
                            items: const [
                              DropdownMenuItem(value: 'linear', child: Text('Linear')),
                              DropdownMenuItem(value: 'polinomial', child: Text('Polinomial')),
                            ],
                            onChanged: (v) => setState(() {
                              _tipoRegressao = v!;
                              _grau = _tipoRegressao == 'linear' ? 1 : 2;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_tipoRegressao == 'polinomial') ...[
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _grau,
                              decoration: const InputDecoration(labelText: 'Grau'),
                              items: [2, 3, 4, 5, 6]
                                  .map((g) => DropdownMenuItem(value: g, child: Text(g.toString())))
                                  .toList(),
                              onChanged: (v) => setState(() => _grau = v!),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: TextFormField(
                            initialValue: _quantidadePontos?.toString(),
                            decoration: const InputDecoration(labelText: 'Qtd. Pontos'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _quantidadePontos = int.tryParse(v),
                            validator: (v) {
                              if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                                return 'Inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _colunas.any((c) => c['nome'] == _campoX && (c['nome'] as String).isNotEmpty) ? _campoX : null,
                            decoration: const InputDecoration(labelText: 'Eixo X'),
                            items: _colunas
                                .where((c) => (c['nome'] as String).isNotEmpty)
                                .fold<List<Map<String, dynamic>>>([], (list, item) {
                                  if (!list.any((c) => c['nome'] == item['nome'])) {
                                    list.add(item);
                                  }
                                  return list;
                                })
                                .map((c) => DropdownMenuItem(
                                    value: c['nome'] as String, child: Text(c['label'] as String)))
                                .toList(),
                            onChanged: (v) => setState(() => _campoX = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _colunas.any((c) => c['nome'] == _campoY && (c['nome'] as String).isNotEmpty) ? _campoY : null,
                            decoration: const InputDecoration(labelText: 'Eixo Y'),
                            items: _colunas
                                .where((c) => (c['nome'] as String).isNotEmpty)
                                .fold<List<Map<String, dynamic>>>([], (list, item) {
                                  if (!list.any((c) => c['nome'] == item['nome'])) {
                                    list.add(item);
                                  }
                                  return list;
                                })
                                .map((c) => DropdownMenuItem(
                                    value: c['nome'] as String, child: Text(c['label'] as String)))
                                .toList(),
                            onChanged: (v) => setState(() => _campoY = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _loading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: _loading ? null : () => _submit(ref),
              child: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Criar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColunaRow(int index) {
    final col = _colunas[index];
    final isCalculated = col['calculado'] != false && col['calculado'] != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: col['label'],
              decoration: const InputDecoration(labelText: 'Rótulo', isDense: true),
              onChanged: (v) => setState(() {
                col['label'] = v;
                if (col['nome'].isEmpty) {
                  col['nome'] = v.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '');
                }
              }),
              validator: (v) => v!.isEmpty ? 'Err' : null,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: col['nome'],
              decoration: const InputDecoration(labelText: 'ID', isDense: true),
              onChanged: (v) => setState(() => col['nome'] = v),
              validator: (v) => v!.isEmpty ? 'Err' : null,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<dynamic>(
              value: col['calculado'],
              decoration: const InputDecoration(labelText: 'Cálculo', isDense: true),
              items: const [
                DropdownMenuItem(value: false, child: Text('Manual')),
                DropdownMenuItem(value: 'media', child: Text('Média')),
                DropdownMenuItem(value: 'erro', child: Text('Erro')),
                DropdownMenuItem(value: 'subtracao', child: Text('Subtr.')),
              ],
              onChanged: (v) => setState(() {
                col['calculado'] = v;
                col['origem'] = [];
              }),
            ),
          ),
          if (isCalculated) ...[
            const SizedBox(width: 4),
            Expanded(
              flex: 4,
              child: _buildOrigemSelector(index),
            ),
          ],
          IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove_circle_outline, color: NormatiqColors.danger700, size: 20),
            onPressed: () => _removeColuna(index),
          ),
        ],
      ),
    );
  }

  Widget _buildOrigemSelector(int index) {
    final col = _colunas[index];
    final preset = col['calculado'];
    final List<dynamic> origem = col['origem'] ?? [];
    
    final colunasDisponiveis = _colunas
        .where((c) => c['nome'] != null && (c['nome'] as String).isNotEmpty && c['nome'] != col['nome'])
        .fold<List<Map<String, dynamic>>>([], (list, item) {
          if (!list.any((c) => c['nome'] == item['nome'])) {
            list.add(item);
          }
          return list;
        })
        .toList();

    if (preset == 'media') {
      return Wrap(
        spacing: 2,
        children: colunasDisponiveis.map((c) {
          final nome = c['nome'] as String;
          final selected = origem.contains(nome);
          return FilterChip(
            label: Text(c['label'], style: const TextStyle(fontSize: 9)),
            selected: selected,
            padding: EdgeInsets.zero,
            onSelected: (val) {
              setState(() {
                if (val) {
                  origem.add(nome);
                } else {
                  origem.remove(nome);
                }
                col['origem'] = origem;
              });
            },
          );
        }).toList(),
      );
    } else {
      final String? a = origem.isNotEmpty ? origem[0] : null;
      final String? b = origem.length > 1 ? origem[1] : null;

      return Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: colunasDisponiveis.any((c) => c['nome'] == a) ? a : null,
              items: colunasDisponiveis.map((c) => DropdownMenuItem(
                value: c['nome'] as String,
                child: Text(c['label'], style: const TextStyle(fontSize: 10)),
              )).toList(),
              onChanged: (v) => setState(() {
                if (origem.isEmpty) {
                  col['origem'] = [v, null];
                } else {
                  origem[0] = v;
                  col['origem'] = origem;
                }
              }),
            ),
          ),
          const Text('-', style: TextStyle(fontSize: 10)),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: colunasDisponiveis.any((c) => c['nome'] == b) ? b : null,
              items: colunasDisponiveis.map((c) => DropdownMenuItem(
                value: c['nome'] as String,
                child: Text(c['label'], style: const TextStyle(fontSize: 10)),
              )).toList(),
              onChanged: (v) => setState(() {
                if (origem.length < 2) {
                  col['origem'] = [origem.firstOrNull, v];
                } else {
                  origem[1] = v;
                  col['origem'] = origem;
                }
              }),
            ),
          ),
        ],
      );
    }
  }

  Future<void> _submit(WidgetRef ref) async {
    if (!_formKey.currentState!.validate()) return;
    if (_campoX == null || _campoY == null) return;

    setState(() => _loading = true);

    final client = ref.read(apiClientProvider);
    try {
      final data = {
        'nome': _nomeCtrl.text.trim(),
        'tipo_instrumento_id': _tipoId,
        'tipo_regressao_default': _tipoRegressao,
        'grau_polinomio_default': _grau,
        'quantidade_pontos_default': _quantidadePontos,
        'campos_pontos': {
          'colunas': _colunas,
          'campo_regressao_x': _campoX,
          'campo_regressao_y': _campoY,
        }
      };

      final r = await client.dio.post('/api/certificados-padrao/templates', data: data);
      final newTemplate = FormularioTemplateModel.fromJson(r.data);
      
      ref.invalidate(templatesCertificadoProvider);
      
      if (mounted) {
        widget.onCreated(newTemplate);
        Navigator.pop(context); // Close dialog
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: ${e.response?.data?['detail'] ?? e.message}'),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

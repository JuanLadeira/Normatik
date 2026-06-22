import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import 'package:dio/dio.dart';
import '../../core/api/client.dart';
import '../../core/providers/equipment_catalog_provider.dart';
import '../padroes/certificados_padrao_provider.dart';

class TemplatesMedicaoPage extends ConsumerWidget {
  const TemplatesMedicaoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesCertificadoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Templates de Medição',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: () => _showTemplateDialog(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Novo template'),
          ),
        ],
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.table_chart_outlined,
                      size: 48, color: NormatiqColors.neutral400),
                  const SizedBox(height: 12),
                  const Text('Nenhum template cadastrado.',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showTemplateDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar template'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(NormatiqSpacing.s4),
            itemCount: templates.length,
            separatorBuilder: (_, __) => const SizedBox(height: NormatiqSpacing.s2),
            itemBuilder: (context, i) =>
                _TemplateCard(template: templates[i]),
          );
        },
      ),
    );
  }

  void _showTemplateDialog(BuildContext context, WidgetRef ref, {FormularioTemplateModel? template}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TemplateFormDialog(ref: ref, template: template),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final FormularioTemplateModel template;
  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiposAsync = ref.watch(tiposEquipamentoProvider);
    final tipoNome = tiposAsync.maybeWhen(
      data: (tipos) => tipos
          .where((t) => t.id == template.tipoInstrumentoId)
          .firstOrNull
          ?.nome,
      orElse: () => null,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _TemplateFormDialog(ref: ref, template: template),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: NormatiqColors.primary600.withOpacity(0.1),
            borderRadius: BorderRadius.circular(NormatiqRadius.sm),
          ),
          child: const Icon(Icons.table_chart_outlined,
              size: 20, color: NormatiqColors.primary600),
        ),
        title: Text(template.nome,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tipoNome != null)
              Text('Instrumento: $tipoNome',
                  style: const TextStyle(fontSize: 12)),
            Text(
                '${template.campos.length} colunas | Regressão: ${template.tipoRegressaoDefault}',
                style: const TextStyle(
                    fontSize: 12, color: NormatiqColors.neutral500)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: NormatiqColors.danger700),
          onPressed: () => _confirmDelete(context, ref),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Template'),
        content: Text('Deseja realmente excluir o template "${template.nome}"?'),
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

    if (confirmed == true) {
      final client = ref.read(apiClientProvider);
      try {
        await client.dio.delete('/api/certificados-padrao/templates/${template.id}');
        ref.invalidate(templatesCertificadoProvider);
      } on DioException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao excluir: ${e.response?.data?['detail'] ?? e.message}'),
            backgroundColor: NormatiqColors.danger700,
          ));
        }
      }
    }
  }
}

class _TemplateFormDialog extends StatefulWidget {
  final WidgetRef ref;
  final FormularioTemplateModel? template;
  const _TemplateFormDialog({required this.ref, this.template});

  @override
  State<_TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends State<_TemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  int? _tipoId;
  String _tipoRegressao = 'linear';
  int _grau = 1;
  int? _quantidadePontos = 10;
  bool _loading = false;

  List<Map<String, dynamic>> _colunas = [];
  String? _campoX;
  String? _campoY;

  bool get _isEdit => widget.template != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.template!;
      _nomeCtrl.text = t.nome;
      _tipoId = t.tipoInstrumentoId;
      _tipoRegressao = t.tipoRegressaoDefault;
      _grau = t.grauPolinomioDefault;
      _quantidadePontos = t.quantidadePontosDefault;
      _colunas = List<Map<String, dynamic>>.from(t.campos.map((c) => Map<String, dynamic>.from(c)));
      _campoX = t.campoRegressaoX;
      _campoY = t.campoRegressaoY;
    } else {
      _colunas = [
        {'nome': 'valor_nominal', 'label': 'Padrão', 'calculado': false},
        {'nome': 'erro', 'label': 'Erro', 'calculado': 'erro', 'origem': []},
      ];
      _campoX = 'valor_nominal';
      _campoY = 'erro';
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

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
    final tiposAsync = widget.ref.watch(tiposEquipamentoProvider);

    return AlertDialog(
      title: Text(_isEdit ? 'Editar Template' : 'Novo Template'),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(title: 'Dados Gerais'),
                TextFormField(
                  controller: _nomeCtrl,
                  decoration: const InputDecoration(labelText: 'Nome do Template *'),
                  validator: (v) => v!.trim().isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 16),
                tiposAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Erro: $e'),
                  data: (tipos) => DropdownButtonFormField<int>(
                    value: _tipoId,
                    decoration: const InputDecoration(labelText: 'Tipo de Instrumento *'),
                    items: tipos
                        .map((t) => DropdownMenuItem(value: t.id, child: Text(t.nome)))
                        .toList(),
                    onChanged: _isEdit ? null : (v) => setState(() => _tipoId = v),
                    validator: (v) => v == null ? 'Obrigatório' : null,
                  ),
                ),
                const SizedBox(height: 24),
                
                _SectionHeader(title: 'Definição de Colunas'),
                const Text(
                  'Campos de entrada e cálculos automatizados.',
                  style: TextStyle(fontSize: 12, color: NormatiqColors.neutral500),
                ),
                const SizedBox(height: 12),
                ...List.generate(_colunas.length, (index) => _buildColunaRow(index)),
                TextButton.icon(
                  onPressed: _addColuna,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Adicionar Coluna'),
                ),
                const SizedBox(height: 24),

                _SectionHeader(title: 'Regressão e Análise'),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _tipoRegressao,
                        decoration: const InputDecoration(labelText: 'Tipo de Regressão'),
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
                    const SizedBox(width: 12),
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
                      const SizedBox(width: 12),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _colunas.any((c) => c['nome'] == _campoX && (c['nome'] as String).isNotEmpty) ? _campoX : null,
                        decoration: const InputDecoration(labelText: 'Eixo X (Referência)'),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _colunas.any((c) => c['nome'] == _campoY && (c['nome'] as String).isNotEmpty) ? _campoY : null,
                        decoration: const InputDecoration(labelText: 'Eixo Y (Erro)'),
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
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_isEdit ? 'Salvar Alterações' : 'Criar Template'),
        ),
      ],
    );
  }

  Widget _buildColunaRow(int index) {
    final col = _colunas[index];
    final isCalculated = col['calculado'] != false && col['calculado'] != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
              validator: (v) => v!.isEmpty ? 'Erro' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: col['nome'],
              decoration: const InputDecoration(labelText: 'ID (Nome Técnico)', isDense: true),
              onChanged: (v) => setState(() => col['nome'] = v),
              validator: (v) => v!.isEmpty ? 'Erro' : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<dynamic>(
              value: col['calculado'],
              decoration: const InputDecoration(labelText: 'Tipo de Campo', isDense: true),
              items: const [
                DropdownMenuItem(value: false, child: Text('Entrada (Manual)')),
                DropdownMenuItem(value: 'media', child: Text('Média')),
                DropdownMenuItem(value: 'erro', child: Text('Erro (L-Ref)')),
                DropdownMenuItem(value: 'subtracao', child: Text('Subtração (A-B)')),
              ],
              onChanged: (v) => setState(() {
                col['calculado'] = v;
                col['origem'] = [];
              }),
            ),
          ),
          if (isCalculated) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: _buildOrigemSelector(index),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: NormatiqColors.danger700),
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
    
    // Filtra colunas disponíveis (não calculadas ou com ID preenchido)
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
        spacing: 4,
        children: colunasDisponiveis.map((c) {
          final nome = c['nome'] as String;
          final selected = origem.contains(nome);
          return FilterChip(
            label: Text(c['label'], style: const TextStyle(fontSize: 10)),
            selected: selected,
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
      // erro ou subtracao (A - B)
      final String? a = origem.isNotEmpty ? origem[0] : null;
      final String? b = origem.length > 1 ? origem[1] : null;

      return Row(
        children: [
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: colunasDisponiveis.any((c) => c['nome'] == a) ? a : null,
              hint: const Text('A', style: TextStyle(fontSize: 11)),
              items: colunasDisponiveis.map((c) => DropdownMenuItem(
                value: c['nome'] as String,
                child: Text(c['label'], style: const TextStyle(fontSize: 11)),
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
          const Text(' - ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: colunasDisponiveis.any((c) => c['nome'] == b) ? b : null,
              hint: const Text('B', style: TextStyle(fontSize: 11)),
              items: colunasDisponiveis.map((c) => DropdownMenuItem(
                value: c['nome'] as String,
                child: Text(c['label'], style: const TextStyle(fontSize: 11)),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_campoX == null || _campoY == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecione os eixos X e Y para a regressão.'),
        backgroundColor: NormatiqColors.danger700,
      ));
      return;
    }

    setState(() => _loading = true);

    final client = widget.ref.read(apiClientProvider);
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

      if (_isEdit) {
        await client.dio.put('/api/certificados-padrao/templates/${widget.template!.id}', data: data);
      } else {
        await client.dio.post('/api/certificados-padrao/templates', data: data);
      }

      widget.ref.invalidate(templatesCertificadoProvider);
      if (mounted) Navigator.pop(context);
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              letterSpacing: 1.2,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

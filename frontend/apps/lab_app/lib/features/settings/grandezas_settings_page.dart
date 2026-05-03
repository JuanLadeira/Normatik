import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../../core/providers/grandeza_provider.dart';

class GrandezasSettingsPage extends ConsumerWidget {
  const GrandezasSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grandezasAsync = ref.watch(grandezasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Grandezas e Unidades',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: () => _showNovaGrandezaDialog(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nova grandeza'),
          ),
        ],
      ),
      body: grandezasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (grandezas) {
          if (grandezas.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.straighten_outlined,
                      size: 48, color: NormatiqColors.neutral400),
                  const SizedBox(height: 12),
                  const Text('Nenhuma grandeza cadastrada.',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showNovaGrandezaDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar grandeza'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(NormatiqSpacing.s4),
            itemCount: grandezas.length,
            separatorBuilder: (_, __) => const SizedBox(height: NormatiqSpacing.s2),
            itemBuilder: (context, i) =>
                _GrandezaCard(grandeza: grandezas[i]),
          );
        },
      ),
    );
  }

  void _showNovaGrandezaDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _NovaGrandezaDialog(ref: ref),
    );
  }
}

class _GrandezaCard extends ConsumerStatefulWidget {
  final Grandeza grandeza;
  const _GrandezaCard({required this.grandeza});

  @override
  ConsumerState<_GrandezaCard> createState() => _GrandezaCardState();
}

class _GrandezaCardState extends ConsumerState<_GrandezaCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final g = widget.grandeza;
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: NormatiqColors.primary600.withOpacity(0.1),
                borderRadius: BorderRadius.circular(NormatiqRadius.sm),
              ),
              child: Text(
                g.simbolo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: NormatiqColors.primary600,
                ),
              ),
            ),
            title: Text(g.nome,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${g.unidades.length} unidade(s)',
                style: const TextStyle(
                    fontSize: 12, color: NormatiqColors.neutral500)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: NormatiqColors.neutral500,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: NormatiqColors.danger700, size: 20),
                  onPressed: () => _confirmDelete(context, g),
                ),
              ],
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  NormatiqSpacing.s4, NormatiqSpacing.s3,
                  NormatiqSpacing.s4, NormatiqSpacing.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (g.unidades.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhuma unidade cadastrada para esta grandeza.',
                        style: TextStyle(
                            fontSize: 13, color: NormatiqColors.neutral500),
                      ),
                    )
                  else
                    ...g.unidades.map((u) => _UnidadeRow(
                          unidade: u,
                          grandezaId: g.id,
                        )),
                  const SizedBox(height: NormatiqSpacing.s2),
                  TextButton.icon(
                    onPressed: () => _showAddUnidadeDialog(context, g.id),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Adicionar unidade'),
                    style: TextButton.styleFrom(
                      foregroundColor: NormatiqColors.primary600,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddUnidadeDialog(BuildContext context, int grandezaId) {
    showDialog(
      context: context,
      builder: (_) => _AddUnidadeDialog(grandezaId: grandezaId, ref: ref),
    );
  }

  void _confirmDelete(BuildContext context, Grandeza g) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir grandeza'),
        content: Text(
          'Deseja excluir "${g.nome}"? Isso também removerá todas as unidades associadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: NormatiqColors.danger700),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(grandezasProvider.notifier).deleteGrandeza(g.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erro ao excluir: $e'),
                    backgroundColor: NormatiqColors.danger700,
                  ));
                }
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _UnidadeRow extends ConsumerWidget {
  final UnidadeMedida unidade;
  final int grandezaId;
  const _UnidadeRow({required this.unidade, required this.grandezaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: NormatiqColors.primary600.withOpacity(0.08),
              borderRadius: BorderRadius.circular(NormatiqRadius.sm),
            ),
            child: Text(
              unidade.simbolo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: NormatiqColors.primary600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(unidade.nome,
                style: const TextStyle(fontSize: 13)),
          ),
          if (unidade.isSi)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: NormatiqColors.success700.withOpacity(0.1),
                borderRadius: BorderRadius.circular(NormatiqRadius.sm),
              ),
              child: const Text(
                'SI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: NormatiqColors.success700,
                ),
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 16,
                color: NormatiqColors.neutral500),
            visualDensity: VisualDensity.compact,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover unidade'),
        content: Text(
            'Remover "${unidade.nome} (${unidade.simbolo})" desta grandeza?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: NormatiqColors.danger700),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(grandezasProvider.notifier)
                    .deleteUnidade(grandezaId, unidade.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erro ao remover: $e'),
                    backgroundColor: NormatiqColors.danger700,
                  ));
                }
              }
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

class _NovaGrandezaDialog extends StatefulWidget {
  final WidgetRef ref;
  const _NovaGrandezaDialog({required this.ref});

  @override
  State<_NovaGrandezaDialog> createState() => _NovaGrandezaDialogState();
}

class _NovaGrandezaDialogState extends State<_NovaGrandezaDialog> {
  final _nomeCtrl = TextEditingController();
  final _simboloCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _simboloCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova grandeza'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nome *', hintText: 'ex: Comprimento'),
              autofocus: true,
              validator: (v) =>
                  v!.trim().isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: NormatiqSpacing.s3),
            TextFormField(
              controller: _simboloCtrl,
              decoration: const InputDecoration(
                  labelText: 'Símbolo *', hintText: 'ex: L'),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Informe o símbolo' : null,
            ),
          ],
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
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Criar'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.ref.read(grandezasProvider.notifier).create(
            _nomeCtrl.text.trim(),
            _simboloCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao criar grandeza: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _AddUnidadeDialog extends StatefulWidget {
  final int grandezaId;
  final WidgetRef ref;
  const _AddUnidadeDialog({required this.grandezaId, required this.ref});

  @override
  State<_AddUnidadeDialog> createState() => _AddUnidadeDialogState();
}

class _AddUnidadeDialogState extends State<_AddUnidadeDialog> {
  final _nomeCtrl = TextEditingController();
  final _simboloCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSi = false;
  bool _loading = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _simboloCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar unidade'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nome *', hintText: 'ex: Milímetro'),
              autofocus: true,
              validator: (v) =>
                  v!.trim().isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: NormatiqSpacing.s3),
            TextFormField(
              controller: _simboloCtrl,
              decoration: const InputDecoration(
                  labelText: 'Símbolo *', hintText: 'ex: mm'),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Informe o símbolo' : null,
            ),
            const SizedBox(height: NormatiqSpacing.s3),
            SwitchListTile(
              title: const Text('Unidade SI'),
              subtitle: const Text(
                'Unidade base do Sistema Internacional',
                style: TextStyle(fontSize: 12),
              ),
              value: _isSi,
              onChanged: (v) => setState(() => _isSi = v),
              contentPadding: EdgeInsets.zero,
            ),
          ],
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
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Adicionar'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.ref.read(grandezasProvider.notifier).addUnidade(
            widget.grandezaId,
            nome: _nomeCtrl.text.trim(),
            simbolo: _simboloCtrl.text.trim(),
            isSi: _isSi,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao adicionar unidade: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

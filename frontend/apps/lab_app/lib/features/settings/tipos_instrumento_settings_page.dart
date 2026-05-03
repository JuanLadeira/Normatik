import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../../core/providers/equipment_catalog_provider.dart';
import '../../core/providers/grandeza_provider.dart';

class TiposInstrumentoSettingsPage extends ConsumerWidget {
  const TiposInstrumentoSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiposAsync = ref.watch(tiposEquipamentoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tipos de Instrumento',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          TextButton.icon(
            onPressed: () => _showNovoTipoDialog(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Novo tipo'),
          ),
        ],
      ),
      body: tiposAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (tipos) {
          if (tipos.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.category_outlined,
                      size: 48, color: NormatiqColors.neutral400),
                  const SizedBox(height: 12),
                  const Text('Nenhum tipo de instrumento cadastrado.',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showNovoTipoDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Criar tipo'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(NormatiqSpacing.s4),
            itemCount: tipos.length,
            separatorBuilder: (_, __) => const SizedBox(height: NormatiqSpacing.s2),
            itemBuilder: (context, i) =>
                _TipoEquipamentoCard(tipo: tipos[i]),
          );
        },
      ),
    );
  }

  void _showNovoTipoDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _NovoTipoDialog(ref: ref),
    );
  }
}

class _TipoEquipamentoCard extends ConsumerStatefulWidget {
  final TipoEquipamento tipo;
  const _TipoEquipamentoCard({required this.tipo});

  @override
  ConsumerState<_TipoEquipamentoCard> createState() => _TipoEquipamentoCardState();
}

class _TipoEquipamentoCardState extends ConsumerState<_TipoEquipamentoCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tipo;
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: NormatiqColors.primary600.withOpacity(0.1),
                borderRadius: BorderRadius.circular(NormatiqRadius.sm),
              ),
              child: const Icon(Icons.category_outlined,
                  size: 20, color: NormatiqColors.primary600),
            ),
            title: Text(t.nome,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${t.modelos.length} modelo(s) cadastrado(s)',
                style: const TextStyle(
                    fontSize: 12, color: NormatiqColors.neutral500)),
            trailing: IconButton(
              icon: Icon(
                _expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: NormatiqColors.neutral500,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
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
                  if (t.modelos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhum modelo cadastrado para este tipo.',
                        style: TextStyle(
                            fontSize: 13, color: NormatiqColors.neutral500),
                      ),
                    )
                  else
                    ...t.modelos.map((m) => _ModeloRow(
                          modelo: m,
                          onEdit: () => _showModeloFormDialog(context, t.id, modelo: m),
                        )),
                  const SizedBox(height: NormatiqSpacing.s2),
                  TextButton.icon(
                    onPressed: () => _showModeloFormDialog(context, t.id),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Adicionar modelo'),
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

  void _showModeloFormDialog(BuildContext context, int tipoId, {ModeloEquipamento? modelo}) {
    showDialog(
      context: context,
      builder: (_) => _ModeloFormDialog(tipoId: tipoId, ref: ref, modelo: modelo),
    );
  }
}

class _ModeloRow extends StatelessWidget {
  final ModeloEquipamento modelo;
  final VoidCallback onEdit;
  const _ModeloRow({required this.modelo, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(modelo.nome,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (modelo.fabricanteNome != null)
                  Text(modelo.fabricanteNome!,
                      style: const TextStyle(fontSize: 11, color: NormatiqColors.neutral500)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: NormatiqColors.neutral500),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

class _NovoTipoDialog extends StatefulWidget {
  final WidgetRef ref;
  const _NovoTipoDialog({required this.ref});

  @override
  State<_NovoTipoDialog> createState() => _NovoTipoDialogState();
}

class _NovoTipoDialogState extends State<_NovoTipoDialog> {
  final _nomeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int? _grandezaId;
  bool _loading = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grandezasAsync = widget.ref.watch(grandezasProvider);

    return AlertDialog(
      title: const Text('Novo tipo de instrumento'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nome *', hintText: 'ex: Paquímetro'),
              autofocus: true,
              validator: (v) =>
                  v!.trim().isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: NormatiqSpacing.s3),
            grandezasAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Erro ao carregar grandezas: $e'),
              data: (grandezas) => DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Grandeza *'),
                value: _grandezaId,
                items: grandezas
                    .map((g) => DropdownMenuItem(
                          value: g.id,
                          child: Text(g.nome),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _grandezaId = v),
                validator: (v) => v == null ? 'Selecione uma grandeza' : null,
              ),
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
      await widget.ref.read(tiposEquipamentoProvider.notifier).create(
            _nomeCtrl.text.trim(),
            grandezaId: _grandezaId!,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao criar tipo: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _ModeloFormDialog extends StatefulWidget {
  final int tipoId;
  final WidgetRef ref;
  final ModeloEquipamento? modelo;
  const _ModeloFormDialog({required this.tipoId, required this.ref, this.modelo});

  @override
  State<_ModeloFormDialog> createState() => _ModeloFormDialogState();
}

class _ModeloFormDialogState extends State<_ModeloFormDialog> {
  final _fabricanteCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.modelo != null) {
      _fabricanteCtrl.text = widget.modelo!.fabricanteNome ?? '';
      _modeloCtrl.text = widget.modelo!.nome;
    }
  }

  @override
  void dispose() {
    _fabricanteCtrl.dispose();
    _modeloCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.modelo != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar modelo' : 'Adicionar modelo'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _fabricanteCtrl,
              decoration: const InputDecoration(
                  labelText: 'Marca/Fabricante *', hintText: 'ex: Mitutoyo'),
              autofocus: true,
              validator: (v) =>
                  v!.trim().isEmpty ? 'Informe a marca' : null,
            ),
            const SizedBox(height: NormatiqSpacing.s3),
            TextFormField(
              controller: _modeloCtrl,
              decoration: const InputDecoration(
                  labelText: 'Modelo *', hintText: 'ex: 530-118'),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Informe o modelo' : null,
            ),
          ],
        ),
      ),
      actions: [
        if (isEdit)
          TextButton(
            onPressed: _loading ? null : _confirmDelete,
            style: TextButton.styleFrom(foregroundColor: NormatiqColors.danger700),
            child: const Text('Excluir'),
          ),
        const Spacer(),
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
              : Text(isEdit ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir modelo'),
        content: const Text('Deseja realmente excluir este modelo do catálogo?'),
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
      setState(() => _loading = true);
      try {
        await widget.ref.read(tiposEquipamentoProvider.notifier).deleteModelo(widget.modelo!.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erro ao excluir modelo: $e'),
            backgroundColor: NormatiqColors.danger700,
          ));
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final notifier = widget.ref.read(tiposEquipamentoProvider.notifier);
      if (widget.modelo != null) {
        await notifier.updateModelo(
          id: widget.modelo!.id,
          fabricanteNome: _fabricanteCtrl.text.trim(),
          modeloNome: _modeloCtrl.text.trim(),
        );
      } else {
        await notifier.addModelo(
          tipoId: widget.tipoId,
          fabricanteNome: _fabricanteCtrl.text.trim(),
          modeloNome: _modeloCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar modelo: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

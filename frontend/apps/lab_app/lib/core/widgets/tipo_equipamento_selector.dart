import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../providers/equipment_catalog_provider.dart';
import '../providers/grandeza_provider.dart';

// ── Widget público ─────────────────────────────────────────────────────────────

class TipoEquipamentoSelector extends ConsumerStatefulWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final String? Function(int?)? validator;
  final bool enabled;

  const TipoEquipamentoSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  ConsumerState<TipoEquipamentoSelector> createState() =>
      _TipoEquipamentoSelectorState();
}

class _TipoEquipamentoSelectorState
    extends ConsumerState<TipoEquipamentoSelector> {
  final _fieldKey = GlobalKey<FormFieldState<int>>();

  String _nomeAtual(List<TipoEquipamento> tipos) {
    if (widget.value == null) return '';
    return tipos.where((t) => t.id == widget.value).firstOrNull?.nome ?? '';
  }

  Future<void> _openSearch() async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _TipoSearchDialog(
        onCreated: (id) {
          widget.onChanged(id);
          _fieldKey.currentState?.didChange(id);
        },
      ),
    );
    if (result != null) {
      widget.onChanged(result);
      _fieldKey.currentState?.didChange(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiposAsync = ref.watch(tiposEquipamentoProvider);

    return FormField<int>(
      key: _fieldKey,
      initialValue: widget.value,
      validator: widget.validator,
      builder: (state) {
        final tipos = tiposAsync.valueOrNull ?? [];
        final nome = _nomeAtual(tipos);
        final hasError = state.hasError;

        final errorBorder = hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(NormatiqRadius.md),
                borderSide: const BorderSide(
                    color: NormatiqColors.danger700, width: 2),
              )
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: widget.enabled ? _openSearch : null,
              borderRadius: BorderRadius.circular(NormatiqRadius.md),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Tipo de equipamento *',
                  suffixIcon: tiposAsync.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : const Icon(Icons.expand_more),
                  enabledBorder: errorBorder,
                  focusedBorder: errorBorder,
                  errorBorder: errorBorder,
                  focusedErrorBorder: errorBorder,
                ),
                isEmpty: nome.isEmpty,
                child: nome.isEmpty
                    ? const SizedBox.shrink()
                    : Text(nome, style: const TextStyle(fontSize: 14)),
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(state.errorText!,
                    style: const TextStyle(
                        color: NormatiqColors.danger700, fontSize: 12)),
              ),
          ],
        );
      },
    );
  }
}

// ── Dialog: busca de tipo ──────────────────────────────────────────────────────

class _TipoSearchDialog extends ConsumerStatefulWidget {
  final ValueChanged<int> onCreated;
  const _TipoSearchDialog({required this.onCreated});

  @override
  ConsumerState<_TipoSearchDialog> createState() => _TipoSearchDialogState();
}

class _TipoSearchDialogState extends ConsumerState<_TipoSearchDialog> {
  String _query = '';

  List<TipoEquipamento> get _filtered {
    final tipos = ref.watch(tiposEquipamentoProvider).valueOrNull ?? [];
    return tipos
        .where((t) => t.nome.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  Future<void> _promptCreate() async {
    // Abre _CriarTipoDialog POR CIMA deste dialog (não faz pop antes)
    final id = await showDialog<int>(
      context: context,
      builder: (_) => _CriarTipoDialog(),
    );
    if (id != null && mounted) {
      widget.onCreated(id);
      Navigator.of(context).pop(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiposAsync = ref.watch(tiposEquipamentoProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 480),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Pesquisar tipo...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const Divider(height: 1),
            if (tiposAsync.isLoading)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                children: [
                  ..._filtered.map((t) => ListTile(
                        title: Text(t.nome),
                        subtitle: Text(t.codigo,
                            style: const TextStyle(
                                fontSize: 11,
                                color: NormatiqColors.neutral500)),
                        onTap: () => Navigator.of(context).pop(t.id),
                      )),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline,
                        color: NormatiqColors.primary600),
                    title: const Text('Criar novo tipo',
                        style: TextStyle(
                            color: NormatiqColors.primary600,
                            fontWeight: FontWeight.w600)),
                    onTap: _promptCreate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog: criar tipo ─────────────────────────────────────────────────────────

class _CriarTipoDialog extends ConsumerStatefulWidget {
  const _CriarTipoDialog();

  @override
  ConsumerState<_CriarTipoDialog> createState() => _CriarTipoDialogState();
}

class _CriarTipoDialogState extends ConsumerState<_CriarTipoDialog> {
  final _nomeCtrl = TextEditingController();
  int? _grandezaId;
  String _grandezaNome = '';
  bool _loading = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarGrandeza() async {
    final result = await showDialog<(int, String)>(
      context: context,
      builder: (_) => const _GrandezaSearchDialog(),
    );
    if (result != null) {
      setState(() {
        _grandezaId = result.$1;
        _grandezaNome = result.$2;
      });
    }
  }

  Future<void> _submit() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty || _grandezaId == null) return;
    setState(() => _loading = true);
    try {
      final novo = await ref
          .read(tiposEquipamentoProvider.notifier)
          .create(nome, grandezaId: _grandezaId!);
      if (mounted) Navigator.of(context).pop(novo.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao criar tipo: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        !_loading && _nomeCtrl.text.trim().isNotEmpty && _grandezaId != null;

    return AlertDialog(
      title: const Text('Novo tipo de equipamento'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nomeCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome *'),
              enabled: !_loading,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _SeletorField(
              label: 'Grandeza física *',
              value: _grandezaNome,
              onTap: _loading ? null : _selecionarGrandeza,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: canSubmit ? _submit : null,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Criar'),
        ),
      ],
    );
  }
}

// ── Dialog: busca de grandeza ──────────────────────────────────────────────────

class _GrandezaSearchDialog extends ConsumerStatefulWidget {
  const _GrandezaSearchDialog();

  @override
  ConsumerState<_GrandezaSearchDialog> createState() =>
      _GrandezaSearchDialogState();
}

class _GrandezaSearchDialogState extends ConsumerState<_GrandezaSearchDialog> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(grandezasProvider.notifier).fetch());
  }

  List<Grandeza> get _filtered {
    final grandezas = ref.watch(grandezasProvider).valueOrNull ?? [];
    return grandezas
        .where((g) => g.nome.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  Future<void> _promptCreate() async {
    final result = await showDialog<Grandeza>(
      context: context,
      builder: (_) => const _CriarGrandezaDialog(),
    );
    if (result != null && mounted) {
      Navigator.of(context).pop((result.id, result.nome));
    }
  }

  @override
  Widget build(BuildContext context) {
    final grandezasAsync = ref.watch(grandezasProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 440),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Pesquisar grandeza...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const Divider(height: 1),
            if (grandezasAsync.isLoading)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                children: [
                  ..._filtered.map((g) {
                        final si = g.unidadeSi;
                        final subtitle = si != null
                            ? '${g.simbolo} · ${si.simbolo}'
                            : g.simbolo;
                        return ListTile(
                          title: Text(g.nome),
                          subtitle: Text(subtitle,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: NormatiqColors.neutral500)),
                          onTap: () =>
                              Navigator.of(context).pop((g.id, g.nome)),
                        );
                      }),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline,
                        color: NormatiqColors.primary600),
                    title: const Text('Criar nova grandeza',
                        style: TextStyle(
                            color: NormatiqColors.primary600,
                            fontWeight: FontWeight.w600)),
                    onTap: _promptCreate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog: criar grandeza ─────────────────────────────────────────────────────

class _CriarGrandezaDialog extends ConsumerStatefulWidget {
  const _CriarGrandezaDialog();

  @override
  ConsumerState<_CriarGrandezaDialog> createState() =>
      _CriarGrandezaDialogState();
}

class _CriarGrandezaDialogState extends ConsumerState<_CriarGrandezaDialog> {
  final _nomeCtrl = TextEditingController();
  final _simboloCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _simboloCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _nomeCtrl.text.trim().isNotEmpty && _simboloCtrl.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_valid) return;
    setState(() => _loading = true);
    try {
      final nova = await ref.read(grandezasProvider.notifier).create(
            _nomeCtrl.text.trim(),
            _simboloCtrl.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(nova);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao criar grandeza: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova grandeza física'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeCtrl,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'Nome * (ex: Temperatura)'),
              enabled: !_loading,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _simboloCtrl,
              decoration:
                  const InputDecoration(labelText: 'Símbolo * (ex: T)'),
              enabled: !_loading,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: (_loading || !_valid) ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Criar'),
        ),
      ],
    );
  }
}

// ── Widget auxiliar: campo seletor estilizado ──────────────────────────────────

class _SeletorField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _SeletorField({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = value.isEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NormatiqRadius.md),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor ??
              NormatiqColors.neutral50,
          borderRadius: BorderRadius.circular(NormatiqRadius.md),
          border: Border.all(color: NormatiqColors.neutral300),
        ),
        child: Row(
          children: [
            Expanded(
              child: empty
                  ? Text(label,
                      style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 14))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 1),
                        Text(value,
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
            ),
            const Icon(Icons.expand_more, size: 20,
                color: NormatiqColors.neutral500),
          ],
        ),
      ),
    );
  }
}

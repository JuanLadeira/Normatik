import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../providers/equipment_catalog_provider.dart';

class ModeloEquipamentoSelector extends ConsumerStatefulWidget {
  final int? value; // ID do modelo
  final int? tipoEquipamentoId;
  final void Function(ModeloEquipamento?) onChanged;
  final String? Function(int?)? validator;
  final bool enabled;

  const ModeloEquipamentoSelector({
    super.key,
    required this.value,
    required this.tipoEquipamentoId,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  ConsumerState<ModeloEquipamentoSelector> createState() =>
      _ModeloEquipamentoSelectorState();
}

class _ModeloEquipamentoSelectorState
    extends ConsumerState<ModeloEquipamentoSelector> {
  final _fieldKey = GlobalKey<FormFieldState<int>>();

  Future<void> _openSearch() async {
    if (widget.tipoEquipamentoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione primeiro o tipo de equipamento.')),
      );
      return;
    }

    final result = await showDialog<ModeloEquipamento>(
      context: context,
      builder: (_) => _ModeloSearchDialog(tipoId: widget.tipoEquipamentoId!),
    );

    if (result != null) {
      widget.onChanged(result);
      _fieldKey.currentState?.didChange(result.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelosAsync = ref.watch(modelosProvider(widget.tipoEquipamentoId));

    return FormField<int>(
      key: _fieldKey,
      initialValue: widget.value,
      validator: widget.validator,
      builder: (state) {
        // Sincroniza o estado do FormField com o widget.value externo
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.value != state.value) {
            state.didChange(widget.value);
          }
        });

        final modelos = modelosAsync.valueOrNull ?? [];
        final modelo = modelos.where((m) => m.id == state.value).firstOrNull;
        
        final label = modelo != null 
            ? '${modelo.nome} (${modelo.fabricanteNome})'
            : '';
            
        final hasError = state.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: widget.enabled ? _openSearch : null,
              borderRadius: BorderRadius.circular(NormatiqRadius.md),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Modelo e Marca *',
                  hintText: widget.tipoEquipamentoId == null 
                      ? 'Selecione o tipo primeiro' 
                      : 'Pesquisar modelo...',
                  suffixIcon: modelosAsync.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : const Icon(Icons.expand_more),
                  fillColor: widget.tipoEquipamentoId == null ? NormatiqColors.neutral100 : null,
                  filled: widget.tipoEquipamentoId == null,
                ),
                isEmpty: label.isEmpty,
                child: label.isEmpty
                    ? const SizedBox.shrink()
                    : Text(label, style: const TextStyle(fontSize: 14)),
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

class _ModeloSearchDialog extends ConsumerStatefulWidget {
  final int tipoId;
  const _ModeloSearchDialog({required this.tipoId});

  @override
  ConsumerState<_ModeloSearchDialog> createState() => _ModeloSearchDialogState();
}

class _ModeloSearchDialogState extends ConsumerState<_ModeloSearchDialog> {
  String _query = '';

  Future<void> _promptCreate() async {
    final result = await showDialog<ModeloEquipamento>(
      context: context,
      builder: (_) => _CriarModeloDialog(tipoId: widget.tipoId),
    );
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelosAsync = ref.watch(modelosProvider(widget.tipoId));

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
                  hintText: 'Pesquisar modelo ou marca...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const Divider(height: 1),
            if (modelosAsync.isLoading)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: modelosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data: (modelos) {
                  final filtered = modelos.where((m) {
                    final q = _query.toLowerCase();
                    return m.nome.toLowerCase().contains(q) ||
                        (m.fabricanteNome?.toLowerCase().contains(q) ?? false);
                  }).toList();

                  return ListView(
                    children: [
                      ...filtered.map((m) => ListTile(
                            title: Text(m.nome),
                            subtitle: Text(m.fabricanteNome ?? '',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: NormatiqColors.neutral500)),
                            onTap: () => Navigator.of(context).pop(m),
                          )),
                      ListTile(
                        leading: const Icon(Icons.add_circle_outline,
                            color: NormatiqColors.primary600),
                        title: const Text('Cadastrar novo modelo',
                            style: TextStyle(
                                color: NormatiqColors.primary600,
                                fontWeight: FontWeight.w600)),
                        onTap: _promptCreate,
                      ),
                    ],
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

class _CriarModeloDialog extends ConsumerStatefulWidget {
  final int tipoId;
  const _CriarModeloDialog({required this.tipoId});

  @override
  ConsumerState<_CriarModeloDialog> createState() => _CriarModeloDialogState();
}

class _CriarModeloDialogState extends ConsumerState<_CriarModeloDialog> {
  final _fabricanteCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _fabricanteCtrl.dispose();
    _nomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fab = _fabricanteCtrl.text.trim();
    final nome = _nomeCtrl.text.trim();
    if (fab.isEmpty || nome.isEmpty) return;
    
    setState(() => _loading = true);
    try {
      final novo = await ref.read(tiposEquipamentoProvider.notifier).addModelo(
            tipoId: widget.tipoId,
            fabricanteNome: fab,
            modeloNome: nome,
          );
      // Força o refresh do provider de modelos para esse tipo
      ref.invalidate(modelosProvider(widget.tipoId));
      if (mounted) Navigator.of(context).pop(novo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao criar modelo: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Modelo'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Para simplificar como o usuário pediu "combobox", 
            // vamos usar um campo de texto com sugestões (fabricantes existentes)
            _FabricanteAutocomplete(controller: _fabricanteCtrl),
            const SizedBox(height: 16),
            TextField(
              controller: _nomeCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome do Modelo *',
                hintText: 'ex: 530-118',
              ),
              enabled: !_loading,
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
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Criar e Selecionar'),
        ),
      ],
    );
  }
}

class _FabricanteAutocomplete extends ConsumerWidget {
  final TextEditingController controller;
  const _FabricanteAutocomplete({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fabricantesAsync = ref.watch(fabricantesProvider);

    return fabricantesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Erro: $e'),
      data: (fabricantes) => Autocomplete<String>(
        optionsBuilder: (TextEditingValue value) {
          if (value.text.isEmpty) return const Iterable<String>.empty();
          return fabricantes
              .map((f) => f.nome)
              .where((nome) => nome.toLowerCase().contains(value.text.toLowerCase()));
        },
        onSelected: (String selection) {
          controller.text = selection;
        },
        fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
          // Sincroniza o textController do Autocomplete com o controller externo
          textController.addListener(() {
            controller.text = textController.text;
          });
          return TextFormField(
            controller: textController,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: 'Marca / Fabricante *',
              hintText: 'Digite ou selecione...',
            ),
            validator: (v) => v!.isEmpty ? 'Informe o fabricante' : null,
          );
        },
      ),
    );
  }
}

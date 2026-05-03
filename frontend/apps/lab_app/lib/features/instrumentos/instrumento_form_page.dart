import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../../core/widgets/form_card.dart';
import '../../core/widgets/tipo_equipamento_selector.dart';
import '../../core/widgets/modelo_equipamento_selector.dart';
import '../../core/widgets/faixas_medicao_editor.dart';
import '../../core/widgets/photos_editor.dart';
import '../clientes/clientes_provider.dart';
import 'instrumentos_provider.dart';

class InstrumentoFormPage extends ConsumerStatefulWidget {
  final int? instrumentoId;
  final int? clienteIdInicial;
  const InstrumentoFormPage(
      {super.key, this.instrumentoId, this.clienteIdInicial});

  @override
  ConsumerState<InstrumentoFormPage> createState() =>
      _InstrumentoFormPageState();
}

class _InstrumentoFormPageState extends ConsumerState<InstrumentoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _faixasKey = GlobalKey<FaixasMedicaoEditorState>();
  final _photosKey = GlobalKey<PhotosEditorState>();

  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _serieCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  int? _tipoEquipamentoId;
  int? _modeloEquipamentoId;
  int? _clienteId;
  bool _ativo = true;
  bool _isLoading = false;
  List<FaixaMedicaoModel> _initialFaixas = [];
  List<String> _initialPhotos = [];

  bool get _isEdit => widget.instrumentoId != null;

  @override
  void initState() {
    super.initState();
    _clienteId = widget.clienteIdInicial;
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
    }
  }

  void _prefill() {
    final instrs = ref.read(instrumentosProvider).valueOrNull ?? [];
    final instr =
        instrs.where((i) => i.id == widget.instrumentoId).firstOrNull;
    if (instr != null) {
      _marcaCtrl.text = instr.marca;
      _modeloCtrl.text = instr.modelo;
      _serieCtrl.text = instr.numeroSerie;
      _tagCtrl.text = instr.tag ?? '';
      setState(() {
        _tipoEquipamentoId = instr.tipoEquipamentoId;
        _modeloEquipamentoId = instr.modeloEquipamentoId;
        _clienteId = instr.clienteId;
        _ativo = instr.ativo;
        _initialFaixas = instr.faixas;
        _initialPhotos = instr.fotos;
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_marcaCtrl, _modeloCtrl, _serieCtrl, _tagCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione o cliente.')));
      return;
    }
    if (_tipoEquipamentoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione o tipo de equipamento.')));
      return;
    }

    final notifier = ref.read(instrumentosProvider.notifier);
    final faixas = _faixasKey.currentState?.getData() ?? [];
    final fotos = _photosKey.currentState?.getPhotos() ?? [];
    final data = {
      'tipo_equipamento_id': _tipoEquipamentoId,
      'modelo_equipamento_id': _modeloEquipamentoId == 0 ? null : _modeloEquipamentoId,
      'cliente_id': _clienteId,
      'marca': _marcaCtrl.text.trim(),
      'modelo': _modeloCtrl.text.trim(),
      'numero_serie': _serieCtrl.text.trim(),
      if (_tagCtrl.text.trim().isNotEmpty) 'tag': _tagCtrl.text.trim(),
      'faixas': faixas,
      'fotos': fotos,
      'ativo': _ativo,
    };

    setState(() => _isLoading = true);

    try {
      if (_isEdit) {
        await notifier.updateInstrumento(widget.instrumentoId!, data);
      } else {
        await notifier.createInstrumento(data);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar instrumento: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientesAsync = ref.watch(clientesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Editar Instrumento' : 'Novo Instrumento',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(NormatiqSpacing.s4),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: FormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cliente
                    clientesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Erro ao carregar clientes: $e',
                          style:
                              const TextStyle(color: NormatiqColors.danger700)),
                      data: (clientes) => DropdownButtonFormField<int>(
                        value: _clienteId,
                        decoration:
                            const InputDecoration(labelText: 'Cliente *'),
                        items: clientes
                            .map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.nome)))
                            .toList(),
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _clienteId = v),
                        validator: (v) =>
                            v == null ? 'Selecione o cliente' : null,
                      ),
                    ),
                    const SizedBox(height: NormatiqSpacing.s4),

                    TipoEquipamentoSelector(
                      value: _tipoEquipamentoId,
                      enabled: !_isLoading,
                      onChanged: (v) {
                        setState(() {
                          _tipoEquipamentoId = v;
                          _modeloEquipamentoId = null;
                          _marcaCtrl.clear();
                          _modeloCtrl.clear();
                        });
                      },
                      validator: (v) =>
                          v == null ? 'Selecione o tipo' : null,
                    ),
                    const SizedBox(height: NormatiqSpacing.s4),

                    ModeloEquipamentoSelector(
                      value: _modeloEquipamentoId,
                      tipoEquipamentoId: _tipoEquipamentoId,
                      onChanged: (m) {
                        setState(() {
                          _modeloEquipamentoId = m?.id;
                          _marcaCtrl.text = m?.fabricanteNome ?? '';
                          _modeloCtrl.text = m?.nome ?? '';
                        });
                      },
                      enabled: !_isLoading,
                      validator: (v) => v == null ? 'Selecione o modelo' : null,
                    ),
                    const SizedBox(height: NormatiqSpacing.s3),

                    TextFormField(
                      controller: _tagCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Tag (identificador interno)'),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: NormatiqSpacing.s3),
                    TextFormField(
                      controller: _serieCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Número de série *'),
                      enabled: !_isLoading,
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Informe o número de série' : null,
                    ),
                    const SizedBox(height: NormatiqSpacing.s4),

                    FaixasMedicaoEditor(
                      key: _faixasKey,
                      tipoEquipamentoId: _tipoEquipamentoId,
                      initialFaixas: _initialFaixas,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: NormatiqSpacing.s4),
                    PhotosEditor(
                      key: _photosKey,
                      initialPhotos: _initialPhotos,
                      enabled: !_isLoading,
                    ),

                    if (_isEdit) ...[
                      const SizedBox(height: NormatiqSpacing.s4),
                      SwitchListTile(
                        title: const Text('Instrumento ativo'),
                        value: _ativo,
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _ativo = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    const SizedBox(height: NormatiqSpacing.s6),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_isEdit
                              ? 'Salvar alterações'
                              : 'Criar instrumento'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

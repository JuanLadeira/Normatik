import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import '../../core/widgets/form_card.dart';
import '../../core/widgets/tipo_equipamento_selector.dart';
import '../../core/widgets/modelo_equipamento_selector.dart';
import '../../core/widgets/faixas_medicao_editor.dart';
import '../../core/widgets/photos_editor.dart';
import 'padroes_provider.dart';

class PadraoFormPage extends ConsumerStatefulWidget {
  final int? padraoId;
  const PadraoFormPage({super.key, this.padraoId});

  @override
  ConsumerState<PadraoFormPage> createState() => _PadraoFormPageState();
}

class _PadraoFormPageState extends ConsumerState<PadraoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _faixasKey = GlobalKey<FaixasMedicaoEditorState>();
  final _photosKey = GlobalKey<PhotosEditorState>();

  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _serieCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _alertaCtrl = TextEditingController(text: '30');
  final _uMaxCtrl = TextEditingController();
  final _criterioCtrl = TextEditingController();
  int? _tipoEquipamentoId;
  int? _modeloEquipamentoId;
  bool _ativo = true;
  bool _isLoading = false;
  List<FaixaMedicaoModel> _initialFaixas = [];
  List<String> _initialPhotos = [];

  bool get _isEdit => widget.padraoId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());
    }
  }

  void _prefill() {
    final padroes = ref.read(padroesProvider).valueOrNull ?? [];
    final p = padroes.where((p) => p.id == widget.padraoId).firstOrNull;
    if (p != null) {
      _marcaCtrl.text = p.marca;
      _modeloCtrl.text = p.modelo;
      _serieCtrl.text = p.numeroSerie;
      _tagCtrl.text = p.tag ?? '';
      _freqCtrl.text = p.frequenciaCalibracaoDias?.toString() ?? '';
      _alertaCtrl.text = p.alertaDiasAntes.toString();
      _uMaxCtrl.text = p.uMaximoAceito?.toString() ?? '';
      _criterioCtrl.text = p.criterioAceitacao ?? '';
      setState(() {
        _tipoEquipamentoId = p.tipoEquipamentoId;
        _modeloEquipamentoId = p.modeloEquipamentoId;
        _ativo = p.ativo;
        _initialFaixas = p.faixas;
        _initialPhotos = p.fotos;
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _marcaCtrl, _modeloCtrl, _serieCtrl, _tagCtrl,
      _freqCtrl, _alertaCtrl, _uMaxCtrl, _criterioCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipoEquipamentoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecione o tipo de equipamento.')));
      return;
    }

    final notifier = ref.read(padroesProvider.notifier);
    final faixas = _faixasKey.currentState?.getData() ?? [];
    final fotos = _photosKey.currentState?.getPhotos() ?? [];
    final data = {
      'tipo_equipamento_id': _tipoEquipamentoId,
      'modelo_equipamento_id': _modeloEquipamentoId == 0 ? null : _modeloEquipamentoId,
      'marca': _marcaCtrl.text.trim(),
      'modelo': _modeloCtrl.text.trim(),
      'numero_serie': _serieCtrl.text.trim(),
      if (_tagCtrl.text.trim().isNotEmpty) 'tag': _tagCtrl.text.trim(),
      'faixas': faixas,
      'fotos': fotos,
      if (_freqCtrl.text.trim().isNotEmpty)
        'frequencia_calibracao_dias': int.tryParse(_freqCtrl.text.trim()),
      'alerta_dias_antes': int.tryParse(_alertaCtrl.text.trim()) ?? 30,
      if (_uMaxCtrl.text.trim().isNotEmpty)
        'u_maximo_aceito': double.tryParse(_uMaxCtrl.text.trim()),
      if (_criterioCtrl.text.trim().isNotEmpty)
        'criterio_aceitacao': _criterioCtrl.text.trim(),
      'ativo': _ativo,
    };

    setState(() => _isLoading = true);

    try {
      if (_isEdit) {
        await notifier.updatePadrao(widget.padraoId!, data);
      } else {
        await notifier.createPadrao(data);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar padrão: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Editar Padrão' : 'Novo Padrão',
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

                  _label(context, 'Identificação'),
                  const SizedBox(height: NormatiqSpacing.s3),
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
                    controller: _serieCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Número de série *'),
                    enabled: !_isLoading,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Informe o número de série' : null,
                  ),
                  const SizedBox(height: NormatiqSpacing.s3),
                  TextFormField(
                    controller: _tagCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Tag (identificador interno)'),
                    enabled: !_isLoading,
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

                  const SizedBox(height: NormatiqSpacing.s6),
                  _label(context, 'Controle de calibração'),
                  const SizedBox(height: NormatiqSpacing.s3),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _freqCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Frequência (dias)',
                              hintText: 'ex: 365'),
                          keyboardType: TextInputType.number,
                          enabled: !_isLoading,
                        ),
                      ),
                      const SizedBox(width: NormatiqSpacing.s3),
                      Expanded(
                        child: TextFormField(
                          controller: _alertaCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Alerta (dias antes)',
                              hintText: '30'),
                          keyboardType: TextInputType.number,
                          enabled: !_isLoading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: NormatiqSpacing.s3),
                  TextFormField(
                    controller: _uMaxCtrl,
                    decoration: const InputDecoration(
                        labelText: 'U máxima aceita'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: NormatiqSpacing.s3),
                  TextFormField(
                    controller: _criterioCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Critério de aceitação'),
                    maxLines: 2,
                    enabled: !_isLoading,
                  ),

                  if (_isEdit) ...[
                    const SizedBox(height: NormatiqSpacing.s4),
                    SwitchListTile(
                      title: const Text('Padrão ativo'),
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
                            : 'Criar padrão'),
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

Widget _label(BuildContext context, String text) {
  return Text(
    text.toUpperCase(),
    style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        letterSpacing: 1),
  );
}

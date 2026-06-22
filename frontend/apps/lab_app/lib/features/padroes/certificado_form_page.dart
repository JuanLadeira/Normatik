import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import 'package:dio/dio.dart';
import '../../core/api/client.dart';
import '../../core/widgets/form_card.dart';
import 'certificados_padrao_provider.dart';
import 'widgets/template_selector_field.dart';

class CertificadoFormPage extends ConsumerStatefulWidget {
  final int padraoId;

  const CertificadoFormPage({super.key, required this.padraoId});

  @override
  ConsumerState<CertificadoFormPage> createState() =>
      _CertificadoFormPageState();
}

class _CertificadoFormPageState extends ConsumerState<CertificadoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _numeroCtrl = TextEditingController();
  final _labCtrl = TextEditingController();
  final _uExpandidaCtrl = TextEditingController();
  final _kAbrangenciaCtrl = TextEditingController(text: '2.0');

  DateTime _dataEmissao = DateTime.now();
  DateTime _dataValidade = DateTime.now().add(const Duration(days: 365));

  FormularioTemplateModel? _templateSelecionado;
  PlatformFile? _pdfFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _labCtrl.dispose();
    _uExpandidaCtrl.dispose();
    _kAbrangenciaCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(bool emissao) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: emissao ? _dataEmissao : _dataValidade,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        if (emissao) {
          _dataEmissao = picked;
        } else {
          _dataValidade = picked;
        }
      });
    }
  }

  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null && mounted) {
      setState(() => _pdfFile = result.files.first);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final client = ref.read(apiClientProvider);

    try {
      final data = {
        'padrao_id': widget.padraoId,
        'numero_certificado': _numeroCtrl.text.trim(),
        'laboratorio_calibrador': _labCtrl.text.trim(),
        'data_emissao': _isoDate(_dataEmissao),
        'data_validade': _isoDate(_dataValidade),
        'U_expandida': double.parse(_uExpandidaCtrl.text.trim()),
        'k_abrangencia': double.parse(_kAbrangenciaCtrl.text.trim()),
        if (_templateSelecionado != null)
          'formulario_template_id': _templateSelecionado!.id,
      };

      final response = await client.dio.post(
        '/api/certificados-padrao/certificados',
        data: data,
      );
      final cert = CertificadoPadraoModel.fromJson(response.data);

      // Upload do PDF, se selecionado
      if (_pdfFile != null && _pdfFile!.bytes != null) {
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            _pdfFile!.bytes!,
            filename: _pdfFile!.name,
          ),
        });
        await client.dio.post(
          '/api/certificados-padrao/certificados/${cert.id}/upload-pdf',
          data: formData,
        );
      }

      if (!mounted) return;

      // Invalida a lista para forçar refresh
      ref.invalidate(certificadosPadraoProvider(widget.padraoId));

      context.pushReplacement(
        '/padroes/${widget.padraoId}/certificados/${cert.id}',
      );
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data?['detail'] ?? 'Erro ao criar certificado';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg.toString()),
          backgroundColor: NormatiqColors.danger700,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro inesperado: $e'),
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
        title: const Text(
          'Novo Certificado',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                    _label(context, 'Identificação'),
                    const SizedBox(height: NormatiqSpacing.s3),
                    // Número
                    TextFormField(
                      controller: _numeroCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Número do Certificado *'),
                      enabled: !_isLoading,
                      validator: (v) => v!.trim().isEmpty
                          ? 'Informe o número do certificado'
                          : null,
                    ),
                    const SizedBox(height: NormatiqSpacing.s4),

                    // Laboratório
                    TextFormField(
                      controller: _labCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Laboratório Calibrador *'),
                      enabled: !_isLoading,
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Informe o laboratório' : null,
                    ),
                    const SizedBox(height: NormatiqSpacing.s6),

                    _label(context, 'Datas'),
                    const SizedBox(height: NormatiqSpacing.s3),
                    // Datas
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                _isLoading ? null : () => _pickDate(true),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text('Emissão: ${_fmtDate(_dataEmissao)}'),
                          ),
                        ),
                        const SizedBox(width: NormatiqSpacing.s3),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                _isLoading ? null : () => _pickDate(false),
                            icon: const Icon(Icons.event_available, size: 16),
                            label: Text('Validade: ${_fmtDate(_dataValidade)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: NormatiqSpacing.s6),

                    _label(context, 'Metrologia'),
                    const SizedBox(height: NormatiqSpacing.s3),
                    // Incerteza
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _uExpandidaCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Incerteza Expandida (U) *'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            enabled: !_isLoading,
                            validator: (v) {
                              if (v!.trim().isEmpty) return 'Obrigatório';
                              if (double.tryParse(v.trim()) == null) {
                                return 'Valor inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: NormatiqSpacing.s3),
                        Expanded(
                          child: TextFormField(
                            controller: _kAbrangenciaCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Fator k *'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            enabled: !_isLoading,
                            validator: (v) {
                              if (v!.trim().isEmpty) return 'Obrigatório';
                              if (double.tryParse(v.trim()) == null) {
                                return 'Valor inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: NormatiqSpacing.s4),

                    // Template
                    TemplateSelectorField(
                      selectedTemplate: _templateSelecionado,
                      isLoading: _isLoading,
                      onSelected: (t) =>
                          setState(() => _templateSelecionado = t),
                    ),
                    const SizedBox(height: NormatiqSpacing.s6),

                    _label(context, 'Documentação'),
                    const SizedBox(height: NormatiqSpacing.s3),
                    // PDF
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.picture_as_pdf,
                        color: _pdfFile != null
                            ? NormatiqColors.primary600
                            : NormatiqColors.neutral400,
                      ),
                      title: Text(
                        _pdfFile?.name ?? 'Nenhum PDF selecionado',
                        style: TextStyle(
                          color: _pdfFile != null
                              ? Theme.of(context).colorScheme.onSurface
                              : NormatiqColors.neutral500,
                          fontSize: 13,
                        ),
                      ),
                      trailing: OutlinedButton(
                        onPressed: _isLoading ? null : _pickPDF,
                        child: const Text('SELECIONAR'),
                      ),
                    ),
                    const SizedBox(height: NormatiqSpacing.s6),

                    // Botão salvar
                    FilledButton(
                      onPressed: _isLoading ? null : _salvar,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('SALVAR E CONTINUAR'),
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
      letterSpacing: 1,
    ),
  );
}


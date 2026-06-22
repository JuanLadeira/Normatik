import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:normatiq_ui/normatiq_ui.dart';
import 'package:dio/dio.dart';
import '../../core/api/client.dart';
import '../../core/widgets/form_card.dart';
import '../../core/widgets/pontos_medicao_widget.dart';
import 'certificados_padrao_provider.dart';
import 'widgets/template_selector_field.dart';

// ── Chip de status do certificado ──────────────────────────────────────────────

Color _certStatusColor(String status) {
  switch (status) {
    case 'ativo':
      return NormatiqColors.success700;
    case 'aguardando_aprovacao_curva':
      return NormatiqColors.warning700;
    case 'expirado':
      return NormatiqColors.danger700;
    default: // rascunho
      return NormatiqColors.neutral500;
  }
}

String _certStatusLabel(String status) {
  switch (status) {
    case 'ativo':
      return 'Ativo';
    case 'aguardando_aprovacao_curva':
      return 'Aguardando Aprovação';
    case 'expirado':
      return 'Expirado';
    default:
      return 'Rascunho';
  }
}

Widget _buildStatusChip(String status) {
  final color = _certStatusColor(status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(NormatiqRadius.full),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(
      _certStatusLabel(status),
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// ── Página de detalhe ──────────────────────────────────────────────────────────

class CertificadoDetailPage extends ConsumerStatefulWidget {
  final int padraoId;
  final int certId;

  const CertificadoDetailPage({
    super.key,
    required this.padraoId,
    required this.certId,
  });

  @override
  ConsumerState<CertificadoDetailPage> createState() =>
      _CertificadoDetailPageState();
}

class _CertificadoDetailPageState
    extends ConsumerState<CertificadoDetailPage> {
  // Estado carregado de forma assíncrona
  CertificadoPadraoModel? _cert;
  List<PontoMedicaoModel> _pontos = [];
  bool _loadingPontos = false;
  bool _loadingCert = true;
  String? _erroMsg;

  // Formulário de metadados
  final _formKey = GlobalKey<FormState>();
  final _labCtrl = TextEditingController();
  final _uExpandidaCtrl = TextEditingController();
  final _kAbrangenciaCtrl = TextEditingController();

  DateTime? _dataEmissao;
  DateTime? _dataValidade;
  FormularioTemplateModel? _templateSelecionado;
  PlatformFile? _pdfFile;
  bool _savingMeta = false;

  @override
  void initState() {
    super.initState();
    _loadCert();
  }

  @override
  void dispose() {
    _labCtrl.dispose();
    _uExpandidaCtrl.dispose();
    _kAbrangenciaCtrl.dispose();
    super.dispose();
  }

  // ── Carregamento inicial ───────────────────────────────────────────────────

  Future<void> _loadCert() async {
    setState(() {
      _loadingCert = true;
      _erroMsg = null;
    });
    try {
      final client = ref.read(apiClientProvider);
      final r = await client.dio
          .get('/api/certificados-padrao/certificados/${widget.certId}');
      final cert = CertificadoPadraoModel.fromJson(r.data);
      if (mounted) {
        setState(() {
          _cert = cert;
          _loadingCert = false;
        });
        _populateForm(cert);
        _loadPontos();
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _erroMsg =
              e.response?.data?['detail']?.toString() ?? 'Erro ao carregar certificado';
          _loadingCert = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erroMsg = 'Erro inesperado: $e';
          _loadingCert = false;
        });
      }
    }
  }

  void _populateForm(CertificadoPadraoModel cert) {
    _labCtrl.text = cert.laboratorioCalibrador;
    _uExpandidaCtrl.text = cert.uExpandida.toString();
    _kAbrangenciaCtrl.text = cert.kAbrangencia.toString();
    try {
      _dataEmissao = DateTime.parse(cert.dataEmissao);
      _dataValidade = DateTime.parse(cert.dataValidade);
    } catch (_) {
      _dataEmissao = DateTime.now();
      _dataValidade = DateTime.now().add(const Duration(days: 365));
    }

    // Prioriza o snapshot (formularioConfig) para garantir fidelidade histórica
    if (cert.formularioConfig != null) {
      final config = cert.formularioConfig!;
      setState(() => _templateSelecionado = FormularioTemplateModel(
            id: cert.formularioTemplateId ?? 0,
            tipoInstrumentoId: 0,
            nome: config['nome'] ?? 'Template do Certificado',
            camposPontos: config['campos_pontos'] ?? {},
            tipoRegressaoDefault: config['tipo_regressao_default'] ?? 'linear',
            grauPolinomioDefault: config['grau_polinomio_default'] ?? 1,
          ));
    } else if (cert.formularioTemplateId != null) {
      final templates =
          ref.read(templatesCertificadoProvider).valueOrNull ?? [];
      final found = templates
          .where((t) => t.id == cert.formularioTemplateId)
          .firstOrNull;
      if (found != null) setState(() => _templateSelecionado = found);
    }
  }

  Future<void> _loadPontos() async {
    setState(() => _loadingPontos = true);
    try {
      final client = ref.read(apiClientProvider);
      final r = await client.dio
          .get('/api/certificados-padrao/certificados/${widget.certId}/pontos');
      if (mounted) {
        setState(() {
          _pontos = (r.data as List)
              .map((e) => PontoMedicaoModel.fromJson(e))
              .toList();
          _loadingPontos = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPontos = false);
    }
  }

  // ── Helpers de data ────────────────────────────────────────────────────────

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Selecionar';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(bool emissao) async {
    final initial = emissao ? _dataEmissao : _dataValidade;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
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

  // ── Salvar metadados ────────────────────────────────────────────────────────

  Future<void> _salvarMetadados() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataEmissao == null || _dataValidade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe as datas de emissão e validade.')),
      );
      return;
    }
    setState(() => _savingMeta = true);
    try {
      final client = ref.read(apiClientProvider);
      final data = {
        'laboratorio_calibrador': _labCtrl.text.trim(),
        'data_emissao': _isoDate(_dataEmissao!),
        'data_validade': _isoDate(_dataValidade!),
        'U_expandida': double.parse(_uExpandidaCtrl.text.trim()),
        'k_abrangencia': double.parse(_kAbrangenciaCtrl.text.trim()),
        if (_templateSelecionado != null)
          'formulario_template_id': _templateSelecionado!.id,
      };
      final r = await client.dio.put(
        '/api/certificados-padrao/certificados/${widget.certId}',
        data: data,
      );

      // Upload PDF se novo arquivo selecionado
      if (_pdfFile != null && _pdfFile!.bytes != null) {
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            _pdfFile!.bytes!,
            filename: _pdfFile!.name,
          ),
        });
        await client.dio.post(
          '/api/certificados-padrao/certificados/${widget.certId}/upload-pdf',
          data: formData,
        );
      }

      if (mounted) {
        setState(() {
          _cert = CertificadoPadraoModel.fromJson(r.data);
          _savingMeta = false;
          _pdfFile = null;
        });
        ref.invalidate(certificadosPadraoProvider(widget.padraoId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metadados salvos com sucesso.')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data?['detail'] ?? 'Erro ao salvar';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg.toString()),
          backgroundColor: NormatiqColors.danger700,
        ));
        setState(() => _savingMeta = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: NormatiqColors.danger700,
        ));
        setState(() => _savingMeta = false);
      }
    }
  }

  // ── Salvar pontos e navegar para análise ───────────────────────────────────

  Future<void> _onSalvarPontos(List<Map<String, dynamic>> pontos) async {
    final template = _templateSelecionado;
    if (template == null) return;

    final payload = pontos
        .asMap()
        .entries
        .map((e) => {'ordem': e.key, 'valores': e.value})
        .toList();

    try {
      final client = ref.read(apiClientProvider);
      await client.dio.post(
        '/api/certificados-padrao/certificados/${widget.certId}/pontos',
        data: payload,
      );

      if (!mounted) return;

      // Navega para a página de análise via go_router com extra
      context.push(
        '/padroes/${widget.padraoId}/certificados/${widget.certId}/analise',
        extra: {
          'campos': template.campos,
          'tipo': template.tipoRegressaoDefault,
          'grau': template.grauPolinomioDefault,
          'campo_x': template.campoRegressaoX,
          'campo_y': template.campoRegressaoY,
        },
      );
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data?['detail'] ?? 'Erro ao salvar pontos';
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
    }
  }

  // ── Excluir certificado ─────────────────────────────────────────────────────

  Future<void> _confirmarExclusao() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Certificado'),
        content: const Text(
            'Todos os pontos de medição e curvas associadas serão excluídos permanentemente. Confirmar?'),
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
    if (confirmed != true || !mounted) return;

    try {
      final client = ref.read(apiClientProvider);
      await client.dio
          .delete('/api/certificados-padrao/certificados/${widget.certId}');
      if (mounted) {
        ref.invalidate(certificadosPadraoProvider(widget.padraoId));
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data?['detail'] ?? 'Erro ao excluir';
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
    }
  }

  // ── Seleção de PDF ──────────────────────────────────────────────────────────

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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loadingCert) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_erroMsg != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: NormatiqColors.danger700, size: 48),
              const SizedBox(height: 12),
              Text(_erroMsg!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: NormatiqColors.danger700)),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: _loadCert, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    final cert = _cert!;

    final campos = _templateSelecionado?.campos ?? [];

    final List<Map<String, dynamic>> pontosIniciais;
    if (_pontos.isNotEmpty) {
      pontosIniciais =
          _pontos.map((p) => Map<String, dynamic>.from(p.valores)).toList();
    } else if (_templateSelecionado?.quantidadePontosDefault != null) {
      // Gera linhas vazias baseadas na regra do template
      final qtd = _templateSelecionado!.quantidadePontosDefault!;
      final colNames = campos.map((c) => c['nome'] as String).toList();
      pontosIniciais = List.generate(
        qtd,
        (_) => {for (var name in colNames) name: null},
      );
    } else {
      pontosIniciais = [];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Cert. #${cert.numeroCertificado}'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: NormatiqSpacing.s2),
            child: _buildStatusChip(cert.status),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: NormatiqColors.danger700,
            tooltip: 'Excluir certificado',
            onPressed: _confirmarExclusao,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(NormatiqSpacing.s4),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Metadados colapsáveis ─────────────────────────────────────────
                FormCard(
                  child: ExpansionTile(
                    title: const Text(
                      'Dados do Certificado',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    initiallyExpanded: _pontos.isEmpty,
                    tilePadding: EdgeInsets.zero,
                    shape: const RoundedRectangleBorder(side: BorderSide.none),
                    children: [
                      const SizedBox(height: NormatiqSpacing.s2),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _label(context, 'Identificação'),
                            const SizedBox(height: NormatiqSpacing.s3),
                            // Número (readonly)
                            TextFormField(
                              initialValue: cert.numeroCertificado,
                              decoration: const InputDecoration(
                                  labelText: 'Número do Certificado'),
                              enabled: false,
                            ),
                            const SizedBox(height: NormatiqSpacing.s4),

                            // Laboratório
                            TextFormField(
                              controller: _labCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Laboratório Calibrador *'),
                              enabled: !_savingMeta,
                              validator: (v) => v!.trim().isEmpty
                                  ? 'Informe o laboratório'
                                  : null,
                            ),
                            const SizedBox(height: NormatiqSpacing.s6),

                            _label(context, 'Datas'),
                            const SizedBox(height: NormatiqSpacing.s3),
                            // Datas
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _savingMeta
                                        ? null
                                        : () => _pickDate(true),
                                    icon: const Icon(Icons.calendar_today,
                                        size: 16),
                                    label: Text(
                                        'Emissão: ${_fmtDate(_dataEmissao)}'),
                                  ),
                                ),
                                const SizedBox(width: NormatiqSpacing.s3),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _savingMeta
                                        ? null
                                        : () => _pickDate(false),
                                    icon: const Icon(Icons.event_available,
                                        size: 16),
                                    label: Text(
                                        'Validade: ${_fmtDate(_dataValidade)}'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: NormatiqSpacing.s6),

                            _label(context, 'Metrologia'),
                            const SizedBox(height: NormatiqSpacing.s3),
                            // U expandida e k
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _uExpandidaCtrl,
                                    decoration: const InputDecoration(
                                        labelText: 'Incerteza Expandida (U) *'),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    enabled: !_savingMeta,
                                    validator: (v) {
                                      if (v!.trim().isEmpty)
                                        return 'Obrigatório';
                                      if (double.tryParse(v.trim()) == null) {
                                        return 'Inválido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: NormatiqSpacing.s3),
                                Expanded(
                                  child: TextFormField(
                                    controller: _kAbrangenciaCtrl,
                                    decoration: const InputDecoration(
                                        labelText: 'Fator k *'),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    enabled: !_savingMeta,
                                    validator: (v) {
                                      if (v!.trim().isEmpty)
                                        return 'Obrigatório';
                                      if (double.tryParse(v.trim()) == null) {
                                        return 'Inválido';
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
                              isLoading: _savingMeta,
                              onSelected: (t) =>
                                  setState(() => _templateSelecionado = t),
                            ),
                            const SizedBox(height: NormatiqSpacing.s6),

                            _label(context, 'Documentação'),
                            const SizedBox(height: NormatiqSpacing.s3),
                            // PDF picker
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.picture_as_pdf,
                                color: _pdfFile != null
                                    ? NormatiqColors.primary600
                                    : NormatiqColors.neutral400,
                              ),
                              title: Text(
                                _pdfFile?.name ??
                                    cert.arquivoPdf ??
                                    'Nenhum PDF',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _pdfFile != null ||
                                          cert.arquivoPdf != null
                                      ? Theme.of(context).colorScheme.onSurface
                                      : NormatiqColors.neutral500,
                                ),
                              ),
                              trailing: OutlinedButton(
                                onPressed: _savingMeta ? null : _pickPDF,
                                child: const Text('SELECIONAR'),
                              ),
                            ),

                            const SizedBox(height: NormatiqSpacing.s6),
                            FilledButton(
                              onPressed: _savingMeta ? null : _salvarMetadados,
                              child: _savingMeta
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('SALVAR METADADOS'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: NormatiqSpacing.s6),

                // ── Pontos de medição ─────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: NormatiqSpacing.s2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pontos de Medição',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: NormatiqSpacing.s1),
                      Text(
                        'Insira os valores coletados no certificado externo.',
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: NormatiqSpacing.s4),

                if (_templateSelecionado == null)
                  Card(
                    color: NormatiqColors.warning700.withOpacity(0.08),
                    margin: EdgeInsets.zero,
                    child: const Padding(
                      padding: EdgeInsets.all(NormatiqSpacing.s4),
                      child: Text(
                        'Nenhum template selecionado. Expanda "Dados do Certificado" e selecione um template para habilitar a tabela de medição.',
                      ),
                    ),
                  )
                else if (_loadingPontos)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(NormatiqSpacing.s6),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  FormCard(
                    child: PontosMedicaoWidget(
                      certificadoId: widget.certId,
                      config: {'colunas': campos},
                      pontosIniciais: pontosIniciais,
                      onSaved: _onSalvarPontos,
                    ),
                  ),

                const SizedBox(height: NormatiqSpacing.s8),
              ],
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


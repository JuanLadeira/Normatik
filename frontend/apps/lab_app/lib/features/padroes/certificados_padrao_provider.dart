import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/client.dart';

// ── Modelos ────────────────────────────────────────────────────────────────────

class FormularioTemplateModel {
  final int id;
  final String nome;
  final int tipoInstrumentoId;
  final Map<String, dynamic> camposPontos;
  final String tipoRegressaoDefault;
  final int grauPolinomioDefault;
  final int? quantidadePontosDefault;

  FormularioTemplateModel({
    required this.id,
    required this.nome,
    required this.tipoInstrumentoId,
    required this.camposPontos,
    required this.tipoRegressaoDefault,
    required this.grauPolinomioDefault,
    this.quantidadePontosDefault,
  });

  factory FormularioTemplateModel.fromJson(Map<String, dynamic> json) {
    return FormularioTemplateModel(
      id: json['id'],
      nome: json['nome'],
      tipoInstrumentoId: json['tipo_instrumento_id'],
      camposPontos: Map<String, dynamic>.from(json['campos_pontos'] ?? {}),
      tipoRegressaoDefault: json['tipo_regressao_default'] ?? 'linear',
      grauPolinomioDefault: json['grau_polinomio_default'] ?? 1,
      quantidadePontosDefault: json['quantidade_pontos_default'],
    );
  }

  /// Extrai a lista de colunas normalizada do mapa `{colunas: [...]}`.
  List<dynamic> get campos {
    final raw = camposPontos['colunas'];
    if (raw is List) return raw;
    // Retrocompatibilidade se já houver dados com a chave antiga 'campos'
    final oldRaw = camposPontos['campos'];
    if (oldRaw is List) return oldRaw;
    return [];
  }

  String? get campoRegressaoX => camposPontos['campo_regressao_x'] as String?;
  String? get campoRegressaoY => camposPontos['campo_regressao_y'] as String?;

  Map<String, dynamic> get config => camposPontos;
}

class CertificadoPadraoModel {
  final int id;
  final int padraoId;
  final String numeroCertificado;
  final String laboratorioCalibrador;
  final String dataEmissao;
  final String dataValidade;
  final String? arquivoPdf;
  final double uExpandida;
  final double kAbrangencia;
  final double? uPadrao;
  final int? formularioTemplateId;
  final Map<String, dynamic>? formularioConfig;
  final String status;
  final String? criadoPor;
  final String? createdAt;
  final String? updatedAt;

  CertificadoPadraoModel({
    required this.id,
    required this.padraoId,
    required this.numeroCertificado,
    required this.laboratorioCalibrador,
    required this.dataEmissao,
    required this.dataValidade,
    this.arquivoPdf,
    required this.uExpandida,
    required this.kAbrangencia,
    this.uPadrao,
    this.formularioTemplateId,
    this.formularioConfig,
    required this.status,
    this.criadoPor,
    this.createdAt,
    this.updatedAt,
  });

  factory CertificadoPadraoModel.fromJson(Map<String, dynamic> json) {
    return CertificadoPadraoModel(
      id: json['id'] ?? 0,
      padraoId: json['padrao_id'] ?? 0,
      numeroCertificado: json['numero_certificado'] ?? '',
      laboratorioCalibrador: json['laboratorio_calibrador'] ?? '',
      dataEmissao: json['data_emissao'] ?? '',
      dataValidade: json['data_validade'] ?? '',
      arquivoPdf: json['arquivo_pdf'],
      uExpandida: (json['U_expandida'] as num?)?.toDouble() ?? 0.0,
      kAbrangencia: (json['k_abrangencia'] as num?)?.toDouble() ?? 2.0,
      uPadrao: (json['u_padrao'] as num?)?.toDouble(),
      formularioTemplateId: json['formulario_template_id'],
      formularioConfig: json['formulario_config'] != null
          ? Map<String, dynamic>.from(json['formulario_config'])
          : null,
      status: json['status'] ?? 'rascunho',
      criadoPor: json['criado_por']?.toString(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}

class PontoMedicaoModel {
  final int id;
  final int ordem;
  final Map<String, dynamic> valores;

  PontoMedicaoModel({
    required this.id,
    required this.ordem,
    required this.valores,
  });

  factory PontoMedicaoModel.fromJson(Map<String, dynamic> json) {
    return PontoMedicaoModel(
      id: json['id'],
      ordem: json['ordem'],
      valores: Map<String, dynamic>.from(json['valores'] ?? {}),
    );
  }
}

class CurvaCorrecaoModel {
  final int id;
  final int certificadoId;
  final String tipo;
  final int grau;
  final List<double> coeficientes;
  final double rQuadrado;
  final List<Map<String, double>> pontosCurva;
  final String status;
  final String? aprovadoPor;
  final String? dataAprovacao;

  CurvaCorrecaoModel({
    required this.id,
    required this.certificadoId,
    required this.tipo,
    required this.grau,
    required this.coeficientes,
    required this.rQuadrado,
    required this.pontosCurva,
    required this.status,
    this.aprovadoPor,
    this.dataAprovacao,
  });

  factory CurvaCorrecaoModel.fromJson(Map<String, dynamic> json) {
    return CurvaCorrecaoModel(
      id: json['id'],
      certificadoId: json['certificado_id'],
      tipo: json['tipo'] ?? 'linear',
      grau: json['grau'] ?? 1,
      coeficientes: (json['coeficientes'] as List? ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),
      rQuadrado: (json['r_quadrado'] as num?)?.toDouble() ?? 0.0,
      pontosCurva: (json['pontos_curva'] as List? ?? []).map((e) {
        return {
          'x': (e['x'] as num).toDouble(),
          'y': (e['y'] as num).toDouble(),
        };
      }).toList(),
      status: json['status'] ?? 'sugerida',
      aprovadoPor: json['aprovado_por'],
      dataAprovacao: json['data_aprovacao'],
    );
  }
}

// ── Providers ──────────────────────────────────────────────────────────────────

final certificadosPadraoProvider =
    FutureProvider.family<List<CertificadoPadraoModel>, int>(
  (ref, padraoId) async {
    final client = ref.watch(apiClientProvider);
    try {
      final r = await client.dio
          .get('/api/certificados-padrao/padroes/$padraoId/certificados');
      
      if (r.data is! List) {
        throw 'Resposta da API inválida: esperava uma lista, recebeu ${r.data.runtimeType}';
      }

      return (r.data as List).map((e) {
        try {
          return CertificadoPadraoModel.fromJson(e);
        } catch (err, st) {
          dev.log('Erro ao mapear certificado: $err', stackTrace: st, name: 'CertificadosProvider');
          throw 'Erro ao processar dados do certificado #${e['id']}: $err';
        }
      }).toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message;
      dev.log('Erro Dio ao buscar certificados: $msg', name: 'CertificadosProvider');
      throw msg;
    } catch (e, st) {
      dev.log('Erro inesperado ao buscar certificados: $e', stackTrace: st, name: 'CertificadosProvider');
      rethrow;
    }
  },
);

final templatesCertificadoProvider =
    FutureProvider<List<FormularioTemplateModel>>(
  (ref) async {
    final client = ref.watch(apiClientProvider);
    final r = await client.dio.get('/api/certificados-padrao/templates');
    return (r.data as List)
        .map((e) => FormularioTemplateModel.fromJson(e))
        .toList();
  },
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api/client.dart';
import '../../core/widgets/faixas_medicao_editor.dart';
import 'dart:developer' as dev;

class PadraoCalibracaoStatus {
  static const emDia = 'em_dia';
  static const vencendoEmBreve = 'vencendo_em_breve';
  static const vencido = 'vencido';
  static const semCalibracao = 'sem_calibracao';
}

class PadraoCalibracaoModel {
  final int id;
  final String marca;
  final String modelo;
  final String numeroSerie;
  final String? tag;
  final int tipoEquipamentoId;
  final String? tipoEquipamentoNome;
  final int? modeloEquipamentoId;
  final List<FaixaMedicaoModel> faixas;
  final List<String> fotos;
  final bool ativo;

  // Controle de calibração
  final String statusCalibracao;
  final String? validadeCalibracao;
  final String? numeroCertificado;
  final String? laboratorioCalibrador;
  final double? uExpandidaAtual;
  final int? frequenciaCalibracaoDias;
  final int alertaDiasAntes;
  final String? criterioAceitacao;
  final double? uMaximoAceito;

  PadraoCalibracaoModel({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.numeroSerie,
    this.tag,
    required this.tipoEquipamentoId,
    this.tipoEquipamentoNome,
    this.modeloEquipamentoId,
    required this.faixas,
    this.fotos = const [],
    required this.ativo,
    required this.statusCalibracao,
    this.validadeCalibracao,
    this.numeroCertificado,
    this.laboratorioCalibrador,
    this.uExpandidaAtual,
    this.frequenciaCalibracaoDias,
    required this.alertaDiasAntes,
    this.criterioAceitacao,
    this.uMaximoAceito,
  });

  factory PadraoCalibracaoModel.fromJson(Map<String, dynamic> json) {
    return PadraoCalibracaoModel(
      id: json['id'],
      marca: json['marca'],
      modelo: json['modelo'],
      numeroSerie: json['numero_serie'],
      tag: json['tag'],
      tipoEquipamentoId: json['tipo_equipamento_id'],
      tipoEquipamentoNome: json['tipo_equipamento']?['nome'],
      modeloEquipamentoId: json['modelo_equipamento_id'],
      faixas: (json['faixas'] as List? ?? [])
          .map((e) => FaixaMedicaoModel.fromJson(e))
          .toList(),
      fotos: (json['fotos'] as List? ?? []).cast<String>(),
      ativo: json['ativo'] ?? true,
      statusCalibracao: json['status_calibracao'] ?? PadraoCalibracaoStatus.semCalibracao,
      validadeCalibracao: json['validade_calibracao'],
      numeroCertificado: json['numero_certificado'],
      laboratorioCalibrador: json['laboratorio_calibrador'],
      uExpandidaAtual: (json['u_expandida_atual'] as num?)?.toDouble(),
      frequenciaCalibracaoDias: json['frequencia_calibracao_dias'],
      alertaDiasAntes: json['alerta_dias_antes'] ?? 30,
      criterioAceitacao: json['criterio_aceitacao'],
      uMaximoAceito: (json['u_maximo_aceito'] as num?)?.toDouble(),
    );
  }
}

class HistoricoCalibracaoPadrao {
  final int id;
  final String dataCalibracao;
  final String dataVencimento;
  final String numeroCertificado;
  final String? laboratorioCalibrador;
  final double? uExpandidaCertificado;
  final bool aceito;
  final String? observacoes;

  HistoricoCalibracaoPadrao({
    required this.id,
    required this.dataCalibracao,
    required this.dataVencimento,
    required this.numeroCertificado,
    this.laboratorioCalibrador,
    this.uExpandidaCertificado,
    required this.aceito,
    this.observacoes,
  });

  factory HistoricoCalibracaoPadrao.fromJson(Map<String, dynamic> json) {
    return HistoricoCalibracaoPadrao(
      id: json['id'],
      dataCalibracao: json['data_calibracao'],
      dataVencimento: json['data_vencimento'],
      numeroCertificado: json['numero_certificado'],
      laboratorioCalibrador: json['laboratorio_calibrador'],
      uExpandidaCertificado: (json['u_expandida_certificado'] as num?)?.toDouble(),
      aceito: json['aceito'] ?? true,
      observacoes: json['observacoes'],
    );
  }
}

class PadroesNotifier extends StateNotifier<AsyncValue<List<PadraoCalibracaoModel>>> {
  final ApiClient _apiClient;

  PadroesNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchPadroes();
  }

  Future<void> fetchPadroes() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.dio.get('/api/equipamentos/padroes');
      final list = (response.data as List)
          .map((e) => PadraoCalibracaoModel.fromJson(e))
          .toList();
      state = AsyncValue.data(list);
    } on DioException catch (e) {
      dev.log('Erro ao buscar padrões: ${e.response?.statusCode}');
      state = AsyncValue.error(e, StackTrace.current);
    } catch (e, st) {
      dev.log('Erro inesperado ao buscar padrões: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createPadrao(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/api/equipamentos/padroes', data: data);
    await fetchPadroes();
  }

  Future<void> updatePadrao(int id, Map<String, dynamic> data) async {
    await _apiClient.dio.patch('/api/equipamentos/padroes/$id', data: data);
    await fetchPadroes();
  }

  Future<void> deletePadrao(int id) async {
    await _apiClient.dio.delete('/api/equipamentos/padroes/$id');
    await fetchPadroes();
  }

  Future<List<HistoricoCalibracaoPadrao>> fetchHistorico(int padraoId) async {
    final response = await _apiClient.dio
        .get('/api/equipamentos/padroes/$padraoId/calibracoes');
    return (response.data as List)
        .map((e) => HistoricoCalibracaoPadrao.fromJson(e))
        .toList();
  }

  Future<void> registrarCalibracao(int padraoId, Map<String, dynamic> data) async {
    await _apiClient.dio
        .post('/api/equipamentos/padroes/$padraoId/calibracoes', data: data);
    await fetchPadroes();
  }

  Future<void> updateHistorico(int padraoId, int historicoId, Map<String, dynamic> data) async {
    await _apiClient.dio
        .patch('/api/equipamentos/padroes/$padraoId/calibracoes/$historicoId', data: data);
    await fetchPadroes();
  }

  Future<void> deleteHistorico(int padraoId, int historicoId) async {
    await _apiClient.dio
        .delete('/api/equipamentos/padroes/$padraoId/calibracoes/$historicoId');
    await fetchPadroes();
  }
}

final padroesProvider =
    StateNotifierProvider<PadroesNotifier, AsyncValue<List<PadraoCalibracaoModel>>>(
  (ref) => PadroesNotifier(ref.watch(apiClientProvider)),
);

// Provider para histórico de um padrão específico
final historicoCalibracaoPadraoProvider =
    FutureProvider.family<List<HistoricoCalibracaoPadrao>, int>((ref, padraoId) async {
  return ref.read(padroesProvider.notifier).fetchHistorico(padraoId);
});

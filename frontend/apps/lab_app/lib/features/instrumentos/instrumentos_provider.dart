import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api/client.dart';
import '../../core/widgets/faixas_medicao_editor.dart';
import 'dart:developer' as dev;

class InstrumentoModel {
  final int id;
  final String marca;
  final String modelo;
  final String numeroSerie;
  final String? tag;
  final int tipoEquipamentoId;
  final int? modeloEquipamentoId;
  final int clienteId;
  final List<FaixaMedicaoModel> faixas;
  final List<String> fotos;
  final bool ativo;

  InstrumentoModel({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.numeroSerie,
    this.tag,
    required this.tipoEquipamentoId,
    this.modeloEquipamentoId,
    required this.clienteId,
    required this.faixas,
    this.fotos = const [],
    required this.ativo,
  });

  factory InstrumentoModel.fromJson(Map<String, dynamic> json) {
    return InstrumentoModel(
      id: json['id'],
      marca: json['marca'],
      modelo: json['modelo'],
      numeroSerie: json['numero_serie'],
      tag: json['tag'],
      tipoEquipamentoId: json['tipo_equipamento_id'],
      modeloEquipamentoId: json['modelo_equipamento_id'],
      clienteId: json['cliente_id'],
      faixas: (json['faixas'] as List? ?? [])
          .map((e) => FaixaMedicaoModel.fromJson(e))
          .toList(),
      fotos: (json['fotos'] as List? ?? []).cast<String>(),
      ativo: json['ativo'] ?? true,
    );
  }
}

class InstrumentosNotifier
    extends StateNotifier<AsyncValue<List<InstrumentoModel>>> {
  final ApiClient _apiClient;

  InstrumentosNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchInstrumentos();
  }

  Future<void> fetchInstrumentos({int? clienteId}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.dio.get(
        '/api/equipamentos/instrumentos',
        queryParameters: clienteId != null ? {'cliente_id': clienteId} : null,
      );
      final list = (response.data as List)
          .map((e) => InstrumentoModel.fromJson(e))
          .toList();
      state = AsyncValue.data(list);
    } on DioException catch (e) {
      dev.log('Erro ao buscar instrumentos: ${e.response?.statusCode}');
      state = AsyncValue.error(e, StackTrace.current);
    } catch (e, st) {
      dev.log('Erro inesperado ao buscar instrumentos: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createInstrumento(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/api/equipamentos/instrumentos', data: data);
    await fetchInstrumentos();
  }

  Future<void> updateInstrumento(int id, Map<String, dynamic> data) async {
    await _apiClient.dio
        .patch('/api/equipamentos/instrumentos/$id', data: data);
    await fetchInstrumentos();
  }

  Future<void> deleteInstrumento(int id) async {
    await _apiClient.dio.delete('/api/equipamentos/instrumentos/$id');
    await fetchInstrumentos();
  }
}

final instrumentosProvider =
    StateNotifierProvider<InstrumentosNotifier, AsyncValue<List<InstrumentoModel>>>(
  (ref) => InstrumentosNotifier(ref.watch(apiClientProvider)),
);

final instrumentosPorClienteProvider =
    FutureProvider.family<List<InstrumentoModel>, int>((ref, clienteId) async {
  final dio = ref.watch(apiClientProvider).dio;
  final response = await dio.get(
    '/api/equipamentos/instrumentos',
    queryParameters: {'cliente_id': clienteId},
  );
  return (response.data as List)
      .map((e) => InstrumentoModel.fromJson(e))
      .toList();
});

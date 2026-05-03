import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/client.dart';

class TipoEquipamento {
  final int id;
  final String codigo;
  final String nome;
  final int grandezaId;
  final List<ModeloEquipamento> modelos;

  TipoEquipamento({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.grandezaId,
    this.modelos = const [],
  });

  factory TipoEquipamento.fromJson(Map<String, dynamic> json) {
    return TipoEquipamento(
      id: json['id'],
      codigo: json['codigo'],
      nome: json['nome'],
      grandezaId: json['grandeza_id'],
      modelos: json['modelos'] != null
          ? (json['modelos'] as List)
              .map((e) => ModeloEquipamento.fromJson(e))
              .toList()
          : [],
    );
  }
}

class Fabricante {
  final int id;
  final String nome;

  Fabricante({required this.id, required this.nome});

  factory Fabricante.fromJson(Map<String, dynamic> json) {
    return Fabricante(
      id: json['id'],
      nome: json['nome'],
    );
  }
}

class ModeloEquipamento {
  final int id;
  final int tipoEquipamentoId;
  final int fabricanteId;
  final String nome;
  final String? fabricanteNome;

  ModeloEquipamento({
    required this.id,
    required this.tipoEquipamentoId,
    required this.fabricanteId,
    required this.nome,
    this.fabricanteNome,
  });

  factory ModeloEquipamento.fromJson(Map<String, dynamic> json) {
    return ModeloEquipamento(
      id: json['id'],
      tipoEquipamentoId: json['tipo_equipamento_id'],
      fabricanteId: json['fabricante_id'],
      nome: json['nome'],
      fabricanteNome: json['fabricante'] != null ? json['fabricante']['nome'] : null,
    );
  }
}

class TiposEquipamentoNotifier
    extends StateNotifier<AsyncValue<List<TipoEquipamento>>> {
  TiposEquipamentoNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetch();
  }

  final Ref _ref;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(apiClientProvider).dio;
      final response = await dio.get('/api/equipamentos/tipos');
      state = AsyncValue.data((response.data as List)
          .map((e) => TipoEquipamento.fromJson(e))
          .toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<TipoEquipamento> create(String nome, {required int grandezaId}) async {
    final dio = _ref.read(apiClientProvider).dio;
    final response = await dio.post('/api/equipamentos/tipos', data: {
      'nome': nome,
      'grandeza_id': grandezaId,
    });
    final novo = TipoEquipamento.fromJson(response.data);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, novo]);
    return novo;
  }

  Future<ModeloEquipamento> addModelo({
    required int tipoId,
    required String fabricanteNome,
    required String modeloNome,
  }) async {
    final dio = _ref.read(apiClientProvider).dio;
    
    // 1. Garantir Fabricante
    final fabResp = await dio.post('/api/equipamentos/fabricantes', data: {
      'nome': fabricanteNome,
    });
    final fabricante = Fabricante.fromJson(fabResp.data);

    // 2. Criar Modelo
    final modResp = await dio.post('/api/equipamentos/modelos', data: {
      'tipo_equipamento_id': tipoId,
      'fabricante_id': fabricante.id,
      'nome': modeloNome,
    });
    final modelo = ModeloEquipamento.fromJson(modResp.data);

    // 3. Refresh tipos para atualizar lista de modelos (simplificado)
    await fetch();
    
    return modelo;
  }

  Future<void> updateModelo({
    required int id,
    String? fabricanteNome,
    String? modeloNome,
  }) async {
    final dio = _ref.read(apiClientProvider).dio;

    int? fabId;
    if (fabricanteNome != null) {
      final fabResp = await dio.post('/api/equipamentos/fabricantes', data: {
        'nome': fabricanteNome,
      });
      fabId = Fabricante.fromJson(fabResp.data).id;
    }

    await dio.patch('/api/equipamentos/modelos/$id', data: {
      if (fabId != null) 'fabricante_id': fabId,
      if (modeloNome != null) 'nome': modeloNome,
    });

    await fetch();
  }

  Future<void> deleteModelo(int id) async {
    final dio = _ref.read(apiClientProvider).dio;
    await dio.delete('/api/equipamentos/modelos/$id');
    await fetch();
  }
}

final tiposEquipamentoProvider = StateNotifierProvider<TiposEquipamentoNotifier,
    AsyncValue<List<TipoEquipamento>>>(
  (ref) => TiposEquipamentoNotifier(ref),
);

// Providers para listas auxiliares
final fabricantesProvider = FutureProvider<List<Fabricante>>((ref) async {
  final dio = ref.read(apiClientProvider).dio;
  final response = await dio.get('/api/equipamentos/fabricantes');
  return (response.data as List).map((e) => Fabricante.fromJson(e)).toList();
});

final modelosProvider = FutureProvider.family<List<ModeloEquipamento>, int?>((ref, tipoId) async {
  final dio = ref.read(apiClientProvider).dio;
  final response = await dio.get('/api/equipamentos/modelos', queryParameters: {
    if (tipoId != null) 'tipo_id': tipoId,
  });
  return (response.data as List).map((e) => ModeloEquipamento.fromJson(e)).toList();
});


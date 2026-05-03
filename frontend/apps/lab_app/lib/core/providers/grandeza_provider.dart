import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/client.dart';

class UnidadeMedida {
  final int id;
  final int grandezaId;
  final String nome;
  final String simbolo;
  final bool isSi;

  UnidadeMedida({
    required this.id,
    required this.grandezaId,
    required this.nome,
    required this.simbolo,
    required this.isSi,
  });

  factory UnidadeMedida.fromJson(Map<String, dynamic> json) => UnidadeMedida(
        id: json['id'],
        grandezaId: json['grandeza_id'],
        nome: json['nome'],
        simbolo: json['simbolo'],
        isSi: json['is_si'] ?? false,
      );
}

class Grandeza {
  final int id;
  final String nome;
  final String simbolo;
  final List<UnidadeMedida> unidades;

  Grandeza({
    required this.id,
    required this.nome,
    required this.simbolo,
    required this.unidades,
  });

  UnidadeMedida? get unidadeSi =>
      unidades.where((u) => u.isSi).firstOrNull;

  factory Grandeza.fromJson(Map<String, dynamic> json) => Grandeza(
        id: json['id'],
        nome: json['nome'],
        simbolo: json['simbolo'],
        unidades: (json['unidades'] as List? ?? [])
            .map((e) => UnidadeMedida.fromJson(e))
            .toList(),
      );
}

class GrandezasNotifier extends StateNotifier<AsyncValue<List<Grandeza>>> {
  GrandezasNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetch();
  }

  final Ref _ref;

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(apiClientProvider).dio;
      final response = await dio.get('/api/grandezas/');
      state = AsyncValue.data(
          (response.data as List).map((e) => Grandeza.fromJson(e)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Grandeza> create(String nome, String simbolo) async {
    final dio = _ref.read(apiClientProvider).dio;
    final response = await dio.post('/api/grandezas/', data: {
      'nome': nome,
      'simbolo': simbolo,
    });
    final nova = Grandeza.fromJson(response.data);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, nova]);
    return nova;
  }

  Future<UnidadeMedida> addUnidade(
    int grandezaId, {
    required String nome,
    required String simbolo,
    bool isSi = false,
  }) async {
    final dio = _ref.read(apiClientProvider).dio;
    final response = await dio.post(
      '/api/grandezas/$grandezaId/unidades',
      data: {'nome': nome, 'simbolo': simbolo, 'is_si': isSi},
    );
    final unidade = UnidadeMedida.fromJson(response.data);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.map((g) {
      if (g.id != grandezaId) return g;
      return Grandeza(
        id: g.id,
        nome: g.nome,
        simbolo: g.simbolo,
        unidades: [...g.unidades, unidade],
      );
    }).toList());
    return unidade;
  }

  Future<void> deleteUnidade(int grandezaId, int unidadeId) async {
    final dio = _ref.read(apiClientProvider).dio;
    await dio.delete('/api/grandezas/$grandezaId/unidades/$unidadeId');
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.map((g) {
      if (g.id != grandezaId) return g;
      return Grandeza(
        id: g.id,
        nome: g.nome,
        simbolo: g.simbolo,
        unidades: g.unidades.where((u) => u.id != unidadeId).toList(),
      );
    }).toList());
  }

  Future<void> deleteGrandeza(int id) async {
    final dio = _ref.read(apiClientProvider).dio;
    await dio.delete('/api/grandezas/$id');
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((g) => g.id != id).toList());
  }
}

final grandezasProvider =
    StateNotifierProvider<GrandezasNotifier, AsyncValue<List<Grandeza>>>(
  (ref) => GrandezasNotifier(ref),
);

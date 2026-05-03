import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api/client.dart';
import 'dart:developer' as dev;

class ClienteLaboratorio {
  final int id;
  final String nome;
  final String? cnpj;
  final String? email;
  final String? telefone;
  final String? contato;
  final bool ativo;

  ClienteLaboratorio({
    required this.id,
    required this.nome,
    this.cnpj,
    this.email,
    this.telefone,
    this.contato,
    required this.ativo,
  });

  factory ClienteLaboratorio.fromJson(Map<String, dynamic> json) {
    return ClienteLaboratorio(
      id: json['id'],
      nome: json['nome'],
      cnpj: json['cnpj'],
      email: json['email'],
      telefone: json['telefone'],
      contato: json['contato'],
      ativo: json['ativo'] ?? true,
    );
  }
}

class ClientesNotifier extends StateNotifier<AsyncValue<List<ClienteLaboratorio>>> {
  final ApiClient _apiClient;

  ClientesNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchClientes();
  }

  Future<void> fetchClientes() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.dio.get('/api/clientes');
      final list = (response.data as List)
          .map((e) => ClienteLaboratorio.fromJson(e))
          .toList();
      state = AsyncValue.data(list);
    } on DioException catch (e) {
      dev.log('Erro ao buscar clientes: ${e.response?.statusCode}');
      state = AsyncValue.error(e, StackTrace.current);
    } catch (e, st) {
      dev.log('Erro inesperado ao buscar clientes: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createCliente(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/api/clientes', data: data);
    await fetchClientes();
  }

  Future<void> updateCliente(int id, Map<String, dynamic> data) async {
    await _apiClient.dio.patch('/api/clientes/$id', data: data);
    await fetchClientes();
  }

  Future<void> deleteCliente(int id) async {
    await _apiClient.dio.delete('/api/clientes/$id');
    await fetchClientes();
  }
}

final clientesProvider =
    StateNotifierProvider<ClientesNotifier, AsyncValue<List<ClienteLaboratorio>>>(
  (ref) => ClientesNotifier(ref.watch(apiClientProvider)),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/client.dart';
import 'package:dio/dio.dart';
import 'dart:developer' as dev;

class LabUser {
  final int id;
  final String email;
  final String nome;
  final String role;
  final bool isActive;

  LabUser({
    required this.id,
    required this.email,
    required this.nome,
    required this.role,
    required this.isActive,
  });

  factory LabUser.fromJson(Map<String, dynamic> json) {
    return LabUser(
      id: json['id'],
      email: json['email'],
      nome: json['nome'],
      role: json['role'],
      isActive: json['is_active'],
    );
  }
}

class UsersNotifier extends StateNotifier<AsyncValue<List<LabUser>>> {
  final ApiClient _apiClient;

  UsersNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    state = const AsyncValue.loading();
    try {
      dev.log("Buscando usuários em /api/users");
      // Removida barra final para evitar problemas de redirect no FastAPI
      final response = await _apiClient.dio.get('/api/users');
      final list = (response.data as List).map((e) => LabUser.fromJson(e)).toList();
      state = AsyncValue.data(list);
      dev.log("Sucesso: ${list.length} usuários encontrados");
    } on DioException catch (e) {
      dev.log("Erro Dio ao buscar usuários: ${e.response?.statusCode} - ${e.message}");
      state = AsyncValue.error(e, StackTrace.current);
    } catch (e, st) {
      dev.log("Erro inesperado ao buscar usuários: $e");
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> inviteUser(String email, String nome, String role) async {
    try {
      await _apiClient.dio.post('/api/users/invite', data: {
        'email': email,
        'nome': nome,
        'role': role,
      });
      await fetchUsers(); 
    } catch (e) {
      dev.log("Erro ao convidar: $e");
      rethrow;
    }
  }
}

final usersProvider = StateNotifierProvider<UsersNotifier, AsyncValue<List<LabUser>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UsersNotifier(apiClient);
});

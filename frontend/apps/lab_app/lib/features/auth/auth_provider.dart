import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api/client.dart';
import 'package:dio/dio.dart';

enum AuthStatus { idle, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  AuthState({required this.status, this.errorMessage});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._ref) : super(AuthState(status: AuthStatus.idle)) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      state = AuthState(status: AuthStatus.authenticated);
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState(status: AuthStatus.loading);

    try {
      final formData = FormData.fromMap({
        'username': email,
        'password': password,
      });

      // Acessamos o Dio via ref para evitar circularidade no construtor
      final dio = _ref.read(apiClientProvider).dio;
      final response = await dio.post('/api/auth/login', data: formData);
      
      final token = response.data['access_token'];
      await _storage.write(key: 'access_token', value: token);

      state = AuthState(status: AuthStatus.authenticated);
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Erro ao realizar login';
      state = AuthState(status: AuthStatus.error, errorMessage: message);
    } catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: 'Erro inesperado');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late Dio dio;
  final storage = const FlutterSecureStorage();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        // URL da nossa API FastAPI (usando localhost para Web, 
        // mas para Android Emulator seria 10.0.2.2)
        baseUrl: 'http://localhost:8000',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );

    // Adiciona interceptor para incluir o token JWT em todas as requisições
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            // Aqui poderíamos tratar o logout automático
            print('Token expirado ou inválido');
          }
          return handler.next(e);
        },
      ),
    );
  }

  // Método simples para login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await dio.post('/auth/token', data: {
        'username': username,
        'password': password,
      });
      
      final token = response.data['access_token'];
      await storage.write(key: 'access_token', value: token);
      
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}

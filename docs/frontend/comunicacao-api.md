# 🌐 Comunicação com a API

A integração com os serviços de backend é realizada através da biblioteca **Dio**, um cliente HTTP robusto para Dart que suporta interceptadores, configuração global e tratamento avançado de requisições.

## 📦 Configuração do Cliente de Rede

A lógica de rede está centralizada para garantir a padronização das chamadas e a segurança das comunicações.

### Provedor `apiClientProvider`

A configuração do cliente é disponibilizada através de um provider global (`lib/core/api/client.dart`), que estabelece:

1.  **Base URL:** O endereço base do servidor de API.
2.  **Interceptadores:** Camadas de processamento executadas em cada requisição para:
    *   Injeção automática de tokens de autenticação (JWT) nos cabeçalhos (`Authorization: Bearer ...`).
    *   Log de requisições e respostas em ambiente de desenvolvimento.
    *   Tratamento global de códigos de erro (ex: logout automático em caso de erro 401).

## 🧱 Tratamento de Exceções

As chamadas de rede são encapsuladas em blocos de tratamento de erro para garantir a estabilidade da interface:

```dart
try {
  final response = await dio.get('/api/resource');
  return response.data;
} on DioException catch (e) {
  // Tratamento específico para erros do protocolo HTTP ou conectividade
  throw Exception('Falha na comunicação com o servidor: ${e.response?.statusCode}');
}
```

## 🛠️ Padrões de Implementação

*   **Programação Assíncrona:** O uso de `async/await` é obrigatório para todas as operações de I/O, evitando o bloqueio da thread principal de interface.
*   **Serialização de Dados:** O mapeamento entre o JSON retornado pela API e os objetos de domínio Dart é realizado através de métodos de fábrica `fromJson`, garantindo a tipagem forte e a validação dos dados em tempo de compilação.

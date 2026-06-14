import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/api_config.dart';
import 'api_exception.dart';

/// Token em memória usado pelo interceptor. O AuthController atualiza este
/// provider no login/logout. Manter o token aqui (e não no AuthController)
/// evita um ciclo: dio depende deste provider; AuthController depende do dio
/// e escreve aqui.
final authTokenProvider = StateProvider<String?>((ref) => null);

/// Cliente HTTP único e autenticado. Injeta o Bearer token em toda requisição
/// e converte erros do dio em [ApiException].
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authTokenProvider);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final status = error.response?.statusCode;
        final detail = error.response?.data is Map
            ? (error.response?.data['detail']?.toString())
            : null;
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            error: ApiException(
              detail ?? error.message ?? 'Erro de conexão',
              statusCode: status,
            ),
          ),
        );
      },
    ),
  );

  return dio;
});

/// Extrai o [ApiException] de um erro do dio para uso nos repositórios.
ApiException toApiException(Object error) {
  if (error is DioException && error.error is ApiException) {
    return error.error as ApiException;
  }
  if (error is DioException) {
    return ApiException(error.message ?? 'Erro de conexão',
        statusCode: error.response?.statusCode);
  }
  return ApiException(error.toString());
}

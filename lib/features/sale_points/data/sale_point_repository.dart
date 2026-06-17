import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/sale_point.dart';

class SalePointRepository {
  final Dio _dio;
  SalePointRepository(this._dio);

  Future<List<SalePoint>> list() async {
    try {
      final response = await _dio.get('/auth/');
      return (response.data as List)
          .map((e) => SalePoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Cadastra um novo ponto de venda / vendedor (admin). O backend recebe
  /// nome/senha/email por QUERY PARAMS (não body) e cria com papel "vendedor".
  Future<void> create({
    required String name,
    required String password,
    String? email,
  }) async {
    try {
      await _dio.post('/auth/', queryParameters: {
        'name': name,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      });
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/auth/$id');
    } catch (e) {
      throw toApiException(e);
    }
  }
}

final salePointRepositoryProvider = Provider<SalePointRepository>(
    (ref) => SalePointRepository(ref.watch(dioProvider)));

final salePointsProvider = FutureProvider.autoDispose<List<SalePoint>>(
    (ref) => ref.watch(salePointRepositoryProvider).list());

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/stock_request.dart';

class StockRequestRepository {
  final Dio _dio;
  StockRequestRepository(this._dio);

  Future<List<StockRequest>> list() async {
    try {
      final response = await _dio.get('/stock-requests/');
      return (response.data as List)
          .map((e) => StockRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> create(
      {required int productId,
      required double quantity,
      required String unidade}) async {
    try {
      await _dio.post('/stock-requests/', data: {
        'product_id': productId,
        'quantity': quantity,
        'unidade': unidade,
      });
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> approve(int id) async {
    try {
      await _dio.post('/stock-requests/$id/approve');
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> reject(int id, String reason) async {
    try {
      await _dio.post('/stock-requests/$id/reject', data: {'reason': reason});
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _dio.post('/stock-requests/$id/cancel');
    } catch (e) {
      throw toApiException(e);
    }
  }
}

final stockRequestRepositoryProvider = Provider<StockRequestRepository>(
    (ref) => StockRequestRepository(ref.watch(dioProvider)));

/// Lista de solicitações (o backend já filtra por papel: admin vê todas,
/// vendedor vê só as suas).
final stockRequestsProvider = FutureProvider.autoDispose<List<StockRequest>>(
    (ref) => ref.watch(stockRequestRepositoryProvider).list());

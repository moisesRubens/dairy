import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../auth/application/auth_controller.dart';
import '../domain/order.dart';

class OrderRepository {
  final Dio _dio;
  OrderRepository(this._dio);

  Future<List<Order>> listToday(int salePointId) async {
    try {
      final today = _todayStr();
      final response =
          await _dio.get('/auth/$salePointId/order', queryParameters: {'date': today});
      return (response.data as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Persiste uma venda. [items] = [{product_id, amount|kg|liters: qtd}].
  /// O total é calculado no servidor. [clientId] vincula a venda a um cliente
  /// (opcional — null = venda rápida/anônima).
  Future<Order> createOrder(
      int salePointId, List<Map<String, dynamic>> items,
      {int? clientId}) async {
    try {
      final response = await _dio.post('/auth/$salePointId/order', data: {
        'description': 'Venda no PDV',
        'client_id': ?clientId,
        'items': items,
      });
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}

final orderRepositoryProvider =
    Provider<OrderRepository>((ref) => OrderRepository(ref.watch(dioProvider)));

/// Pedidos do dia do ponto logado.
final ordersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final salePointId = ref.watch(currentSalePointIdProvider);
  if (salePointId == null) return [];
  return ref.watch(orderRepositoryProvider).listToday(salePointId);
});

/// Faturamento do dia = soma dos pedidos do dia.
final vendorTodayRevenueProvider = Provider.autoDispose<double>((ref) {
  final orders = ref.watch(ordersProvider).valueOrNull ?? const [];
  return orders.fold<double>(0, (sum, o) => sum + o.totalValue);
});

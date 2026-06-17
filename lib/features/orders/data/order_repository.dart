import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/local/local_store.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/sync/outbox_dao.dart';
import '../../auth/application/auth_controller.dart';
import '../domain/order.dart';

class OrderRepository {
  final Dio _dio;
  final OutboxDao _outbox;
  OrderRepository(this._dio, this._outbox);

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
  /// Cada venda carrega um `client_uuid` (idempotência). Retorna `true` se foi
  /// ENVIADA online; `false` se ficou ENFILEIRADA no outbox (offline) — nesse
  /// caso sincroniza depois, sem duplicar (o backend deduplica pelo uuid).
  Future<bool> createOrder(
      int salePointId, List<Map<String, dynamic>> items,
      {int? clientId, String? paymentMethod}) async {
    final body = <String, dynamic>{
      'description': 'Venda no PDV',
      'client_id': ?clientId,
      'payment_method': ?paymentMethod,
      'client_uuid': const Uuid().v4(),
      'items': items,
    };
    try {
      await _dio.post('/auth/$salePointId/order', data: body);
      return true; // enviada online
    } on DioException catch (e) {
      if (e.response == null) {
        // Sem resposta = offline → enfileira para reenvio idempotente.
        await _outbox.enqueue(
            clientUuid: body['client_uuid'] as String,
            salePointId: salePointId,
            payload: body);
        return false; // registrada offline
      }
      throw toApiException(e);
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

final orderRepositoryProvider = Provider<OrderRepository>((ref) =>
    OrderRepository(ref.watch(dioProvider), OutboxDao(LocalStore.instance)));

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

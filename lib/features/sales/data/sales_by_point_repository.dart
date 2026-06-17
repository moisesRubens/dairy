import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/sale_order.dart';

/// Acesso às vendas (pedidos com itens) de um ponto de venda específico, para
/// a tela "Vendas por Banca" (admin). Consome `GET /auth/{id}/order`.
class SalesByPointRepository {
  final Dio _dio;
  SalesByPointRepository(this._dio);

  /// Pedidos do ponto [salePointId]. Sem [date] traz todo o histórico; com
  /// data (YYYY-MM-DD) filtra pelo dia.
  Future<List<SaleOrder>> ordersOf(int salePointId, {String? date}) async {
    try {
      final response = await _dio.get('/auth/$salePointId/order',
          queryParameters: {'date': ?date});
      final data = response.data;
      if (data is! List) return const [];
      return data
          .map((e) => SaleOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }
}

final salesByPointRepositoryProvider = Provider<SalesByPointRepository>(
    (ref) => SalesByPointRepository(ref.watch(dioProvider)));

/// Vendas de um ponto (histórico completo). Família por id do ponto.
final salesByPointProvider =
    FutureProvider.autoDispose.family<List<SaleOrder>, int>(
  (ref, salePointId) =>
      ref.watch(salesByPointRepositoryProvider).ordersOf(salePointId),
);

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../auth/application/auth_controller.dart';
import '../domain/outbound.dart';

/// Acesso às retiradas (outbounds) de um ponto: o estoque que ele tem para
/// vender. Consome `GET /auth/{id}/outbounds` e a devolução
/// `PATCH /auth/{id}/outbounds` (devolve o restante de hoje ao depósito).
class StockRepository {
  final Dio _dio;
  StockRepository(this._dio);

  Future<List<Outbound>> outbounds(int salePointId) async {
    try {
      final response = await _dio.get('/auth/$salePointId/outbounds');
      final data = response.data;
      if (data is! List) return const [];
      return data
          .map((e) => Outbound.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Devolve ao depósito o restante das retiradas de HOJE deste ponto
  /// (fecha o dia). O backend zera `remaining_quantity` e baixa o status.
  Future<void> returnRemaining(int salePointId) async {
    try {
      await _dio.patch('/auth/$salePointId/outbounds');
    } catch (e) {
      throw toApiException(e);
    }
  }
}

final stockRepositoryProvider =
    Provider<StockRepository>((ref) => StockRepository(ref.watch(dioProvider)));

/// Estoque (retiradas) do ponto logado.
final myStockProvider = FutureProvider.autoDispose<List<Outbound>>((ref) {
  final salePointId = ref.watch(currentSalePointIdProvider);
  if (salePointId == null) return Future.value(const []);
  return ref.watch(stockRepositoryProvider).outbounds(salePointId);
});

// e2e do ciclo offline→online (P4 Fase 3) contra um BACKEND REAL:
// login real → venda OFFLINE (enfileira no outbox) → flush via SyncService →
// o servidor passa a ter o pedido UMA vez (idempotente mesmo com reenvio).
//
// Pré-requisito (orquestrado por bash): backend no ar em API_BASE_URL com um
// vendedor `vend`/`v123` que tenha uma retirada de HOJE (estoque para vender).
//   flutter test integration_test/e2e_offline_sync_test.dart -d macos \
//     --dart-define=API_BASE_URL=http://127.0.0.1:8044
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dairy/core/local/local_store.dart';
import 'package:dairy/core/network/dio_provider.dart';
import 'package:dairy/core/sync/outbox_dao.dart';
import 'package:dairy/core/sync/sync_service.dart';
import 'package:dairy/features/auth/application/auth_controller.dart';
import 'package:dairy/features/orders/data/order_repository.dart';

Dio _deadDio() => Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1:9',
      connectTimeout: const Duration(milliseconds: 800),
    ));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('venda offline → flush → servidor tem o pedido (idempotente)',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Login REAL (backend no ar).
    await container.read(authControllerProvider.notifier).login('vend', 'v123');
    final vid = container.read(currentSalePointIdProvider);
    expect(vid, isNotNull);

    // Zera o outbox local.
    final outbox = OutboxDao(LocalStore.instance);
    for (final e in await outbox.pending()) {
      await outbox.remove(e.id);
    }

    // 1) VENDA OFFLINE: Dio morto → cai no outbox.
    final offlineRepo = OrderRepository(_deadDio(), outbox);
    final sentOnline = await offlineRepo.createOrder(
      vid!,
      [
        {'product_id': 1, 'kg': 2}
      ],
      paymentMethod: 'pix',
    );
    expect(sentOnline, false);
    expect(await outbox.count(), 1);

    // 2) FLUSH (online, Dio real autenticado) via SyncService.
    await container.read(syncServiceProvider.notifier).flush();
    expect(await outbox.count(), 0); // saiu da fila

    // 3) O SERVIDOR tem o pedido — e UMA vez só (idempotência).
    final dio = container.read(dioProvider);
    final orders = (await dio.get('/auth/$vid/order')).data as List;
    expect(orders.length, 1, reason: 'a venda offline sincronizou (1 pedido)');

    // Reenviar de novo NÃO duplica (dedup por client_uuid no backend).
    await container.read(syncServiceProvider.notifier).flush();
    final orders2 = (await dio.get('/auth/$vid/order')).data as List;
    expect(orders2.length, 1, reason: 'reenvio idempotente — segue 1 pedido');
  });
}

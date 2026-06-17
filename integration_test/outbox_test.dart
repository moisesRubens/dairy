// Valida a ESCRITA offline (P4 Fase 3): uma venda sem rede vai para o outbox
// (com client_uuid) e a mecânica da fila (count/remove). A idempotência do
// reenvio já é garantida pelo backend (dedup por client_uuid).
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dairy/core/local/local_store.dart';
import 'package:dairy/core/sync/outbox_dao.dart';
import 'package:dairy/features/orders/data/order_repository.dart';

Dio _deadDio() => Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1:9',
      connectTimeout: const Duration(milliseconds: 800),
    ));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('venda offline enfileira no outbox + mecânica da fila',
      (tester) async {
    final outbox = OutboxDao(LocalStore.instance);
    // limpa resíduos de execuções anteriores
    for (final e in await outbox.pending()) {
      await outbox.remove(e.id);
    }

    final repo = OrderRepository(_deadDio(), outbox);
    final sentOnline = await repo.createOrder(
      7,
      [
        {'product_id': 1, 'kg': 2}
      ],
      paymentMethod: 'pix',
    );

    // Offline → não enviou; ficou enfileirado.
    expect(sentOnline, false);

    final pending = await outbox.pending();
    expect(pending.length, 1);
    expect(pending.first.salePointId, 7);
    expect(pending.first.payload['client_uuid'], isNotNull);
    expect(pending.first.payload['items'], isNotEmpty);
    expect(pending.first.payload['payment_method'], 'pix');

    // Mecânica da fila: count + remove (= sucesso no flush).
    expect(await outbox.count(), 1);
    await outbox.remove(pending.first.id);
    expect(await outbox.count(), 0);
  });

  testWidgets('falha estaciona (fora do count) e retry recoloca como pendente',
      (tester) async {
    final outbox = OutboxDao(LocalStore.instance);
    for (final e in await outbox.all()) {
      await outbox.remove(e.id);
    }

    await outbox.enqueue(clientUuid: 'u-1', salePointId: 3, payload: {
      'client_uuid': 'u-1',
      'items': [
        {'product_id': 1, 'kg': 1}
      ],
    });
    final pend = await outbox.pending();
    expect(pend.length, 1);

    // Rejeitada pelo servidor (4xx) → estaciona: sai do count, fica em all().
    await outbox.markFailed(pend.first.id, 'Sem estoque');
    expect(await outbox.count(), 0);
    final all = await outbox.all();
    expect(all.length, 1);
    expect(all.first.isFailed, true);
    expect(all.first.error, 'Sem estoque');

    // Retry manual recoloca na fila.
    await outbox.retry(all.first.id);
    expect(await outbox.count(), 1);

    for (final e in await outbox.all()) {
      await outbox.remove(e.id);
    }
  });
}

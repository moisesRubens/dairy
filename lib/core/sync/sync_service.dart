import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/orders/data/order_repository.dart';
import '../local/local_store.dart';
import '../network/connectivity_provider.dart';
import '../network/dio_provider.dart';
import 'outbox_dao.dart';

/// Sincroniza o outbox (vendas offline). O estado é a **contagem de pendências**
/// (usada no banner). Faz flush ao iniciar, ao voltar a rede e ao logar — cada
/// reenvio é idempotente no servidor (dedup por `client_uuid`).
class SyncService extends Notifier<int> {
  OutboxDao get _outbox => OutboxDao(LocalStore.instance);
  bool _flushing = false;

  @override
  int build() {
    // Reenvia quando a rede volta ou quando a sessão é (re)autenticada.
    ref.listen(isOnlineProvider, (_, next) {
      if (next.valueOrNull == true) flush();
    });
    ref.listen(authControllerProvider, (_, next) {
      if (next.authenticated) flush();
    });
    Future.microtask(flush); // tenta drenar ao iniciar
    return 0;
  }

  Future<void> _refreshCount() async => state = await _outbox.count();

  /// Recalcula o nº de pendências (após descartar/retry na tela de Sincronização).
  Future<void> refreshCount() => _refreshCount();

  /// Reenvia as vendas pendentes na ordem. Para no primeiro erro de rede
  /// (ainda offline); erros com resposta marcam a entrada como falha.
  Future<void> flush() async {
    if (_flushing) return; // evita flushes concorrentes (connectivity + auth)
    if (!ref.read(authControllerProvider).authenticated) return;
    _flushing = true;
    try {
      final dio = ref.read(dioProvider);
      final pending = await _outbox.pending();
      var sent = 0;
      for (final e in pending) {
        try {
          await dio.post('/auth/${e.salePointId}/order', data: e.payload);
          await _outbox.remove(e.id); // sucesso (idempotente) → sai da fila
          sent++;
        } on DioException catch (err) {
          if (err.response == null) break; // ainda offline → para o flush
          await _outbox.markFailed(e.id, err.message ?? 'erro'); // 4xx/5xx
        }
      }
      await _refreshCount();
      if (sent > 0) ref.invalidate(ordersProvider); // atualiza pedidos do dia
    } finally {
      _flushing = false;
    }
  }
}

final syncServiceProvider =
    NotifierProvider<SyncService, int>(SyncService.new);

/// Todas as vendas na fila (pendentes + falhas) para a tela de Sincronização.
final outboxEntriesProvider = FutureProvider.autoDispose<List<OutboxEntry>>(
    (ref) => OutboxDao(LocalStore.instance).all());

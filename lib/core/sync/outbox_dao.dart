import 'dart:convert';
import '../local/local_store.dart';

/// Uma venda pendente de sincronização (gravada offline).
class OutboxEntry {
  final int id;
  final String clientUuid;
  final int salePointId;
  final Map<String, dynamic> payload;

  OutboxEntry({
    required this.id,
    required this.clientUuid,
    required this.salePointId,
    required this.payload,
  });

  factory OutboxEntry.fromRow(Map<String, Object?> r) => OutboxEntry(
        id: r['id'] as int,
        clientUuid: r['client_uuid'] as String,
        salePointId: r['sale_point_id'] as int,
        payload: jsonDecode(r['payload'] as String) as Map<String, dynamic>,
      );
}

/// Fila de escrita offline: vendas que aguardam reenvio quando a rede voltar.
/// O `client_uuid` (UNIQUE) garante idempotência no servidor.
class OutboxDao {
  final LocalStore _store;
  OutboxDao(this._store);

  Future<void> enqueue({
    required String clientUuid,
    required int salePointId,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _store.database;
    await db.insert('outbox', {
      'client_uuid': clientUuid,
      'sale_point_id': salePointId,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'status': 'pending',
    });
  }

  Future<List<OutboxEntry>> pending() async {
    final db = await _store.database;
    final rows = await db.query('outbox', orderBy: 'id ASC');
    return rows.map(OutboxEntry.fromRow).toList();
  }

  Future<int> count() async {
    final db = await _store.database;
    final r =
        await db.rawQuery('SELECT COUNT(*) AS c FROM outbox');
    return (r.first['c'] as int?) ?? 0;
  }

  /// Sucesso no reenvio → remove da fila.
  Future<void> remove(int id) async {
    final db = await _store.database;
    await db.delete('outbox', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markFailed(int id, String error) async {
    final db = await _store.database;
    await db.update('outbox', {'status': 'failed', 'error': error},
        where: 'id = ?', whereArgs: [id]);
  }
}

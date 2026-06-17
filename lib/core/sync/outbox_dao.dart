import 'dart:convert';
import '../local/local_store.dart';

/// Uma venda na fila de sincronização (gravada offline).
class OutboxEntry {
  final int id;
  final String clientUuid;
  final int salePointId;
  final Map<String, dynamic> payload;
  final String status; // pending | failed
  final String? error;
  final DateTime? createdAt;

  OutboxEntry({
    required this.id,
    required this.clientUuid,
    required this.salePointId,
    required this.payload,
    required this.status,
    this.error,
    this.createdAt,
  });

  bool get isFailed => status == 'failed';

  /// Itens da venda (para resumir na tela): [{product_id, amount|kg|liters}].
  List get items => (payload['items'] as List?) ?? const [];
  String? get paymentMethod => payload['payment_method'] as String?;

  factory OutboxEntry.fromRow(Map<String, Object?> r) => OutboxEntry(
        id: r['id'] as int,
        clientUuid: r['client_uuid'] as String,
        salePointId: r['sale_point_id'] as int,
        payload: jsonDecode(r['payload'] as String) as Map<String, dynamic>,
        status: r['status'] as String? ?? 'pending',
        error: r['error'] as String?,
        createdAt: r['created_at'] != null
            ? DateTime.tryParse(r['created_at'] as String)
            : null,
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

  /// Só as PENDENTES (status 'pending'). As 'failed' (rejeitadas pelo servidor,
  /// ex.: 409) ficam estacionadas — não são reenviadas em loop nem contam no
  /// banner; uma tela de falhas (Fase 4) cuida delas depois.
  Future<List<OutboxEntry>> pending() async {
    final db = await _store.database;
    final rows = await db.query('outbox',
        where: "status = 'pending'", orderBy: 'id ASC');
    return rows.map(OutboxEntry.fromRow).toList();
  }

  Future<int> count() async {
    final db = await _store.database;
    final r = await db.rawQuery(
        "SELECT COUNT(*) AS c FROM outbox WHERE status = 'pending'");
    return (r.first['c'] as int?) ?? 0;
  }

  /// Todas as entradas (pendentes + falhas), mais recentes primeiro — para a
  /// tela de Sincronização.
  Future<List<OutboxEntry>> all() async {
    final db = await _store.database;
    final rows = await db.query('outbox', orderBy: 'id DESC');
    return rows.map(OutboxEntry.fromRow).toList();
  }

  /// Recoloca uma entrada falha de volta na fila (status 'pending') para nova
  /// tentativa manual.
  Future<void> retry(int id) async {
    final db = await _store.database;
    await db.update('outbox', {'status': 'pending', 'error': null},
        where: 'id = ?', whereArgs: [id]);
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

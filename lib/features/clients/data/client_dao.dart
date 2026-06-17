import '../../../core/local/local_store.dart';
import '../domain/client.dart';

/// Cache local de clientes (offline-first, P4). Colunas espelham o JSON do
/// backend, então a leitura reusa `Client.fromJson`.
class ClientDao {
  final LocalStore _store;
  ClientDao(this._store);

  Future<List<Client>> getAll() async {
    final db = await _store.database;
    final rows = await db.query('clients', orderBy: 'name COLLATE NOCASE');
    return rows
        .map((r) => Client.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Substitui o cache pelo snapshot do servidor.
  Future<void> replaceAll(List<Client> clients) async {
    final db = await _store.database;
    await db.transaction((txn) async {
      await txn.delete('clients');
      final batch = txn.batch();
      for (final c in clients) {
        batch.insert('clients', _toRow(c));
      }
      await batch.commit(noResult: true);
    });
  }

  Map<String, Object?> _toRow(Client c) => {
        'id': c.id,
        'name': c.name,
        'phone': c.phone,
        'email': c.email,
        'notes': c.notes,
        'sale_point_id': c.salePointId,
        'updated_at': DateTime.now().toIso8601String(),
      };
}

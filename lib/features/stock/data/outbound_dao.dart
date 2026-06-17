import '../../../core/local/local_store.dart';
import '../domain/outbound.dart';

/// Cache local das retiradas (estoque) por ponto de venda (offline-first, P4).
/// `status` é guardado como INTEGER no SQLite e convertido para bool na leitura.
class OutboundDao {
  final LocalStore _store;
  OutboundDao(this._store);

  Future<List<Outbound>> getBySalePoint(int salePointId) async {
    final db = await _store.database;
    final rows = await db.query('outbounds',
        where: 'sale_point_id = ?', whereArgs: [salePointId], orderBy: 'data DESC');
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m['status'] = (r['status'] as int?) == 1; // INTEGER → bool
      return Outbound.fromJson(m);
    }).toList();
  }

  /// Substitui o cache das retiradas DESTE ponto pelo snapshot do servidor.
  Future<void> replaceForSalePoint(
      int salePointId, List<Outbound> items) async {
    final db = await _store.database;
    await db.transaction((txn) async {
      await txn
          .delete('outbounds', where: 'sale_point_id = ?', whereArgs: [salePointId]);
      final batch = txn.batch();
      for (final o in items) {
        batch.insert('outbounds', _toRow(o, salePointId));
      }
      await batch.commit(noResult: true);
    });
  }

  Map<String, Object?> _toRow(Outbound o, int salePointId) => {
        'id': o.id,
        'sale_point_id': salePointId,
        'product_id': o.productId,
        'name': o.name,
        'status': o.status ? 1 : 0,
        'data': o.date?.toIso8601String(),
        'unidade': o.unidade,
        'taken_quantity': o.takenQuantity,
        'sold_quantity': o.soldQuantity,
        'remaining_quantity': o.remainingQuantity,
        'total_value': o.totalValue,
        'observacao': o.observation,
        'updated_at': DateTime.now().toIso8601String(),
      };
}

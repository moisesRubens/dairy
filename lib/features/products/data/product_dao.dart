import '../../../core/local/local_store.dart';
import '../domain/product.dart';

/// Cache local do catálogo de produtos (offline-first, P4). As colunas espelham
/// o JSON do backend (`image_url`, etc.), então a leitura reusa `Product.fromJson`.
class ProductDao {
  final LocalStore _store;
  ProductDao(this._store);

  Future<List<Product>> getAll() async {
    final db = await _store.database;
    final rows = await db.query('products', orderBy: 'name COLLATE NOCASE');
    return rows
        .map((r) => Product.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Substitui o catálogo pelo snapshot do servidor (o backend é a verdade).
  Future<void> replaceAll(List<Product> products) async {
    final db = await _store.database;
    await db.transaction((txn) async {
      await txn.delete('products');
      final batch = txn.batch();
      for (final p in products) {
        batch.insert('products', _toRow(p));
      }
      await batch.commit(noResult: true);
    });
  }

  Map<String, Object?> _toRow(Product p) => {
        'id': p.id,
        'name': p.name,
        'price': p.price,
        'amount': p.amount,
        'kg': p.kg,
        'liters': p.liters,
        'image_url': p.imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };
}

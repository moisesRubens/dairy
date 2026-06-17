import 'package:sqflite/sqflite.dart';
import '../domain/product.dart';
import 'db.dart';

class ProductDao {
  // ============================================================
  // Inserir ou atualizar produto
  // ============================================================
  Future<int> insertProduct(Product product) async {
    final db = await DB.instance.database;
    
    final Map<String, dynamic> map = {
      'produtoId': product.id,
      'name': product.name,
      'price': product.price,
      'amount': product.amount,
      'kg': product.kg,
      'liters': product.liters,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final existing = await db.query(
      'produtos',
      where: 'produtoId = ?',
      whereArgs: [product.id],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'produtos',
        map,
        where: 'produtoId = ?',
        whereArgs: [product.id],
      );
      print('🔄 Produto "${product.name}" atualizado!');
      return existing.first['id'] as int;
    } else {
      final id = await db.insert('produtos', map);
      print('✅ Produto "${product.name}" inserido!');
      return id;
    }
  }

  // ============================================================
  // Inserir múltiplos produtos
  // ============================================================
  Future<void> insertProducts(List<Product> products) async {
    for (var product in products) {
      await insertProduct(product);
    }
    print('📦 ${products.length} produtos salvos no banco');
  }

  // ============================================================
  // Buscar todos os produtos
  // ============================================================
  Future<List<Product>> getAllProducts() async {
    final db = await DB.instance.database;
    
    final List<Map<String, dynamic>> results = await db.query(
      'produtos',
      orderBy: 'name ASC',
    );

    return results.map((map) => Product(
      id: map['produtoId'] as int?,
      name: map['name'] as String,
      price: map['price'] as double?,
      amount: map['amount'] as int?,
      kg: map['kg'] as double?,
      liters: map['liters'] as double?,
    )).toList();
  }

  // ============================================================
  // Buscar produto por ID do backend
  // ============================================================
  Future<Product?> getProductById(int produtoId) async {
    final db = await DB.instance.database;
    
    final List<Map<String, dynamic>> results = await db.query(
      'produtos',
      where: 'produtoId = ?',
      whereArgs: [produtoId],
    );

    if (results.isEmpty) return null;

    final map = results.first;
    return Product(
      id: map['produtoId'] as int?,
      name: map['name'] as String,
      price: map['price'] as double?,
      amount: map['amount'] as int?,
      kg: map['kg'] as double?,
      liters: map['liters'] as double?,
    );
  }

  // ============================================================
  // Buscar produto por nome (pesquisa)
  // ============================================================
  Future<List<Product>> searchProducts(String query) async {
    final db = await DB.instance.database;
    
    final List<Map<String, dynamic>> results = await db.query(
      'produtos',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );

    return results.map((map) => Product(
      id: map['produtoId'] as int?,
      name: map['name'] as String,
      price: map['price'] as double?,
      amount: map['amount'] as int?,
      kg: map['kg'] as double?,
      liters: map['liters'] as double?,
    )).toList();
  }

  // ============================================================
  // Atualizar quantidade de um produto
  // ============================================================
  Future<bool> updateQuantity(int produtoId, int newAmount) async {
    try {
      final db = await DB.instance.database;
      await db.update(
        'produtos',
        {
          'amount': newAmount,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'produtoId = ?',
        whereArgs: [produtoId],
      );
      print('📦 Produto ID $produtoId atualizado para $newAmount');
      return true;
    } catch (e) {
      print('❌ Erro ao atualizar quantidade: $e');
      return false;
    }
  }

  // ============================================================
  // Deletar um produto
  // ============================================================
  Future<bool> deleteProduct(int produtoId) async {
    try {
      final db = await DB.instance.database;
      await db.delete(
        'produtos',
        where: 'produtoId = ?',
        whereArgs: [produtoId],
      );
      print('🗑️ Produto ID $produtoId deletado');
      return true;
    } catch (e) {
      print('❌ Erro ao deletar: $e');
      return false;
    }
  }

  // ============================================================
  // Limpar todos os produtos
  // ============================================================
  Future<void> deleteAll() async {
    final db = await DB.instance.database;
    await db.delete('produtos');
    print('🗑️ Todos os produtos removidos!');
  }

  // ============================================================
  // Contar produtos
  // ============================================================
  Future<int> countProducts() async {
    final db = await DB.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM produtos');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ============================================================
  // Verificar se produto existe
  // ============================================================
  Future<bool> productExists(int produtoId) async {
    final db = await DB.instance.database;
    final result = await db.query(
      'produtos',
      where: 'produtoId = ?',
      whereArgs: [produtoId],
    );
    return result.isNotEmpty;
  }
}
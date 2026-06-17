import 'package:sqflite/sqflite.dart';
import '../domain/product.dart';
import 'db.dart';

class ProductDao {

  Future<int> insertProduct(Product product) async {
    final db = await DB.instance.database;
    
    final Map<String, dynamic> map = {
      'produtoId': product.id,
      'name': product.name,
      'price': product.price,
      'amount': product.amount ?? -1,  // Garantir que não seja null
      'kg': product.kg ?? -1,          // Garantir que não seja null
      'liters': product.liters ?? -1,  // Garantir que não seja null
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final existing = await db.query(
      'produtos',  // Mantém o nome da tabela consistente
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
      amount: map['amount'] as int? ?? -1,  // Valor padrão se null
      kg: map['kg'] as double? ?? -1,       // Valor padrão se null
      liters: map['liters'] as double? ?? -1, // Valor padrão se null
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
      amount: map['amount'] as int? ?? -1,
      kg: map['kg'] as double? ?? -1,
      liters: map['liters'] as double? ?? -1,
    );
  }

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
      amount: map['amount'] as int? ?? -1,
      kg: map['kg'] as double? ?? -1,
      liters: map['liters'] as double? ?? -1,
    )).toList();
  }

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
      print('📦 Produto ID $produtoId atualizado para $newAmount un');
      return true;
    } catch (e) {
      print('❌ Erro ao atualizar quantidade: $e');
      return false;
    }
  }

  Future<bool> updateKg(int produtoId, double newKg) async {
    try {
      final db = await DB.instance.database;
      await db.update(
        'produtos',  
        {
          'kg': newKg,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'produtoId = ?',  
        whereArgs: [produtoId],
      );
      print('📦 Produto ID $produtoId atualizado para $newKg kg');
      return true;
    } catch (e) {
      print('❌ Erro ao atualizar kg: $e');
      return false;
    }
  }

  Future<bool> updateLiters(int produtoId, double newLiters) async {
    try {
      final db = await DB.instance.database;
      await db.update(
        'produtos',  // CORRIGIDO: era 'products'
        {
          'liters': newLiters,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'produtoId = ?',  // CORRIGIDO: era 'id = ?'
        whereArgs: [produtoId],
      );
      print('📦 Produto ID $produtoId atualizado para $newLiters L');
      return true;
    } catch (e) {
      print('❌ Erro ao atualizar litros: $e');
      return false;
    }
  }

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

  Future<void> deleteAll() async {
    final db = await DB.instance.database;
    await db.delete('produtos');
    print('🗑️ Todos os produtos removidos!');
  }

  Future<int> countProducts() async {
    final db = await DB.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM produtos');
    return Sqflite.firstIntValue(result) ?? 0;
  }

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
import 'package:sqflite/sqflite.dart';
import '../domain/product.dart';
import 'db.dart';
import 'database_provider.dart';

class ProductDao {
  final DatabaseProvider _database = DatabaseProvider();

  Future<List<Product>> getAllProducts2 () async {
    Database db = await _database.db;

    List<Map<String, dynamic>> maps = await db.rawQuery("select * from products"); 
    List<Product> productsList = [];

    for (Map<String, dynamic> m in maps) {
      productsList.add(Product.fromMap(m));
    }
    return productsList;
  }

  Future<int> addProduct(Product product) async {
    Database db = await _database.db;

    return await db.insert("products", product.toMap());
  } 

  Future<void> addProductsList(List<Product> products) async {
    Database db = await _database.db;

    for (Product p in products) {
      await db.insert("products", p.toMap());
    } 
  }

  Future<int> insertProduct(Product product) async {
    final db = await DB.instance.database;

    final Map<String, dynamic> map = {
      'produtoId': product.id,  // ← id do backend
      'name': product.name,
      'price': product.price,
      'amount': product.amount ?? 0,
      'kg': product.kg ?? 0.0,
      'liters': product.liters ?? 0.0,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    // Verifica se já existe pelo produtoId (id do backend)
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
      print('✅ Produto "${product.name}" inserido! (ID SQLite: $id)');
      return id;
    }
  }

  // ============================================================
  // INSERIR MÚLTIPLOS PRODUTOS
  // ============================================================
  Future<void> insertProducts(List<Product> products) async {
    for (var product in products) {
      await insertProduct(product);
    }
    print('📦 ${products.length} produtos salvos no banco');
  }

  // ============================================================
  // BUSCAR TODOS OS PRODUTOS
  // ============================================================
  Future<List<Product>> getAllProducts() async {
    final db = await DB.instance.database;
    
    final List<Map<String, dynamic>> results = await db.query(
      'produtos',
      orderBy: 'name ASC',
    );

    return results.map((map) => Product(
      id: map['produtoId'] as int?,  // ← id do backend
      name: map['name'] as String,
      price: map['price'] as double?,
      amount: map['amount'] as int?,
      kg: map['kg'] as double?,
      liters: map['liters'] as double?,
    )).toList();
  }

  Future<Product?> getProductById(int id) async {
    Database db = await _database.db;
    List<Map<String, dynamic>> product_map = await db.query(
      "products",
      where: "id = ?",
      whereArgs: [id]
    );

    if(product_map.isEmpty) {
      return null;
    }
    Product product = Product.fromMap(product_map.first);
    return product;
  }
  
  Future<Product?> getProductByLocalId(int localId) async {
    final db = await DB.instance.database;
    
    final List<Map<String, dynamic>> results = await db.query(
      'produtos',
      where: 'id = ?',  
      whereArgs: [localId],
    );

    if (results.isEmpty) return null;

    final map = results.first;
    return Product(
      id: map['produtoId'] as int?,  // ← id do backend
      name: map['name'] as String,
      price: map['price'] as double?,
      amount: map['amount'] as int?,
      kg: map['kg'] as double?,
      liters: map['liters'] as double?,
    );
  }

  // ============================================================
  // BUSCAR PRODUTO POR ID DO BACKEND
  // ============================================================
  Future<Product?> getProductByBackendId(int backendId) async {
    final db = await DB.instance.database;
    
    final List<Map<String, dynamic>> results = await db.query(
      'produtos',
      where: 'produtoId = ?',  // ← id do backend
      whereArgs: [backendId],
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
  // BUSCAR PRODUTOS POR NOME
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
  // 🔥 ATUALIZAR PRODUTO COMPLETO (USADO PELO ORDER SERVICE)
  // ============================================================
  Future<void> updateProduct(Product product) async {
    try {
      final db = await DB.instance.database;

      final updates = <String, dynamic>{
        'name': product.name,
        'price': product.price,
        'amount': product.amount ?? 0,
        'kg': product.kg ?? 0.0,
        'liters': product.liters ?? 0.0,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // 🔥 ATUALIZA PELO ID DO SQLITE
      // Precisamos encontrar o ID local do SQLite primeiro
      final existing = await db.query(
        'produtos',
        where: 'produtoId = ?',
        whereArgs: [product.id],
      );

      if (existing.isNotEmpty) {
        final localId = existing.first['id'] as int;
        await db.update(
          'produtos',
          updates,
          where: 'id = ?',
          whereArgs: [localId],
        );
        print('✅ Produto "${product.name}" (ID Backend: ${product.id}) atualizado');
      } else {
        print('⚠️ Produto "${product.name}" não encontrado no banco local');
      }
    } catch (e) {
      print('❌ Erro ao atualizar produto: $e');
      rethrow;
    }
  }

  // ============================================================
  // DELETAR PRODUTO
  // ============================================================
  Future<bool> deleteProduct(int backendId) async {
    try {
      final db = await DB.instance.database;
      await db.delete(
        'produtos',
        where: 'produtoId = ?',
        whereArgs: [backendId],
      );
      print('🗑️ Produto ID $backendId deletado');
      return true;
    } catch (e) {
      print('❌ Erro ao deletar: $e');
      return false;
    }
  }

  // ============================================================
  // DELETAR TODOS
  // ============================================================
  Future<void> deleteAll() async {
    final db = await DB.instance.database;
    await db.delete('produtos');
    print('🗑️ Todos os produtos removidos!');
  }

  // ============================================================
  // CONTAR PRODUTOS
  // ============================================================
  Future<int> countProducts() async {
    final db = await DB.instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM produtos');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ============================================================
  // VERIFICAR SE PRODUTO EXISTE
  // ============================================================
  Future<bool> productExists(int backendId) async {
    final db = await DB.instance.database;
    final result = await db.query(
      'produtos',
      where: 'produtoId = ?',
      whereArgs: [backendId],
    );
    return result.isNotEmpty;
  }

  // ============================================================
// ATUALIZAR QUANTIDADE (unidades)
// ============================================================
Future<bool> updateQuantity(int backendId, int newAmount) async {
  try {
    final db = await DB.instance.database;
    
    // Primeiro encontra o ID local pelo backendId
    final existing = await db.query(
      'produtos',
      where: 'produtoId = ?',
      whereArgs: [backendId],
    );

    if (existing.isEmpty) {
      print('⚠️ Produto ID $backendId não encontrado');
      return false;
    }

    final localId = existing.first['id'] as int;
    
    await db.update(
      'produtos',
      {
        'amount': newAmount,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
    print('📦 Produto ID $backendId atualizado para $newAmount un');
    return true;
  } catch (e) {
    print('❌ Erro ao atualizar quantidade: $e');
    return false;
  }
}

// ============================================================
// ATUALIZAR KG
// ============================================================
Future<bool> updateKg(int backendId, double newKg) async {
  try {
    final db = await DB.instance.database;
    
    final existing = await db.query(
      'produtos',
      where: 'produtoId = ?',
      whereArgs: [backendId],
    );

    if (existing.isEmpty) {
      print('⚠️ Produto ID $backendId não encontrado');
      return false;
    }

    final localId = existing.first['id'] as int;
    
    await db.update(
      'produtos',
      {
        'kg': newKg,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
    print('📦 Produto ID $backendId atualizado para $newKg kg');
    return true;
  } catch (e) {
    print('❌ Erro ao atualizar kg: $e');
    return false;
  }
}

// ============================================================
// ATUALIZAR LITROS
// ============================================================
Future<bool> updateLiters(int backendId, double newLiters) async {
  try {
    final db = await DB.instance.database;
    
    final existing = await db.query(
      'produtos',
      where: 'produtoId = ?',
      whereArgs: [backendId],
    );

    if (existing.isEmpty) {
      print('⚠️ Produto ID $backendId não encontrado');
      return false;
    }

    final localId = existing.first['id'] as int;
    
    await db.update(
      'produtos',
      {
        'liters': newLiters,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
    print('📦 Produto ID $backendId atualizado para $newLiters L');
    return true;
  } catch (e) {
    print('❌ Erro ao atualizar litros: $e');
    return false;
  }
}
}
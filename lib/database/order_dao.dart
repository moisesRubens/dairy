import 'package:dairy/domain/product.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/order2.dart';
import '../domain/order_item.dart';
import 'database_provider.dart';

class OrderDao {
  final DatabaseProvider _db = DatabaseProvider();

  
  Future<void> saveOrder(Order order) async {
    final db = await _db.db;

    final existing = await db.query(
      'orders',
      where: 'order_date = ? AND description = ?',
      whereArgs: [order.dateTime, order.description],
    );

    int orderLocalId;

    if (existing.isNotEmpty) {
      orderLocalId = existing.first['id'] as int;
      await db.update(
        'orders',
        {
          'description': order.description,
          'status': 1,
          'total_value': order.totalValue,
          'order_date': order.dateTime,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [orderLocalId],
      );
      
      await db.delete(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderLocalId],
      );
    } else {
      orderLocalId = await db.insert('orders', {
        'description': order.description,
        'status': 1,
        'total_value': order.totalValue,
        'order_date': order.dateTime,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    for (var item in order.products) 
    {
      await db.insert('order_items', 
      {
        'order_id': orderLocalId,
        'product_id': item.productId,
        'product_name': item.name,  // 🔥 NOVO
        'item_price': item.price,      // 🔥 NOVO
        'amount': item.quantity,
        'kg': item.quantity,
        'liters': item.quantity,
      });
    }

    print('✅ Pedido salvo localmente com ${order.products.length} itens');
  }

  // ============================================================
  // 🔥 SALVAR MÚLTIPLOS PEDIDOS
  // ============================================================
  Future<void> saveOrders(List<Order> orders) async {
    for (var order in orders) {
      await saveOrder(order);
    }
    print('📦 ${orders.length} pedidos salvos localmente');
  }
  

  Future<List<Order>> getAllOrders() async 
  {
    final db = await _db.db;

    final results = await db.query(
      'orders',
      orderBy: 'order_date DESC',
    );

    final List<Order> orders = [];

    for (var map in results) 
    {
      final order = Order(
        description: map['description'] as String,
        status: Status.values[['status'] as int],
        totalValue: (map['total_value'] as num).toDouble(),
        dateTime: map['order_date'] as DateTime,
        products: [],
      );

      final itemsResults = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [map['id']],
      );

      order.setProducts(
        itemsResults.map((item) => Product.fromMap(item)).toList()
      );
      orders.add(order);
    }
    return orders;
  }

  // ============================================================
  // 🔥 BUSCAR PEDIDOS POR DATA
  // ============================================================
  Future<List<Order>> getOrdersByDate(String date) async {
    final db = await _db.db;

    final results = await db.query(
      'orders',
      where: 'order_date LIKE ?',
      whereArgs: ['$date%'],
      orderBy: 'order_date DESC',
    );

    final List<Order> orders = [];

    for (var map in results) 
    {
      final order = Order.fromMap(map);
      final itemsResults = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [map['id']],
      );

      order.setProducts(
        itemsResults.map((item) => Product.fromMap(item)).toList()
      );
      orders.add(order);
    }
    return orders;
  }
  
  
  Future<Order?> getOrderByDateAndDescription(String date, String description) async 
  {
    final db = await _db.db;

    final results = await db.query(
      'orders',
      where: 'order_date = ? AND description = ?',
      whereArgs: [date, description],
    );

    if (results.isEmpty) return null;

    final map = results.first;
    final order = Order(
      description: map['description'] as String,
      status: Status.values[(map['status'] as int)],
      totalValue: (map['total_value'] as num).toDouble(),
      dateTime: map['order_date'] as DateTime,
      products: [],
    );

    final itemsResults = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [map['id']],
    );

    order.setProducts(
      itemsResults.map((item) => Product.fromMap(item)).toList()
    );
    return order;
  }


  Future<void> deleteOrder(DateTime date, String? description) async 
  {
    final db = await _db.db;
    
    final results = await db.query(
      'orders',
      where: 'order_date = ? AND description = ?',
      whereArgs: [date, description],
    );

    if (results.isNotEmpty) {
      final orderId = results.first['id'] as int;
      
      await db.delete(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      
      await db.delete(
        'orders',
        where: 'id = ?',
        whereArgs: [orderId],
      );
      
      print('🗑️ Pedido deletado: $description - $date');
    }
  }

  // ============================================================
  // 🔥 DELETAR TODOS OS PEDIDOS
  // ============================================================
  Future<void> deleteAllOrders() async {
    final db = await _db.db;
    await db.delete('order_items');
    await db.delete('orders');
    print('🗑️ Todos os pedidos deletados');
  }

  // ============================================================
  // 🔥 CONTAR PEDIDOS
  // ============================================================
  Future<int> countOrders() async {
    final db = await _db.db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM orders');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ============================================================
  // 🔥 CALCULAR FATURAMENTO TOTAL
  // ============================================================
  Future<double> getTotalRevenue() async {
    final db = await _db.db;
    final result = await db.rawQuery('SELECT SUM(total_value) as total FROM orders WHERE status = 1');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
  

  Future<double> getRevenueByDate(String date) async {
    final db = await _db.db;
  
    final List<Map<String, dynamic>> result = await db.query(
      'orders',
      columns: ['total_value'],
      where: 'status = 1 AND order_date LIKE ?',
      whereArgs: ['$date%'],
    );
      
    double total = 0.0;
    for (var row in result) {
      total += (row['total_value'] as num).toDouble();
    }
    return total;
  }
}
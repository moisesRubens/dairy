import 'package:sqflite/sqflite.dart';
import '../domain/order.dart';
import '../domain/order_item.dart';
import 'db.dart';

class OrderDao {
  final DB _db = DB.instance;

  
  Future<void> saveOrder(Order order) async {
    final db = await _db.database;

    final existing = await db.query(
      'orders',
      where: 'order_date = ? AND description = ?',
      whereArgs: [order.orderDate, order.description],
    );

    int orderLocalId;

    if (existing.isNotEmpty) {
      orderLocalId = existing.first['id'] as int;
      await db.update(
        'orders',
        {
          'description': order.description,
          'status': order.status ? 1 : 0,
          'total_value': order.totalValue,
          'order_date': order.orderDate,
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
        'status': order.status ? 1 : 0,
        'total_value': order.totalValue,
        'order_date': order.orderDate,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // 🔥 SALVA OS ITENS COM OS NOVOS CAMPOS
    for (var item in order.items) {
      await db.insert('order_items', {
        'order_id': orderLocalId,
        'product_id': item.productId,
        'product_name': item.productName,  // 🔥 NOVO
        'item_price': item.itemPrice,      // 🔥 NOVO
        'amount': item.amount,
        'kg': item.kg,
        'liters': item.liters,
      });
    }

    print('✅ Pedido salvo localmente com ${order.items.length} itens');
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

  // ============================================================
  // 🔥 BUSCAR TODOS OS PEDIDOS
  // ============================================================
  Future<List<Order>> getAllOrders() async {
    final db = await _db.database;

    final results = await db.query(
      'orders',
      orderBy: 'order_date DESC',
    );

    final List<Order> orders = [];

    for (var map in results) {
      final order = Order(
        description: map['description'] as String,
        status: (map['status'] as int) == 1,
        totalValue: (map['total_value'] as num).toDouble(),
        orderDate: map['order_date'] as String,
        items: [],
      );

      final itemsResults = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [map['id']],
      );

      // 🔥 RECUPERA OS ITENS COM OS NOVOS CAMPOS
      order.items = itemsResults.map((itemMap) => OrderItem(
        productId: itemMap['product_id'] as int,
        productName: itemMap['product_name'] as String? ?? 'Produto ${itemMap['product_id']}',  // 🔥 NOVO
        itemPrice: (itemMap['item_price'] as num?)?.toDouble() ?? 0.0,  // 🔥 NOVO
        amount: itemMap['amount'] as int,
        kg: (itemMap['kg'] as num).toDouble(),
        liters: (itemMap['liters'] as num).toDouble(),
      )).toList();

      orders.add(order);
    }

    return orders;
  }

  // ============================================================
  // 🔥 BUSCAR PEDIDOS POR DATA
  // ============================================================
  Future<List<Order>> getOrdersByDate(String date) async {
    final db = await _db.database;

    final results = await db.query(
      'orders',
      where: 'order_date LIKE ?',
      whereArgs: ['$date%'],
      orderBy: 'order_date DESC',
    );

    final List<Order> orders = [];

    for (var map in results) {
      final order = Order(
        description: map['description'] as String,
        status: (map['status'] as int) == 1,
        totalValue: (map['total_value'] as num).toDouble(),
        orderDate: map['order_date'] as String,
        items: [],
      );

      final itemsResults = await db.query(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [map['id']],
      );

      // 🔥 RECUPERA OS ITENS COM OS NOVOS CAMPOS
      order.items = itemsResults.map((itemMap) => OrderItem(
        productId: itemMap['product_id'] as int,
        productName: itemMap['product_name'] as String? ?? 'Produto ${itemMap['product_id']}',
        itemPrice: (itemMap['item_price'] as num?)?.toDouble() ?? 0.0,
        amount: itemMap['amount'] as int,
        kg: (itemMap['kg'] as num).toDouble(),
        liters: (itemMap['liters'] as num).toDouble(),
      )).toList();

      orders.add(order);
    }

    return orders;
  }

  // ============================================================
  // 🔥 BUSCAR PEDIDO POR DATA E DESCRIÇÃO
  // ============================================================
  Future<Order?> getOrderByDateAndDescription(String date, String description) async {
    final db = await _db.database;

    final results = await db.query(
      'orders',
      where: 'order_date = ? AND description = ?',
      whereArgs: [date, description],
    );

    if (results.isEmpty) return null;

    final map = results.first;
    final order = Order(
      description: map['description'] as String,
      status: (map['status'] as int) == 1,
      totalValue: (map['total_value'] as num).toDouble(),
      orderDate: map['order_date'] as String,
      items: [],
    );

    final itemsResults = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [map['id']],
    );

    // 🔥 RECUPERA OS ITENS COM OS NOVOS CAMPOS
    order.items = itemsResults.map((itemMap) => OrderItem(
      productId: itemMap['product_id'] as int,
      productName: itemMap['product_name'] as String? ?? 'Produto ${itemMap['product_id']}',
      itemPrice: (itemMap['item_price'] as num?)?.toDouble() ?? 0.0,
      amount: itemMap['amount'] as int,
      kg: (itemMap['kg'] as num).toDouble(),
      liters: (itemMap['liters'] as num).toDouble(),
    )).toList();

    return order;
  }

  // ============================================================
  // 🔥 DELETAR PEDIDO
  // ============================================================
  Future<void> deleteOrder(String date, String description) async {
    final db = await _db.database;
    
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
    final db = await _db.database;
    await db.delete('order_items');
    await db.delete('orders');
    print('🗑️ Todos os pedidos deletados');
  }

  // ============================================================
  // 🔥 CONTAR PEDIDOS
  // ============================================================
  Future<int> countOrders() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM orders');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ============================================================
  // 🔥 CALCULAR FATURAMENTO TOTAL
  // ============================================================
  Future<double> getTotalRevenue() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT SUM(total_value) as total FROM orders WHERE status = 1');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
  

  Future<double> getRevenueByDate(String date) async {
    final db = await _db.database;
  
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
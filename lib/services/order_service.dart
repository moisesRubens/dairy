import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../domain/product.dart';
import '../database/product_dao.dart';
import '../database/order_dao.dart';
import '../domain/order.dart';
import '../domain/order_item.dart';

class OrderService {
  
  final ProductDao _productDao = ProductDao();
  final OrderDao _orderDao = OrderDao();  

  Future<bool> createOrder({
    required List<Product> products,
    String description = '',
    double totalValue = 0,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final salePointId = prefs.getInt('sale_point_id');

      if (token == null || salePointId == null) {
        debugPrint('❌ Token ou sale_point_id não encontrado');
        return false;
      }

      // productId é o ID do produto no backend.
      final items = products.map((product) {
        final Map<String, dynamic> item = {
          'product_id': product.productId,
          'quantity': 0.0
        };
        return item;
      }).toList();

      final calculatedTotal = totalValue > 0 
          ? totalValue 
          : products.fold(0.0, (sum, product) => sum + (product.price ?? 0));
       
      final orderData = {
        'description': description.isNotEmpty ? description : 'Pedido ${DateTime.now().toIso8601String()}',
        'status': true,
        'total_value': calculatedTotal,
        'order_date': DateTime.now().toIso8601String().split('T')[0],
        'items': items,
      };

      debugPrint('📦 Enviando pedido: ${jsonEncode(orderData)}');

      final url = Uri.parse('${ApiConfig.baseUrl}/auth/$salePointId/order');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(orderData),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao criar pedido');
        },
      );

      debugPrint('📡 Status: ${response.statusCode}');
      debugPrint('📡 Resposta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 🔥 ATUALIZA O ESTOQUE LOCAL
        await _updateLocalStock(products);
        
        // 🔥 SALVA O PEDIDO LOCALMENTE
        await _saveOrderLocally(products, description, calculatedTotal);
        
        return true;
      } else {
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ Erro no OrderService.createOrder: $e');
      return false;
    }
  }

  Future<void> _saveOrderLocally(List<Product> products, String description, double totalValue) async {
  try {
    final orderItems = products.map((product) 
    {
      Map<String, dynamic> map = product.toJson();
      return OrderItem(
        productId: product.productId ?? 0,
        productName: product.name ?? "",
        itemPrice: product.price ?? 0.0,
        amount: map['amount'] ?? 0,
        kg: map['kg'] ?? 0.0,
        liters: map['liters'] ?? 0.0,
      );
    }).toList();

    final order = Order(
      description: description.isNotEmpty ? description : 'Pedido ${DateTime.now().toIso8601String()}',
      status: true,
      totalValue: totalValue,
      orderDate: DateTime.now().toIso8601String(),
      items: orderItems,
    );

    await _orderDao.saveOrder(order);
    debugPrint('✅ Pedido salvo localmente com ${order.items.length} itens');
  } catch (e) {
    debugPrint('❌ Erro ao salvar pedido localmente: $e');
  }
}

  // ============================================================
  // ATUALIZA O ESTOQUE LOCAL
  // ============================================================
  Future<void> _updateLocalStock(List<Product> soldProducts) async {
    try {
      for (Product soldProduct in soldProducts) {
        final currentProduct = await _productDao.getProduct2(
          productId: soldProduct.productId,
        );
        
        if (currentProduct != null) 
        {
          double toSub = soldProduct.quantity ?? 0;
          currentProduct.setQuantity(currentProduct.quantity! - toSub);
          await _productDao.updateQuantity2(currentProduct);
        } 
        else 
        {
          debugPrint(
            '⚠️ Produto ID ${soldProduct.productId} não encontrado no banco local',
          );
        }
      }
      
      debugPrint('✅ Estoque local atualizado com sucesso!');
    } 
    catch (e) 
    {
      debugPrint('❌ Erro ao atualizar estoque local: $e');
      rethrow;
    }
  }

  // ============================================================
  // 🔥 BUSCAR PEDIDOS DO BANCO LOCAL
  // ============================================================
  Future<List<Order>> getLocalOrders() async {
    try {
      return await _orderDao.getAllOrders();
    } catch (e) {
      debugPrint('❌ Erro ao buscar pedidos locais: $e');
      return [];
    }
  }

  // ============================================================
  // 🔥 BUSCAR PEDIDOS POR DATA
  // ============================================================
  Future<List<Order>> getLocalOrdersByDate(String date) async {
    try {
      return await _orderDao.getOrdersByDate(date);
    } catch (e) {
      debugPrint('❌ Erro ao buscar pedidos por data: $e');
      return [];
    }
  }

  // ============================================================
  // 🔥 CALCULAR FATURAMENTO TOTAL
  // ============================================================
  Future<double> getTotalRevenue() async {
    try {
      return await _orderDao.getTotalRevenue();
    } catch (e) {
      debugPrint('❌ Erro ao calcular faturamento: $e');
      return 0.0;
    }
  }
  

  Future<double> getTodayRevenue() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      return await _orderDao.getRevenueByDate(today);
    } catch (e) {
      debugPrint('❌ Erro ao calcular faturamento do dia: $e');
      return 0.0;
    }
  }
}

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
  final OrderDao _orderDao = OrderDao();  // 🔥 ADICIONADO

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

      // 🔥 Usa product.id (que é o ID do backend)
      final items = products.map((product) {
        final Map<String, dynamic> item = {
          'product_id': product.id ?? 0,
          'amount': 0,
          'kg': 0.0,
          'liters': 0.0,
        };

        if (product.amount != null && product.amount != -1) {
          item['amount'] = product.amount;
        } else if (product.kg != null && product.kg != -1) {
          item['kg'] = product.kg;
        } else if (product.liters != null && product.liters != -1) {
          item['liters'] = product.liters;
        }

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
    final orderItems = products.map((product) {
      // Determina qual campo de quantidade foi preenchido
      int? amount = product.amount != null && product.amount != -1 ? product.amount : null;
      double? kg = product.kg != null && product.kg != -1 ? product.kg : null;
      double? liters = product.liters != null && product.liters != -1 ? product.liters : null;

      // Se todos forem null, usa 0 como fallback (mas não deve acontecer)
      return OrderItem(
        productId: product.id ?? 0,
        productName: product.name,
        itemPrice: product.price ?? 0.0,
        amount: amount ?? 0,
        kg: kg ?? 0.0,
        liters: liters ?? 0.0,
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
      for (var soldProduct in soldProducts) {
        // 🔥 Busca pelo ID do backend (product.id)
        final currentProduct = await _productDao.getProductByBackendId(soldProduct.id!);
        
        if (currentProduct != null) {
          final updatedProduct = Product(
            id: currentProduct.id,  // Mantém o ID do backend
            name: currentProduct.name,
            price: currentProduct.price,
            // Subtrai as quantidades
            amount: currentProduct.amount != null && soldProduct.amount != null
                ? currentProduct.amount! - soldProduct.amount!
                : currentProduct.amount,
            kg: currentProduct.kg != null && soldProduct.kg != null
                ? currentProduct.kg! - soldProduct.kg!
                : currentProduct.kg,
            liters: currentProduct.liters != null && soldProduct.liters != null
                ? currentProduct.liters! - soldProduct.liters!
                : currentProduct.liters,
          );

          await _productDao.updateProduct(updatedProduct);
          
          debugPrint('📦 Estoque atualizado: ${currentProduct.name} '
              '(amount: ${updatedProduct.amount}, kg: ${updatedProduct.kg}, liters: ${updatedProduct.liters})');
        } else {
          debugPrint('⚠️ Produto ID ${soldProduct.id} não encontrado no banco local');
        }
      }
      
      debugPrint('✅ Estoque local atualizado com sucesso!');
    } catch (e) {
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
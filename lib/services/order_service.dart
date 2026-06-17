import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../domain/product.dart';
import '../database/product_dao.dart';

class OrderService {
  
  final ProductDao _productDao = ProductDao();

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

        if (product.amount != -1) {
          item['amount'] = product.amount;
        } else if (product.kg != -1) {
          item['kg'] = product.kg;
        } else if (product.liters != -1) {
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
        await _updateLocalStock(products);
        return true;
      } else {
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ Erro no OrderService.createOrder: $e');
      return false;
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
}
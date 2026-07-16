import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/product.dart';
import '../domain/outbound.dart';
import '../config/api_config.dart';
import '../database/product_dao.dart';
import '../services/outbound_service.dart';
import '../services/order_service.dart';
import '../domain/order.dart';

class SalePointController {
  final ProductDao _productDao = ProductDao();
  final OrderService _orderService = OrderService();
  final OutboundService _outboundService = OutboundService();
  
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  Future<void> loadAllOutbounds() async {
    try {
      isLoading.value = true;
      await _outboundService.loadAllOutbounds();
    } catch (e) {
      errorMessage.value = 'Erro ao carregar outbounds: $e';
      debugPrint('❌ Erro em loadAllOutbounds: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // 🔥 CARREGAR OUTBOUNDS POR DATA
  // ============================================================
  Future<void> loadOutboundsByDate(String date) async {
    try {
      isLoading.value = true;
      await _outboundService.loadOutboundsByDate(date);
    } catch (e) {
      errorMessage.value = 'Erro ao carregar outbounds: $e';
      debugPrint('❌ Erro em loadOutboundsByDate: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // 🔥 MÉTODO ESTÁTICO PARA RECARREGAR (BOTTOM NAVIGATION)
  // ============================================================
  static Future<void> refreshOutbounds() async {
    await OutboundService.refreshOutbounds();
  }

  Future<bool> retornarProdutosAoEstoque() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final salePointId = prefs.getInt('sale_point_id'); 

    if (token == null || salePointId == null) {
      debugPrint("❌ Token ou sale_point_id não encontrado");
      return false;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/auth/$salePointId/outbounds');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await _productDao.deleteAllProducts2();
        OutboundService.saleProductsNotifier.value = [];
        return true;
      } else {
        debugPrint("❌ Erro na API: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Erro de conexão ao retornar produtos ao estoque: $e");
      return false;
    } 
  }
  
  Future<bool> fazerVenda(
    List<Product> products, {
    String description = '',
    double totalValue = 0,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      if (products.isEmpty) {
        errorMessage.value = 'Nenhum produto selecionado';
        return false;
      }

      final invalidProducts = products.where((p) { 
        print("PRODUTO DA VENDA: ${p}");
        return p.productId == null;
      });

      if (invalidProducts.isNotEmpty) {
        errorMessage.value = 'Alguns produtos não têm ID válido';
        return false;
      }

      final success = await _orderService.createOrder(
        products: products,
        description: description,
        totalValue: totalValue,
      );

      if (success) {
        debugPrint('✅ Venda realizada com sucesso!');
        return true;
      } else {
        errorMessage.value = 'Erro ao criar pedido. Tente novamente.';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Erro ao fazer venda: $e';
      debugPrint('❌ Erro em fazerVenda: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // 🔥 BUSCAR FATURAMENTO DO DIA
  // ============================================================
  Future<double> getTodayRevenue() async {
    try {
      return await _orderService.getTodayRevenue();
    } catch (e) {
      debugPrint('❌ Erro ao buscar faturamento do dia: $e');
      return 0.0;
    }
  }

  // ============================================================
  // 🔥 BUSCAR FATURAMENTO TOTAL
  // ============================================================
  Future<double> getTotalRevenue() async {
    try {
      return await _orderService.getTotalRevenue();
    } catch (e) {
      debugPrint('❌ Erro ao buscar faturamento total: $e');
      return 0.0;
    }
  }

  // ============================================================
  // 🔥 BUSCAR TODOS OS PEDIDOS LOCAIS
  // ============================================================
  Future<List<Order>> getLocalOrders() async {
    try {
      return await _orderService.getLocalOrders();
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
      return await _orderService.getLocalOrdersByDate(date);
    } catch (e) {
      debugPrint('❌ Erro ao buscar pedidos por data: $e');
      return [];
    }
  }

  // ============================================================
  // 🔥 LIMPAR RECURSOS
  // ============================================================
  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
  }
}

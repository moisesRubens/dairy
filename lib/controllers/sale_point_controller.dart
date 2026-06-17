import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/product.dart';
import '../config/api_config.dart';
import '../database/product_dao.dart';
import '../services/outbound_service.dart';
import '../services/order_service.dart';

class SalePointController {
  final ProductDao _productDao = ProductDao();
  final OrderService _orderService = OrderService();

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  // 🔥 RETORNAR PRODUTOS AO ESTOQUE
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
        await _productDao.deleteAll();
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

  // 🔥 FAZER VENDA
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

      // Verifica se todos os produtos têm ID
      final invalidProducts = products.where((p) => p.id == null);
      if (invalidProducts.isNotEmpty) {
        errorMessage.value = 'Alguns produtos não têm ID válido';
        return false;
      }

      debugPrint('🛒 Iniciando venda de ${products.length} produtos...');

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

  // 🔥 LIMPAR RECURSOS
  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
  }
}
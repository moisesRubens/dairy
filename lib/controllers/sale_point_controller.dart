import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/product.dart'; // IMPORTANTE: Importe seu model aqui
import '../config/api_config.dart';
import '../database/product_dao.dart';
import '../services/outbound_service.dart';

class SalePointController {
  final ProductDao _productDao = ProductDao();

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
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _productDao.deleteAll();
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
}
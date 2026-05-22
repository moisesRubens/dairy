import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dairy/domain/product.dart';
import 'package:flutter/material.dart';


class OutboundService {
  static const String baseUrl = "http://127.0.0.1:8000";
  static ValueNotifier<List<Product>> saleProductsNotifier = ValueNotifier<List<Product>>([]);
  static List<Product> get saleProducts => saleProductsNotifier.value;


  Future<bool> createOutbound(Map<Product, int> outboundsQuantity, {String? observacao}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final salePointId = prefs.getInt('sale_point_id'); 

    final url = Uri.parse('$baseUrl/auth/$salePointId/outbounds');

    final List<Map<String, dynamic>> produtosJson = outboundsQuantity.entries.map((entry) {
      Product product = entry.key;
      String unit; 
      
      if (product.amount != null) {
        unit = "amount"; 
      } else if (product.kg != null) {
        unit = "kg";
      } else {
        unit = "liters"; 
      }

      return {
        "product_id": product.id,
        "quantidade": entry.value,
        "unidade": unit, 
      };
    }).toList();

    final Map<String, dynamic> requestBody = {
      "produtos": produtosJson,
      "observacao": observacao ?? "", 
    };

    try {
      // 3. Executa o POST enviando os cabeçalhos de autenticação e o body codificado
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final currentProducts = saleProductsNotifier.value;
        final newProducts = outboundsQuantity.keys.toList();
        final allProducts = {...currentProducts, ...newProducts}.toList();
        
        final uniqueProductsMap = {for (var p in allProducts) p.id: p};

        for (var entry in outboundsQuantity.entries) {
          Product produtoEnviado = entry.key;
          double quantidadeSomar = entry.value.toDouble();
          
          if (!uniqueProductsMap.containsKey(produtoEnviado.id)) {
            uniqueProductsMap[produtoEnviado.id] = produtoEnviado;
          }
          
          final p = uniqueProductsMap[produtoEnviado.id]!;
          
          if (p.amount != null) {
            p.amount = (p.amount ?? 0) + quantidadeSomar.toInt();
          } else if (p.kg != null) {
            p.kg = (p.kg ?? 0) + quantidadeSomar;
          } else if (p.liters != null) {
            p.liters = (p.liters ?? 0) + quantidadeSomar;
          }
          print(p);
        }
        saleProductsNotifier.value = uniqueProductsMap.values.toList();
        return true;
      } else {
        print("Erro na API: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Erro de conexão ao criar saída: $e");
      return false;
    }
  }
}
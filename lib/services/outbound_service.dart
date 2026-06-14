import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dairy/domain/product.dart';
import 'package:dairy/config/api_config.dart';
import 'package:flutter/material.dart';


class OutboundService {
  static ValueNotifier<List<Product>> saleProductsNotifier = ValueNotifier<List<Product>>([]);
  static List<Product> get saleProducts => saleProductsNotifier.value;


  Future<bool> createOutbound(Map<Product, int> outboundsQuantity, {String? observacao}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final salePointId = prefs.getInt('sale_point_id'); 

    final url = Uri.parse('${ApiConfig.baseUrl}/auth/$salePointId/outbounds');

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
        final currentList = List<Product>.from(saleProductsNotifier.value);

        outboundsQuantity.forEach((product, quantity) {
          final existingIndex = currentList.indexWhere((p) => p.id == product.id);
          
          if (existingIndex != -1) {
            // Se já existe na Home, apenas soma a quantidade
            final p = currentList[existingIndex];
            if (p.amount != null) p.amount = (p.amount ?? 0) + quantity;
            else if (p.kg != null) p.kg = (p.kg ?? 0) + quantity.toDouble();
            else if (p.liters != null) p.liters = (p.liters ?? 0) + quantity.toDouble();
          } else {
            // Se é novo, adiciona uma cópia com a quantidade inicial
            currentList.add(Product(
              id: product.id,
              name: product.name,
              price: product.price,
              amount: product.amount != null ? quantity : null,
              kg: product.kg != null ? quantity.toDouble() : null,
              liters: product.liters != null ? quantity.toDouble() : null,
            ));
          }
        });

        saleProductsNotifier.value = currentList;
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
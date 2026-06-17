import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dairy/domain/product.dart';
import 'package:dairy/config/api_config.dart';
import 'package:flutter/material.dart';
import '../database/product_dao.dart';

class OutboundService {
  static ValueNotifier<List<Product>> saleProductsNotifier = ValueNotifier<List<Product>>([]);
  static List<Product> get saleProducts => saleProductsNotifier.value;

  // 🆕 Método para carregar produtos do banco (apenas retiradas)
  static Future<void> loadProductsFromLocal() async {
    try {
      final dao = ProductDao();
      final products = await dao.getAllProducts();
      saleProductsNotifier.value = products;
      
      // ✅ CORRIGIDO: Mostra todos os produtos com suas quantidades
      print('📊 ${products.length} produtos carregados do banco (retiradas):');
      for (var p in products) {
        // Mostra a quantidade correta dependendo do tipo
        if (p.amount != null) {
          print('   - ${p.name}: amount=${p.amount} un');
        } else if (p.kg != null) {
          print('   - ${p.name}: kg=${p.kg}');
        } else if (p.liters != null) {
          print('   - ${p.name}: liters=${p.liters}');
        } else {
          print('   - ${p.name}: SEM QUANTIDADE');
        }
      }
    } catch (e) {
      print('❌ Erro ao carregar produtos do banco: $e');
      saleProductsNotifier.value = [];
    }
  }

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
        // 1. Atualiza o notifier (memória)
        final currentList = List<Product>.from(saleProductsNotifier.value);

        outboundsQuantity.forEach((product, quantity) {
          final existingIndex = currentList.indexWhere((p) => p.id == product.id);
          
          if (existingIndex != -1) {
            // Se já existe, soma a quantidade
            final p = currentList[existingIndex];
            if (p.amount != null) {
              p.amount = (p.amount ?? 0) + quantity;
            } else if (p.kg != null) {
              p.kg = (p.kg ?? 0) + quantity.toDouble();
            } else if (p.liters != null) {
              p.liters = (p.liters ?? 0) + quantity.toDouble();
            }
          } else {
            // Se é novo, adiciona
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

        // 🆕 2. SALVA NO BANCO LOCAL (somente as retiradas)
        await _saveOutboundToLocal(outboundsQuantity);

        return true;
      } else {
        debugPrint("Erro na API: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Erro de conexão ao criar saída: $e");
      return false;
    }
  }

  // 🆕 MÉTODO: Salvar retirada no banco local
  static Future<void> _saveOutboundToLocal(Map<Product, int> outboundsQuantity) async {
    try {
      final dao = ProductDao();
      
      print('📝 SALVANDO RETIRADA NO BANCO:');
      
      for (var entry in outboundsQuantity.entries) {
        final product = entry.key;
        final quantity = entry.value;

        print('   📦 ${product.name}: retirada de $quantity');

        // Verifica se o produto já existe no banco (retirada anterior)
        final existing = await dao.getProductById(product.id!);
        
        if (existing != null) {
          // Se já existe, soma a quantidade
          final newAmount = (existing.amount ?? 0) + quantity;
          await dao.updateQuantity(product.id!, newAmount);
          print('   🔄 "${product.name}" atualizado: ${existing.amount} → $newAmount');
        } else {
          // Se não existe, insere novo
          final productWithAmount = Product(
            id: product.id,
            name: product.name,
            price: product.price,
            amount: quantity,  // ← USA A QUANTIDADE DA RETIRADA
            kg: product.kg,
            liters: product.liters,
          );
          await dao.insertProduct(productWithAmount);
          print('   ✅ "${product.name}" inserido com amount=$quantity');
        }
      }
      
      // 🔥 VERIFICA SE SALVOU CORRETAMENTE
      final allProducts = await dao.getAllProducts();
      print('📊 BANCO APÓS SALVAR: ${allProducts.length} produtos:');
      for (var p in allProducts) {
        print('   - ${p.name}: amount=${p.amount}');
      }
      
    } catch (e) {
      print('❌ Erro ao salvar retirada no banco: $e');
    }
  }

  // 🆕 MÉTODO: Limpar histórico de retiradas
  static Future<void> clearLocalHistory() async {
    try {
      final dao = ProductDao();
      await dao.deleteAll();
      saleProductsNotifier.value = [];
      print('🗑️ Histórico de retiradas limpo');
    } catch (e) {
      print('❌ Erro ao limpar histórico: $e');
    }
  }
}
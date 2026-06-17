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

  static Future<void> loadProductsFromLocal() async {
    try {
      final dao = ProductDao();
      final products = await dao.getAllProducts();
      saleProductsNotifier.value = products;
      
      print('📊 ${products.length} produtos carregados do banco (retiradas):');
      for (var p in products) {
        if (p.amount != null && p.amount != -1) {
          print('   - ${p.name}: amount=${p.amount} un');
        } else if (p.kg != null && p.kg != -1) {
          print('   - ${p.name}: kg=${p.kg}');
        } else if (p.liters != null && p.liters != -1) {
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

  Future<bool> createOutbound(Map<Product, double> outboundsQuantity, {String? observacao}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final salePointId = prefs.getInt('sale_point_id'); 

    if (token == null || salePointId == null) {
      debugPrint("❌ Token ou sale_point_id não encontrado");
      return false;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/auth/$salePointId/outbounds');

    final List<Map<String, dynamic>> produtosJson = outboundsQuantity.entries.map((entry) {
      Product product = entry.key;
      String unit; 
      
      if (product.amount != -1) {
        unit = "amount"; 
      } else if (product.kg != -1) {
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
            if (p.amount != -1) {
              p.amount = (p.amount ?? 0) + quantity.toInt();
            } else if (p.kg != -1) {
              // 🔥 CORRIGIDO: Mantém como double
              p.kg = (p.kg ?? 0.0) + quantity;
            } else if (p.liters != -1) {
              // 🔥 CORRIGIDO: Mantém como double
              p.liters = (p.liters ?? 0.0) + quantity;
            }
          } else {
            // Se é novo, adiciona
            final newProduct = Product(
              id: product.id,
              name: product.name,
              price: product.price,
              amount: product.amount != -1 ? quantity.toInt() : -1,
              kg: product.kg != -1 ? quantity : -1,  // ← Mantém como double
              liters: product.liters != -1 ? quantity : -1,  // ← Mantém como double
            );
            currentList.add(newProduct);
          }
        });

        saleProductsNotifier.value = currentList;

        // 2. SALVA NO BANCO LOCAL
        await _saveOutboundToLocal(outboundsQuantity);

        return true;
      } else {
        debugPrint("❌ Erro na API: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Erro de conexão ao criar saída: $e");
      return false;
    }
  }

  static Future<void> _saveOutboundToLocal(Map<Product, double> outboundsQuantity) async {
    try {
      final dao = ProductDao();
      
      print('📝 SALVANDO RETIRADA NO BANCO:');
      
      for (var entry in outboundsQuantity.entries) {
        final product = entry.key;
        final double quantity = entry.value;

        print('   📦 ${product.name}: retirada de $quantity');

        final existing = await dao.getProductById(product.id!);
        
        if (existing != null) {
          // Se já existe, soma a quantidade
          if (product.amount != -1) {
            final newAmount = (existing.amount ?? 0) + quantity.toInt();
            await dao.updateQuantity(product.id!, newAmount);
            print('   🔄 "${product.name}" atualizado: ${existing.amount} → $newAmount un');
          } else if (product.kg != -1) {
            // 🔥 CORRIGIDO: Mantém como double
            final newKg = (existing.kg ?? 0.0) + quantity;
            await dao.updateKg(product.id!, newKg);
            print('   🔄 "${product.name}" atualizado: ${existing.kg} → $newKg kg');
          } else if (product.liters != -1) {
            // 🔥 CORRIGIDO: Mantém como double
            final newLiters = (existing.liters ?? 0.0) + quantity;
            await dao.updateLiters(product.id!, newLiters);
            print('   🔄 "${product.name}" atualizado: ${existing.liters} → $newLiters L');
          }
        } else {
          // Se não existe, insere novo
          if (product.amount != -1) {
            final productWithAmount = Product(
              id: product.id,
              name: product.name,
              price: product.price,
              amount: quantity.toInt(),
              kg: -1,
              liters: -1,
            );
            await dao.insertProduct(productWithAmount);
            print('   ✅ "${product.name}" inserido com amount=${quantity.toInt()} un');
          } else if (product.kg != -1) {
            // 🔥 CORRIGIDO: Mantém como double
            final productWithKg = Product(
              id: product.id,
              name: product.name,
              price: product.price,
              amount: -1,
              kg: quantity,  // ← Mantém como double
              liters: -1,
            );
            await dao.insertProduct(productWithKg);
            print('   ✅ "${product.name}" inserido com kg=$quantity');
          } else if (product.liters != -1) {
            // 🔥 CORRIGIDO: Mantém como double
            final productWithLiters = Product(
              id: product.id,
              name: product.name,
              price: product.price,
              amount: -1,
              kg: -1,
              liters: quantity,  // ← Mantém como double
            );
            await dao.insertProduct(productWithLiters);
            print('   ✅ "${product.name}" inserido com liters=$quantity');
          }
        }
      }
      
      // Verifica se salvou corretamente
      final allProducts = await dao.getAllProducts();
      print('📊 BANCO APÓS SALVAR: ${allProducts.length} produtos:');
      for (var p in allProducts) {
        if (p.amount != -1) {
          print('   - ${p.name}: amount=${p.amount} un');
        } else if (p.kg != -1) {
          print('   - ${p.name}: kg=${p.kg}');  // ← Deve mostrar decimal
        } else if (p.liters != -1) {
          print('   - ${p.name}: liters=${p.liters}');  // ← Deve mostrar decimal
        }
      }
      
    } catch (e) {
      print('❌ Erro ao salvar retirada no banco: $e');
      throw e;
    }
  }

  // MÉTODO: Limpar histórico de retiradas
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
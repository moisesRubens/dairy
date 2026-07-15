import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dairy/domain/product.dart';
import 'package:dairy/config/api_config.dart';
import 'package:flutter/material.dart';
import '../database/product_dao.dart';
import '../domain/outbound.dart';

class OutboundService {
  static ValueNotifier<List<Product>> saleProductsNotifier = ValueNotifier<List<Product>>([]);
  static List<Product> get saleProducts => saleProductsNotifier.value;

  // 🔥 NOTIFIER PARA TODOS OS PONTOS DE VENDA
  static ValueNotifier<List<Map<String, dynamic>>> allSalePointsNotifier = 
      ValueNotifier<List<Map<String, dynamic>>>([]);
  
  // 🔥 NOTIFIER PARA O PONTO SELECIONADO (atual)
  static ValueNotifier<List<Outbound>> outboundsNotifier = ValueNotifier<List<Outbound>>([]);
  static ValueNotifier<String> salePointName = ValueNotifier<String>('Ponto de Venda');
  static ValueNotifier<double> totalSold = ValueNotifier<double>(0.0);
  static ValueNotifier<int> totalItems = ValueNotifier<int>(0);

  
  void _processOutboundsResponse(List<dynamic> data) {
    final List<Map<String, dynamic>> allPoints = [];
    
    for (var item in data) {
      final name = item['sale_point_name'] ?? 'Ponto de Venda';
      final outboundsJson = item['outbounds'] ?? [];
      
      // 🔥 CONVERTE CADA ITEM PARA OUTBOUND
      final List<Outbound> outboundList = [];
      for (var json in outboundsJson) {
        outboundList.add(Outbound.fromMap(json));
      }
      
      // 🔥 CALCULA O TOTAL E A PORCENTAGEM GERAL
      double totalValue = 0.0;
      double totalTaken = 0.0;
      double totalSold = 0.0;
      
      for (var outbound in outboundList) {
        totalValue += outbound.totalValue;
        totalTaken += outbound.takenQuantity;
        totalSold += outbound.soldQuantity;
      }
      
      // 🔥 PORCENTAGEM GERAL DE VENDAS
      double overallPercentage = 0.0;
      if (totalTaken > 0) {
        overallPercentage = (totalSold / totalTaken) * 100;
      }
      
      allPoints.add({
        'name': name,
        'outbounds': outboundList,
        'totalValue': totalValue,
        'totalItems': outboundList.length,
        'totalTaken': totalTaken,
        'totalSold': totalSold,
        'overallPercentage': overallPercentage,
      });
    }
    
    allSalePointsNotifier.value = allPoints;
    
    if (allPoints.isNotEmpty) {
      final firstPoint = allPoints[0];
      salePointName.value = firstPoint['name'] as String;
      outboundsNotifier.value = firstPoint['outbounds'] as List<Outbound>;
      _calculateTotals(outboundsNotifier.value);
    } else {
      outboundsNotifier.value = [];
      salePointName.value = 'Nenhum ponto de venda';
      totalSold.value = 0.0;
      totalItems.value = 0;
    }
  }

  // ============================================================
  // 🔥 CARREGAR TODOS OS OUTBOUNDS DO DIA
  // ============================================================
  Future<void> loadAllOutbounds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        debugPrint("❌ Token não encontrado");
        return;
      }

      // Data atual
      final dateParam = DateTime.now().toIso8601String().split('T')[0];

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/outbounds/?date=$dateParam'
      );

      debugPrint('🌐 Buscando outbounds: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao buscar outbounds');
        },
      );

      debugPrint('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _processOutboundsResponse(data);
        debugPrint('📋 ${allSalePointsNotifier.value.length} pontos de venda carregados');
      } else {
        debugPrint('❌ Erro ao buscar outbounds: ${response.statusCode} - ${response.body}');
        allSalePointsNotifier.value = [];
        outboundsNotifier.value = [];
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar outbounds: $e');
      allSalePointsNotifier.value = [];
      outboundsNotifier.value = [];
    }
  }

  // ============================================================
  // 🔥 CARREGAR OUTBOUNDS POR DATA ESPECÍFICA
  // ============================================================
  Future<void> loadOutboundsByDate(String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        debugPrint("❌ Token não encontrado");
        return;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/outbounds/?date=$date'
      );

      debugPrint('🌐 Buscando outbounds por data: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _processOutboundsResponse(data);
        debugPrint('📋 ${allSalePointsNotifier.value.length} pontos de venda carregados para data: $date');
      } else {
        debugPrint('❌ Erro ao buscar outbounds: ${response.statusCode}');
        allSalePointsNotifier.value = [];
        outboundsNotifier.value = [];
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar outbounds por data: $e');
      allSalePointsNotifier.value = [];
      outboundsNotifier.value = [];
    }
  }

  // ============================================================
  // 🔥 SELECIONAR UM PONTO DE VENDA ESPECÍFICO
  // ============================================================
  static void selectSalePoint(int index) {
    final allPoints = allSalePointsNotifier.value;
    if (index >= 0 && index < allPoints.length) {
      final point = allPoints[index];
      salePointName.value = point['name'] as String;
      // 🔥 CORRIGIDO: Não faz cast
      outboundsNotifier.value = point['outbounds'];
      _calculateTotals(outboundsNotifier.value);
    }
  }

  // ============================================================
  // 🔥 CALCULAR TOTAIS
  // ============================================================
  static void _calculateTotals(List<Outbound> items) {
    double total = 0.0;
    for (var item in items) {
      total += item.totalValue;
    }
    totalSold.value = total;
    totalItems.value = items.length;
  }

  // ============================================================
  // 🔥 MÉTODO ESTÁTICO PARA RECARREGAR (BOTTOM NAVIGATION)
  // ============================================================
  static Future<void> refreshOutbounds() async {
    try {
      final service = OutboundService();
      await service.loadAllOutbounds();
    } catch (e) {
      debugPrint('❌ Erro ao recarregar outbounds: $e');
    }
  }

  // ============================================================
  // 🔥 CARREGAR PRODUTOS DO BANCO LOCAL
  // ============================================================
  static Future<void> loadProductsFromLocal() async {
    try {
      final dao = ProductDao();
      final products = await dao.getAllProducts2();
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

  // ============================================================
  // 🔥 CRIAR OUTBOUND (RETIRADA)
  // ============================================================
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
        "product_id": product.productId,
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
        final currentList = List<Product>.from(saleProductsNotifier.value);

        outboundsQuantity.forEach((product, quantity) {
          final int localProductId = (currentList.indexWhere((p) => p.productId == product.productId) != -1 ) ?(currentList.firstWhere((p) => p.productId == product.productId).id!) : -1;

          print("ID LOCAL DO PRODUTO: ${localProductId}");

          if (localProductId != -1) {
            /*É AQUI QUE TÁ TENDO A EXCESSÃO (ID DIFERENTE DO DB E DA CURRENT LIST)*/
            final p = currentList[localProductId];
            print("ID DO PRODUTO NA CURRENT LIST: ${p.id}");
            if (p.amount != -1) {
              p.amount = (p.amount ?? 0) + quantity.toInt();
            } else if (p.kg != -1) {
              p.kg = (p.kg ?? 0.0) + quantity;
            } else if (p.liters != -1) {
              p.liters = (p.liters ?? 0.0) + quantity;
            }
          } else {
            final newProduct = Product(
              id: product.id,
              name: product.name,
              price: product.price,
              amount: product.amount != -1 ? quantity.toInt() : -1,
              kg: product.kg != -1 ? quantity : -1,
              liters: product.liters != -1 ? quantity : -1,
            );
            currentList.add(newProduct);
          }
        });

        saleProductsNotifier.value = currentList;

        // 2. SALVA NO BANCO LOCAL
        await _saveOutboundToLocal(outboundsQuantity);

        // 3. RECARREGA OS OUTBOUNDS
        await loadAllOutbounds();

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

  // ============================================================
  // 🔥 SALVAR OUTBOUND NO BANCO LOCAL
  // ============================================================
  static Future<void> _saveOutboundToLocal(Map<Product, double> outboundsQuantity) async {
    try {
      final dao = ProductDao();
      
      print('📝 SALVANDO RETIRADA NO BANCO:');
      
      for (var entry in outboundsQuantity.entries) {
        final product = entry.key;
        final double quantity = entry.value;

        var existing = await dao.getProductById(product.productId!);
        if (existing != null) {

          if (product.amount != -1) {
            final newAmount = (existing.amount ?? 0) + quantity.toInt();
            await dao.updateQuantity(product.id!, newAmount);
          } else if (product.kg != -1) {
            final newKg = (existing.kg ?? 0.0) + quantity;
            await dao.updateKg(product.id!, newKg);
          } else if (product.liters != -1) {
            final newLiters = (existing.liters ?? 0.0) + quantity;
            await dao.updateLiters(product.id!, newLiters);
          }
        } else {
          if (product.amount != -1) {
            final productWithAmount = Product(
              productId: product.productId,
              name: product.name,
              price: product.price,
              amount: quantity.toInt(),
              kg: -1,
              liters: -1,
            );
            await dao.addProduct(productWithAmount);
          } else if (product.kg != -1) {
            final productWithKg = Product(
              productId: product.productId,
              name: product.name,
              price: product.price,
              amount: -1,
              kg: quantity,
              liters: -1,
            );
            await dao.addProduct(productWithKg);
          } else if (product.liters != -1) {
            final productWithLiters = Product(
              productId: product.productId,
              name: product.name,
              price: product.price,
              amount: -1,
              kg: -1,
              liters: quantity,
            );
            await dao.addProduct(productWithLiters);
          }
        }
      }
      
      final allProducts = await dao.getAllProducts();
      print('📊 BANCO APÓS SALVAR: ${allProducts.length} produtos:');
      for (var p in allProducts) {
        if (p.amount != -1) {
          print('   - ${p.name}: amount=${p.amount} un');
        } else if (p.kg != -1) {
          print('   - ${p.name}: kg=${p.kg}');
        } else if (p.liters != -1) {
          print('   - ${p.name}: liters=${p.liters}');
        }
      }
      
    } catch (e) {
      print('❌ Erro ao salvar retirada no banco: $e');
      throw e;
    }
  }

  // ============================================================
  // 🔥 LIMPAR HISTÓRICO
  // ============================================================
  static Future<void> clearLocalHistory() async {
    try {
      final dao = ProductDao();
      await dao.deleteAll();
      saleProductsNotifier.value = [];
      outboundsNotifier.value = [];
      allSalePointsNotifier.value = [];
      print('🗑️ Histórico de retiradas limpo');
    } catch (e) {
      print('❌ Erro ao limpar histórico: $e');
    }
  }
  
  
  static Future<void> refreshProducts() async {
    try {
      print("DENTRO DE REFRESH PRODUCTS");
      final dao = ProductDao();
      final products = await dao.getAllProducts2();
      saleProductsNotifier.value = products;
      print('🔄 Produtos recarregados do banco: ${products.length} itens');

      for (var p in products) {
        print(p);
      }
    } catch (e) {
      print('❌ Erro ao recarregar produtos: $e');
    }
  }

  // ============================================================
  // 🔥 RECARREGAR TODOS OS DADOS (PRODUTOS + OUTBOUNDS)
  // ============================================================
  static Future<void> refreshAll() async {
    try {
      await refreshProducts();
      await refreshOutbounds();
      print('🔄 Todos os dados recarregados');
    } catch (e) {
      print('❌ Erro ao recarregar todos os dados: $e');
    }
  }
}
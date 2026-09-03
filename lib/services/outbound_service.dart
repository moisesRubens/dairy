import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dairy/domain/product.dart';
import 'package:dairy/config/api_config.dart';
import 'package:flutter/material.dart';
import '../database/product_dao.dart';
import '../domain/outbound.dart';
import 'package:intl/intl.dart';

class OutboundService {
  final dao = ProductDao();
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

  Future<List<Product>?> loadOutboundsByDate(String? date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        debugPrint("❌ Token não encontrado");
        return null;
      }

      DateTime dateTime = (date != null) ? DateTime.parse(date!) : DateTime.now();
      String dateFormat = DateFormat("dd/MM/yyyy").format(dateTime);
      
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/outbounds/?date=$dateFormat'
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) 
      {
        final List<Map<String, dynamic>> data = jsonDecode(response.body);
        final List<Product> outbounds = data.map((d)
        {
          return Product.fromMap(d);
        }).toList();
        return outbounds;
      } 
      else 
      {
        debugPrint('❌ Erro ao buscar outbounds: ${response.statusCode}');
        return null;
      }
    } 
    catch (e) 
    {
      debugPrint('❌ Erro ao carregar outbounds por data: $e');
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
    } catch (e) {
      print('❌ Erro ao carregar produtos do banco: $e');
      saleProductsNotifier.value = [];
    }
  }
  
  Future<bool> createOutbound(List<Product>? products, double quantity, String? obs) async {
    if(products == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final salePointId = prefs.getInt('sale_point_id'); 

    if (token == null || salePointId == null) return false;
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/$salePointId/outbounds');

    final List<Map<String, dynamic>> produtosJson = products.map((entry) 
    {
      return entry.toJson(); 
    }).toList();

    final Map<String, dynamic> requestBody = 
    {
      "produtos": produtosJson,
      "observacao": obs ?? "", 
    };

    try 
    {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) 
      {
        for (final entry in products) 
        {
          final Product? localProduct = await dao.getProduct2(
            productId: entry.productId,
          );
          if (localProduct != null) {
            localProduct.setQuantity(quantity);
            await dao.updateQuantity2(localProduct);
          } 
          else 
          {
            await dao.addProduct(entry);
          }
        }

        await refreshProducts();
        await loadAllOutbounds();

        return true;
      } 
      else 
      {
        debugPrint("❌ Erro na API: ${response.statusCode} - ${response.body}");
        return false;
      }
    } 
    catch (e) 
    {
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
      
      for (var entry in outboundsQuantity.entries)
      {
        final product = entry.key;
        final double quantity = entry.value;

        Product? p = await dao.getProductById(product.productId!);
        if (p != null) 
        {
          p.setQuantity(quantity);
          dao.updateProduct(p);
        } 
        else 
        {
          product.setQuantity(quantity);
          await dao.addProduct(product);
        }
      }
    } 
    catch (e) 
    {
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

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
  static ValueNotifier<List<Product>> saleProductsNotifier =
      ValueNotifier<List<Product>>([]);
  static List<Product> get saleProducts => saleProductsNotifier.value;

  // 🔥 NOTIFIER PARA O PONTO SELECIONADO (atual)
  static ValueNotifier<List<Outbound>> outboundsNotifier =
      ValueNotifier<List<Outbound>>([]);
  static ValueNotifier<String> salePointName = ValueNotifier<String>(
    'Ponto de Venda',
  );
  static ValueNotifier<double> totalSold = ValueNotifier<double>(0.0);
  static ValueNotifier<int> totalItems = ValueNotifier<int>(0);

  void _processOutboundsResponse(
    List<dynamic> data,
    ValueNotifier<List<Map<String, dynamic>>> salesPoints,
  ) {
    final List<Map<String, dynamic>> allPoints = [];

    for (var item in data) {
      final name = item['sale_point_name'] ?? 'Ponto de Venda';
      final outboundsJson = item['outbounds'] ?? [];

      final List<Outbound> outboundList = [];
      for (var json in outboundsJson) {
        outboundList.add(Outbound.fromMap(json));
      }

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

    salesPoints.value = allPoints;

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

  Future<void> loadAllOutbounds(
    ValueNotifier<List<Map<String, dynamic>>> salesPoints,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        debugPrint("❌ Token não encontrado");
        return;
      }

      final dateParam = DateTime.now().toIso8601String().split('T')[0];

      final url = Uri.parse('${ApiConfig.baseUrl}/outbounds/?date=$dateParam');

      debugPrint('🌐 Buscando outbounds: $url');

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Timeout ao buscar outbounds');
            },
          );

      debugPrint('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _processOutboundsResponse(data, salesPoints);
      } else {
        debugPrint(
          '❌ Erro ao buscar outbounds: ${response.statusCode} - ${response.body}',
        );
        salesPoints.value = [];
        outboundsNotifier.value = [];
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar outbounds: $e');
      salesPoints.value = [];
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

      DateTime dateTime = (date != null)
          ? DateTime.parse(date!)
          : DateTime.now();
      String dateFormat = DateFormat("dd/MM/yyyy").format(dateTime);

      final url = Uri.parse('${ApiConfig.baseUrl}/outbounds/?date=$dateFormat');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> data = jsonDecode(response.body);
        final List<Product> outbounds = data.map((d) {
          return Product.fromMap(d);
        }).toList();
        return outbounds;
      } else {
        debugPrint('❌ Erro ao buscar outbounds: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar outbounds por data: $e');
    }
  }

  static void selectSalePoint(
    int index,
    ValueNotifier<List<Map<String, dynamic>>> salesPoints,
  ) {
    final allPoints = salesPoints.value;
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
  static Future<void> refreshOutbounds(
    ValueNotifier<List<Map<String, dynamic>>> salesPoints,
  ) async {
    try {
      final service = OutboundService();
      await service.loadAllOutbounds(salesPoints);
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

  Future<bool> createOutbound(
    //ValueNotifier<List<Product>> stockProducts,
    List<Product>? products,
    double quantity,
    String? obs,
  ) async {
    if (products == null) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final salePointId = prefs.getInt('sale_point_id');

    if (token == null || salePointId == null) {
      return false;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/auth/$salePointId/outbounds');
    print('🟡 [5] URL: $url');

    final List<Map<String, dynamic>> produtosJson = products.map((p) {
      p.quantity = quantity;
      return p.toJson();
    }).toList();

    print('🟡 [6] Payload: $produtosJson');

    final Map<String, dynamic> requestBody = {
      "produtos": produtosJson,
      "observacao": obs ?? "",
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

      print('🟡 [7] Status HTTP: ${response.statusCode}');
      print('🟡 [8] Body: ${response.body}');
      print("STATUS CODE DO RESPONSE: $response");
      return (response.statusCode == 201 || response.statusCode == 200);
    } catch (e) {
      print('🔴 [11] Exceção: $e');
      return false;
    }
  }

  // ============================================================
  // 🔥 SALVAR OUTBOUND NO BANCO LOCAL
  // ============================================================
  static Future<void> _saveOutboundToLocal(
    Map<Product, double> outboundsQuantity,
  ) async {
    try {
      final dao = ProductDao();

      print('📝 SALVANDO RETIRADA NO BANCO:');

      for (var entry in outboundsQuantity.entries) {
        final product = entry.key;
        final double quantity = entry.value;

        Product? p = await dao.getProductById(product.productId!);
        p?.quantity = quantity;
        if (p != null) {
          await dao.updateProduct(p);
        } else {
          await dao.addProduct(product);
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
  static Future<void> clearLocalHistory(
    ValueNotifier<List<Map<String, dynamic>>> salesPoints,
  ) async {
    try {
      final dao = ProductDao();
      await dao.deleteAll();
      saleProductsNotifier.value = [];
      outboundsNotifier.value = [];
      salesPoints.value = [];
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
  static Future<void> refreshAll(
    ValueNotifier<List<Map<String, dynamic>>> salesPoints,
  ) async {
    try {
      await refreshProducts();
      await refreshOutbounds(salesPoints);
      print('🔄 Todos os dados recarregados');
    } catch (e) {
      print('❌ Erro ao recarregar todos os dados: $e');
    }
  }
}

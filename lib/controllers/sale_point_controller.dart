import 'package:dairy/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Enums/product_enum.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/product.dart';
import '../domain/sale_point.dart';
import '../config/api_config.dart';
import '../database/product_dao.dart';
import '../services/outbound_service.dart';
import '../services/order_service.dart';
import '../domain/order.dart';

class SalePointController extends ChangeNotifier {
  final ProductDao _productDao = ProductDao();
  final OrderService _orderService = OrderService();
  final OutboundService _outboundService = OutboundService();
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  final AuthService _authService;
  bool _isAdmin = false;
  int? _salePointId;

  bool get isAdmin => _isAdmin;
  int? get salePointId => _salePointId;

  final ValueNotifier<List<Map<String, dynamic>>> _salesPoints =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  final ValueNotifier<List<Product>> _products = ValueNotifier<List<Product>>([]);

  SalePointController() : _authService = AuthService() {
    getSalePointId();
  }

  ValueNotifier<List<Map<String, dynamic>>> get salesPoints => _salesPoints;
  ValueNotifier<List<Product>> get products => _products;

  Future<bool> createOutbound(
    List<Product> productsToRetire,
    double quantity,
    String? obs,
  ) async {
    bool result = await _outboundService.createOutbound(
      productsToRetire,
      quantity,
      obs,
    );
    if (result) await loadOutboundsByDate();
    return result;
  }

  Future<void> getSalePointId() async {
    _salePointId = await _authService.getCurrentSalePointId();
    if (_salePointId != null) _admVerification(_salePointId!);
    notifyListeners();
  }

  Future<void> loadAllOutbounds() async {
    try {
      isLoading.value = true;
      await _outboundService.loadAllOutbounds(_salesPoints);
    } catch (e) {
      errorMessage.value = 'Erro ao carregar outbounds: $e';
      debugPrint('❌ Erro em loadAllOutbounds: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _admVerification(int salePointId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/${salePointId}');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final bool isAdmin = data['level'] == 1;

        debugPrint(
          '✅ SalePoint $salePointId é admin? $isAdmin (level: ${data['level']})',
        );
        _isAdmin = isAdmin;
      } else {
        debugPrint("❌ Erro ao verificar admin: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Erro na requisição de verificação de admin: $e");
    }
  }

  Future<void> loadOutboundsByDate([String? date]) async {
    print(" PRODUTOS DO SALE POINT: ${_products.value}");
    try {
      isLoading.value = true;
      List<Product>? list = await _outboundService.loadOutboundsByDate(date);
      if(list != null) _products.value = list;
    } catch (e) {
      errorMessage.value = 'Erro ao carregar outbounds: $e';
      debugPrint('❌ Erro em loadOutboundsByDate: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshOutbounds() async {
    await OutboundService.refreshOutbounds(_salesPoints);
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
  // 🔥 LIMPAR RECURSOS
  // ============================================================
  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
  }
}

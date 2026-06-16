import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dairy/domain/product.dart';
import 'package:dairy/config/api_config.dart';
import 'package:flutter/material.dart';

class SalePointController {
  static final SalePointController _instance = SalePointController._internal();
  factory SalePointController() => _instance;
  SalePointController._internal();

  // ValueNotifier para produtos disponíveis no sale point
  final ValueNotifier<List<Product>> productsNotifier = ValueNotifier<List<Product>>([]);
  
  // ValueNotifier para o carrinho de compras
  final ValueNotifier<List<CartItem>> cartNotifier = ValueNotifier<List<CartItem>>([]);

  // Getter para produtos
  List<Product> get products => productsNotifier.value;
  
  // Getter para carrinho
  List<CartItem> get cart => cartNotifier.value;

  Future<bool> fazerVenda({
    required Map<Product, double> outboundsQuantity,
    String? observacao,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final salePointId = prefs.getInt('sale_point_id');

      if (token == null || salePointId == null) {
        debugPrint("Erro: Token ou SalePointId não encontrados");
        return false;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/auth/$salePointId/outbounds');

      // Prepara os dados da requisição
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

      // Faz a requisição
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
        // Atualiza os produtos localmente
        _atualizarProdutosLocais(outboundsQuantity);
        
        // Limpa o carrinho após sucesso
        limparCarrinho();
        
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

  // Método para atualizar produtos localmente
  void _atualizarProdutosLocais(Map<Product, int> outboundsQuantity) {
    final currentList = List<Product>.from(productsNotifier.value);

    outboundsQuantity.forEach((product, quantity) {
      final existingIndex = currentList.indexWhere((p) => p.id == product.id);
      
      if (existingIndex != -1) {
        // Produto já existe, atualiza a quantidade
        final p = currentList[existingIndex];
        if (p.amount != null) {
          p.amount = (p.amount ?? 0) + quantity;
        } else if (p.kg != null) {
          p.kg = (p.kg ?? 0) + quantity.toDouble();
        } else if (p.liters != null) {
          p.liters = (p.liters ?? 0) + quantity.toDouble();
        }
      } else {
        // Produto novo, adiciona uma cópia
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

    productsNotifier.value = currentList;
  }

  // Métodos para gerenciar o carrinho
  void adicionarAoCarrinho(Product product, double quantidade) {
    if (quantidade <= 0) return;

    final currentCart = List<CartItem>.from(cartNotifier.value);
    final existingIndex = currentCart.indexWhere((item) => item.product.id == product.id);

    if (existingIndex != -1) {
      currentCart[existingIndex].quantidade += quantidade;
    } else {
      currentCart.add(CartItem(
        product: product,
        quantidade: quantidade,
      ));
    }

    cartNotifier.value = currentCart;
  }

  void removerDoCarrinho(String productName) {
    final currentCart = List<CartItem>.from(cartNotifier.value);
    currentCart.removeWhere((item) => item.product.name == productName);
    cartNotifier.value = currentCart;
  }

  void limparCarrinho() {
    cartNotifier.value = [];
  }

  double getValorTotalCarrinho() {
    return cartNotifier.value.fold(
      0.0, 
      (sum, item) => sum + (item.product.price ?? 0) * item.quantidade
    );
  }

  int getQuantidadeTotalItens() {
    return cartNotifier.value.length;
  }

  // Método para carregar produtos iniciais
  Future<void> carregarProdutos() async {
    // Implemente aqui a lógica para carregar os produtos do sale point
    // Por exemplo, fazendo uma requisição GET para buscar os produtos disponíveis
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final salePointId = prefs.getInt('sale_point_id');

      if (token == null || salePointId == null) return;

      final url = Uri.parse('${ApiConfig.baseUrl}/auth/$salePointId/products');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Product> products = data.map((json) => Product.fromJson(json)).toList();
        productsNotifier.value = products;
      }
    } catch (e) {
      debugPrint("Erro ao carregar produtos: $e");
    }
  }
}

// Modelo para itens do carrinho
class CartItem {
  final Product product;
  double quantidade;

  CartItem({
    required this.product,
    required this.quantidade,
  });

  String get unit {
    if (product.amount != null) return 'un';
    if (product.kg != null) return 'kg';
    return 'L';
  }

  double get valorTotal => (product.price ?? 0) * quantidade;

  Map<String, dynamic> toMap() {
    return {
      'name': product.name,
      'price': product.price ?? 0.0,
      'unit': unit,
      'quantity': quantidade,
    };
  }
}
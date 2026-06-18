import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/product.dart';
import '../config/api_config.dart';

class ProductService {
  Future<List<Product>> getProducts() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products');
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
        Iterable dynamicList = json.decode(response.body);
        List<Product> products = List<Product>.from(
          dynamicList.map((data) => Product.fromJson(data))
        );

        

        return products;
      } else {
        debugPrint("Erro ao buscar produtos: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Erro na requisição de produtos: $e");
      return [];
    }
  }

  Future<bool> isAdmin(int salePointId) async {
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
      
      // 🔥 AGORA VERIFICA O CAMPO 'level'
      final bool isAdmin = data['level'] == 1; // level == 1 significa admin
      
      debugPrint('✅ SalePoint $salePointId é admin? $isAdmin (level: ${data['level']})');
      return isAdmin;
    } else {
      debugPrint("❌ Erro ao verificar admin: ${response.statusCode}");
      return false;
    }
  } catch (e) {
    debugPrint("❌ Erro na requisição de verificação de admin: $e");
    return false;
  }
}

  Future<bool> createProduct(Product product) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  
  if (token == null) {
    print('❌ Token não encontrado');
    return false;
  }

  final url = Uri.parse('${ApiConfig.baseUrl}/products/');
  final List<Map<String, dynamic>> body = [
    {
      'name': product.name,
      'price': product.price,
      'amount': product.amount ?? -1,
      'kg': product.kg ?? -1,
      'liters': product.liters ?? -1,
    }
  ];

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print('📡 Status: ${response.statusCode}');
    print('📡 Resposta: ${response.body}');

    // 🔥 Sucesso é definido pelo status code, não pelo corpo
    if (response.statusCode == 201 || response.statusCode == 200) {
      // Opcional: tenta decodificar apenas se houver corpo e se for útil
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is List && decoded.isNotEmpty) {
            // Aqui você pode extrair o produto criado se quiser
            final newProduct = Product.fromJson(decoded.first);
            // Salvar localmente se desejar
          }
        } catch (_) {
          // Ignora erro de parse, pois o status já indica sucesso
        }
      }
      return true;
    } else {
      return false;
    }
  } catch (e) {
    print('❌ Exceção ao criar produto: $e');
    return false;
  }
}
}
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/product.dart';
import '../config/api_config.dart';

class ProductService {
  Future<List<Product>> getProducts() async {
    print("DENTRO DE PRODUCTS GETPRODUCTS API");

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
      print("FORA DO IF DE PRODUCTS REFRESHPRODUCTS");
      if (response.statusCode == 200) {
        print("DENTRO DO TRY DE PRODUCTS REFRESHPRODUCTS");
        List productsData = json.decode(response.body);
        print("PRODUTOS VEINDOS DA API: $productsData");
        return productsData.map((m) => Product.fromJson(m)).toList();
      } else {
        print("DENTRO DO ELSE DE PRODUCTS REFRESHPRODUCTS");
        debugPrint("Erro ao buscar produtos: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("DENTRO DO CACTCH DE PRODUCTS REFRESHPRODUCTS");
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

        debugPrint(
          '✅ SalePoint $salePointId é admin? $isAdmin (level: ${data['level']})',
        );
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

  Future<bool> createProduct(Product product) async 
  {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      print('❌ Token não encontrado');
      return false;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/products/');
    final List<Map<String, dynamic>> body = [product.toJson()];

    try 
    {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) 
      {
        return true;
      } 
      else 
      {
        debugPrint("NAO DEU A RESPOSTA CORRETA");
        return false;
      }
    } 
    catch (e) 
    {
      print('❌ Exceção ao criar produto: $e');
      return false;
    }
  }
}

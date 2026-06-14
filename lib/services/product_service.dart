import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/product.dart'; // IMPORTANTE: Importe seu model aqui
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
        // 1. O JSON bruto chega como uma lista dinâmica
        Iterable dynamicList = json.decode(response.body);
        
        // 2. Transformamos cada item dinâmico em um objeto Product real
        // usando o construtor .fromJson que criamos no model
        List<Product> products = List<Product>.from(
          dynamicList.map((data) => Product.fromJson(data))
        );
        return products;
      } else {
        print("Erro ao buscar produtos: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Erro na requisição de produtos: $e");
      return [];
    }
  }
}
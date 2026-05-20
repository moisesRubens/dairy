import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dairy/domain/product.dart';

class OutboundService {
  static const String baseUrl = "http://127.0.0.1:8000";

  /// Envia as retiradas de produtos para a API.
  /// [outboundsQuantity] chave: objeto Product, valor: quantidade retirada.
  Future<bool> createOutbound(Map<Product, int> outboundsQuantity, {String? observacao}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final salePointId = prefs.getInt('sale_point_id'); 

    // Monta a URL correta dinamicamente
    final url = Uri.parse('$baseUrl/auth/$salePointId/outbounds');

    // 1. Transforma o Map<Product, int> na lista de mapas que a API espera
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

    // 2. Monta o corpo final da requisição (Payload)
    final Map<String, dynamic> requestBody = {
      "produtos": produtosJson,
      "observacao": observacao ?? "", 
    };

    try {
      // 3. Executa o POST enviando os cabeçalhos de autenticação e o body codificado
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
        return true;
      } else {
        print("Erro na API: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Erro de conexão ao criar saída: $e");
      return false;
    }
  }
}
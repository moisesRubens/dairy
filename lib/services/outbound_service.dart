import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/product.dart'; // IMPORTANTE: Importe seu model aqui

class OutboundService {
  static const String baseUrl = "http://127.0.0.1:8000";

  Future<bool> createOutbound(List<int> productIds, double quantity) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final salePointId = prefs.getInt('sale_point_id'); 

    // URL: http://127.0.0.1:8000/auth/1/outbounds
    final url = Uri.parse('$baseUrl/auth/$salePointId/outbounds');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'product_ids': productIds,
        'quantity': quantity,
      }),
    );

    return response.statusCode == 201;
  }
}
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/sale_point.dart'; // Importe seu domain aqui

class AuthService {
  // Windows/macOS/Linux desktop e iOS Simulator: 127.0.0.1.
  // Emulador Android: trocar por 10.0.2.2. Device físico: IP da LAN do PC.
  static const String baseUrl = "http://127.0.0.1:8000";

  Future<SalePoint?> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // 1. Verifica se o token existe antes de continuar
        if (data.containsKey('access_token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', data['access_token']);

          // 2. Se a sua API NÃO retorna o campo 'user', você não pode chamá-lo.
          // Se quiser navegar para a home apenas com o token, retorne um objeto fictício ou ajuste a API.
          if (data['user'] != null) {
            return SalePoint.fromJson(data['user']);
          } else {
            // Retorna um SalePoint genérico apenas para validar o sucesso do login
            return SalePoint(id: 0, name: username); 
          }
        }
        return null;
      } else {
        // Se o status não for 200 (ex: 401 ou 400), o login falhou
        return null; 
      }
    } catch (e) {
      print("Erro na requisição: $e");
      return null;
    }
  }
}
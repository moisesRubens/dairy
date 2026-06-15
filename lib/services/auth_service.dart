import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/sale_point.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../config/api_config.dart';

class AuthService {
  static const String tokenKey = 'access_token';
  static const String salePointKey = 'sale_point_id';

  Future<SalePoint?> login(String username, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');

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
        
        if (data.containsKey('access_token')) {
          String token = data['access_token'];
          Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
          int userId = int.parse(decodedToken['sub']);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(tokenKey, token);
          await prefs.setInt(salePointKey, userId);

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
      debugPrint("Erro na requisição: $e");
      return null;
    }
  }

  /// Retorna true se há um token salvo e ainda não expirado.
  /// Usado para o auto-login (pular a tela de login se a sessão é válida).
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    if (token == null || token.isEmpty) return false;
    try {
      return !JwtDecoder.isExpired(token);
    } catch (_) {
      // Token malformado: trata como deslogado.
      return false;
    }
  }

  /// Encerra a sessão removendo o token e o id do ponto de venda do device.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(salePointKey);
  }
}
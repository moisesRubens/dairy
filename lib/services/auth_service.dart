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

          if (data['user'] != null) {
            return SalePoint.fromJson(data['user']);
          } else {
            return SalePoint(id: 0, name: username); 
          }
        }
        return null;
      } else {
        return null; 
      }
    } catch (e) {
      debugPrint("Erro na requisição: $e");
      return null;
    }
  }

  Future<int?> getCurrentSalePointId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(salePointKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    if (token == null || token.isEmpty) return false;
    try {
      return !JwtDecoder.isExpired(token);
    } catch (_) {
      return false;
    }
  }

  /// 🔥 LOGOUT: chama a API e limpa os dados locais
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);

    // 1. Tenta chamar o endpoint de logout (se houver token)
    if (token != null && token.isNotEmpty) {
      try {
        final url = Uri.parse('${ApiConfig.baseUrl}/auth/logout');
        final response = await http.post(
          url,
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        // Espera-se status 204 (sem conteúdo) ou 200
        if (response.statusCode == 204 || response.statusCode == 200) {
          debugPrint('✅ Logout na API realizado com sucesso');
        } else {
          debugPrint('⚠️ Logout na API retornou status: ${response.statusCode}');
        }
      } catch (e) {
        // Se a API falhar, continuamos com o logout local
        debugPrint('❌ Erro ao chamar logout na API: $e');
      }
    }

    // 2. Sempre limpa os dados locais, independente do sucesso da API
    await prefs.remove(tokenKey);
    await prefs.remove(salePointKey);
    // Opcional: limpar outros dados (cache, etc.)
    // await prefs.clear();

    debugPrint('🔑 Sessão finalizada localmente');
  }

  // Retorna o SalePoint atual (baseado no ID salvo)
Future<SalePoint?> getCurrentSalePoint() async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getInt(salePointKey);
  if (id == null) return null;
  // Busca na API (ou no cache)
  final url = Uri.parse('${ApiConfig.baseUrl}/auth/$id');
  final token = prefs.getString(tokenKey);
  try {
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return SalePoint.fromJson(data);
    }
    return null;
  } catch (_) {
    return null;
  }
}

// Atualiza o perfil via PATCH /auth/
Future<bool> updateProfile({String? name, String? email, String? password, int? level}) async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getInt(salePointKey);
  if (id == null) return false;
  final token = prefs.getString(tokenKey);
  
  // Constrói a URL com os parâmetros query
  final queryParameters = <String, String>{};
  if (name != null && name.isNotEmpty) queryParameters['name'] = name;
  if (email != null && email.isNotEmpty) queryParameters['email'] = email;
  if (password != null && password.isNotEmpty) queryParameters['password'] = password;
  if (level != null) queryParameters['level'] = level.toString();
  
  final uri = Uri.parse('${ApiConfig.baseUrl}/auth/')
      .replace(queryParameters: queryParameters);
  // O id também vai como query? Pelo Swagger, id é query, então adicionamos:
  final fullUri = uri.replace(queryParameters: {...queryParameters, 'id': id.toString()});
  
  try {
    final response = await http.patch(
      fullUri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    return response.statusCode == 200 || response.statusCode == 204;
  } catch (_) {
    return false;
  }
}
}
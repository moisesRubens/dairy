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

  Future<bool> login(String username, String password) async 
  {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    try 
    {
      final response = await http.post(
        url,
        body: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) 
      {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data.containsKey('access_token')) 
        {
          String token = data['access_token'];
          Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
          int userId = int.parse(decodedToken['sub']);

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(tokenKey, token);
          await prefs.setInt(salePointKey, userId);
        }
        return true;
      }
      return false;
    } 
    catch (e) 
    {
      debugPrint("Erro na requisição: $e");
      return false;
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


  Future<void> logout() async 
  {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);

    if (token != null && token.isNotEmpty) 
    {
      try 
      {
        final url = Uri.parse('${ApiConfig.baseUrl}/auth/logout');
        final response = await http.post(
          url,
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 204 || response.statusCode == 200) 
        {
          debugPrint('✅ Logout na API realizado com sucesso');
        } 
        else 
        {
          debugPrint('⚠️ Logout na API retornou status: ${response.statusCode}');
        }
      } 
      catch (e) 
      {
        debugPrint('❌ Erro ao chamar logout na API: $e');
      }
    }
    await prefs.remove(tokenKey);
    await prefs.remove(salePointKey);
    debugPrint('🔑 Sessão finalizada localmente');
  }

  Future<SalePoint?> getCurrentSalePoint() async 
  {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(salePointKey);
    
    if (id == null) return null;
    
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/$id');
    final token = prefs.getString(tokenKey);
    
    try 
    {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) 
      {
        final data = jsonDecode(response.body);
        return SalePoint.fromJson(data);
      }
      return null;
    } 
    catch (e) 
    {
      debugPrint("Falha ao obter dados do perfil");
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
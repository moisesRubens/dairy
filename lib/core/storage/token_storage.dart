import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Única fonte de verdade para o token JWT salvo no dispositivo.
/// Centraliza a leitura/escrita que antes estava espalhada nos services.
class TokenStorage {
  static const tokenKey = 'access_token';
  static const salePointKey = 'sale_point_id';

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> write(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(salePointKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

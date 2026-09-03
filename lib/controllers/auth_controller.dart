import 'package:dairy/services/auth_service.dart';
import '../domain/sale_point.dart';

class AuthController {
  final AuthService _authService;

  AuthController() : _authService = AuthService();

  // Login
  Future<SalePoint?> login(String username, String password) async {
    try {
      return await _authService.login(username, password);
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.logout();
  }

  // Verificar se está logado
  Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  // Buscar dados do usuário atual
  Future<SalePoint?> getCurrentSalePoint() async {
    return await _authService.getCurrentSalePoint();
  }

  // Atualizar perfil
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? password,
    int? level,
  }) async {
    return await _authService.updateProfile(
      name: name,
      email: email,
      password: password,
      level: level,
    );
  }

  // Get current user ID
  Future<int?> getCurrentSalePointId() async {
    return await _authService.getCurrentSalePointId();
  }
}
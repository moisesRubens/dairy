import 'package:dairy/services/auth_service.dart';
import '../domain/sale_point.dart';

class AuthController {
  final AuthService _authService;

  AuthController() : _authService = AuthService();

  Future<SalePoint?> login(String username, String password) async 
  {
    try 
    {
      bool result = await _authService.login(username, password);
      if(result)
      {
        return await _authService.getCurrentSalePoint();
      }
      return null;
    } 
    catch (e) 
    {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  Future<void> logout() async 
  {
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
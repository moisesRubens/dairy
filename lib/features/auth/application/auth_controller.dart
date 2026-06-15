import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/token_storage.dart';

enum UserRole { admin, vendedor }

UserRole roleFromString(String? value) =>
    value == 'admin' ? UserRole.admin : UserRole.vendedor;

/// Estado de sessão. Carrega o id do ponto e o papel direto do JWT —
/// não existe mais o SalePoint(id: 0) fabricado do antigo AuthService.
class AuthState {
  final bool authenticated;
  final int? salePointId;
  final UserRole? role;
  final String? token;

  const AuthState._(this.authenticated, this.salePointId, this.role, this.token);

  const AuthState.unauthenticated() : this._(false, null, null, null);

  const AuthState.authenticated({
    required int salePointId,
    required UserRole role,
    required String token,
  }) : this._(true, salePointId, role, token);

  bool get isAdmin => role == UserRole.admin;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // O storage é assíncrono; inicia deslogado e tenta restaurar a sessão.
    _bootstrap();
    return const AuthState.unauthenticated();
  }

  Future<void> _bootstrap() async {
    final token = await ref.read(tokenStorageProvider).read();
    if (token == null || token.isEmpty) return;
    try {
      if (JwtDecoder.isExpired(token)) {
        await ref.read(tokenStorageProvider).clear();
        return;
      }
      _applyToken(token);
    } catch (_) {
      await ref.read(tokenStorageProvider).clear();
    }
  }

  void _applyToken(String token) {
    final claims = JwtDecoder.decode(token);
    final id = int.parse(claims['sub'].toString());
    final role = roleFromString(claims['role'] as String?);
    ref.read(authTokenProvider.notifier).state = token;
    state = AuthState.authenticated(salePointId: id, role: role, token: token);
  }

  /// Login OAuth2 (form-encoded): o backend espera username (= nome) e senha.
  Future<void> login(String username, String password) async {
    final dio = ref.read(dioProvider);
    final response = await dio.post(
      '/auth/login',
      data: {'username': username.trim(), 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    final token = response.data['access_token'] as String;
    await ref.read(tokenStorageProvider).write(token);
    _applyToken(token);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    ref.read(authTokenProvider.notifier).state = null;
    state = const AuthState.unauthenticated();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Atalhos para telas/roteador.
final currentRoleProvider =
    Provider<UserRole?>((ref) => ref.watch(authControllerProvider).role);
final currentSalePointIdProvider =
    Provider<int?>((ref) => ref.watch(authControllerProvider).salePointId);

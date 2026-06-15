import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/network/dio_provider.dart';
import '../application/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).login(
            _userController.text,
            _passwordController.text,
          );
      // O redirect do GoRouter leva para a área do papel automaticamente.
    } catch (e) {
      if (!mounted) return;
      final api = toApiException(e);
      setState(() {
        _errorMessage = api.statusCode == 401 || api.statusCode == 404
            ? 'Credenciais inválidas. Tente novamente.'
            : 'Erro ao conectar. Verifique sua conexão.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? AppColors.green
                            : AppColors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.agriculture,
                          size: 44, color: AppColors.white),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'FAZENDA BOA ESPERANÇA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ponto de Venda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 1.0,
                        color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 48),
                  _buildLabel('USUÁRIO'),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _userController,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Digite seu usuário',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildLabel('SENHA'),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isLoading,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      hintText: '********',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadii.table),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.red, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: AppColors.white, strokeWidth: 2),
                          )
                        : const Text('ENTRAR',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: Colors.grey[600],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart'; // Import the AuthService

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService(); // Initialize AuthService
  bool _isLoading = false;
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
      _errorMessage = null; // Clear previous errors
    });

    final String username = _userController.text;
    final String password = _passwordController.text;

    try {
      // Call the login method from AuthService
      final salePoint = await _authService.login(username, password);

      if (salePoint != null) {
        // Login successful, navigate to the main screen
        if (mounted) {
          context.go('/'); // Use context.go to navigate to the main route
        }
      } else {
        // Login failed (e.g., invalid credentials, 401 Unauthorized from API)
        setState(() {
          _errorMessage = 'Credenciais inválidas. Tente novamente.';
        });
      }
    } catch (e) {
      // Handle network errors or other exceptions
      setState(() {
        _errorMessage = 'Ocorreu um erro ao tentar fazer login. Verifique sua conexão.';
      });
      print("Erro no login: $e"); // For debugging purposes
    } finally {
      setState(() {
        _isLoading = false; // Always stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo ou Nome da Fazenda
              const Icon(Icons.agriculture, size: 64, color: Colors.black),
              const SizedBox(height: 16),
              const Text(
                'FAZENDA BOA ESPERANÇA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 48),

              // Input de Usuário
              const Text(
                'USUÁRIO',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  hintText: 'Digite seu usuário',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Input de Senha
              const Text(
                'SENHA',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: '********',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Display error message if any
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Color(0xFFE74C3C), fontWeight: FontWeight.bold), // Red for error
                    textAlign: TextAlign.center,
                  ),
                ),

              // Botão de Login
              ElevatedButton(
                onPressed: _isLoading ? null : _login, // Disable button when loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isLoading ? 0 : 2, // Reduce elevation when loading
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'ENTRAR',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
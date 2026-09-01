import 'package:dairy/screens/inventory_page.dart';
import 'package:dairy/screens/sales_points.dart';
import 'package:dairy/screens/login_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_page.dart';
import 'screens/orders_page.dart';
import 'services/auth_service.dart';
import 'services/outbound_service.dart';
import 'database/db.dart';
import 'domain/sale_point.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o banco
  await DB.instance.database;
  
  runApp(const MyApp());
}

final AuthService _authService = AuthService();

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final loggedIn = await _authService.isLoggedIn();
    final goingToLogin = state.matchedLocation == '/login';
    if (!loggedIn) return goingToLogin ? null : '/login';
    if (goingToLogin) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const MainShell(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      title: 'Fazenda Boa Esperança',
      theme: ThemeData(
        primaryColor: Colors.black,
        useMaterial3: true,
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final InventoryPageState _inventoryPageState;
  late final List<Widget> _pages;
  final GlobalKey<InventoryPageState> _inventoryKey = GlobalKey<InventoryPageState>();

  _MainShellState() {
    _inventoryPageState = InventoryPageState();
    _pages = [
      HomePage(key: HomePage.homeKey),
      const OrdersPage(),
      InventoryPage(key: _inventoryKey),
      const SalesPointsPage(),
    ];
  }
  
  
  void _showProfileDialog(BuildContext context) {
    // Busca os dados atuais do usuário
    Future<SalePoint?> futureUser = _authService.getCurrentSalePoint();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FutureBuilder<SalePoint?>(
          future: futureUser,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = snapshot.data;
            return ProfileDialog(
              initialName: user?.name ?? '',
              initialEmail: user?.email ?? '',
              onSave: (String name, String email, String password) async {
                // Chama o serviço para atualizar
                final success = await _authService.updateProfile(
                  name: name.isNotEmpty ? name : null,
                  email: email.isNotEmpty ? email : null,
                  password: password.isNotEmpty ? password : null,
                );
                if (success && context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil atualizado com sucesso!')),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao atualizar perfil.')),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 2)),
        title: const Text('Fazenda Boa Esperança', style: TextStyle(color: Colors.white)),
      ),
      drawer: AppDrawer(
        onProfileTap: () => _showProfileDialog(context),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              WidgetsBinding.instance.addPostFrameCallback((_) {
                HomePage.homeKey.currentState?.scrollToTopNow();
              });
              break;
            case 1:
              OrdersPage.loadOrders();
              break;
            case 2:
              _inventoryKey.currentState?.refreshProducts(); 
              break;
            case 3:
              SalesPointsPage.loadSalesPoints();
              break;
            default:
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Estoque'),
          BottomNavigationBarItem(icon: Icon(Icons.person_search), label: 'Perfis'),
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final VoidCallback onProfileTap;

  const AppDrawer({super.key, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            child: Text(
              'Fazenda Boa Esperança',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined, color: Colors.black),
            title: const Text('PERFIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            onTap: () {
              Navigator.pop(context); // Fecha o drawer
              onProfileTap();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_outlined, color: Color(0xFFE74C3C)),
            title: const Text(
              'SAIR',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFE74C3C)),
            ),
            onTap: () async {
              await _authService.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DIALOG DE PERFIL
// ============================================================
class ProfileDialog extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final Future<void> Function(String name, String email, String password) onSave;

  const ProfileDialog({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.onSave,
  });

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Perfil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Nova Senha (opcional)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  await widget.onSave(
                    _nameController.text.trim(),
                    _emailController.text.trim(),
                    _passwordController.text.trim(),
                  );
                  if (mounted) setState(() => _isLoading = false);
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

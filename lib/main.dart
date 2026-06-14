import 'package:dairy/screens/inventory_page.dart';
import 'package:dairy/screens/sales_points.dart';
import 'package:dairy/screens/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_page.dart';
import 'screens/orders_page.dart';
import 'services/auth_service.dart';
import 'config/theme.dart';

void main() {
  // ProviderScope habilita o Riverpod em toda a árvore de widgets.
  runApp(const ProviderScope(child: MyApp()));
}

final AuthService _authService = AuthService();

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  // Auto-login: se a sessão é válida, pula a tela de login; se não é,
  // qualquer rota protegida é redirecionada de volta para /login.
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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Segue o tema do sistema operacional (claro/escuro).
      themeMode: ThemeMode.system,
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

  // Lista de páginas que preencherão o Body
  final List<Widget> _pages = [
    const HomePage(),                   // Index 0: Home
    const OrdersPage(), // Index 1: Pedidos
    const InventoryPage(), // Index 2: Estoque
    const SalesPointsPage(),  // Index 3: Perfis
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 2)),
        title: const Text('Fazenda Boa Esperança'),
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
  const AppDrawer({super.key});

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
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('PERFIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            onTap: () => Navigator.pop(context),
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
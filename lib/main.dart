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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o banco
  await DB.instance.database;
  
  // Carrega apenas as retiradas do banco
  await OutboundService.loadProductsFromLocal();
  
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

  final List<Widget> _pages = [
    const HomePage(),
    const OrdersPage(),
    const InventoryPage(),
    const SalesPointsPage(),
  ];

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
      drawer: const AppDrawer(),
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
          if (index == 2) {
            // ✅ CHAMA O MÉTODO ESTÁTICO loadInventory()
            InventoryPage.loadInventory();
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
            leading: const Icon(Icons.account_circle_outlined, color: Colors.black),
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
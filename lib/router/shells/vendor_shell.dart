import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/cart/presentation/pos_home_page.dart';
import '../../features/clients/presentation/clients_page.dart';
import '../../features/orders/presentation/vendor_orders_page.dart';
import '../../features/stock_requests/presentation/request_stock_page.dart';
import 'app_shell_scaffold.dart';

/// Shell do VENDEDOR: PDV · Pedidos · Meu Estoque · Solicitar.
/// Telas reais entram em commits seguintes (placeholders por enquanto).
StatefulShellRoute vendorShellRoute() {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => AppShellScaffold(
      navigationShell: navigationShell,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined), label: 'PDV'),
        BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined), label: 'Pedidos'),
        BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined), label: 'Clientes'),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined), label: 'Solicitar'),
      ],
    ),
    branches: [
      StatefulShellBranch(routes: [
        GoRoute(path: '/vendor/home', builder: (c, s) => const PosHomePage()),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
            path: '/vendor/orders',
            builder: (c, s) => const VendorOrdersPage()),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
            path: '/vendor/clients', builder: (c, s) => const ClientsPage()),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
            path: '/vendor/request',
            builder: (c, s) => const RequestStockPage()),
      ]),
    ],
  );
}

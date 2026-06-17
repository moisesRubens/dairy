import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/clients/presentation/clients_page.dart';
import '../../features/metrics/presentation/dashboard_page.dart';
import '../../features/products/presentation/products_page.dart';
import '../../features/sale_points/presentation/sale_points_page.dart';
import '../../features/sales/presentation/sales_by_point_page.dart';
import '../../features/stock_requests/presentation/approvals_page.dart';
import 'app_shell_scaffold.dart';

/// Shell do ADMIN: Painel · Aprovações · Clientes · Produtos · Pontos.
StatefulShellRoute adminShellRoute() {
  return StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) => AppShellScaffold(
      navigationShell: navigationShell,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined), label: 'Painel'),
        BottomNavigationBarItem(
            icon: Icon(Icons.inbox_outlined), label: 'Aprovações'),
        BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined), label: 'Clientes'),
        BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined), label: 'Produtos'),
        BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined), label: 'Pontos'),
      ],
    ),
    branches: [
      StatefulShellBranch(routes: [
        GoRoute(
            path: '/admin/dashboard',
            builder: (c, s) => const DashboardPage()),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
            path: '/admin/requests',
            builder: (c, s) => const ApprovalsPage()),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
            path: '/admin/clients', builder: (c, s) => const ClientsPage()),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
            path: '/admin/products',
            builder: (c, s) => const ProductsPage()),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
          path: '/admin/points',
          builder: (c, s) => const SalePointsPage(),
          routes: [
            // Drill-down "Vendas por Banca": /admin/points/:id/sales
            GoRoute(
              path: ':id/sales',
              builder: (c, s) => SalesByPointPage(
                salePointId: int.tryParse(s.pathParameters['id'] ?? '') ?? 0,
                salePointName:
                    s.uri.queryParameters['name'] ?? 'Vendas da banca',
              ),
            ),
          ],
        ),
      ]),
    ],
  );
}

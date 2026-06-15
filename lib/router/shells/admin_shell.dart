import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/clients/presentation/clients_page.dart';
import '../../features/metrics/presentation/dashboard_page.dart';
import '../../features/stock_requests/presentation/approvals_page.dart';
import 'app_shell_scaffold.dart';

/// Shell do ADMIN: Painel · Aprovações · Estoque · Pontos.
/// Telas reais entram em commits seguintes (placeholders por enquanto).
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
            path: '/admin/points',
            builder: (c, s) => const ShellPlaceholder(
                title: 'Pontos de Venda', icon: Icons.storefront_outlined)),
      ]),
    ],
  );
}

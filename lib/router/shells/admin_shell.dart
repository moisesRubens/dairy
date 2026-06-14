import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
            icon: Icon(Icons.inventory_2_outlined), label: 'Estoque'),
        BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined), label: 'Pontos'),
      ],
    ),
    branches: [
      StatefulShellBranch(routes: [
        GoRoute(
            path: '/admin/dashboard',
            builder: (c, s) => const ShellPlaceholder(
                title: 'Painel do Administrador', icon: Icons.dashboard_outlined)),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
            path: '/admin/requests',
            builder: (c, s) => const ShellPlaceholder(
                title: 'Aprovações de Estoque', icon: Icons.inbox_outlined)),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
            path: '/admin/stock',
            builder: (c, s) => const ShellPlaceholder(
                title: 'Estoque (todos os pontos)',
                icon: Icons.inventory_2_outlined)),
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

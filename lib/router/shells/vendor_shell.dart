import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
            icon: Icon(Icons.inventory_2_outlined), label: 'Meu Estoque'),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined), label: 'Solicitar'),
      ],
    ),
    branches: [
      StatefulShellBranch(routes: [
        GoRoute(
            path: '/vendor/home',
            builder: (c, s) => const ShellPlaceholder(
                title: 'PDV — Venda', icon: Icons.point_of_sale_outlined)),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
            path: '/vendor/orders',
            builder: (c, s) => const ShellPlaceholder(
                title: 'Meus Pedidos', icon: Icons.shopping_cart_outlined)),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
            path: '/vendor/stock',
            builder: (c, s) => const ShellPlaceholder(
                title: 'Meu Estoque', icon: Icons.inventory_2_outlined)),
      ]),
      StatefulShellBranch(routes: [
        GoRoute(
            path: '/vendor/request',
            builder: (c, s) => const ShellPlaceholder(
                title: 'Solicitar Estoque', icon: Icons.add_box_outlined)),
      ]),
    ],
  );
}

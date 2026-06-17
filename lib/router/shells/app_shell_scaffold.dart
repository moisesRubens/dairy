import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../core/network/connectivity_provider.dart';
import '../../features/auth/application/auth_controller.dart';

/// Casca compartilhada pelos dois shells (admin e vendedor): AppBar preta,
/// Drawer ciente do papel com logout, e a BottomNavigationBar do papel.
class AppShellScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  final List<BottomNavigationBarItem> items;

  const AppShellScaffold({
    super.key,
    required this.navigationShell,
    required this.items,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // valueOrNull ?? true: enquanto resolve, assume online (não pisca o banner).
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    return Scaffold(
      appBar: AppBar(
        shape: Border(bottom: BorderSide(color: Colors.grey[800]!, width: 2)),
        title: const Text('Fazenda Boa Esperança'),
      ),
      drawer: const _AppDrawer(),
      body: Column(
        children: [
          if (!isOnline) const _OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        // fixed: com 4+ abas, mantém rótulos sempre visíveis (sem animação shifting).
        type: BottomNavigationBarType.fixed,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: items,
      ),
    );
  }
}

/// Faixa de "sem conexão" (Nielsen: visibilidade do estado do sistema).
/// Âmbar, consistente com os avisos de estoque baixo. Some quando volta a rede.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFB8860B),
      padding:
          const EdgeInsets.symmetric(vertical: 6, horizontal: AppSpacing.md),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined, color: AppColors.white, size: 16),
          SizedBox(width: AppSpacing.sm),
          Text('Sem conexão — usando dados locais',
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final isAdmin = auth.isAdmin;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.black),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Fazenda Boa Esperança',
                    style: TextStyle(color: AppColors.white, fontSize: 20)),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isAdmin ? AppColors.green : AppColors.grey)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadii.input),
                  ),
                  child: Text(
                    isAdmin ? 'ADMINISTRADOR' : 'VENDEDOR',
                    style: TextStyle(
                      color: isAdmin ? AppColors.green : AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout_outlined, color: AppColors.red),
            title: const Text('SAIR',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.red)),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}

/// Placeholder temporário enquanto as telas reais não são plugadas (C16+).
class ShellPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;
  const ShellPlaceholder({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: AppSpacing.md),
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          Text('Em construção', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

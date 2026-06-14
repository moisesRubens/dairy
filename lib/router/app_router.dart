import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import 'shells/admin_shell.dart';
import 'shells/vendor_shell.dart';

/// Ponte entre o estado de auth (Riverpod) e o refreshListenable do GoRouter:
/// quando a sessão muda (login/logout/expiração), o router reavalia o redirect.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loggingIn = state.matchedLocation == '/login';

      if (!auth.authenticated) {
        return loggingIn ? null : '/login';
      }

      // Já autenticado: manda para a área do papel.
      final home = auth.isAdmin ? '/admin/dashboard' : '/vendor/home';
      if (loggingIn) return home;

      // Impede vendedor de entrar na área admin e vice-versa.
      final inAdminArea = state.matchedLocation.startsWith('/admin');
      final inVendorArea = state.matchedLocation.startsWith('/vendor');
      if (auth.isAdmin && inVendorArea) return '/admin/dashboard';
      if (!auth.isAdmin && inAdminArea) return '/vendor/home';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      adminShellRoute(),
      vendorShellRoute(),
    ],
  );
});

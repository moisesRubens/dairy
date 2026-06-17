import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dairy/config/theme.dart';
import 'package:dairy/features/auth/presentation/login_page.dart';

/// Garante que a LoginPage renderiza sem lançar exceções nos DOIS temas
/// (claro e escuro). É a rede de segurança da migração para o design system:
/// se algum widget tivesse cor/layout inválido no dark mode, o teste falharia.
void main() {
  // ProviderScope porque a LoginPage agora é um ConsumerWidget (Riverpod).
  Widget wrap(Widget child, ThemeData theme) {
    return ProviderScope(
      child: MaterialApp(
        theme: theme,
        home: child is LoginPage ? child : Scaffold(body: child),
      ),
    );
  }

  for (final entry in {
    'light': AppTheme.light,
    'dark': AppTheme.dark,
  }.entries) {
    final modo = entry.key;
    final tema = entry.value;

    testWidgets('LoginPage renderiza no tema $modo', (tester) async {
      await tester.pumpWidget(wrap(const LoginPage(), tema));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ENTRAR'), findsOneWidget);
    });
  }
}

// Teste end-to-end da feature de Produtos, dirigindo a árvore REAL de widgets
// contra um backend REAL (FastAPI). Não usa mocks — exercita login OAuth2,
// roteamento por papel e o CRUD de /products de verdade.
//
// Pré-requisitos para rodar:
//   1. Backend no ar em API_BASE_URL com um admin `admin/admin123` e produtos.
//   2. flutter test integration_test/products_flow_test.dart -d macos \
//        --dart-define=API_BASE_URL=http://127.0.0.1:8000
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dairy/main.dart' as app;

/// Pumpa quadros até [finder] aparecer (útil quando há HTTP em voo e um
/// spinner girando — pumpAndSettle travaria nesse caso).
Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timeout esperando por: $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login admin → aba Produtos lista os produtos do backend',
      (tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 1));

    // --- Login ---
    final fields = find.byType(TextField);
    await _pumpUntil(tester, fields);
    await tester.enterText(fields.at(0), 'admin');
    await tester.enterText(fields.at(1), 'admin123');
    await tester.tap(find.text('ENTRAR'));

    // Aguarda o POST /auth/login + redirect para a área admin.
    await _pumpUntil(tester, find.text('Produtos'),
        timeout: const Duration(seconds: 15));

    // --- Navega para a aba Produtos ---
    await tester.tap(find.text('Produtos').last);

    // Aguarda o GET /products/ pintar a lista (título da tela + um produto seed).
    await _pumpUntil(tester, find.text('PRODUTOS'));
    await _pumpUntil(tester, find.text('Queijo Coalho'),
        timeout: const Duration(seconds: 15));

    expect(find.text('PRODUTOS'), findsOneWidget);
    expect(find.text('Queijo Coalho'), findsOneWidget);
  });
}

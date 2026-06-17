// Valida o offline-first da P4.1: persistência no SQLite (ProductDao) e o
// cache-fallback do ProductRepository quando NÃO há rede (Dio sem resposta).
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dairy/core/local/local_store.dart';
import 'package:dairy/features/products/data/product_dao.dart';
import 'package:dairy/features/products/data/product_repository.dart';
import 'package:dairy/features/products/domain/product.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ProductDao persiste e o cache-fallback serve offline',
      (tester) async {
    final dao = ProductDao(LocalStore.instance);
    await dao.replaceAll([
      Product(id: 1, name: 'Queijo Coalho', kg: 10),
      Product(id: 2, name: 'Leite Integral', liters: 5),
    ]);

    // Cache local persistido.
    final cached = await dao.getAll();
    expect(cached.length, 2);

    // Dio apontando para uma porta morta → erro SEM resposta (offline).
    final dio = Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1:9',
      connectTimeout: const Duration(milliseconds: 800),
    ));
    final repo = ProductRepository(dio, dao);

    // O GET falha por falta de rede → o repositório serve o cache local.
    final list = await repo.list();
    expect(list.length, 2);
    expect(list.map((p) => p.name),
        containsAll(['Queijo Coalho', 'Leite Integral']));
  });
}

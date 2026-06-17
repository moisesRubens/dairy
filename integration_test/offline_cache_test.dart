// Valida o offline-first (P4): persistência no SQLite e o cache-fallback dos
// repositórios quando NÃO há rede (Dio sem resposta), para Produtos, Clientes
// e Estoque/retiradas.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dairy/core/local/local_store.dart';
import 'package:dairy/features/products/data/product_dao.dart';
import 'package:dairy/features/products/data/product_repository.dart';
import 'package:dairy/features/products/domain/product.dart';
import 'package:dairy/features/clients/data/client_dao.dart';
import 'package:dairy/features/clients/data/client_repository.dart';
import 'package:dairy/features/clients/domain/client.dart';
import 'package:dairy/features/stock/data/outbound_dao.dart';
import 'package:dairy/features/stock/data/stock_repository.dart';
import 'package:dairy/features/stock/domain/outbound.dart';

/// Dio apontando para uma porta morta → erro SEM resposta (simula offline).
Dio _deadDio() => Dio(BaseOptions(
      baseUrl: 'http://127.0.0.1:9',
      connectTimeout: const Duration(milliseconds: 800),
    ));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('produtos: cache-fallback serve offline', (tester) async {
    final dao = ProductDao(LocalStore.instance);
    await dao.replaceAll([
      Product(id: 1, name: 'Queijo Coalho', kg: 10),
      Product(id: 2, name: 'Leite Integral', liters: 5),
    ]);
    final list = await ProductRepository(_deadDio(), dao).list();
    expect(list.length, 2);
    expect(list.map((p) => p.name),
        containsAll(['Queijo Coalho', 'Leite Integral']));
  });

  testWidgets('clientes: cache-fallback serve offline', (tester) async {
    final dao = ClientDao(LocalStore.instance);
    await dao.replaceAll([
      Client(id: 1, name: 'Maria', salePointId: 1),
      Client(id: 2, name: 'João', phone: '999', salePointId: 1),
    ]);
    final list = await ClientRepository(_deadDio(), dao).list();
    expect(list.length, 2);
    expect(list.map((c) => c.name), containsAll(['Maria', 'João']));
  });

  testWidgets('estoque: cache-fallback offline + status int↔bool',
      (tester) async {
    final dao = OutboundDao(LocalStore.instance);
    await dao.replaceForSalePoint(7, [
      Outbound(
        id: 1,
        productId: 1,
        name: 'Queijo Coalho',
        status: true,
        unidade: 'kg',
        takenQuantity: 20,
        soldQuantity: 5,
        remainingQuantity: 15,
        totalValue: 0,
      ),
    ]);
    final list = await StockRepository(_deadDio(), dao).outbounds(7);
    expect(list.length, 1);
    expect(list.first.status, true); // INTEGER no SQLite → bool na leitura
    expect(list.first.remainingQuantity, 15);
    expect(list.first.unitLabel, 'kg');
  });
}

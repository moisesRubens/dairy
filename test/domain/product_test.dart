import 'package:flutter_test/flutter_test.dart';
import 'package:dairy/domain/product.dart';

void main() {
  group('Product.fromJson', () {
    test('faz parse de um produto vendido por unidade (amount)', () {
      final product = Product.fromJson({
        'id': 1,
        'name': 'Manteiga Pote',
        'price': 12.0,
        'amount': 20,
      });

      expect(product.id, 1);
      expect(product.name, 'Manteiga Pote');
      expect(product.price, 12.0);
      expect(product.amount, 20);
      expect(product.kg, isNull);
      expect(product.liters, isNull);
    });

    test('faz parse de produto por peso (kg) e volume (liters)', () {
      final queijo = Product.fromJson({
        'id': 2,
        'name': 'Queijo Coalho',
        'price': 35.5,
        'kg': 10.5,
      });
      expect(queijo.kg, 10.5);

      final leite = Product.fromJson({
        'id': 3,
        'name': 'Leite Integral',
        'price': 6.5,
        'liters': 40.0,
      });
      expect(leite.liters, 40.0);
    });

    // Regressão: a API pode serializar um inteiro (5) onde o model espera
    // double. O cast antigo (as double?) lançava exceção; o atual usa num.
    test('aceita inteiro onde se espera double (kg/liters/price)', () {
      expect(
        () => Product.fromJson({
          'id': 4,
          'name': 'Queijo Frescal',
          'price': 25, // int, não 25.0
          'kg': 5, // int, não 5.0
        }),
        returnsNormally,
      );

      final product = Product.fromJson({
        'id': 4,
        'name': 'Queijo Frescal',
        'price': 25,
        'kg': 5,
      });
      expect(product.price, 25.0);
      expect(product.kg, 5.0);
      expect(product.price, isA<double>());
      expect(product.kg, isA<double>());
    });

    test('lida com campos ausentes/nulos sem quebrar', () {
      final product = Product.fromJson({'name': 'Sem Preço'});
      expect(product.id, isNull);
      expect(product.price, isNull);
      expect(product.amount, isNull);
      expect(product.kg, isNull);
      expect(product.liters, isNull);
      expect(product.name, 'Sem Preço');
    });
  });
}

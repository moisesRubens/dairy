import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/product.dart';

class ProductRepository {
  final Dio _dio;
  ProductRepository(this._dio);

  Future<List<Product>> list() async {
    try {
      // Barra final obrigatória: /products (sem barra) gera 307 e perde o token.
      final response = await _dio.get('/products/');
      return (response.data as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }
}

final productRepositoryProvider =
    Provider<ProductRepository>((ref) => ProductRepository(ref.watch(dioProvider)));

final productsProvider = FutureProvider.autoDispose<List<Product>>(
    (ref) => ref.watch(productRepositoryProvider).list());

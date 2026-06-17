import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/local/local_store.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/product.dart';
import 'product_dao.dart';

class ProductRepository {
  final Dio _dio;
  final ProductDao _dao;
  ProductRepository(this._dio, this._dao);

  /// Offline-first (cache-fallback): busca o catálogo no servidor e atualiza o
  /// cache local; se estiver SEM REDE (erro sem resposta), serve o cache.
  /// Erros COM resposta (401, 500…) propagam — não mascaramos com dado velho.
  Future<List<Product>> list() async {
    try {
      // Barra final obrigatória: /products (sem barra) gera 307 e perde o token.
      final response = await _dio.get('/products/');
      final products = (response.data as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
      await _dao.replaceAll(products); // snapshot do servidor → cache
      return products;
    } on DioException catch (e) {
      if (e.response == null) {
        // Sem resposta = offline/timeout → usa o cache local, se houver.
        final cached = await _dao.getAll();
        if (cached.isNotEmpty) return cached;
      }
      throw toApiException(e);
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Cadastra um produto (admin). O backend recebe nome/preço/quantidade por
  /// QUERY PARAMS (não body). [unit] é a unidade ('amount'|'kg'|'liters') e só
  /// esse campo de quantidade é enviado. Para 'amount' o backend espera inteiro
  /// — enviar double geraria 422. Retorna o produto criado (para anexar foto).
  Future<Product> create({
    required String name,
    required double price,
    required String unit,
    required double quantity,
  }) async {
    try {
      final response = await _dio.post('/products/', queryParameters: {
        'name': name,
        'price': price,
        unit: unit == 'amount' ? quantity.toInt() : quantity,
      });
      return Product.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Edita um produto (admin) via body. O backend exige name+price presentes
  /// (campos required-nullable no DTO), então sempre os enviamos.
  Future<void> update(
    int id, {
    required String name,
    required double price,
    required String unit,
    required double quantity,
  }) async {
    try {
      await _dio.patch('/products/$id', data: {
        'name': name,
        'price': price,
        unit: unit == 'amount' ? quantity.toInt() : quantity,
      });
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/products/$id');
    } catch (e) {
      throw toApiException(e);
    }
  }

  /// Faz upload da foto do produto (admin). Multipart/form-data, campo `file`.
  /// Retorna o produto atualizado (já com `image_url` preenchido). [filename]
  /// preserva a extensão para o backend salvar o estático corretamente.
  Future<Product> uploadImage(
    int id,
    Uint8List bytes, {
    required String filename,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final response = await _dio.post('/products/$id/image', data: form);
      return Product.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) =>
    ProductRepository(ref.watch(dioProvider), ProductDao(LocalStore.instance)));

final productsProvider = FutureProvider.autoDispose<List<Product>>(
    (ref) => ref.watch(productRepositoryProvider).list());

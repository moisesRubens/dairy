import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/client.dart';

class ClientRepository {
  final Dio _dio;
  ClientRepository(this._dio);

  Future<List<Client>> list() async {
    try {
      final response = await _dio.get('/clients/');
      return (response.data as List)
          .map((e) => Client.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<Client> create(
      {required String name, String? phone, String? email}) async {
    try {
      final response = await _dio.post('/clients/', data: {
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
      });
      return Client.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<Client> update(int clientId,
      {String? name, String? phone, String? email, String? notes}) async {
    try {
      final response = await _dio.patch('/clients/$clientId', data: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      return Client.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> delete(int clientId) async {
    try {
      await _dio.delete('/clients/$clientId');
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<ClientHistory> history(int clientId) async {
    try {
      final response = await _dio.get('/clients/$clientId/orders');
      return ClientHistory.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<ClientRanking>> ranking() async {
    try {
      final response = await _dio.get('/clients/ranking');
      return (response.data as List)
          .map((e) => ClientRanking.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }
}

final clientRepositoryProvider =
    Provider<ClientRepository>((ref) => ClientRepository(ref.watch(dioProvider)));

final clientsProvider = FutureProvider.autoDispose<List<Client>>(
    (ref) => ref.watch(clientRepositoryProvider).list());

final clientRankingProvider = FutureProvider.autoDispose<List<ClientRanking>>(
    (ref) => ref.watch(clientRepositoryProvider).ranking());

final clientHistoryProvider =
    FutureProvider.autoDispose.family<ClientHistory, int>(
        (ref, clientId) => ref.watch(clientRepositoryProvider).history(clientId));

/// Cliente selecionado para vincular à próxima venda (PDV). Null = venda rápida.
final selectedClientProvider = StateProvider<Client?>((ref) => null);

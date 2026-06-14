import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/metrics.dart';

class MetricsRepository {
  final Dio _dio;
  MetricsRepository(this._dio);

  Future<MetricsSummary> summary() async {
    try {
      final response = await _dio.get('/admin/metrics/summary');
      return MetricsSummary.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<PointRevenue>> revenueByPoint() async {
    try {
      final response = await _dio.get('/admin/metrics/revenue/by-point');
      return (response.data as List)
          .map((e) => PointRevenue.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw toApiException(e);
    }
  }
}

final metricsRepositoryProvider =
    Provider<MetricsRepository>((ref) => MetricsRepository(ref.watch(dioProvider)));

final metricsSummaryProvider = FutureProvider.autoDispose<MetricsSummary>(
    (ref) => ref.watch(metricsRepositoryProvider).summary());

final revenueByPointProvider = FutureProvider.autoDispose<List<PointRevenue>>(
    (ref) => ref.watch(metricsRepositoryProvider).revenueByPoint());

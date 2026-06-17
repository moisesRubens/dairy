class MetricsSummary {
  final double totalRevenue;
  final double revenueToday;
  final int ordersCount;
  final int vendorsCount;
  final int productsCount;
  final int pendingRequests;

  MetricsSummary({
    required this.totalRevenue,
    required this.revenueToday,
    required this.ordersCount,
    required this.vendorsCount,
    required this.productsCount,
    required this.pendingRequests,
  });

  factory MetricsSummary.fromJson(Map<String, dynamic> json) => MetricsSummary(
        totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
        revenueToday: (json['revenue_today'] as num?)?.toDouble() ?? 0,
        ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
        vendorsCount: (json['vendors_count'] as num?)?.toInt() ?? 0,
        productsCount: (json['products_count'] as num?)?.toInt() ?? 0,
        pendingRequests: (json['pending_requests'] as num?)?.toInt() ?? 0,
      );
}

class PointRevenue {
  final int salePointId;
  final String name;
  final double revenue;
  final int ordersCount;

  PointRevenue({
    required this.salePointId,
    required this.name,
    required this.revenue,
    required this.ordersCount,
  });

  factory PointRevenue.fromJson(Map<String, dynamic> json) => PointRevenue(
        salePointId: (json['sale_point_id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '—',
        revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
        ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      );
}

class PaymentBreakdown {
  final String method;
  final double revenue;
  final int ordersCount;

  PaymentBreakdown({
    required this.method,
    required this.revenue,
    required this.ordersCount,
  });

  factory PaymentBreakdown.fromJson(Map<String, dynamic> json) =>
      PaymentBreakdown(
        method: json['method'] as String? ?? '—',
        revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
        ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      );
}

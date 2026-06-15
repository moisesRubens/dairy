class Client {
  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? notes;
  final int salePointId;

  Client({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.notes,
    required this.salePointId,
  });

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        notes: json['notes'] as String?,
        salePointId: (json['sale_point_id'] as num?)?.toInt() ?? 0,
      );
}

class HistoryOrder {
  final int id;
  final double totalValue;
  final DateTime? date;
  HistoryOrder({required this.id, required this.totalValue, this.date});

  factory HistoryOrder.fromJson(Map<String, dynamic> json) => HistoryOrder(
        id: (json['id'] as num).toInt(),
        totalValue: (json['total_value'] as num?)?.toDouble() ?? 0,
        date: json['date'] != null
            ? DateTime.tryParse(json['date'].toString())
            : null,
      );
}

class ClientHistory {
  final int ordersCount;
  final double totalSpent;
  final List<HistoryOrder> orders;
  ClientHistory(
      {required this.ordersCount,
      required this.totalSpent,
      required this.orders});

  factory ClientHistory.fromJson(Map<String, dynamic> json) => ClientHistory(
        ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
        totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
        orders: ((json['orders'] as List?) ?? [])
            .map((e) => HistoryOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ClientRanking {
  final int clientId;
  final String name;
  final int salePointId;
  final double totalSpent;
  final int ordersCount;

  ClientRanking({
    required this.clientId,
    required this.name,
    required this.salePointId,
    required this.totalSpent,
    required this.ordersCount,
  });

  factory ClientRanking.fromJson(Map<String, dynamic> json) => ClientRanking(
        clientId: (json['client_id'] as num).toInt(),
        name: json['name'] as String? ?? '—',
        salePointId: (json['sale_point_id'] as num?)?.toInt() ?? 0,
        totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0,
        ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      );
}

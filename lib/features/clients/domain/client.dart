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

class Order {
  final int id;
  final double totalValue;
  final bool status;
  final DateTime? date;

  Order({
    required this.id,
    required this.totalValue,
    required this.status,
    this.date,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: (json['id'] as num).toInt(),
        totalValue: (json['total_value'] as num?)?.toDouble() ?? 0,
        status: json['status'] as bool? ?? true,
        // create retorna 'date'; list pode trazer 'date' ou 'order_date'.
        date: _parseDate(json['date'] ?? json['order_date']),
      );

  static DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}

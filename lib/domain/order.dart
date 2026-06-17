import 'order_item.dart';

class Order {
  final String description;
  final bool status;
  final double totalValue;
  final String orderDate;
  final List<OrderItem> items;

  Order({
    required this.description,
    required this.status,
    required this.totalValue,
    required this.orderDate,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'description': description,
    'status': status,
    'total_value': totalValue,
    'order_date': orderDate,
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    description: json['description'] ?? '',
    status: json['status'] ?? true,
    totalValue: (json['total_value'] ?? 0).toDouble(),
    orderDate: json['order_date'] ?? '',
    items: (json['items'] as List)
        .map((item) => OrderItem.fromJson(item))
        .toList(),
  );
}
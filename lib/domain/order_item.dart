class OrderItem {
  final int productId;
  final int amount;
  final double kg;
  final double liters;

  OrderItem({
    required this.productId,
    required this.amount,
    required this.kg,
    required this.liters,
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'amount': amount,
    'kg': kg,
    'liters': liters,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['product_id'],
    amount: json['amount'] ?? 0,
    kg: json['kg']?.toDouble() ?? 0.0,
    liters: json['liters']?.toDouble() ?? 0.0,
  );
}
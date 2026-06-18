class OrderItem {
  final int productId;
  final String productName;  
  final double itemPrice;    
  final int amount;
  final double kg;
  final double liters;

  OrderItem({
    required this.productId,
    required this.productName, 
    required this.itemPrice,    
    required this.amount,
    required this.kg,
    required this.liters,
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'product_name': productName,  
    'item_price': itemPrice,      
    'amount': amount,
    'kg': kg,
    'liters': liters,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['product_id'],
    productName: json['product_name'] ?? 'Produto ${json['product_id']}', 
    itemPrice: (json['item_price'] ?? 0).toDouble(),  
    amount: json['amount'] ?? 0,
    kg: json['kg']?.toDouble() ?? 0.0,
    liters: json['liters']?.toDouble() ?? 0.0,
  );

  String getQuantityString() {
    if (amount > 0) return '$amount un';
    if (kg > 0) return '${kg.toStringAsFixed(2)} kg';
    if (liters > 0) return '${liters.toStringAsFixed(2)} L';
    return '0';
  }

  double get subtotal => itemPrice * (amount > 0 ? amount : (kg > 0 ? kg : liters));
}
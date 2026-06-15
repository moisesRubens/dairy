class Product {
  final int id;
  final String name;
  final double? price;
  final int? amount;
  final double? kg;
  final double? liters;

  Product({
    required this.id,
    required this.name,
    this.price,
    this.amount,
    this.kg,
    this.liters,
  });

  /// Unidade do produto (um dos três campos vem preenchido).
  String get unitKey =>
      amount != null ? 'amount' : (kg != null ? 'kg' : 'liters');

  String get unitLabel =>
      amount != null ? 'un' : (kg != null ? 'kg' : 'L');

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        price: (json['price'] as num?)?.toDouble(),
        amount: (json['amount'] as num?)?.toInt(),
        kg: (json['kg'] as num?)?.toDouble(),
        liters: (json['liters'] as num?)?.toDouble(),
      );
}

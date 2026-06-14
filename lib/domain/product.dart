class Product {
  final int? id;
  final String name;
  double? price;
  int? amount;
  double? kg;
  double? liters;

  Product({
    this.id,
    required this.name,
    this.price,
    this.amount,
    this.kg,
    this.liters
  });

  @override
  String toString() {
    return 'Product(id: $id, amount: $amount, kg: $kg, liters: $liters)';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      name: json['name'] as String,
      price: (json['price'] as num?)?.toDouble(),
      kg: (json['kg'] as num?)?.toDouble(),
      amount: (json['amount'] as num?)?.toInt(),
      liters: (json['liters'] as num?)?.toDouble()
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      //a incrementar pro adm add novos produtos
    };
  }
}
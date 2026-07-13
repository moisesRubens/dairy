class Product {
  static const String idColumn = "id";
  static const String productIdColumn = "product_id";
  static const String nameColumn = "name";
  static const String priceColumn = "price";
  static const String amountColumn = "amount" ;
  static const String kgColumn = "kg";
  static const String litersColumn = "liters";

  int? id;
  int? productId;
  String? name;
  double? price;
  int? amount;
  double? kg;
  double? liters;

  Product({
    this.id,
    this.productId,
    this.name,
    this.price,
    this.amount,
    this.kg,
    this.liters
  });

  @override
  String toString() {
    return 'Product(id: $id, amount: $amount, kg: $kg, liters: $liters)';
  }

  Product.fromMap(Map<String, dynamic> map) {
    id = map[idColumn];
    productId = map[productIdColumn];
    name = map[nameColumn];
    price = map[priceColumn];
    amount = map[amountColumn];
    kg = map[kgColumn];
    liters = map[litersColumn];
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      productIdColumn: productId,
      nameColumn: name,
      priceColumn: price,
      amountColumn: amount,
      kgColumn: kg,
      litersColumn: liters
    };

    if(id != null) {
      map[idColumn] = id;
    }
    return map;
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
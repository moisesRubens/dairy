import 'package:dairy/Enums/product_enum.dart';

class Product {
  static const String idColumn = "id";
  static const String productIdColumn = "product_id";
  static const String nameColumn = "name";
  static const String priceColumn = "price";
  static const String amountColumn = "amount" ;
  static const String kgColumn = "kg";
  static const String litersColumn = "liters";
  static const String dateColumn = "date";

  int? id;
  int? productId;
  String? name;
  double? price;
  late final Unit _unitType;
  double _quantity;
  DateTime date;

  Unit get unitType => _unitType;
  double? get quantity => _quantity;

  void setQuantity(double quantity)
  {
    _quantity = quantity;
  }

  Product({
    this.id,
    this.productId,
    this.name,
    this.price,
    DateTime? date,
    required Unit unitType,
    required double quantity
  }) : date = date ?? DateTime.now(), _unitType = unitType, _quantity = quantity;

  @override
  String toString() {
    return 'Product(id: $id, productId: $productId, unit: $_unitType)';
  }

  Unit _setUnitTypeFromDatabase(Map<String, dynamic> map)
  { 
    if(map[amountColumn] != null && map[amountColumn] != -1) return Unit.amount;
    else if(map[kgColumn] != null && map[kgColumn] != -1) return Unit.kg;
    else if(map[litersColumn] != null && map[litersColumn] != -1) return Unit.liters;
    return Unit.amount;
  }

  void _setUnitTypeToDatabase(Map<String, dynamic> map)
  {
    map[amountColumn] = (_unitType == Unit.amount) ? _quantity : -1;
    map[kgColumn] = (_unitType == Unit.kg) ? _quantity : -1;
    map[litersColumn] = (_unitType == Unit.liters) ? _quantity : -1;
  }

  void _setUnitTypeToJson(Map<String, dynamic> map)
  {
    map['amount'] = (_unitType == Unit.amount) ? _quantity : -1;
    map['kg'] = (_unitType == Unit.kg) ? _quantity : -1;
    map['liters'] = (_unitType == Unit.liters) ? _quantity : -1;
  }

  static Unit _setUnitTypeFromJson(Map<String, dynamic> map)
  {
    if(map['amount'] != null && map['amount'] != -1) return Unit.amount;
    else if(map['kg'] != null && map['kg'] != -1) return Unit.kg;
    else if(map['liters'] != null && map['liters'] != -1) return Unit.liters;
    return Unit.amount;
  }

  static double _setQuantityFromDatabase(Map<String, dynamic> map)
  {
    if(map[amountColumn] != null && map[amountColumn] != -1) return  map[amountColumn];
    else if(map[kgColumn] != null && map[kgColumn] != -1) return map[kgColumn];
    else if(map[litersColumn] != null && map[litersColumn] != -1) return map[litersColumn];
    return map[amountColumn];
  }

  static double _setQuantityFromJson(Map<String, dynamic> map)
  {
    if(map['amount'] != null && map['amount'] != -1) return  map['amount'];
    else if(map['kg'] != null && map['kg'] != -1) return map['kg'];
    else if(map['liters'] != null && map['liters'] != -1) return map['liters'];
    return -1;
  }

  Product.fromMap(Map<String, dynamic> map)
      : date = DateTime.now(), _quantity = _setQuantityFromDatabase(map)
  {
    id = map[idColumn];
    productId = map[productIdColumn];
    name = map[nameColumn];
    price = map[priceColumn];
    _unitType = _setUnitTypeFromDatabase(map);

    final rawDate = map[dateColumn];
    if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    }
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      productIdColumn: productId,
      nameColumn: name,
      priceColumn: price,
      dateColumn: date.toIso8601String()
    };
    _setUnitTypeToDatabase(map);
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
      unitType: _setUnitTypeFromJson(json),
      quantity: _setQuantityFromJson(json)
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'name': name,
      'price': price,
    };
    _setUnitTypeToJson(map);
    return map;
  }
}

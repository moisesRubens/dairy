import 'package:dairy/Enums/product_enum.dart';

class Product {
  static const String idColumn = "id";
  static const String productIdColumn = "product_id";
  static const String nameColumn = "name";
  static const String priceColumn = "price";
  static const String amountColumn = "amount" ;
  static const String kgColumn = "kg";
  static const String litersColumn = "liters";
  static const String unitColumn = "unit";
  static const String quantityColumn = "quantity";
  static const String dateColumn = "date";

  int? id;
  int? productId;
  String? name;
  double? price;
  late final Unit _unitType;
  double _quantity;
  DateTime? date;

  Unit get unitType => _unitType;
  double get quantity => _quantity;

  set quantity(double quantity)
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
  return 'Product(id: $id, productId: $productId, name: $name, '
         'price: $price, quantity: $_quantity, unit: $_unitType, date: $date)';
}

  Unit _setUnitTypeFromDatabase(Map<String, dynamic> map)
  { 
    if(map[amountColumn] != null && map[amountColumn] != -1) return Unit.amount;
    else if(map[kgColumn] != null && map[kgColumn] != -1) return Unit.kg;
    else if(map[litersColumn] != null && map[litersColumn] != -1) return Unit.liters;
    return Unit.amount;
  }
  static double _setQuantityFromDatabase(Map<String, dynamic> map)
  {
    if(map[amountColumn] != null && map[amountColumn] != -1) return  map[amountColumn];
    else if(map[kgColumn] != null && map[kgColumn] != -1) return map[kgColumn];
    else if(map[litersColumn] != null && map[litersColumn] != -1) return map[litersColumn];
    return map[amountColumn];
  }

  Product.fromMap(Map<String, dynamic> map)
      : _quantity = _setQuantityFromDatabase(map)
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

  Map<String, dynamic> toMap() 
  {
    final Map<String, dynamic> map = 
    {
      idColumn: productId,
      productIdColumn: productId,
      nameColumn: name,
      priceColumn: price,
      dateColumn: date?.toIso8601String(),
      amountColumn: (_unitType == Unit.amount) ? _quantity : -1,
      kgColumn: (_unitType == Unit.kg) ? _quantity : -1,
      litersColumn: (_unitType == Unit.liters) ? _quantity : -1,
    };
    return map;
  }


/*
id: int
    name: str
    price: float
    amount: float | None = -1
    kg: float | None = -1
    liters: float | None = -1*/
  factory Product.fromJson(Map<String, dynamic> json) 
  {
    if(json['amount'] != null && json['amount'] != -1)
    {
      json['quantity'] = json['amount'];
      json['unitType'] = Unit.amount;
    }
    else if(json['kg'] != null && json['kg'] != -1)
    {
      json['quantity'] = json['kg'];
      json['unitType'] = Unit.kg;
    }
    else
    {
      json['quantity'] = json['liters'];
      json['unitType'] = Unit.liters;
    }
    return Product(
      unitType: json['unitType'],
      quantity: json['quantity'],
      name: json['name'],
      price: json['price'],
      productId: json['id']
    );
  }
/*name: str | None
    price: float | None
    amount: float | None = -1
    kg: float | None = -1
    liters: float | None = -1*/
  Map<String, dynamic> toJson() 
  {
    Map<String, dynamic> map = {
      'name': name,
      'price': price,
      'amount': (unitType.label == "amount") ? quantity : -1,
      'kg': (unitType.label == "kg") ? quantity : -1,
      'liters': (unitType.label == "liters") ? quantity : -1,
      'product_id': productId,
      'quantidade': quantity,
      'unidade': unitType.label ,

    };
    return map;
  }

  String get getUnitSymbol 
  {
    switch (_unitType) 
    {
      case Unit.kg:
        return 'kg';
      case Unit.liters:
        return 'L';
      case Unit.amount:
        return 'un';
    }
  }
}

import 'package:dairy/domain/product.dart';

class Order {
  static const String idColumn = "id";
  static const String idOrderColumn = "id_order";
  static const String descriptionColumn = "description";
  static const String totalValueColumn = "total_value";
  static const String statusColumn = "status";

  int? id; 
  int? orderId;
  String? description;
  double? totalValue;
  bool status;
  final List<Product> _products;

  Order({required this.status, this.id, this.description, this.totalValue, List<Product>? products, this.orderId}): _products = products ?? [];

  List<Product> get products => _products;
}
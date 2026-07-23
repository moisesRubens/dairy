import 'package:dairy/domain/order_item.dart';
import 'package:dairy/domain/product.dart';
import 'package:flutter/foundation.dart';

class Order {
  static const String idColumn = "id";
  static const String orderIdColumn = "order_id";
  static const String descriptionColumn = "description";
  static const String totalValueColumn = "total_value";
  static const String statusColumn = "status";
  static const String dateTimeColumn = "date_time";

  int? id; 
  int? orderId;
  String? description;
  double? totalValue;
  bool status;
  final List<Product> _products;
  DateTime dateTime;

  Order({required this.status, this.id, this.description, this.totalValue, List<Product>? products, this.orderId, DateTime? dateTime}): _products = products ?? [],
  dateTime = dateTime ?? DateTime.now();

  List<Product> get products => _products;

  factory Order.fromJson(Map<String, dynamic> map) {
    return Order(
      orderId: map['id'],
      status: map['status'] ?? false,
      description: map['description'] ?? '',
      totalValue: (map['total_value'] ?? 0.0).toDouble(),
      dateTime: DateTime.parse(map['order_date']),
      products: (map['items'] as List?)?.map((item) => Product.fromJson(item)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'status': status,
      'total_value': totalValue,
      'id': orderId,
      'order_date': dateTime.toIso8601String(),
      'items': products.map((item) => item.toJson()).toList(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      orderId: map['order_id'],
      status: map['status'],
      description: map['description'],
      totalValue: map['total_value'],
      dateTime: DateTime.parse(map['date_time']),
      products: []
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'status': status,
      'description': description,
      'total_value': totalValue,
      'date_time': dateTime
    };
  }
}
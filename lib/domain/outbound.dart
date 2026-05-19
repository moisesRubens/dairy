import 'dart:convert';

class Outbound {
  final int? id;
  final int salePointId;
  final int productId;
  int? quantity_to_add;
  final double takenQuantity;
  final String unidade;
  final String? observacao;
  final DateTime data;
  final double soldQuantity;
  final double totalValue;
  final bool status;

  // O construtor principal
  Outbound({
    this.id,
    required this.salePointId,
    required this.productId,
    required this.takenQuantity,
    required this.unidade,
    this.observacao,
    required this.data,
    required this.soldQuantity,
    required this.totalValue,
    this.status = true,
  });

  // Equivalente à propriedade @property do Python: calcula em tempo real
  double get remainingQuantity => takenQuantity - soldQuantity;

  /// Cria uma cópia do objeto alterando apenas os campos necessários (útil para gerência de estado)
  Outbound copyWith({
    int? id,
    int? salePointId,
    int? productId,
    double? takenQuantity,
    String? unidade,
    String? observacao,
    DateTime? data,
    double? soldQuantity,
    double? totalValue,
    bool? status,
  }) {
    return Outbound(
      id: id ?? this.id,
      salePointId: salePointId ?? this.salePointId,
      productId: productId ?? this.productId,
      takenQuantity: takenQuantity ?? this.takenQuantity,
      unidade: unidade ?? this.unidade,
      observacao: observacao ?? this.observacao,
      data: data ?? this.data,
      soldQuantity: soldQuantity ?? this.soldQuantity,
      totalValue: totalValue ?? this.totalValue,
      status: status ?? this.status,
    );
  }

  /// Converte o JSON vindo da sua API FastAPI para o objeto Dart
  factory Outbound.fromMap(Map<String, dynamic> map) {
    return Outbound(
      id: map['id']?.toInt(),
      salePointId: map['sale_point_id']?.toInt() ?? 0,
      productId: map['product_id']?.toInt() ?? 0,
      takenQuantity: map['taken_quantity']?.toDouble() ?? 0.0,
      unidade: map['unidade'] ?? '',
      observacao: map['observacao'],
      // Converte a string de data da API para DateTime do Dart
      data: map['data'] != null ? DateTime.parse(map['data']) : DateTime.now(),
      soldQuantity: map['sold_quantity']?.toDouble() ?? 0.0,
      totalValue: map['total_value']?.toDouble() ?? 0.0,
      status: map['status'] ?? true,
    );
  }

  /// Converte o objeto Dart para um Map (JSON) para enviar de volta à API
  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'quantidade': quantity_to_add,
      'unidade': unidade 
    };
  }

  factory Outbound.fromJson(String source) => Outbound.fromMap(json.decode(source));
  String toJson() => json.encode(toMap());
}
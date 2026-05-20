class Product {
  final int? id;
  final String name;
  final String? description; // Mapeado do seu schema se necessário
  final double? totalValue;  // Note que no SQL é Float, no Dart usamos double
  double? price;
  int? amount;
  double? kg;
  double? liters;

  Product({
    this.id,
    required this.name,
    this.description,
    this.totalValue,
  });

  // O "Coração" da integração: transforma o Map do JSON em objeto Dart
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      name: json['name'] as String,
      // Usamos 'as num?' e '.toDouble()' para evitar erros caso o JSON venha como int ou double
      totalValue: (json['total_value'] as num?)?.toDouble(),
      description: json['description'] as String?,
    );
  }

  // Útil se você precisar enviar um produto de volta para a API (ex: Criar Produto)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'total_value': totalValue,
      'description': description,
    };
  }
}
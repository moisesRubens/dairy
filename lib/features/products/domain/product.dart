import '../../../config/api_config.dart';

class Product {
  final int id;
  final String name;
  final double? price;
  final int? amount;
  final double? kg;
  final double? liters;

  /// Caminho relativo da imagem servida pelo backend (ex.: "/static/products/5.png").
  /// Nulo quando o produto ainda não tem foto.
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    this.price,
    this.amount,
    this.kg,
    this.liters,
    this.imageUrl,
  });

  /// Unidade do produto (um dos três campos vem preenchido).
  String get unitKey =>
      amount != null ? 'amount' : (kg != null ? 'kg' : 'liters');

  String get unitLabel =>
      amount != null ? 'un' : (kg != null ? 'kg' : 'L');

  /// Quantidade ativa em estoque (o campo de unidade preenchido).
  num get quantity => amount ?? kg ?? liters ?? 0;

  /// URL absoluta da foto, pronta para `Image.network`. Nula se não houver
  /// imagem. Estáticos são servidos em `{baseUrl}/static/...`.
  String? get imageAbsoluteUrl =>
      imageUrl == null || imageUrl!.isEmpty ? null : '${ApiConfig.baseUrl}$imageUrl';

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        price: (json['price'] as num?)?.toDouble(),
        amount: (json['amount'] as num?)?.toInt(),
        kg: (json['kg'] as num?)?.toDouble(),
        liters: (json['liters'] as num?)?.toDouble(),
        imageUrl: json['image_url'] as String?,
      );
}

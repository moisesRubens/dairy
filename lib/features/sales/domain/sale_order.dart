/// Pedido (venda) realizado num ponto, COM seus itens — usado na tela de
/// "Vendas por Banca" (admin). Espelha o `OrderResponse` do backend:
/// `item_order` -> items; `order_date` -> date; cada item traz nome, preço
/// (`item_price`) e a quantidade na unidade do produto (amount|kg|liters).
class SaleOrder {
  final int id;
  final bool status;
  final double totalValue;
  final String? description;
  final String? paymentMethod;
  final DateTime? date;
  final List<SaleOrderItem> items;

  SaleOrder({
    required this.id,
    required this.status,
    required this.totalValue,
    required this.items,
    this.description,
    this.paymentMethod,
    this.date,
  });

  factory SaleOrder.fromJson(Map<String, dynamic> json) => SaleOrder(
        id: (json['id'] as num).toInt(),
        status: json['status'] as bool? ?? true,
        totalValue: (json['total_value'] as num?)?.toDouble() ?? 0,
        description: json['description'] as String?,
        paymentMethod: json['payment_method'] as String?,
        date: _parseDate(json['date'] ?? json['order_date']),
        items: ((json['items'] ?? json['item_order']) as List? ?? const [])
            .map((e) => SaleOrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}

class SaleOrderItem {
  final int productId;
  final String name;
  final double price;
  final int? amount;
  final double? kg;
  final double? liters;

  SaleOrderItem({
    required this.productId,
    required this.name,
    required this.price,
    this.amount,
    this.kg,
    this.liters,
  });

  /// Quantidade vendida na unidade preenchida.
  num get quantity => amount ?? kg ?? liters ?? 0;

  String get unitLabel => amount != null ? 'un' : (kg != null ? 'kg' : 'L');

  /// Subtotal da linha (preço unitário × quantidade).
  double get subtotal => price * quantity;

  factory SaleOrderItem.fromJson(Map<String, dynamic> json) => SaleOrderItem(
        productId: (json['product_id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '—',
        price: (json['price'] as num? ?? json['item_price'] as num?)
                ?.toDouble() ??
            0,
        amount: (json['amount'] as num?)?.toInt(),
        kg: (json['kg'] as num?)?.toDouble(),
        liters: (json['liters'] as num?)?.toDouble(),
      );
}

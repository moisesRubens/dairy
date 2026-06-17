/// Retirada (outbound) = estoque que saiu do depósito para um ponto de venda.
/// O ponto vende a partir do `remainingQuantity`. Espelha o
/// `ItemsRetiradaResponseDTO` do backend, que serializa por ALIAS
/// (`data`/`unidade`/`total_value`/`observacao`) — por isso o fromJson aceita
/// tanto o alias quanto o nome do campo.
class Outbound {
  final int id;
  final int productId;
  final String name;
  final bool status;
  final DateTime? date;
  final String unidade; // amount | kg | liters
  final double takenQuantity;
  final double soldQuantity;
  final double remainingQuantity;
  final double totalValue;
  final String? observation;

  Outbound({
    required this.id,
    required this.productId,
    required this.name,
    required this.status,
    required this.unidade,
    required this.takenQuantity,
    required this.soldQuantity,
    required this.remainingQuantity,
    required this.totalValue,
    this.date,
    this.observation,
  });

  String get unitLabel =>
      unidade == 'amount' ? 'un' : (unidade == 'kg' ? 'kg' : 'L');

  factory Outbound.fromJson(Map<String, dynamic> json) => Outbound(
        id: (json['id'] as num).toInt(),
        productId: (json['product_id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '—',
        status: json['status'] as bool? ?? true,
        date: _parseDate(json['data'] ?? json['date']),
        unidade: (json['unidade'] ?? json['unit_type']) as String? ?? 'amount',
        takenQuantity: (json['taken_quantity'] as num?)?.toDouble() ?? 0,
        soldQuantity: (json['sold_quantity'] as num?)?.toDouble() ?? 0,
        remainingQuantity:
            (json['remaining_quantity'] as num?)?.toDouble() ?? 0,
        totalValue:
            ((json['total_value'] ?? json['total_value_item']) as num?)
                    ?.toDouble() ??
                0,
        observation: (json['observacao'] ?? json['observation']) as String?,
      );

  static DateTime? _parseDate(Object? v) =>
      v == null ? null : DateTime.tryParse(v.toString());
}

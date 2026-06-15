enum StockRequestStatus { pending, approved, rejected, cancelled, unknown }

StockRequestStatus statusFromString(String? value) {
  switch (value) {
    case 'PENDING':
      return StockRequestStatus.pending;
    case 'APPROVED':
      return StockRequestStatus.approved;
    case 'REJECTED':
      return StockRequestStatus.rejected;
    case 'CANCELLED':
      return StockRequestStatus.cancelled;
    default:
      return StockRequestStatus.unknown;
  }
}

class StockRequest {
  final int id;
  final int? requestedById;
  final int targetPointId;
  final int productId;
  final String? productName;
  final double quantity;
  final String unidade;
  final StockRequestStatus status;
  final String? reason;
  final DateTime? createdAt;

  StockRequest({
    required this.id,
    required this.requestedById,
    required this.targetPointId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unidade,
    required this.status,
    required this.reason,
    required this.createdAt,
  });

  bool get isPending => status == StockRequestStatus.pending;

  factory StockRequest.fromJson(Map<String, dynamic> json) => StockRequest(
        id: (json['id'] as num).toInt(),
        requestedById: (json['requested_by_id'] as num?)?.toInt(),
        targetPointId: (json['target_point_id'] as num?)?.toInt() ?? 0,
        productId: (json['product_id'] as num?)?.toInt() ?? 0,
        productName: json['product_name'] as String?,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unidade: json['unidade'] as String? ?? '',
        status: statusFromString(json['status'] as String?),
        reason: json['reason'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );
}

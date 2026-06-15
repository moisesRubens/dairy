import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product.dart';
import '../data/stock_request_repository.dart';
import '../domain/stock_request.dart';

class RequestStockPage extends ConsumerWidget {
  const RequestStockPage({super.key});

  Future<void> _request(
      BuildContext context, WidgetRef ref, Product product) async {
    final controller = TextEditingController();
    final qty = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Solicitar ${product.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: 'Quantidade (${product.unitLabel})'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(
                ctx, double.tryParse(controller.text.replaceAll(',', '.'))),
            child: const Text('SOLICITAR'),
          ),
        ],
      ),
    );
    if (qty == null || qty <= 0) return;
    try {
      await ref.read(stockRequestRepositoryProvider).create(
          productId: product.id, quantity: qty, unidade: product.unitKey);
      ref.invalidate(stockRequestsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Solicitação enviada · aguardando aprovação'),
        backgroundColor: AppColors.green,
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(toApiException(e).message),
          backgroundColor: AppColors.red));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final requests = ref.watch(stockRequestsProvider);

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () async {
        ref.invalidate(productsProvider);
        ref.invalidate(stockRequestsProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text('SOLICITAR REPOSIÇÃO',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: AppSpacing.lg),
          AsyncValueWidget<List<Product>>(
            value: products,
            onRetry: () => ref.invalidate(productsProvider),
            data: (list) => Container(
              decoration: BoxDecoration(
                color: context.cardSurface,
                borderRadius: BorderRadius.circular(AppRadii.table),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  for (final p in list)
                    ListTile(
                      title: Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Unidade: ${p.unitLabel}'),
                      trailing: TextButton.icon(
                        onPressed: () => _request(context, ref, p),
                        icon: const Icon(Icons.add_box_outlined, size: 18),
                        label: const Text('SOLICITAR'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('MINHAS SOLICITAÇÕES',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.grey)),
          const SizedBox(height: AppSpacing.sm),
          AsyncValueWidget<List<StockRequest>>(
            value: requests,
            onRetry: () => ref.invalidate(stockRequestsProvider),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'Nenhuma solicitação ainda');
              }
              return Container(
                decoration: BoxDecoration(
                  color: context.cardSurface,
                  borderRadius: BorderRadius.circular(AppRadii.table),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    for (final r in list)
                      ListTile(
                        title: Text(r.productName ?? 'Produto #${r.productId}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${_fmtQty(r.quantity)} ${r.unidade}'),
                        trailing: _StatusChip(status: r.status),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _fmtQty(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}

class _StatusChip extends StatelessWidget {
  final StockRequestStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;
    switch (status) {
      case StockRequestStatus.pending:
        color = const Color(0xFFEF6C00);
        label = 'PENDENTE';
        break;
      case StockRequestStatus.approved:
        color = AppColors.green;
        label = 'APROVADO';
        break;
      case StockRequestStatus.rejected:
        color = AppColors.red;
        label = 'RECUSADO';
        break;
      case StockRequestStatus.cancelled:
        color = AppColors.grey;
        label = 'CANCELADO';
        break;
      case StockRequestStatus.unknown:
        color = AppColors.grey;
        label = '—';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}

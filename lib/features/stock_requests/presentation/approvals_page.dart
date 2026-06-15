import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../metrics/data/metrics_repository.dart';
import '../data/stock_request_repository.dart';
import '../domain/stock_request.dart';

class ApprovalsPage extends ConsumerWidget {
  const ApprovalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(stockRequestsProvider);

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () async => ref.invalidate(stockRequestsProvider),
      child: AsyncValueWidget<List<StockRequest>>(
        value: requests,
        onRetry: () => ref.invalidate(stockRequestsProvider),
        data: (all) {
          final pending = all.where((r) => r.isPending).toList();
          if (pending.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                EmptyState(
                  icon: Icons.check_rounded,
                  title: 'Tudo em dia',
                  subtitle: 'Nenhuma solicitação pendente no momento.',
                  positive: true,
                ),
              ],
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const Text('APROVAÇÕES PENDENTES',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const SizedBox(height: AppSpacing.lg),
              for (final req in pending) ...[
                _RequestCard(request: req),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final StockRequest request;
  const _RequestCard({required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(stockRequestsProvider);
      ref.invalidate(metricsSummaryProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(okMessage), backgroundColor: AppColors.green));
    } catch (e) {
      if (!mounted) return;
      final api = toApiException(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(api.message), backgroundColor: AppColors.red));
      setState(() => _busy = false);
    }
  }

  Future<void> _approve() {
    final repo = ref.read(stockRequestRepositoryProvider);
    final r = widget.request;
    return _run(() => repo.approve(r.id),
        'Reposição aprovada · ${_qty(r)} para o ponto #${r.targetPointId}');
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recusar solicitação?'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Motivo da recusa'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('RECUSAR',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (reason == null) return;
    final repo = ref.read(stockRequestRepositoryProvider);
    await _run(() => repo.reject(widget.request.id,
        reason.isEmpty ? 'Sem estoque disponível' : reason),
        'Solicitação recusada');
  }

  String _qty(StockRequest r) {
    final q = r.quantity == r.quantity.roundToDouble()
        ? r.quantity.toInt().toString()
        : r.quantity.toString();
    return '$q ${r.unidade}';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.revenue),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_outlined,
                  size: 18, color: AppColors.grey),
              const SizedBox(width: AppSpacing.sm),
              Text('Ponto de venda #${r.targetPointId}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(r.productName ?? 'Produto #${r.productId}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Row(
            children: [
              Text('Reposição solicitada:  ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text('+ ${_qty(r)}',
                  style: const TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_busy)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(color: AppColors.green),
            ))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('RECUSAR'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _approve,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('APROVAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

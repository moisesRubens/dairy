import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../auth/application/auth_controller.dart';
import '../data/stock_repository.dart';
import '../domain/outbound.dart';

/// "Meu Estoque" (vendedor): as retiradas do ponto — o que foi retirado do
/// depósito, quanto já vendeu e quanto resta para vender. Ao fim do dia, o
/// vendedor pode devolver o restante ao depósito.
class StockPage extends ConsumerWidget {
  const StockPage({super.key});

  /// Cor do restante (prevenção de erro / visibilidade): esgotado, baixo, ok.
  Color _remainingColor(double remaining) {
    if (remaining <= 0) return AppColors.red;
    if (remaining <= 5) return const Color(0xFFB8860B); // âmbar
    return AppColors.green;
  }

  Future<void> _returnRemaining(BuildContext context, WidgetRef ref) async {
    final salePointId = ref.read(currentSalePointIdProvider);
    if (salePointId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Devolver restante ao estoque'),
        content: const Text(
            'Devolver ao depósito o que sobrou das retiradas de HOJE? '
            'Use ao fechar o dia.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('DEVOLVER',
                  style: TextStyle(color: AppColors.green))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(stockRepositoryProvider).returnRemaining(salePointId);
      ref.invalidate(myStockProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Restante devolvido ao estoque'),
          backgroundColor: AppColors.green));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(toApiException(e).message),
          backgroundColor: AppColors.red));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stock = ref.watch(myStockProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _returnRemaining(context, ref),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.assignment_return_outlined),
        label: const Text('DEVOLVER'),
      ),
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () async => ref.invalidate(myStockProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const Text('MEU ESTOQUE',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.sm),
            const Text('Retiradas do ponto — o que há para vender',
                style: TextStyle(color: AppColors.grey, fontSize: 12)),
            const SizedBox(height: AppSpacing.lg),
            AsyncValueWidget<List<Outbound>>(
              value: stock,
              onRetry: () => ref.invalidate(myStockProvider),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Nenhuma retirada',
                      subtitle:
                          'Solicite reposição na aba "Solicitar" para receber '
                          'estoque.');
                }
                return Container(
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(AppRadii.table),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < list.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: context.borderColor),
                        _OutboundTile(
                            o: list[i], color: _remainingColor(list[i].remainingQuantity)),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _OutboundTile extends StatelessWidget {
  final Outbound o;
  final Color color;
  const _OutboundTile({required this.o, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(o.name,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
          'Retirado ${o.takenQuantity.toStringAsFixed(0)} · '
          'Vendido ${o.soldQuantity.toStringAsFixed(0)} ${o.unitLabel}'
          '${o.observation != null && o.observation!.isNotEmpty ? '\n${o.observation}' : ''}',
          style: const TextStyle(color: AppColors.grey, fontSize: 12)),
      isThreeLine: o.observation != null && o.observation!.isNotEmpty,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${o.remainingQuantity.toStringAsFixed(0)} ${o.unitLabel}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const Text('resta',
              style: TextStyle(color: AppColors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}

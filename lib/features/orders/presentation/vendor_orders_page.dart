import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/format/formatters.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';

class VendorOrdersPage extends ConsumerWidget {
  const VendorOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () async => ref.invalidate(ordersProvider),
      child: AsyncValueWidget<List<Order>>(
        value: orders,
        onRetry: () => ref.invalidate(ordersProvider),
        data: (list) {
          if (list.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Nenhuma venda hoje',
                    subtitle: 'As vendas do dia aparecem aqui.'),
              ],
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const Text('PEDIDOS DE HOJE',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const SizedBox(height: AppSpacing.lg),
              Container(
                decoration: BoxDecoration(
                  color: context.cardSurface,
                  borderRadius: BorderRadius.circular(AppRadii.table),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    for (final o in list)
                      ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text('Pedido #${o.id}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(_time(o.date)),
                        trailing: Text(currencyBRL(o.totalValue),
                            style: const TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _time(DateTime? d) {
    if (d == null) return '';
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

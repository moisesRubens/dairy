import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/format/formatters.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../data/client_repository.dart';
import '../domain/client.dart';

class ClientHistoryPage extends ConsumerWidget {
  final Client client;
  const ClientHistoryPage({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(clientHistoryProvider(client.id));

    return Scaffold(
      appBar: AppBar(title: Text(client.name)),
      body: AsyncValueWidget<ClientHistory>(
        value: history,
        onRetry: () => ref.invalidate(clientHistoryProvider(client.id)),
        data: (h) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Card hero: total gasto pelo cliente (base do relacionamento).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(AppRadii.revenue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL GASTO',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          letterSpacing: 1)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(currencyBRL(h.totalSpent),
                      style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  Text('${h.ordersCount} compra(s)',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            if (client.phone != null && client.phone!.isNotEmpty ||
                client.email != null && client.email!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.sm, children: [
                if (client.phone != null && client.phone!.isNotEmpty)
                  _contactChip(context, Icons.phone, client.phone!),
                if (client.email != null && client.email!.isNotEmpty)
                  _contactChip(context, Icons.email_outlined, client.email!),
              ]),
            ],
            const SizedBox(height: AppSpacing.xl),
            const Text('COMPRAS',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.grey)),
            const SizedBox(height: AppSpacing.sm),
            if (h.orders.isEmpty)
              const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Nenhuma compra ainda')
            else
              Container(
                decoration: BoxDecoration(
                  color: context.cardSurface,
                  borderRadius: BorderRadius.circular(AppRadii.table),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    for (final o in h.orders)
                      ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text('Pedido #${o.id}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(_fmtDate(o.date)),
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
        ),
      ),
    );
  }

  Widget _contactChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.mutedSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.grey),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm  $hh:$mi';
  }
}

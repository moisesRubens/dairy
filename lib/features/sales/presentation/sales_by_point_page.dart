import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/format/formatters.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../data/sales_by_point_repository.dart';
import '../domain/sale_order.dart';

/// Detalhe de "Vendas por Banca" (admin): tudo o que foi vendido num ponto —
/// cada pedido com seus itens (produto, qtd+unidade, valor), forma de pagamento
/// e data, mais o total geral do ponto. Própria Scaffold (rota empilhada).
class SalesByPointPage extends ConsumerWidget {
  final int salePointId;
  final String salePointName;

  const SalesByPointPage({
    super.key,
    required this.salePointId,
    required this.salePointName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(salesByPointProvider(salePointId));

    return Scaffold(
      appBar: AppBar(title: Text(salePointName)),
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () async =>
            ref.invalidate(salesByPointProvider(salePointId)),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const Text('VENDAS DA BANCA',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.lg),
            AsyncValueWidget<List<SaleOrder>>(
              value: orders,
              onRetry: () =>
                  ref.invalidate(salesByPointProvider(salePointId)),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Nenhuma venda',
                      subtitle: 'Esta banca ainda não registrou pedidos.');
                }
                final total =
                    list.fold<double>(0, (s, o) => s + o.totalValue);
                final sorted = [...list]
                  ..sort((a, b) => (b.date ?? DateTime(0))
                      .compareTo(a.date ?? DateTime(0)));
                return Column(
                  children: [
                    _TotalCard(total: total, count: list.length),
                    const SizedBox(height: AppSpacing.lg),
                    for (final o in sorted) ...[
                      _OrderCard(order: o),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Faturamento total do ponto — cartão preto (idioma de receita do app).
class _TotalCard extends StatelessWidget {
  final double total;
  final int count;
  const _TotalCard({required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(AppRadii.revenue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TOTAL VENDIDO',
              style: TextStyle(
                  color: Colors.white70, fontSize: 13, letterSpacing: 1)),
          const SizedBox(height: AppSpacing.sm),
          Text(currencyBRL(total),
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          Text('$count ${count == 1 ? 'pedido' : 'pedidos'}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Um pedido com seus itens, forma de pagamento e data.
class _OrderCard extends StatelessWidget {
  final SaleOrder order;
  const _OrderCard({required this.order});

  // Padrão numérico (independente de locale) — evita exigir
  // initializeDateFormatting('pt_BR'), que não é chamado no app.
  static final _dateFmt = DateFormat("dd/MM/yyyy 'às' HH:mm");

  static const _payments = {
    'dinheiro': ('Dinheiro', Icons.payments_outlined),
    'pix': ('Pix', Icons.qr_code_2),
    'cartao': ('Cartão', Icons.credit_card),
  };

  @override
  Widget build(BuildContext context) {
    final pay = _payments[order.paymentMethod];
    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.table),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md,
                AppSpacing.lg, AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                      order.date != null
                          ? _dateFmt.format(order.date!)
                          : 'Pedido #${order.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                if (pay != null)
                  Row(
                    children: [
                      Icon(pay.$2, size: 14, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Text(pay.$1,
                          style: const TextStyle(
                              color: AppColors.grey, fontSize: 12)),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                            '${_fmtQty(item.quantity)} ${item.unitLabel} · ${currencyBRL(item.price)}/${item.unitLabel}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(currencyBRL(item.subtotal),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL DO PEDIDO',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5)),
                Text(currencyBRL(order.totalValue),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtQty(num q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}

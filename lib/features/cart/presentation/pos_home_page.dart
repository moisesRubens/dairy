import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/format/formatters.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../clients/data/client_repository.dart';
import '../../clients/domain/client.dart';
import '../../orders/data/order_repository.dart';
import '../../products/data/product_repository.dart';
import '../../products/domain/product.dart';
import '../application/cart_provider.dart';

class PosHomePage extends ConsumerWidget {
  const PosHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final cart = ref.watch(cartProvider);
    final revenue = ref.watch(vendorTodayRevenueProvider);

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () async {
        ref.invalidate(productsProvider);
        ref.invalidate(ordersProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _RevenueCard(revenue: revenue),
          const SizedBox(height: AppSpacing.xl),
          const Text('PRODUTOS',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.grey)),
          const SizedBox(height: AppSpacing.sm),
          AsyncValueWidget<List<Product>>(
            value: products,
            onRetry: () => ref.invalidate(productsProvider),
            data: (list) {
              if (list.isEmpty) {
                return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Nenhum produto');
              }
              return Container(
                decoration: BoxDecoration(
                  color: context.cardSurface,
                  borderRadius: BorderRadius.circular(AppRadii.table),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    for (final p in list) _ProductRow(product: p),
                  ],
                ),
              );
            },
          ),
          if (cart.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const _CartSection(),
          ],
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final double revenue;
  const _RevenueCard({required this.revenue});

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
          const Text('FATURAMENTO DO DIA',
              style:
                  TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1)),
          const SizedBox(height: AppSpacing.sm),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: revenue),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (context, value, _) => Text(currencyBRL(value),
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends ConsumerStatefulWidget {
  final Product product;
  const _ProductRow({required this.product});

  @override
  ConsumerState<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends ConsumerState<_ProductRow> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final qty = double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0;
    if (qty <= 0) return;
    ref.read(cartProvider.notifier).add(widget.product, qty);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${currencyBRL(p.price ?? 0)} / ${p.unitLabel}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            child: TextField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'Qtd',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: _add,
            icon: const Icon(Icons.add_circle, color: AppColors.green),
          ),
        ],
      ),
    );
  }
}

class _CartSection extends ConsumerStatefulWidget {
  const _CartSection();

  @override
  ConsumerState<_CartSection> createState() => _CartSectionState();
}

class _CartSectionState extends ConsumerState<_CartSection> {
  bool _busy = false;

  Future<void> _checkout() async {
    setState(() => _busy = true);
    final total = ref.read(cartProvider.notifier).total;
    try {
      await ref.read(cartProvider.notifier).checkout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Venda finalizada · ${currencyBRL(total)}'),
        backgroundColor: AppColors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      final api = toApiException(e);
      final msg = api.statusCode == 409
          ? 'Sem estoque suficiente no ponto para esta venda.'
          : api.message;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.red));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickClient() async {
    List<Client> clients = const [];
    try {
      clients = await ref.read(clientRepositoryProvider).list();
    } catch (_) {}
    if (!mounted) return;
    final result = await showModalBottomSheet<Object?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.flash_on, color: AppColors.green),
              title: const Text('Venda rápida (sem cliente)'),
              onTap: () => Navigator.pop(ctx, 'rapida'),
            ),
            const Divider(height: 1),
            for (final c in clients)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(c.name),
                subtitle: (c.phone != null && c.phone!.isNotEmpty)
                    ? Text(c.phone!)
                    : null,
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (result == 'rapida') {
      ref.read(selectedClientProvider.notifier).state = null;
    } else if (result is Client) {
      ref.read(selectedClientProvider.notifier).state = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).total;

    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.table),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          _ClientSelector(onPick: _pickClient),
          const Divider(height: 1),
          for (final line in cart)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                        '${line.product.name}  ·  ${_fmtQty(line.quantity)} ${line.product.unitLabel}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Text(currencyBRL(line.subtotal),
                      style: const TextStyle(
                          color: AppColors.green, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.red, size: 20),
                    onPressed: () =>
                        ref.read(cartProvider.notifier).remove(line.product.id),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(currencyBRL(total),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.green)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _checkout,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.white),
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: AppColors.white, strokeWidth: 2))
                        : const Text('FINALIZAR VENDA',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtQty(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}

class _ClientSelector extends ConsumerWidget {
  final VoidCallback onPick;
  const _ClientSelector({required this.onPick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(selectedClientProvider);
    return ListTile(
      leading: Icon(client == null ? Icons.flash_on : Icons.person,
          color: AppColors.green),
      title: Text(client?.name ?? 'Venda rápida (sem cliente)',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(client == null
          ? 'Toque para vincular um cliente'
          : 'Cliente vinculado à venda'),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey),
      onTap: onPick,
    );
  }
}

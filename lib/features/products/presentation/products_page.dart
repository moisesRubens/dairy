import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../core/format/formatters.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';

/// Gestão de catálogo/estoque (admin): listar, cadastrar, editar e excluir
/// produtos. A unidade de medida (un/kg/L) é única por produto.
class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  static const _units = [
    ('amount', 'un'),
    ('kg', 'kg'),
    ('liters', 'L'),
  ];

  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {Product? existing}) async {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
        text: existing?.price != null
            ? existing!.price!.toStringAsFixed(2).replaceAll('.', ',')
            : '');
    final qtyCtrl = TextEditingController(
        text: existing != null ? _quantityOf(existing).toString() : '');
    var unit = existing?.unitKey ?? 'amount';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(isEdit ? 'Editar produto' : 'Novo produto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Nome *')),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                    controller: priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Preço (R\$) *')),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                              labelText: 'Quantidade *')),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    DropdownButton<String>(
                      value: unit,
                      onChanged: (v) => setState(() => unit = v ?? unit),
                      items: [
                        for (final (key, label) in _units)
                          DropdownMenuItem(value: key, child: Text(label)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('CANCELAR')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('SALVAR')),
          ],
        ),
      ),
    );
    if (ok != true) return;

    final name = nameCtrl.text.trim();
    final price = _parseNum(priceCtrl.text);
    final qty = _parseNum(qtyCtrl.text);
    if (name.isEmpty || price == null || qty == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Preencha nome, preço e quantidade válidos'),
          backgroundColor: AppColors.red));
      return;
    }

    try {
      final repo = ref.read(productRepositoryProvider);
      if (isEdit) {
        await repo.update(existing.id,
            name: name, price: price, unit: unit, quantity: qty);
      } else {
        await repo.create(
            name: name, price: price, unit: unit, quantity: qty);
      }
      ref.invalidate(productsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEdit ? 'Produto atualizado' : 'Produto cadastrado'),
          backgroundColor: AppColors.green));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(toApiException(e).message),
          backgroundColor: AppColors.red));
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir produto'),
        content: Text('Excluir "${product.name}"? Esta ação não pode ser '
            'desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('EXCLUIR',
                  style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(productRepositoryProvider).delete(product.id);
      ref.invalidate(productsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Produto excluído'), backgroundColor: AppColors.green));
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

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('NOVO'),
      ),
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () async => ref.invalidate(productsProvider),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const Text('PRODUTOS',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.lg),
            AsyncValueWidget<List<Product>>(
              value: products,
              onRetry: () => ref.invalidate(productsProvider),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Nenhum produto ainda',
                      subtitle: 'Cadastre o primeiro no botão NOVO.');
                }
                return Container(
                  decoration: BoxDecoration(
                    color: context.cardSurface,
                    borderRadius: BorderRadius.circular(AppRadii.table),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    children: [
                      for (final p in list)
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: context.mutedSurface,
                            child: const Icon(Icons.inventory_2_outlined,
                                color: AppColors.grey),
                          ),
                          title: Text(p.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(currencyBRL(p.price ?? 0)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${_quantityOf(p)} ${p.unitLabel}',
                                  style: const TextStyle(
                                      color: AppColors.grey, fontSize: 13)),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert,
                                    color: AppColors.grey),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openForm(context, ref, existing: p);
                                  } else if (value == 'delete') {
                                    _delete(context, ref, p);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(Icons.edit_outlined),
                                          title: Text('Editar'))),
                                  PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(Icons.delete_outline,
                                              color: AppColors.red),
                                          title: Text('Excluir',
                                              style: TextStyle(
                                                  color: AppColors.red)))),
                                ],
                              ),
                            ],
                          ),
                        ),
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

  /// Quantidade ativa do produto (o campo de unidade que veio preenchido).
  static num _quantityOf(Product p) => p.amount ?? p.kg ?? p.liters ?? 0;

  /// Aceita vírgula decimal (pt-BR): "5,50" -> 5.5.
  static double? _parseNum(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));
}

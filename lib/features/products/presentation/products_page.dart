import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme.dart';
import '../../../core/format/formatters.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../data/product_repository.dart';
import '../domain/product.dart';
import 'widgets/product_image.dart';

/// Gestão de catálogo/estoque (admin) como **grade de cards de reconhecimento**:
/// foto, nome, preço e badge de estoque colorido. Toque grande edita; busca por
/// nome filtra. A unidade de medida (un/kg/L) é única por produto.
class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('NOVO'),
      ),
      body: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () async => ref.invalidate(productsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PRODUTOS',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Buscar produto…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.md),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
              sliver: _ProductsBody(
                products: products,
                query: _query,
                onEdit: (p) => _openForm(context, existing: p),
                onDelete: (p) => _delete(context, p),
                onRetry: () => ref.invalidate(productsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Product? existing}) async {
    final result = await showDialog<_ProductFormResult>(
      context: context,
      builder: (ctx) => _ProductFormDialog(existing: existing),
    );
    if (result == null) return;

    final repo = ref.read(productRepositoryProvider);
    final isEdit = existing != null;
    try {
      int id;
      if (isEdit) {
        await repo.update(existing.id,
            name: result.name,
            price: result.price,
            unit: result.unit,
            quantity: result.quantity);
        id = existing.id;
      } else {
        final created = await repo.create(
            name: result.name,
            price: result.price,
            unit: result.unit,
            quantity: result.quantity);
        id = created.id;
      }

      // Foto (opcional): só sobe se o admin escolheu uma imagem nova.
      if (result.imageBytes != null) {
        await repo.uploadImage(id, result.imageBytes!,
            filename: result.imageName ?? 'produto.jpg');
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

  Future<void> _delete(BuildContext context, Product product) async {
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
}

/// Corpo da grade — separa loading/empty/erro do cabeçalho fixo (busca).
class _ProductsBody extends StatelessWidget {
  final AsyncValue<List<Product>> products;
  final String query;
  final void Function(Product) onEdit;
  final void Function(Product) onDelete;
  final VoidCallback onRetry;

  const _ProductsBody({
    required this.products,
    required this.query,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return products.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(48),
          child:
              Center(child: CircularProgressIndicator(color: AppColors.green)),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: ErrorView(message: e.toString(), onRetry: onRetry),
      ),
      data: (all) {
        if (all.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'Nenhum produto ainda',
                subtitle: 'Cadastre o primeiro no botão NOVO.'),
          );
        }
        final list = query.isEmpty
            ? all
            : all
                .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
                .toList();
        if (list.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyState(
                icon: Icons.search_off,
                title: 'Nada encontrado',
                subtitle: 'Tente outro nome de produto.'),
          );
        }
        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.72,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => _ProductCard(
              product: list[i],
              onEdit: () => onEdit(list[i]),
              onDelete: () => onDelete(list[i]),
            ),
            childCount: list.length,
          ),
        );
      },
    );
  }
}

/// Card de reconhecimento: foto grande, nome, preço e badge de estoque.
/// Toque grande edita (área de toque generosa = lei de Fitts).
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.cardSurface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ProductImage(
                      product: product,
                      size: double.infinity,
                      radius: AppRadii.card,
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: _StockBadge(product: product),
                  ),
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: _CardMenu(onEdit: onEdit, onDelete: onDelete),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                        '${currencyBRL(product.price ?? 0)} / ${product.unitLabel}',
                        style: const TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CardMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppColors.white, size: 20),
        tooltip: 'Ações',
        onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
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
                  leading: Icon(Icons.delete_outline, color: AppColors.red),
                  title: Text('Excluir',
                      style: TextStyle(color: AppColors.red)))),
        ],
      ),
    );
  }
}

/// Badge de estoque colorido (prevenção de erro de Nielsen): vermelho = zerado,
/// âmbar = baixo, verde = ok. Quantidade visível para reconhecimento rápido.
class _StockBadge extends StatelessWidget {
  final Product product;
  const _StockBadge({required this.product});

  static const double _lowThreshold = 5;
  static const Color _amber = Color(0xFFF39C12);

  @override
  Widget build(BuildContext context) {
    final qty = product.quantity;
    final (Color color, String label) = qty <= 0
        ? (AppColors.red, 'Sem estoque')
        : qty <= _lowThreshold
            ? (_amber, 'Baixo · ${_fmt(qty)} ${product.unitLabel}')
            : (AppColors.green, '${_fmt(qty)} ${product.unitLabel}');

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }

  static String _fmt(num q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}

/// Resultado do formulário: dados + foto opcional escolhida (bytes + nome).
class _ProductFormResult {
  final String name;
  final double price;
  final String unit;
  final double quantity;
  final Uint8List? imageBytes;
  final String? imageName;

  _ProductFormResult({
    required this.name,
    required this.price,
    required this.unit,
    required this.quantity,
    this.imageBytes,
    this.imageName,
  });
}

/// Formulário de criar/editar produto, agora com seleção de FOTO (galeria).
class _ProductFormDialog extends StatefulWidget {
  final Product? existing;
  const _ProductFormDialog({this.existing});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  static const _units = [
    ('amount', 'un'),
    ('kg', 'kg'),
    ('liters', 'L'),
  ];

  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _qtyCtrl;
  late String _unit;

  Uint8List? _pickedBytes;
  String? _pickedName;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _priceCtrl = TextEditingController(
        text: e?.price != null
            ? e!.price!.toStringAsFixed(2).replaceAll('.', ',')
            : '');
    _qtyCtrl = TextEditingController(
        text: e != null ? _fmtQty(e.quantity) : '');
    _unit = e?.unitKey ?? 'amount';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedBytes = bytes;
        _pickedName = file.name;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível abrir a galeria'),
          backgroundColor: AppColors.red));
    }
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final price = _parseNum(_priceCtrl.text);
    final qty = _parseNum(_qtyCtrl.text);
    if (name.isEmpty || price == null || qty == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Preencha nome, preço e quantidade válidos'),
          backgroundColor: AppColors.red));
      return;
    }
    Navigator.pop(
      context,
      _ProductFormResult(
        name: name,
        price: price,
        unit: _unit,
        quantity: qty,
        imageBytes: _pickedBytes,
        imageName: _pickedName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final existingUrl = widget.existing?.imageAbsoluteUrl;

    return AlertDialog(
      title: Text(isEdit ? 'Editar produto' : 'Novo produto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: context.mutedSurface,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        border: Border.all(color: context.borderColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _pickedBytes != null
                          ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
                          : existingUrl != null
                              ? Image.network(existingUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _photoHint())
                              : _photoHint(),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(_pickedBytes != null || existingUrl != null
                        ? 'Trocar foto'
                        : 'Adicionar foto'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
                controller: _nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome *')),
            const SizedBox(height: AppSpacing.sm),
            TextField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Preço (R\$) *')),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                      controller: _qtyCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Quantidade *')),
                ),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<String>(
                  value: _unit,
                  onChanged: (v) => setState(() => _unit = v ?? _unit),
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
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR')),
        TextButton(onPressed: _submit, child: const Text('SALVAR')),
      ],
    );
  }

  Widget _photoHint() => const Center(
        child: Icon(Icons.add_a_photo_outlined, color: AppColors.grey),
      );

  static String _fmtQty(num q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  /// Aceita vírgula decimal (pt-BR): "5,50" -> 5.5.
  static double? _parseNum(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));
}

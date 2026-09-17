import '../widgets/product_card.dart';
import 'package:dairy/controllers/outbound_controller.dart';
import 'package:dairy/controllers/product_controller.dart';
import 'package:dairy/controllers/sale_point_controller.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '../domain/product.dart';
import '../services/product_service.dart';
import '../services/outbound_service.dart';
import '../database/product_dao.dart';
import '../services/auth_service.dart';
import '../Enums/product_enum.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => InventoryPageState();
}

class InventoryPageState extends State<InventoryPage> with RouteAware {
  late final ProductController _productController;
  late final SalePointController _salePointController;

  int? _expandedProductId;
  final Set<int> _selectedProductIds = {};
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _quantityFocusNode = FocusNode();

  @override
  void initState({
    ProductController? productController,
    SalePointController? salePointController,
    OutboundController? outboundContrller,
  }) {
    super.initState();
    _productController = productController ?? ProductController();
    _salePointController = salePointController ?? SalePointController();
    print("DENTRO DE INTI");
    _productController.refreshProducts();
  }

  @override
  void didPush() {
    super.didPush();
    print("DENTRO DE PUSH");
    _productController.refreshProducts();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    print("DENTRO DE POP");
    _productController.refreshProducts();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  void _showAddProductDialog(BuildContext context) async {
    final Product? product = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddProductDialog(),
    );

    if (product == null) return;

    final bool success = await _productController.add(product);
    if (success) {
      _showSnackBar(
        context,
        "Produto criado ao estoque",
        const Color(0xFF2E7D32),
      );
      return;
    }
    _showSnackBar(context, "Erro ao criar produto ao estoque", Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Product>>(
      valueListenable: _productController.productsData,
      builder: (context, products, child) {
        return Column(
          children: [
            if (_productController.isLoading.value)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _productController.refreshProducts,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_salePointController.isAdmin)
                          _buildHeaderCard(context, products.length),

                        const SizedBox(height: 20),

                        if (products.isEmpty)
                          const Center(
                            child: Text('Nenhum produto encontrado.'),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.75,
                                ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(
                                context,
                                products[index],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_selectedProductIds.isNotEmpty)
              _buildBottomQuantitySelector(context),
          ],
        );
      },
    );
  }

  Widget _buildHeaderCard(BuildContext context, int productCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ESTOQUE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$productCount produtos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => {_showAddProductDialog(context)},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text(
              'NOVO PRODUTO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MÉTODOS AUXILIARES
  // ============================================================
  String _formatQuantity(num? quantity) {
    if (quantity == null) return "0";
    if (quantity is int) return quantity.toString();
    String formatted = quantity.toStringAsFixed(2).replaceAll('.', ',');
    if (formatted.contains(',')) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      if (formatted.endsWith(',')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
    }
    return formatted;
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final bool isSelected = _selectedProductIds.contains(product.productId);
    final bool isExpanded = _expandedProductId == product.productId;
    num? quantity = product.quantity;
    Unit unit = product.unitType;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedProductId = isExpanded ? null : product.productId;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? Colors.black : Colors.grey[300]!,
            width: isExpanded ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(245, 245, 245, 1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    product.name ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'R\$ ${product.price?.toStringAsFixed(2).replaceAll('.', ',') ?? "0,00"}',
                        style: const TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_formatQuantity(product.quantity)}  ${product.getUnitSymbol}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: isSelected,
                            activeColor: Colors.black,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedProductIds.add(product.productId!);
                                } else {
                                  _selectedProductIds.remove(
                                    product.productId!,
                                  );
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Estoque: ${_formatQuantity(quantity)} $unit",
                      style: const TextStyle(fontSize: 12),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _handleEdit(context, product),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Color(0xFFE74C3C),
                          ),
                          onPressed: () => _showDeleteDialog(context, product),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PAINEL INFERIOR — igual à print
  // ============================================================
  Widget _buildBottomQuantitySelector(BuildContext context) {
    final int count = _selectedProductIds.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ITENS SELECIONADOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$count item(s) selecionado(s)',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: TextField(
              controller: _quantityController,
              focusNode: _quantityFocusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[900],
                isDense: true,
                hintText: 'Qtd',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _handleOutboundCreation(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'REGISTRAR SAÍDA',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOutboundCreation(BuildContext context) async {
    final String quantityText = _quantityController.text.replaceAll(',', '.');
    final double? quantity = double.tryParse(quantityText);

    if (quantity == null || quantity <= 0) {
      _showSnackBar(
        context,
        'Por favor, insira uma quantidade válida.',
        Colors.red,
      );
      return;
    }

    if (_selectedProductIds.isEmpty) {
      _showSnackBar(
        context,
        'Selecione pelo menos um produto para registrar a saída.',
        Colors.red,
      );
      return;
    }

    List<Product> productsToRetire = _productController.productsData.value
        .where((product) => _selectedProductIds.contains(product.productId))
        .toList();
    print("PRODUTOS PRA RETIRAR: $productsToRetire");

    final bool success = await _salePointController.createOutbound(
      productsToRetire,
      quantity,
      "",
    );
    print("SUCESSO: $success");
    if (success) {
      _showSnackBar(
        context,
        'Saída de ${_selectedProductIds.length} item(s) registrado(s) com sucesso!',
        const Color(0xFF2E7D32),
      );
      setState(() {
        _selectedProductIds.clear();
      });
      _quantityController.clear();
      _quantityFocusNode.unfocus();
      await OutboundService.refreshProducts();
    } else {
      _showSnackBar(
        context,
        'Falha ao registrar saída. Verifique a conexão ou tente novamente',
        Colors.red,
      );
    }
  }

  // ============================================================
  // AÇÕES AUXILIARES
  // ============================================================
  void _handleEdit(BuildContext context, product) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Editar: ${product.name}')));
  }

  void _showDeleteDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Excluir Produto?',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Deseja realmente remover ${product.name} do estoque?',
          style: const TextStyle(color: Color(0xFF333333)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text(
              'CANCELAR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text(
              'EXCLUIR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }
}

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  Unit? _selectedUnit = Unit.amount;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _handleSave(BuildContext context) {
    final Product product = Product(
      unitType: _selectedUnit!,
      quantity: double.parse(_quantityController.text.trim()),
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
    );
    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Produto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SetInput(label: 'Nome', controller: _nameController),
            const SizedBox(height: 12),
            SetInput(label: 'Preço', controller: _priceController),
            const SizedBox(height: 12),
            SetInput(label: 'Quantidade', controller: _quantityController),
            const SizedBox(height: 12),
            DropdownButtonFormField<Unit>(
              value: _selectedUnit,
              decoration: const InputDecoration(
                labelText: 'TIPO DA UNIDADE',
                border: OutlineInputBorder(),
              ),
              items: Unit.values
                  .map((u) => DropdownMenuItem(value: u, child: Text(u.label)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedUnit = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _handleSave(context),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

// ============================================================
// CREATION PRODUCT CARD
// ============================================================

class CreationProductCard extends StatefulWidget {
  const CreationProductCard({super.key});

  @override
  State<CreationProductCard> createState() => _CreationProductCardState();
}

class _CreationProductCardState extends State<CreationProductCard> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          const Text(
            "Criação de produto",
            style: TextStyle(fontSize: 13, color: Colors.red),
          ),
          const SizedBox(height: 12),
          SetInput(label: 'Nome', controller: _nameController),
          const SizedBox(height: 12),
          SetInput(label: 'Preço', controller: _priceController),
          const SizedBox(height: 12),
          SetInput(label: 'Quantidade', controller: _quantityController),
        ],
      ),
    );
  }
}

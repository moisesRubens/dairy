import 'package:dairy/Enums/product_enum.dart';
import 'package:dairy/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../domain/product.dart';
import '../services/outbound_service.dart';
import '../controllers/sale_point_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static final GlobalKey<HomePageState> homeKey = GlobalKey<HomePageState>();

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final SalePointController _salePointController = SalePointController();
  final ScrollController _scrollController = ScrollController();
  double dailyRevenue = 1250.50;
  List<Product> products = [];
  bool _isLoading = true;
  bool _isReturning = false;
  List<Map<String, dynamic>> cart = [];
  final Map<int, TextEditingController> _quantityControllers = {};

  TextEditingController _quantityControllerFor(Product product) {
    final key = product.productId ?? product.id ?? identityHashCode(product);
    return _quantityControllers.putIfAbsent(
      key,
      TextEditingController.new,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset <= 0) return;
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void scrollToTopNow() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(0);
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    await OutboundService.refreshProducts();
    await _loadDailyRevenue();
    setState(() => _isLoading = false);
  }

  Future<void> _loadDailyRevenue() async {
    try {
      final revenue = await _salePointController.getTodayRevenue();
      setState(() {
        dailyRevenue = revenue;
      });
      debugPrint('💰 Faturamento do dia: R\$ $revenue');
    } catch (e) {
      debugPrint('❌ Erro ao carregar faturamento: $e');
    }
  }

  Future<void> _returnProductsToStock() async {
    if (_isReturning) return;

    final shouldReturn = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar retorno'),
          content: const Text(
            'Deseja realmente retornar os produtos ao estoque?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (shouldReturn != true) return;

    setState(() => _isReturning = true);

    try {
      final success = await _salePointController.retornarProdutosAoEstoque();

      if (success) {
        setState(() {
          cart.clear();
        });

        await OutboundService.refreshProducts();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Produtos retornados ao estoque com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erro ao retornar produtos. Tente novamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isReturning = false);
      }
    }
  }


  bool addToCart(Product product, double quantity) {
    if (quantity <= 0) return false;

    final existingIndex = cart.indexWhere(
      (item) => (item['product'] as Product).productId == product.productId,
    );
    final quantityInCart = existingIndex == -1
        ? 0.0
        : cart[existingIndex]['quantity'] as double;

    if (quantity + quantityInCart > product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quantidade indisponível. Você possui '
            '${product.quantity.toStringAsFixed(product.unitType == Unit.amount ? 0 : 2).replaceAll('.', ',')} ${product.getUnitSymbol}',
          ),
          backgroundColor: Colors.orange[800],
        ),
      );
      return false;
    }

    setState(() {
      if (existingIndex != -1) {
        cart[existingIndex]['quantity'] = quantityInCart + quantity;
      } else {
        cart.add({
          'name': product.name,
          'price': product.price ?? 0.0,
          'unit': product.getUnitSymbol,
          'quantity': quantity,
          'product': product,
        });
      }
    });
    return true;
  }

  void _addProductFromController(
    Product product,
    TextEditingController controller,
  ) {
    FocusScope.of(context).unfocus();
    final normalized = controller.text.trim().replaceAll(',', '.');
    final quantity = double.tryParse(normalized);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite uma quantidade válida. Ex.: 1,5 ou 1.5'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (addToCart(product, quantity)) {
      controller.clear();
    }
  }

  void removeFromCart(String productName) {
    setState(() {
      cart.removeWhere((item) => item['name'] == productName);
    });
  }

  double getTotalValue() {
    return cart.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  Future<void> _finalizarVenda() async {
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Carrinho vazio! Adicione produtos.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final List<Product> productsToSell = cart.map((item) {
      return Product.fromMap(item);
    }).toList();

    final success = await _salePointController.fazerVenda(
      productsToSell,
      description: 'Venda do dia ${DateTime.now().toLocal().toString().split(' ')[0]}',
      totalValue: getTotalValue(),
    );

    if (success) {
      setState(() {
        cart.clear();
      });
      _loadDailyRevenue();
      await OutboundService.refreshProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Venda finalizada com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${_salePointController.errorMessage.value ?? "Erro ao finalizar venda"}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              _buildRevenueCard(),
              if (cart.isNotEmpty) _buildCartSection(),
              const SizedBox(height: 20),
              _buildProductTable(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets de apoio ---

  Widget _buildRevenueCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Faturamento do Dia', style: TextStyle(color: Colors.white, fontSize: 16)),
              _buildReturnButton(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'R\$ ${dailyRevenue.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnButton() {
    return ElevatedButton.icon(
      onPressed: _isReturning ? null : _returnProductsToStock,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: _isReturning
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.assignment_return, size: 20),
      label: Text(_isReturning ? 'Retornando...' : 'Retornar'),
    );
  }

  Widget _buildProductTable() {
    return ValueListenableBuilder<List<Product>>(
      valueListenable: OutboundService.saleProductsNotifier,
      builder: (context, produtosAtualizados, child) {
        print('🏠 HomePage builder - ${produtosAtualizados.length} produtos');
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (produtosAtualizados.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Nenhum produto em estoque.')),
                );
              }

              if (constraints.maxWidth < 700) {
                return Column(
                  children: produtosAtualizados.asMap().entries.map((entry) {
                    final product = entry.value;
                    final controller = _quantityControllerFor(product);
                    return Column(
                      children: [
                        ProductCard(
                          product: product, 
                          allocation: Allocation.sales, 
                          unitType: product.unitType,
                          onTap: () => {}),
                        if (entry.key != produtosAtualizados.length - 1)
                          Divider(height: 1, color: Colors.grey[300]),
                      ],
                    );
                  }).toList(),
                );
              }

              return Column(
                children: [
              // Cabeçalho
              Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Text('Produto', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 1, child: Text('Preço', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.left)),
                    Expanded(flex: 1, child: Text('Estoque', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('Quantidade para venda', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    SizedBox(width: 92),
                  ],
                ),
              ),
              ...produtosAtualizados.asMap().entries.map((entry) {
                  final index = entry.key;
                  final product = entry.value;
                  final controller = _quantityControllerFor(product);
                  return Column(
                    children: [
                      ProductRow(
                        product: product,
                        controller: controller,
                        onAdd: () =>
                            _addProductFromController(product, controller),
                      ),
                      if (index != produtosAtualizados.length - 1)
                        Divider(height: 1, color: Colors.grey[300]),
                    ],
                  );
                }).toList(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: const [
            Icon(Icons.shopping_cart, color: Colors.green, size: 22),
            SizedBox(width: 8),
            Text(
              'Carrinho de Compras',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              ...cart.map((item) => CartItemRow(
                    item: item,
                    onRemove: () => removeFromCart(item['name']),
                  )),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total de Itens:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          cart.length.toString(),
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'R\$ ${getTotalValue().toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCartActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartActions() {
    return ValueListenableBuilder<bool>(
      valueListenable: _salePointController.isLoading,
      builder: (context, isLoading, child) {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : () => setState(() => cart.clear()),
                child: const Text('Limpar', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isLoading ? null : _finalizarVenda,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLoading ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Finalizar Venda'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _scrollController.dispose();
    _salePointController.dispose();
    super.dispose();
  }
}

// ============================================================
// COMPONENTES AUXILIARES
// ============================================================

class ProductCard1 extends StatelessWidget {
  final Product product;
  final TextEditingController controller;
  final VoidCallback onAdd;

  const ProductCard1({
    super.key,
    required this.product,
    required this.controller,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            product.name ?? 'Produto sem nome',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.payments_outlined,
                label:
                    'R\$ ${product.price?.toStringAsFixed(2).replaceAll('.', ',') ?? '0,00'}',
              ),
              _InfoChip(
                icon: Icons.inventory_2_outlined,
                label: 'Disponível: ${product.quantity}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return RegExp(r'^\d*([\.,]\d*)?$')
                              .hasMatch(newValue.text)
                          ? newValue
                          : oldValue;
                    }),
                  ],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onAdd(),
                  decoration: InputDecoration(
                    labelText: 'Quantidade',
                    hintText: product.getUnitSymbol == 'un' ? 'Ex.: 2' : 'Ex.: 1,5',
                    suffixText: product.getUnitSymbol,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(112, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_shopping_cart, size: 19),
                label: const Text('Adicionar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class ProductRow extends StatelessWidget {
  final Product product;
  final TextEditingController controller;
  final VoidCallback onAdd;

  const ProductRow({
    super.key,
    required this.product,
    required this.controller,
    required this.onAdd,
  });


  String _formatQuantity() {
    if (product.getUnitSymbol == 'un') {
      return product.quantity.toString();
    } else {
      return (product.quantity).toStringAsFixed(1).replaceAll('.', ',');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedQuantity = _formatQuantity();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                product.name ?? "Produto sem nome",
                style: const TextStyle(fontWeight: FontWeight.w600),
                softWrap: true,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'R\$ ${product.price?.toStringAsFixed(2).replaceAll('.', ',') ?? "0,00"}',
              textAlign: TextAlign.left,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              softWrap: true,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$formattedQuantity ${product.getUnitSymbol}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final isValid = RegExp(r'^\d*([\.,]\d*)?$')
                      .hasMatch(newValue.text);
                  return isValid ? newValue : oldValue;
                }),
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onAdd(),
              decoration: InputDecoration(
                hintText: (product.getUnitSymbol == 'un') ? 'Ex.: 2' : 'Ex.: 1,5',
                suffixText: product.getUnitSymbol,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                isDense: true,
                filled: true,
                fillColor: Colors.grey[50],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add_shopping_cart, size: 17),
              label: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}

class CartItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;

  const CartItemRow({super.key, required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${(item['quantity'] as double).toStringAsFixed(item['unit'] == 'un' ? 0 : 2).replaceAll('.', ',')} ${item['unit']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'R\$ ${(item['price'] * item['quantity']).toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: onRemove,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

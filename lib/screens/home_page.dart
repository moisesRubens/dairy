import 'package:decimal/decimal.dart';
import 'package:dairy/Enums/product_enum.dart';
import 'package:dairy/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  late SalePointController _salePointController;
  final ScrollController _scrollController = ScrollController();
  double dailyRevenue = 1250.50;
  List<Product> products = [];
  List<Map<String, dynamic>> cart = [];
  bool _isLoading = true;
  bool _isReturning = false;
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, FocusNode> _quantityFocusNodes = {};

  TextEditingController _quantityControllerFor(Product product) {
    final key = product.productId ?? product.id ?? identityHashCode(product);
    return _quantityControllers.putIfAbsent(key, TextEditingController.new);
  }

  FocusNode _quantityFocusNodeFor(Product product) {
    final key = product.productId ?? product.id ?? identityHashCode(product);
    return _quantityFocusNodes.putIfAbsent(key, FocusNode.new);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _salePointController = context.read<SalePointController>();
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
    await _salePointController.loadOutboundsByDate();
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
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
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
        await _salePointController.loadOutboundsByDate();
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
    final quantityInCart = (existingIndex == -1)
        ? 0.0
        : cart[existingIndex]['quantity'] as double;

    Decimal quantityCart =
        Decimal.parse(quantity.toString()) +
        Decimal.parse(quantityInCart.toString());
    Decimal productToSellQuantity = Decimal.parse(product.quantity.toString());
    if (quantityCart > productToSellQuantity) {
      print("QUANTITY + QUANTITYINCART = ${quantity + quantityInCart}");
      print("PRODUCT QUANTITY = ${product.quantity}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          'product_id': product.productId,
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
    FocusNode focusNode,
  ) {
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
      product.quantity -= quantity;
      controller.clear();
      focusNode.unfocus();
    }
  }

  void removeFromCart(String productName) {
    setState(() {
      cart.removeWhere((item) => item['name'] == productName);
    });
  }

  double getTotalValue() {
    double result = cart.fold(0.0, (sum, item) {
      print("${item['price']}");
      return sum + (item['price'] * item['quantity']);
    });
    return result;
  }

  Future<void> _finalizarVenda() async {
    if (cart.isEmpty) {
      print("VENDA VAZIA");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Carrinho vazio! Adicione produtos.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    print("VENDA TEM CHEIA");
    print("CART AQUI $cart");
    final List<Product> productsToSell = cart.map((item) {
      print("ITEM AQUI $item");
      Product product = item['product'];
      print("PRODUTO AQUI $product");
      return product;
    }).toList();
    print("PRODUTOS DO CARRINHO $productsToSell");

    final success = await _salePointController.fazerVenda(
      productsToSell,
      description:
          'Venda do dia ${DateTime.now().toLocal().toString().split(' ')[0]}',
      totalValue: getTotalValue(),
    );

    if (success) {
      setState(() {
        cart.clear();
      });
      _loadDailyRevenue();
      await OutboundService.refreshProducts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            'Venda finalizada com sucesso!',
          ),
          backgroundColor: Colors.green[700],
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ ${_salePointController.errorMessage.value ?? "Erro ao finalizar venda"}',
          ),
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
              const Text(
                'Faturamento do Dia',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              _buildReturnButton(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'R\$ ${dailyRevenue.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnButton() {
    return ElevatedButton.icon(
      onPressed: _isReturning ? null : _returnProductsToStock,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: _isReturning
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.assignment_return, size: 20),
      label: Text(_isReturning ? 'Retornando...' : 'Retornar'),
    );
  }

  Widget _buildProductTable() {
    return ValueListenableBuilder<List<Product>>(
      valueListenable: _salePointController.products,
      builder: (context, produtosAtualizados, child) {
        products = produtosAtualizados.where((p) => p.quantity > 0).toList();
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableProducts = products.where((p) => p.quantity > 0);

              if (availableProducts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Nenhum produto pronto para vender.'),
                  ),
                );
              }

              if (_isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (products.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Nenhum produto em estoque.')),
                );
              }

              if (constraints.maxWidth < 700) {
                return Column(
                  children: products.asMap().entries.map((entry) {
                    final product = entry.value;
                    final controller = _quantityControllerFor(product);
                    final focusNode = _quantityFocusNodeFor(product);
                    return Column(
                      children: [
                        ProductCard(
                          key: ValueKey(
                            product.productId ??
                                product.id ??
                                identityHashCode(product),
                          ),
                          product: product,
                          allocation: Allocation.sales,
                          unitType: product.unitType,
                          controller: controller,
                          focusNode: focusNode,
                          onAdd: _addProductFromController,
                        ),
                        if (entry.key != products.length - 1)
                          Divider(height: 1, color: Colors.grey[300]),
                      ],
                    );
                  }).toList(),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            style: BorderStyle.solid,
                            color: Colors.grey[300]!,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      width: constraints.maxWidth,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Produto',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Preço',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Estoque',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Quantidade para venda',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: products.map((p) {
                        final controller = _quantityControllerFor(p);
                        final focusNode = _quantityFocusNodeFor(p);
                        return Container(
                          padding: EdgeInsets.all(12),
                          child: ProductRow(
                            key: ValueKey(
                              p.productId ?? p.id ?? identityHashCode(p),
                            ),
                            product: p,
                            controller: controller,
                            focusNode: focusNode,
                            onAdd: _addProductFromController,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
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
              ...cart.map(
                (item) => CartItemRow(
                  item: item,
                  onRemove: () => removeFromCart(item['name']),
                ),
              ),
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
                onPressed: isLoading
                    ? null
                    : () => {
                        setState(() {
                          cart.map((c) {
                            print("ITEM DO CART NO SETSTATE $c");
                            print("LISTA NO SETSTATE $products");
                            final Product product = _salePointController.products.value.firstWhere(
                              (p) => p.productId == c["product_id"],
                            );
                            print("PRODUTO NO SETSTATE $product E SUA QUANTIDADE ${product.quantity}");
                            print("C QUANTITY NO SETSTATE ${c['quantity']} E NOVA QUANTIDADE ${product.quantity}");
                            product.quantity += c['quantity'];
                          }).toList();
                          cart.clear();
                        }),
                      },
                child: const Text(
                  'Limpar',
                  style: TextStyle(color: Colors.black),
                ),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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
    for (final focusNode in _quantityFocusNodes.values) {
      focusNode.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }
}

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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return RegExp(r'^\d*([\.,]\d*)?$').hasMatch(newValue.text)
                          ? newValue
                          : oldValue;
                    }),
                  ],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onAdd(),
                  decoration: InputDecoration(
                    labelText: 'Quantidade',
                    hintText: product.getUnitSymbol == 'un'
                        ? 'Ex.: 2'
                        : 'Ex.: 1,5',
                    suffixText: product.getUnitSymbol,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
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
  final void Function(Product, TextEditingController, FocusNode) onAdd;
  final FocusNode focusNode;

  const ProductRow({
    super.key,
    required this.product,
    required this.controller,
    required this.onAdd,
    required this.focusNode,
  });

  String _formatQuantity() {
    if (product.getUnitSymbol == 'un') {
      return product.quantity.toStringAsFixed(0);
    } else {
      return (product.quantity).toStringAsFixed(1).replaceAll('.', ',');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedQuantity = _formatQuantity();

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Container(
            alignment: Alignment.centerLeft,
            child: Text(
              product.name ?? "Produto sem nome",
              style: const TextStyle(fontWeight: FontWeight.w600),
              softWrap: true,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            alignment: Alignment.centerLeft,
            child: Text(
              'R\$ ${product.price?.toStringAsFixed(2).replaceAll('.', ',') ?? "0,00"}',
              textAlign: TextAlign.left,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              softWrap: true,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            alignment: Alignment.centerLeft,
            child: Text(
              '$formattedQuantity ${product.getUnitSymbol}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      // Se for 'un', só aceita inteiros. Senão, aceita decimais.
                      product.getUnitSymbol == 'un'
                          ? FilteringTextInputFormatter.digitsOnly
                          : TextInputFormatter.withFunction((
                              oldValue,
                              newValue,
                            ) {
                              final isValid = RegExp(
                                r'^\d*([\.,]\d*)?$',
                              ).hasMatch(newValue.text);
                              return isValid ? newValue : oldValue;
                            }),
                    ],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onAdd(product, controller, focusNode),
                    decoration: InputDecoration(
                      hintText: (product.getUnitSymbol == 'un')
                          ? 'Ex.: 2'
                          : 'Ex.: 1,5',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      filled: true,
                      isDense: true,
                      fillColor: Colors.grey[50],
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  child: ElevatedButton.icon(
                    onPressed: () => onAdd(product, controller, focusNode),
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
          ),
        ),
      ],
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

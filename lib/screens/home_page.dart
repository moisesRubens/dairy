import 'package:flutter/material.dart';
import '../domain/product.dart';
import '../services/outbound_service.dart';
import '../controllers/sale_point_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SalePointController _salePointController = SalePointController();
  double dailyRevenue = 1250.50;
  List<Product> products = [];
  bool _isLoading = true;
  bool _isReturning = false;
  List<Map<String, dynamic>> cart = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
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

  void addToCart(Product product, double quantity) {
    if (quantity <= 0) return;

    setState(() {
      final existingIndex = cart.indexWhere((item) => item['name'] == product.name);
      if (existingIndex != -1) {
        cart[existingIndex]['quantity'] += quantity;
      } else {
        String unit = product.amount != -1 ? 'un' : (product.kg != -1 ? 'kg' : 'L');
        cart.add({
          'name': product.name,
          'price': product.price ?? 0.0,
          'unit': unit,
          'quantity': quantity,
          'product': product,
        });
      }
    });
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
      final product = item['product'] as Product;
      return Product(
        id: product.id,
        name: product.name,
        price: product.price,
        amount: product.amount != -1 ? (item['quantity'] as double).toInt() : null,
        kg: product.kg != -1 ? item['quantity'] : null,
        liters: product.liters != -1 ? item['quantity'] : null,
      );
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
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              _buildRevenueCard(),
              const SizedBox(height: 20),
              _buildProductTable(),
              if (cart.isNotEmpty) _buildCartSection(),
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
        backgroundColor: Colors.orange,
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
          : const Icon(Icons.arrow_back, size: 20),
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
          child: Column(
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
                    Expanded(flex: 1, child: Text('Qtd', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    SizedBox(width: 50),
                  ],
                ),
              ),
              // Conteúdo
              if (_isLoading)
                const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
              else if (produtosAtualizados.isEmpty)
                const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Nenhum produto em estoque.")))
              else
                ...produtosAtualizados.asMap().entries.map((entry) {
                  final index = entry.key;
                  final product = entry.value;
                  final controller = TextEditingController();
                  return Column(
                    children: [
                      ProductRow(
                        product: product,
                        controller: controller,
                        onAdd: () {
                          FocusScope.of(context).unfocus();
                          final qty = double.tryParse(controller.text) ?? 0;
                          addToCart(product, qty);
                          controller.clear();
                        },
                      ),
                      if (index != produtosAtualizados.length - 1)
                        Divider(height: 1, color: Colors.grey[300]),
                    ],
                  );
                }).toList(),
            ],
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
        const Text(
          'Carrinho de Compras',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black),
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
                        const Text('Total de Itens:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                        Text(cart.length.toString()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        Text(
                          'R\$ ${getTotalValue().toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent),
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
    _salePointController.dispose();
    super.dispose();
  }
}

// ============================================================
// COMPONENTES AUXILIARES
// ============================================================

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

  String _getUnit() {
    if (product.amount != -1) return "un";
    if (product.kg != -1) return "kg";
    if (product.liters != -1) return "L";
    return "";
  }

  String _formatQuantity() {
    final unit = _getUnit();
    if (unit == 'un') {
      return product.amount?.toString() ?? '0';
    } else if (unit == 'kg') {
      return (product.kg ?? 0).toStringAsFixed(1).replaceAll('.', ',');
    } else if (unit == 'L') {
      return (product.liters ?? 0).toStringAsFixed(1).replaceAll('.', ',');
    }
    return '0';
  }

  @override
  Widget build(BuildContext context) {
    final unit = _getUnit();
    final formattedQuantity = _formatQuantity();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            flex: 1,
            child: Text(
              'R\$ ${product.price?.toStringAsFixed(2).replaceAll('.', ',') ?? "0,00"}',
              textAlign: TextAlign.left,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$formattedQuantity $unit',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 1,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
                filled: true,
                fillColor: Colors.grey[50],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(4),
                minimumSize: const Size(0, 30),
              ),
              child: const Icon(Icons.add, size: 18),
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
                Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                Text(
                  '${item['quantity'].toStringAsFixed(2)} ${item['unit']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            'R\$ ${(item['price'] * item['quantity']).toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onRemove,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
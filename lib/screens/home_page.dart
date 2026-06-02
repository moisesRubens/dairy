import 'package:flutter/material.dart';
import '../domain/product.dart';
import '../services/outbound_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final OutboundService _outboundService = OutboundService();

  double dailyRevenue = 1250.50;

  List<Product> products = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> cart = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = false);
  }

  void addToCart(Product product, double quantity) {
    if (quantity <= 0) return;

    setState(() {
      final existingIndex = cart.indexWhere((item) => item['name'] == product.name);
      if (existingIndex != -1) {
        cart[existingIndex]['quantity'] += quantity;
      } else {
        String unit = product.amount != null ? 'un' : (product.kg != null ? 'kg' : 'L');
        cart.add({
          'name': product.name,
          'price': product.price ?? 0.0,
          'unit': unit,
          'quantity': quantity
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} adicionado ao carrinho')),
    );
  }

  void removeFromCart(String productName) {
    setState(() {
      cart.removeWhere((item) => item['name'] == productName);
    });
  }

  double getTotalValue() {
    return cart.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
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
              
              // Card de Faturamento
              _buildRevenueCard(),
              
              const SizedBox(height: 20),
              
              // Tabela de Produtos
              _buildProductTable(),
              
              // Seção do Carrinho (Condicional)
              if (cart.isNotEmpty) _buildCartSection(),
            ],
          ),
        ),
      )
    );
  }

  // --- Widgets de Apoio (Refatorados para organização) ---

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
          const Text('Faturamento do Dia', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            'R\$ ${dailyRevenue.toStringAsFixed(2).replaceAll('.', ',')}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTable() {
  // O ValueListenableBuilder fica vigiando o Notifier do Service
  return ValueListenableBuilder<List<Product>>(
    valueListenable: OutboundService.saleProductsNotifier,
    builder: (context, produtosAtualizados, child) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(12),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Produto', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Preço', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(child: Text('Un', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(child: Text('Qtd', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  SizedBox(width: 50),
                ],
              ),
            ),
            if (_isLoading)
              const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
            // MUDANÇA AQUI: Usa a lista "produtosAtualizados" que veio do Notifier
            else if (produtosAtualizados.isEmpty)
              const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Nenhum produto em estoque.")))
            else
              ...produtosAtualizados.map((product) {
                final controller = TextEditingController();
                return ProductRow(
                  product: product,
                  controller: controller,
                  onAdd: () {
                    final qty = double.tryParse(controller.text) ?? 0;
                    addToCart(product, qty);
                    controller.clear();
                  },
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
            color: Colors.grey[300]!,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
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
                        const Text('Total de Itens:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(cart.length.toString()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          'R\$ ${getTotalValue().toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E7D32)),
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
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() => cart.clear()),
            child: const Text('Limpar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Venda finalizada com sucesso!')),
              );
              setState(() => cart.clear());
            },
            child: const Text('Finalizar Venda'),
          ),
        ),
      ],
    );
  }
}

// --- Componentes Auxiliares (Mesma lógica sua, mantidos fora da classe principal) ---

class ProductRow extends StatelessWidget {
  final Product product;
  final TextEditingController controller;
  final VoidCallback onAdd;

  const ProductRow({super.key, required this.product, required this.controller, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    String unit = product.amount != null ? 'un' : (product.kg != null ? 'kg' : 'L');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(product.name)),
          Expanded(
            child: Text(
              'R\$ ${product.price?.toStringAsFixed(2).replaceAll('.', ',') ?? "0,00"}',
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                num? quantityValue;
                if (product.amount != null) {
                  quantityValue = product.amount;
                } else if (product.kg != null) {
                  quantityValue = product.kg;
                } else if (product.liters != null) {
                  quantityValue = product.liters;
                }
                String displayQuantity = quantityValue != null
                    ? (quantityValue is int ? quantityValue.toString() : quantityValue.toStringAsFixed(2).replaceAll('.', ','))
                    : "0";
                return Text('$displayQuantity $unit', textAlign: TextAlign.center);
              },
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(4)),
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
                Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${item['quantity'].toStringAsFixed(2)} ${item['unit']}', 
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text('R\$ ${(item['price'] * item['quantity']).toStringAsFixed(2).replaceAll('.', ',')}', 
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
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
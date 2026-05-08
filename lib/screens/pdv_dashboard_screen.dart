import 'package:flutter/material.dart';

class Dairy extends StatefulWidget {
  const Dairy({Key? key}) : super(key: key);

  @override
  State<Dairy> createState() => _DairyState();
}

class _DairyState extends State<Dairy> {
  double dailyRevenue = 1250.50;
  int _currentIndex = 0;

  final List<Map<String, dynamic>> products = [
    {'name': 'Tomate Caqui', 'price': 8.50, 'unit': 'kg'},
    {'name': 'Alface Crespa', 'price': 4.00, 'unit': 'un'},
    {'name': 'Cenoura Comum', 'price': 3.50, 'unit': 'kg'},
    {'name': 'Banana Nanica', 'price': 2.80, 'unit': 'kg'},
    {'name': 'Maçã Gala', 'price': 6.50, 'unit': 'kg'},
    {'name': 'Laranja Pêra', 'price': 2.50, 'unit': 'kg'},
  ];

  List<Map<String, dynamic>> cart = [];

  void addToCart(Map<String, dynamic> product, double quantity) {
    if (quantity <= 0) return;

    setState(() {
      final existingIndex = cart.indexWhere((item) => item['name'] == product['name']);
      if (existingIndex != -1) {
        cart[existingIndex]['quantity'] += quantity;
      } else {
        cart.add({...product, 'quantity': quantity});
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product['name']} adicionado ao carrinho')),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, // Fundo preto
        iconTheme: const IconThemeData(
          color: Colors.white, // Deixa o ícone do menu (hambúrguer) branco
        ),
        shape: Border(
          bottom: BorderSide(
            color: Colors.grey[800]!, // Escureci um pouco a borda para combinar melhor
            width: 2,
          ),
        ),
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Fazenda Boa Esperança',
            style: TextStyle(color: Colors.white), // Texto branco
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Decoracao qualquer',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Perfil'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Sair'),
              onTap: () {
                null;
              },
            ),
          ],
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Pedidos'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Estoque'),
          BottomNavigationBarItem(icon: Icon(Icons.person_search), label: 'Perfis'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildPDVHome(); // Sua tela atual
      case 1:
        return const Center(child: Text('Tela de Pedidos (Em breve)'));
      case 2:
        return const Center(child: Text('Tela de Estoque (Em breve)'));
      case 3:
        return const Center(child: Text('Explorar Perfis (Em breve)'));
      default:
        return _buildPDVHome();
    }
  }

  Widget _buildPDVHome() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Card de Faturamento
            Container(
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
            ),
            const SizedBox(height: 20),
            // Tabela de Produtos
            Container(
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
                    child: Row(
                      children: const [
                        Expanded(flex: 2, child: Text('Produto', style: TextStyle(fontWeight: FontWeight.bold))),
                        Expanded(child: Text('Preço', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(child: Text('Un', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        Expanded(child: Text('Qtd', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        SizedBox(width: 50),
                      ],
                    ),
                  ),
                  ...products.map((product) {
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
            ),
            // Carrinho
            // ... dentro do Column principal no build()

// Usamos o 'if' de coleção do Dart para mostrar ou esconder o bloco inteiro
if (cart.isNotEmpty) ...[
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
                  const Text('Total de Itens:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(cart.length.toString()),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    'R\$ ${getTotalValue().toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
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
                          const SnackBar(
                              content: Text('Venda finalizada com sucesso!')),
                        );
                        setState(() => cart.clear());
                      },
                      child: const Text('Finalizar Venda'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  ),
],

// ... restante do código
          ],
        ),
      ),
    );
  }
}

class ProductRow extends StatelessWidget {
  final Map<String, dynamic> product;
  final TextEditingController controller;
  final VoidCallback onAdd;

  const ProductRow({
    required this.product,
    required this.controller,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(product['name']),
          ),
          Expanded(
            child: Text('R\$ ${product['price'].toStringAsFixed(2)}', textAlign: TextAlign.center),
          ),
          Expanded(
            child: Text(product['unit'], textAlign: TextAlign.center),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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

  const CartItemRow({
    required this.item,
    required this.onRemove,
  });

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
                Text('${item['quantity'].toStringAsFixed(2)} ${item['unit']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Text('R\$ ${(item['price'] * item['quantity']).toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
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

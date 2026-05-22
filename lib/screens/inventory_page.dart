import 'package:flutter/material.dart';
import '../domain/product.dart'; // Importe seu model
import '../services/product_service.dart'; // Importe seu service
import '../services/outbound_service.dart'; // Importe o OutboundService

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final ProductService _productService = ProductService();
  final OutboundService _outboundService = OutboundService(); // Instância do OutboundService
  
  // MUDANÇA: Lista agora é de Objetos Product e começa vazia
  List<Product> _products = [];
  bool _isLoading = true; // Para o feedback visual de carregamento

  int? _expandedProductId;
  final Set<int> _selectedProductIds = {};
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _quantityFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadProducts(); // Carrega os dados da API
  }

  // Função para buscar os dados do Service
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final data = await _productService.getProducts();
      setState(() {
        _products = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar estoque: $e')),
      );
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _quantityFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) // Mostra loading
            : RefreshIndicator( // Adiciona "puxar para atualizar"
                onRefresh: _loadProducts,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ESTOQUE DE PRODUTOS',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadProducts, // Botão de atualizar
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      _products.isEmpty 
                        ? const Center(child: Text("Nenhum produto encontrado."))
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return _buildProductCard(product);
                            },
                          ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
        ),
        if (_selectedProductIds.isNotEmpty) _buildBottomQuantitySelector(),
      ],
    );
  }

  // MUDANÇA: Recebe o objeto Product agora
  Widget _buildProductCard(Product product) {
    final bool isSelected = _selectedProductIds.contains(product.id);
    final bool isExpanded = _expandedProductId == product.id;
    num? quantity;
    String unit = '';

    if (product.amount != null) {
      quantity = product.amount;
      unit = "un";
    } else if (product.kg != null) {
      quantity = product.kg;
      unit = "kg";
    } else if (product.liters != null) {
      quantity = product.liters;
      unit = "L";
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedProductId = isExpanded ? null : product.id;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded ? Colors.black : Colors.grey[300]!, 
            width: isExpanded ? 2 : 1
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: const Center(
                  child: Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    product.name, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '$unit ${quantity is int ? quantity : quantity?.toStringAsFixed(2).replaceAll('.', ',') ?? "0"}',
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
                                  _selectedProductIds.add(product.id!);
                                } else {
                                  _selectedProductIds.remove(product.id!);
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
                    // Exibe o estoque real vindo da API
                    Text("Estoque: ${quantity ?? 0} $unit", style: const TextStyle(fontSize: 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _handleEdit(product),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFE74C3C)),
                          onPressed: () => _showDeleteDialog(product),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    )
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares agora usam o objeto Product
  void _handleEdit(Product product) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Editar: ${product.name}')));
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Produto?'),
        content: Text('Deseja realmente remover ${product.name} do estoque?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('EXCLUIR', style: TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomQuantitySelector() {
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
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$count item(s) selecionado(s)',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Botão que abre o teclado
          
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: TextField(
              controller: _quantityController,
              focusNode: _quantityFocusNode,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[900],
                isDense: true,
                hintText: 'Qtd',
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              _handleOutboundCreation(); // Chama o novo método para lidar com a lógica
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('REGISTRAR SAÍDA', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOutboundCreation() async {
    final String quantityText = _quantityController.text;
    final int? quantity = int.tryParse(quantityText);

    if (quantity == null || quantity <= 0) {
      _showSnackBar('Por favor, insira uma quantidade válida.', Colors.red);
      return;
    }

    if (_selectedProductIds.isEmpty) {
      _showSnackBar('Selecione pelo menos um produto para registrar a saída.', Colors.red);
      return;
    }

    final Map<Product, int> outboundsMap = {};
    for (int productId in _selectedProductIds) {
      final product = _products.firstWhere((p) => p.id == productId);
      if (product.amount != null) {
        product.amount = 0;
      } else if (product.kg != null) {
        product.kg = 0;
      } else if (product.liters != null) {
        product.liters = 0;
      }
      outboundsMap[product] = quantity;
    }

    final bool success = await _outboundService.createOutbound(outboundsMap);

    if (success) {
      _showSnackBar('Saída de ${outboundsMap.length} item(s) registrada com sucesso!', const Color(0xFF2E7D32));
      setState(() => _selectedProductIds.clear());
      //deve mandar a lista de produtos retirados pra a home_page.dart

      _quantityController.clear();
      _quantityFocusNode.unfocus(); // Esconde o teclado
      _loadProducts();
      //se sucess, deve mandar a lista de produtos pra carregar na screens/home_page.dart 
    } else {
      _showSnackBar('Falha ao registrar saída. Verifique a conexão ou tente novamente.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }
}
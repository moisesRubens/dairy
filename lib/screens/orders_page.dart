import 'package:flutter/material.dart';
import '../controllers/order_controller.dart';
import '../domain/order.dart';
import '../domain/order_item.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();

  static Future<void> loadOrders() async {
    try {
      final controller = OrderController();
      await controller.loadOrders();
      controller.dispose();
    } catch (e) {
      debugPrint('❌ Erro ao recarregar pedidos: $e');
    }
  }
}

class _OrdersPageState extends State<OrdersPage> with WidgetsBindingObserver {
  final OrderController _orderController = OrderController();
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedStatus;
  int _currentPage = 0;
  static const int _pageSize = 8;

  static const List<String> _statusOptions = ['Pendente', 'Finalizado', 'Desconto'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOrders();
    
    _orderController.orders.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadOrders();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && route.isCurrent) {
          _loadOrders();
        }
      });
    }
  }

  Future<void> _loadOrders() async {
    await _orderController.loadOrders();
    debugPrint('🔄 Pedidos recarregados: ${_orderController.orders.value.length}');
  }

  // ============================================================
  // 🔥 CONVERTER ORDER PARA MAP (para a tabela)
  // ============================================================
  List<Map<String, dynamic>> _getOrdersAsMap() {
    final orders = _orderController.orders.value;
    
    return orders.map((order) {
      String formattedDateTime = order.orderDate;
      try {
        final date = DateTime.parse(order.orderDate);
        formattedDateTime = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year.toString().substring(2)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        formattedDateTime = order.orderDate;
      }

      String formattedValue = 'R\$ ${order.totalValue.toStringAsFixed(2).replaceAll('.', ',')}';
      String status = 'Finalizado';
      Color statusColor = const Color(0xFF2E7D32);

      return {
        'date': formattedDateTime,
        'value': formattedValue,
        'status': status,
        'color': statusColor,
        'order': order,
      };
    }).toList();
  }

  // ============================================================
  // 🔥 FILTRAR PEDIDOS
  // ============================================================
  List<Map<String, dynamic>> _getFilteredOrders() {
    final allOrders = _getOrdersAsMap();
    final searchText = _searchController.text.toLowerCase();

    return allOrders.where((order) {
      final matchesSearch = order['date'].toString().toLowerCase().contains(searchText);
      
      bool matchesDate = true;
      if (_selectedDate != null) {
        final orderDate = order['date'] as String;
        final selectedDateStr = '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year.toString().substring(2)}';
        matchesDate = orderDate.contains(selectedDateStr);
      }
      
      bool matchesStatus = true;
      if (_selectedStatus != null && _selectedStatus != 'Todos') {
        matchesStatus = order['status'] == _selectedStatus;
      }
      
      return matchesSearch && matchesDate && matchesStatus;
    }).toList();
  }

  // ============================================================
  // 🔥 BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final filteredOrders = _getFilteredOrders();
    final totalPages = (filteredOrders.length / _pageSize).ceil();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        color: const Color(0xFF2E7D32),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildFilterSection(),
              const SizedBox(height: 24),

              ValueListenableBuilder<bool>(
                valueListenable: _orderController.isLoading,
                builder: (context, isLoading, child) {
                  if (isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    );
                  }

                  if (_orderController.orders.value.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF9E9E9E)),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum pedido encontrado',
                              style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E)),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Faça uma venda para aparecer aqui',
                              style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return _buildOrdersTable(filteredOrders, _currentPage);
                },
              ),
              
              const SizedBox(height: 20),
              
              if (filteredOrders.isNotEmpty)
                _buildPagination(totalPages, filteredOrders.length),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🔥 FILTER SECTION - CARD PRETO
  // ============================================================
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Campo de pesquisa
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() => _currentPage = 0),
            decoration: InputDecoration(
              hintText: 'Pesquisar por data...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: const Icon(Icons.search_outlined, color: Colors.black, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black, width: 2),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          // Linha com seletor de data e dropdown
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDate == null 
                            ? 'Filtrar por Data' 
                            : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                        if (_selectedDate != null) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() {
                              _selectedDate = null;
                              _currentPage = 0;
                            }),
                            child: const Icon(Icons.close, size: 16, color: Color(0xFF9E9E9E)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  isDense: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.black, width: 2),
                    ),
                    hintText: 'Status',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black, fontSize: 13),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos', style: TextStyle(fontSize: 13))),
                    ..._statusOptions.map((status) {
                      return DropdownMenuItem(value: status, child: Text(status, style: const TextStyle(fontSize: 13)));
                    }),
                  ],
                  onChanged: (val) => setState(() {
                    _selectedStatus = val;
                    _currentPage = 0;
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2E7D32),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _currentPage = 0;
      });
    }
  }

  Widget _buildOrdersTable(List<Map<String, dynamic>> filteredOrders, int page) {
    final startIndex = page * _pageSize;
    final visibleOrders = filteredOrders.skip(startIndex).take(_pageSize).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 🔥 CABEÇALHO PRETO
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('DATA/HORA', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5))),
                Expanded(flex: 3, child: Text('TOTAL', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5))),
                Expanded(flex: 3, child: Text('STATUS', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5))),
                SizedBox(width: 50, child: SizedBox()),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          ...visibleOrders.map((order) => _buildOrderRow(order)),
        ],
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Expanded(flex: 4, child: Text(order['date']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF333333)))),
              Expanded(flex: 3, child: Text(order['value']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: (order['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order['status']?.toString().toUpperCase() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: order['color'] as Color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: PopupMenuButton<String>(
                  color: Colors.black,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert_outlined, size: 20, color: Colors.black87),
                  onSelected: (val) {
                    if (val == 'details') _handleDetails(order);
                    if (val == 'delete') _showDeleteDialog(order);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18, color: Colors.greenAccent),
                          SizedBox(width: 8),
                          Text('Detalhes', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Color(0xFFE74C3C)),
                          SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 12, endIndent: 12, color: Color(0xFFE0E0E0)),
      ],
    );
  }

  Widget _buildPagination(int totalPages, int totalItems) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('ANTERIOR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        Text(
          'Página ${_currentPage + 1} de $totalPages',
          style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
        ),
        const SizedBox(width: 16),
        OutlinedButton(
          onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('PRÓXIMO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ============================================================
  // 🔥 AÇÕES
  // ============================================================
  void _handleDetails(Map<String, dynamic> order) {
    final Order? realOrder = order['order'];
    
    if (realOrder != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.receipt_long, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text('Detalhes do Pedido', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Text('📦 ITENS:', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    )
                  ),
                  const SizedBox(height: 8),
                  ...realOrder.items.map((item) {
                    String quantity = item.getQuantityString();
                    String subtotal = 'R\$ ${item.subtotal.toStringAsFixed(2).replaceAll('.', ',')}';
                    String price = 'R\$ ${item.itemPrice.toStringAsFixed(2).replaceAll('.', ',')}';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              item.productName, 
                              style: const TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 15,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quantidade: $quantity', style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
                              const SizedBox(height: 2),
                              Text('Preço: $price', style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Subtotal: $subtotal', 
                              style: const TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 14, 
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL: ${order['value'] ?? 'R\$ 0,00'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16, 
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('FECHAR', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Visualizando detalhes do pedido ${order['id']}')),
      );
    }
  }

  void _showDeleteDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Excluir Pedido?',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Deseja realmente remover este pedido do histórico?',
          style: TextStyle(color: Color(0xFF333333)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
            child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final realOrder = order['order'] as Order;
              await _orderController.deleteOrder(realOrder.orderDate, realOrder.description);
  
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Pedido excluído com sucesso!'),
                  backgroundColor: Color(0xFF2E7D32),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE74C3C),
            ),
            child: const Text('EXCLUIR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
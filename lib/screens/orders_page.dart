import 'package:flutter/material.dart';
import '../config/theme.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedStatus;
  int _currentPage = 0;
  static const int _pageSize = 6;

  static const List<String> _statusOptions = ['Pendente', 'Finalizado', 'Desconto'];

  final List<Map<String, dynamic>> _allOrders = List.generate(20, (index) {
    final statuses = ['Finalizado', 'Pendente', 'Desconto'];
    final status = statuses[index % 3];
    Color color;
    if (status == 'Finalizado') {
      color = const Color(0xFF2E7D32);
    } else if (status == 'Pendente') {
      color = Colors.orange[800]!;
    } else {
      // "Desconto": magenta — evita azul (proibido pelo design system).
      color = const Color(0xFFAD1457);
    }

    return {
      'id': '#${1024 + index}',
      'date': '${(index % 28) + 1}/10/2023',
      'value': 'R\$ ${(150 + index * 25.5).toStringAsFixed(2).replaceAll('.', ',')}',
      'status': status,
      'color': color,
    };
  });

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          const Text(
            'HISTÓRICO DE PEDIDOS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),

          // Barra de Pesquisa e Filtros
          _buildFilterSection(),

          const SizedBox(height: 24),

          // Tabela de Pedidos (DataTableContainer padrão)
          _buildOrdersTable(),
          
          const SizedBox(height: 20),
          
          // Paginação (Conforme definido no extractor.md)
          _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      children: [
        // Campo de Pesquisa
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Pesquisar por cliente ou código...',
            prefixIcon: const Icon(Icons.search_outlined, color: Colors.black, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black, width: 2),
            ),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Seletor de Data
            Expanded(
              child: InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.borderColor),
                    borderRadius: BorderRadius.circular(AppRadii.table),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDate == null
                          ? 'Filtrar por Data'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Seletor de Status
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                isDense: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  hintText: 'Status',
                ),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(value: status, child: Text(status, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) => setState(() => _selectedStatus = val),
              ),
            ),
          ],
        ),
      ],
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
          colorScheme: const ColorScheme.light(primary: Colors.black, onPrimary: Colors.white, onSurface: Colors.black),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Widget _buildOrdersTable() {
    final startIndex = _currentPage * _pageSize;
    final visibleOrders = _allOrders.skip(startIndex).take(_pageSize).toList();

    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(AppRadii.table),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          // Cabeçalho da Tabela
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: context.mutedSurface, borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('ID', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 3, child: Text('DATA', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 3, child: Text('TOTAL', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                Expanded(flex: 3, child: Text('STATUS', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                SizedBox(width: 50, child: Text('AÇÕES', textAlign: TextAlign.center, maxLines: 1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
              ],
            ),
          ),
          const Divider(height: 1),
          ...visibleOrders.map((order) => _buildOrderRow(
                order,
                order['date']?.toString() ?? '',
                order['value']?.toString() ?? '',
                order['status']?.toString() ?? '',
                (order['color'] as Color?) ?? Colors.grey
              )),
        ],
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order, String date, String value, String status, Color color) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text(order['id']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text(date, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.black54))),
              Expanded(flex: 3, child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(status.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert_outlined, size: 20, color: Colors.black87),
                  onSelected: (val) {
                    if (val == 'details') _handleDetails(order);
                    if (val == 'edit') _handleEdit(order);
                    if (val == 'delete') _showDeleteDialog(order);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Detalhes'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Color(0xFFE74C3C)),
                          SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(color: Color(0xFFE74C3C))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 12, endIndent: 12),
      ],
    );
  }

  Widget _buildPagination() {
    final totalPages = (_allOrders.length / _pageSize).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('ANTERIOR'),
        ),
        const SizedBox(width: 16),
        Text('Página ${_currentPage + 1} de $totalPages', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(width: 16),
        OutlinedButton(
          onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('PRÓXIMO'),
        ),
      ],
    );
  }

  void _handleDetails(Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Visualizando detalhes do pedido ${order['id']}')),
    );
  }

  void _handleEdit(Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editando pedido ${order['id']}')),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Pedido?'),
        content: Text('Deseja realmente remover o pedido ${order['id']} do histórico?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR', style: TextStyle(color: Colors.black))),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('EXCLUIR', style: TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
  }
}
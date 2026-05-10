import 'package:flutter/material.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  // Mock de dados para simular a API
  final List<Map<String, dynamic>> _allOrders = List.generate(25, (index) {
    return {
      'id': '#${1000 + index}',
      'date': '22/10/2023 14:${index.toString().padLeft(2, '0')}',
      'customer': 'Cliente ${index + 1}',
      'total': (index % 5 == 0) // A cada 5 itens, um terá desconto
          ? (45.50 + (index * 5)) * 0.85 // 15% de desconto
          : 45.50 + (index * 10),
      // Alterna entre os status para exemplificar todos os cenários
      'status': (index % 5 == 0) ? 'Desconto' : (index % 2 == 0 ? 'Finalizado' : 'Pendente'),
    };
  }).reversed.toList();

  int _currentPage = 0;
  final int _pageSize = 6;

  List<Map<String, dynamic>> get _paginatedOrders {
    int start = _currentPage * _pageSize;
    int end = start + _pageSize;
    if (start >= _allOrders.length) return [];
    return _allOrders.sublist(start, end > _allOrders.length ? _allOrders.length : end);
  }

  int get _totalPages => (_allOrders.length / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            
            const SizedBox(height: 20),
            
            // Título da Seção
            const Text(
              'HISTÓRICO DE PEDIDOS',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            
            // Tabela de Pedidos (Padrão DNA - Container Branco com borda cinza)
            _buildOrdersTable(),
            
            const SizedBox(height: 16),
            
            // Controles de Paginação
            _buildPaginationControls(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Cabeçalho da Tabela
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Data/Hora', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
          ),
          
          // Lista de Pedidos Paginaos
          ..._paginatedOrders.map((order) => _buildOrderRow(order)).toList(),
          
          if (_paginatedOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Nenhum pedido encontrado.'),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Data e Horário
          Expanded(
            flex: 3,
            child: Text(order['date'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          
          // Total
          Expanded(
            flex: 2,
            child: Text(
              'R\$ ${order['total'].toStringAsFixed(2).replaceAll('.', ',')}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                color: Color(0xFF2E7D32), // Verde Sucesso do DNA
              ),
            ),
          ),
          
          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: () {
                  switch (order['status']) {
                    case 'Finalizado': return Colors.green[50];
                    case 'Fiado': return Colors.red[50];
                    case 'Desconto': return Colors.blue[50]; // Azul claro para o fundo
                    case 'Desconto': return Colors.blue[50];
                    default: return Colors.orange[50];
                  }
                }(),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                order['status'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: () {
                    switch (order['status']) {
                      case 'Finalizado': return Colors.green[800];
                      case 'Fiado': return Colors.red[800];
                      case 'Desconto': return Colors.blue[800]; // Azul escuro para o texto
                      case 'Desconto': return Colors.blue[800];
                      default: return Colors.orange[800];
                    }
                  }(),
                ),
              ),
            ),
          ),
          
          // Ações (Menu discreto contendo Detalhes, Editar e Excluir)
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$value pedido ${order['id']}')),
                );
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'Visualizar', child: ListTile(leading: Icon(Icons.visibility_outlined, size: 18), title: Text('Detalhes'), dense: true)),
                const PopupMenuItem(
                    value: 'Editar', child: ListTile(leading: Icon(Icons.edit, size: 18), title: Text('Editar'), dense: true)),
                const PopupMenuItem(
                    value: 'Excluir', child: ListTile(leading: Icon(Icons.delete, size: 18, color: Colors.red), title: Text('Excluir', style: TextStyle(color: Colors.red)), dense: true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Página ${_currentPage + 1} de $_totalPages',
          style: TextStyle(color: Colors.grey[600]),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: _currentPage > 0 
                  ? () => setState(() => _currentPage--) 
                  : null,
              style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.black)),
              child: const Icon(Icons.chevron_left, color: Colors.black),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _currentPage < _totalPages - 1 
                  ? () => setState(() => _currentPage++) 
                  : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.black),
                backgroundColor: Colors.black,
              ),
              child: const Icon(Icons.chevron_right, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}
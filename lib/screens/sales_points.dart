import 'package:flutter/material.dart';

class SalesPointsPage extends StatefulWidget {
  const SalesPointsPage({Key? key}) : super(key: key);

  @override
  State<SalesPointsPage> createState() => _SalesPointsPageState();
}

class _SalesPointsPageState extends State<SalesPointsPage> {
  int? _expandedPointId;

  // Dados Mockados dos Pontos de Venda
  final List<Map<String, dynamic>> _salesPoints = [
    {
      'id': 1,
      'name': 'QUIOSQUE CENTRAL',
      'revenue': 1250.50,
      'products': [
        {'name': 'Queijo Frescal', 'stock': '15 kg', 'price': 'R\$ 25,00'},
        {'name': 'Leite Integral', 'stock': '40 L', 'price': 'R\$ 6,50'},
      ],
    },
    {
      'id': 2,
      'name': 'LOJA MATRIZ',
      'revenue': 3420.00,
      'products': [
        {'name': 'Manteiga Pote', 'stock': '20 un', 'price': 'R\$ 12,00'},
        {'name': 'Iogurte Natural', 'stock': '50 un', 'price': 'R\$ 4,50'},
      ],
    },
    {
      'id': 3,
      'name': 'POSTO AVANÇADO B',
      'revenue': 890.20,
      'products': [
        {'name': 'Queijo Coalho', 'stock': '10 kg', 'price': 'R\$ 35,00'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          const Text(
            'PONTOS DE VENDA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          ..._salesPoints.map((point) => _buildSalesPointSection(point)).toList(),
        ],
      ),
    );
  }

  Widget _buildSalesPointSection(Map<String, dynamic> point) {
    final isExpanded = _expandedPointId == point['id'];

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedPointId = isExpanded ? null : point['id'];
            });
          },
          child: _buildRevenueCard(point['name'], point['revenue']),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 12),
          _buildProductTable(point['products']),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRevenueCard(String title, double value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  color: Colors.white, // Verde Sucesso do extractor.md
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  Widget _buildProductTable(List<dynamic> products) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Cabeçalho conforme DataTableContainer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Row(
              children: [
                Expanded(child: Text('PRODUTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                SizedBox(width: 80, child: Text('ESTOQUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
                SizedBox(width: 80, child: Text('PREÇO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey))),
              ],
            ),
          ),
          const Divider(height: 1),
          ...products.map((p) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(child: Text(p['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                        SizedBox(width: 80, child: Text(p['stock'], style: const TextStyle(fontSize: 13, color: Colors.black54))),
                        SizedBox(width: 80, child: Text(p['price'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)))),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 12, endIndent: 12),
                ],
              )),
        ],
      ),
    );
  }
}
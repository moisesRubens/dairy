import 'package:flutter/material.dart';
import '../services/outbound_service.dart';
import '../domain/outbound.dart';

class SalesPointsPage extends StatefulWidget {
  const SalesPointsPage({super.key});

  @override
  State<SalesPointsPage> createState() => _SalesPointsPageState();

  static Future<void> loadSalesPoints() async {
    await OutboundService.refreshOutbounds();
  }
}

class _SalesPointsPageState extends State<SalesPointsPage> {
  final Map<int, bool> _expandedMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = OutboundService();
    await service.loadAllOutbounds();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF2E7D32),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: OutboundService.allSalePointsNotifier,
              builder: (context, allPoints, child) {
                if (allPoints.isEmpty) {
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
                            'Nenhuma retirada hoje',
                            style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E)),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'As retiradas do dia aparecerão aqui',
                            style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: allPoints.asMap().entries.map((entry) {
                    final index = entry.key;
                    final point = entry.value;
                    final name = point['name'] as String;
                    final outbounds = point['outbounds'] as List<Outbound>;
                    final totalValue = point['totalValue'] as double;
                    final totalItems = point['totalItems'] as int;
                    final overallPercentage = point['overallPercentage'] as double? ?? 0.0;

                    if (!_expandedMap.containsKey(index)) {
                      _expandedMap[index] = false;
                    }

                    return _buildSalePointCard(
                      index: index,
                      name: name,
                      outbounds: outbounds,
                      totalValue: totalValue,
                      totalItems: totalItems,
                      overallPercentage: overallPercentage,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalePointCard({
    required int index,
    required String name,
    required List<Outbound> outbounds,
    required double totalValue,
    required int totalItems,
    required double overallPercentage,
  }) {
    final isExpanded = _expandedMap[index] ?? false;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedMap[index] = !isExpanded;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🔥 COLUNA ESQUERDA
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'R\$ ${totalValue.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalItems produto${totalItems > 1 ? 's' : ''} retirados',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 🔥 COLUNA DIREITA - PROGRESSO COM "VENDAS" ABAIXO
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildProgressCircle(overallPercentage),
                      const SizedBox(height: 6),
                      Text(
                        'Vendas',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 400),
          firstChild: const SizedBox.shrink(),
          secondChild: _buildProductTable(outbounds),
          crossFadeState: isExpanded 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ============================================================
  // 🔥 PROGRESSO CIRCULAR - SEMPRE VERDE (greenAccent)
  // ============================================================
  Widget _buildProgressCircle(double percentage) {
    return SizedBox(
      width: 55,
      height: 55,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fundo do círculo
          SizedBox(
            width: 55,
            height: 55,
            child: CircularProgressIndicator(
              value: 1.0,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.transparent),
              strokeWidth: 4,
            ),
          ),
          // Progresso
          SizedBox(
            width: 55,
            height: 55,
            child: CircularProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              strokeWidth: 4,
            ),
          ),
          // Texto da porcentagem
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🔥 TABELA DE PRODUTOS
  // ============================================================
  Widget _buildProductTable(List<Outbound> outbounds) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('PRODUTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9E9E9E), letterSpacing: 0.5))),
                SizedBox(width: 60, child: Text('RETIRADO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9E9E9E), letterSpacing: 0.5))),
                SizedBox(width: 60, child: Text('VENDIDO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9E9E9E), letterSpacing: 0.5))),
                SizedBox(width: 70, child: Text('VENDAS %', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF9E9E9E), letterSpacing: 0.5))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          ...outbounds.map((outbound) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(outbound.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black))),
                    SizedBox(
                      width: 60,
                      child: Text(
                        _formatQuantity(outbound.takenQuantity, outbound.unidade),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        _formatQuantity(outbound.soldQuantity, outbound.unidade),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: _buildPercentageWidget(outbound),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 12, endIndent: 12, color: Color(0xFFE0E0E0)),
            ],
          )),
        ],
      ),
    );
  }

  // ============================================================
  // 🔥 AUXILIARES
  // ============================================================
  String _formatQuantity(double value, String unidade) {
    final isInteger = value.truncateToDouble() == value;
    final formatted = isInteger ? value.toInt().toString() : value.toStringAsFixed(1);
    return '$formatted ${_getUnitLabel(unidade)}';
  }

  String _getUnitLabel(String unidade) {
    switch (unidade) {
      case 'amount':
        return 'un';
      case 'kg':
        return 'kg';
      case 'liters':
        return 'L';
      default:
        return unidade;
    }
  }

  // ============================================================
  // 🔥 WIDGET DE PORCENTAGEM - SEMPRE greenAccent
  // ============================================================
  Widget _buildPercentageWidget(Outbound outbound) {
    final taken = outbound.takenQuantity;
    final sold = outbound.soldQuantity;
    
    double percentage = 0.0;
    if (taken > 0) {
      percentage = (sold / taken) * 100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
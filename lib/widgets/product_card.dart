import 'package:dairy/domain/product.dart';
import 'package:flutter/material.dart';
import '../Enums/product_enum.dart';
import 'package:flutter/services.dart';

class ProductCard extends StatelessWidget
{
  final TextEditingController _quantity = TextEditingController();
  final Unit _unitType;
  final Allocation _allocation;
  final Product _product;
  final VoidCallback _onTap;

  ProductCard({required Product product, required Allocation allocation, required Unit unitType, required VoidCallback onTap}): _allocation = allocation, _unitType = unitType, _product = product, _onTap = onTap;

  // ✅ Getter para o símbolo da unidade
  String get _unitSymbol {
    switch (_unitType) {
      case Unit.kg:
        return 'kg';
      case Unit.liters:
        return 'L';
      case Unit.amount:
        return 'un';
    }
  }

  // ✅ Getter para o hint do TextField
  String get _hintText {
    switch (_unitType) {
      case Unit.kg:
        return 'Ex.: 1,5';
      case Unit.liters:
        return 'Ex.: 1,5';
      case Unit.amount:
        return 'Ex.: 2';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _product.name ?? 'Produto sem nome',
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
                    'R\$ ${_product.price?.toStringAsFixed(2).replaceAll('.', ',') ?? '0,00'}',
              ),
              _InfoChip(
                icon: Icons.inventory_2_outlined,
                label: 'Disponível: ${_product.quantity} $_unitSymbol',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantity,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return RegExp(r'^\d*([\.,]\d*)?$')
                              .hasMatch(newValue.text)
                          ? newValue
                          : oldValue;
                    }),
                  ],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onTap(),
                  decoration: InputDecoration(
                    labelText: 'Quantidade',
                    hintText: _hintText,
                    suffixText: _unitSymbol,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
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
                onPressed: _onTap,
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
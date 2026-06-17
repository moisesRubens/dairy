import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../domain/product.dart';

/// Miniatura/foto de um produto, reutilizada na grade do admin e no PDV.
///
/// Reconhecimento (Nielsen): quando há foto, mostra `Image.network`; quando
/// não há, cai num placeholder elegante (inicial do nome sobre fundo neutro),
/// evitando um "buraco" visual. O mesmo idioma vale para erro de rede.
class ProductImage extends StatelessWidget {
  final Product product;
  final double size;
  final double radius;

  const ProductImage({
    super.key,
    required this.product,
    this.size = 64,
    this.radius = AppRadii.revenue,
  });

  @override
  Widget build(BuildContext context) {
    final url = product.imageAbsoluteUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? _Placeholder(product: product, size: size)
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: context.mutedSurface,
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.green),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, _, _) =>
                    _Placeholder(product: product, size: size),
              ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final Product product;
  final double size;
  const _Placeholder({required this.product, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial =
        product.name.trim().isNotEmpty ? product.name.trim()[0].toUpperCase() : '?';
    return Container(
      color: context.mutedSurface,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
          color: AppColors.grey,
        ),
      ),
    );
  }
}

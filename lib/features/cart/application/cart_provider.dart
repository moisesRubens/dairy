import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_controller.dart';
import '../../orders/data/order_repository.dart';
import '../../products/domain/product.dart';

class CartLine {
  final Product product;
  final double quantity;
  CartLine(this.product, this.quantity);

  double get subtotal => (product.price ?? 0) * quantity;
}

class Cart extends Notifier<List<CartLine>> {
  @override
  List<CartLine> build() => [];

  void add(Product product, double quantity) {
    if (quantity <= 0) return;
    final index = state.indexWhere((l) => l.product.id == product.id);
    if (index >= 0) {
      final updated = [...state];
      updated[index] =
          CartLine(product, updated[index].quantity + quantity);
      state = updated;
    } else {
      state = [...state, CartLine(product, quantity)];
    }
  }

  void remove(int productId) {
    state = state.where((l) => l.product.id != productId).toList();
  }

  void clear() => state = [];

  double get total => state.fold<double>(0, (sum, l) => sum + l.subtotal);

  /// Finaliza a venda: monta os itens, persiste via API e, em caso de
  /// sucesso, limpa o carrinho e invalida pedidos + métricas.
  Future<void> checkout() async {
    final salePointId = ref.read(currentSalePointIdProvider);
    if (salePointId == null) {
      throw StateError('Sessão inválida');
    }
    if (state.isEmpty) return;

    final items = state
        .map((l) => <String, dynamic>{
              'product_id': l.product.id,
              l.product.unitKey: l.quantity,
            })
        .toList();

    await ref.read(orderRepositoryProvider).createOrder(salePointId, items);

    clear();
    ref.invalidate(ordersProvider);
  }
}

final cartProvider = NotifierProvider<Cart, List<CartLine>>(Cart.new);

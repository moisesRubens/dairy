import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_controller.dart';
import '../../clients/data/client_repository.dart';
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

  /// Finaliza a venda: monta os itens, persiste (online ou enfileira offline) e,
  /// em caso de sucesso, limpa o carrinho e invalida pedidos. Retorna `true` se
  /// foi enviada online; `false` se ficou registrada offline (será sincronizada).
  Future<bool> checkout() async {
    final salePointId = ref.read(currentSalePointIdProvider);
    if (salePointId == null) {
      throw StateError('Sessão inválida');
    }
    if (state.isEmpty) return true;

    final items = state
        .map((l) => <String, dynamic>{
              'product_id': l.product.id,
              l.product.unitKey: l.quantity,
            })
        .toList();

    final clientId = ref.read(selectedClientProvider)?.id;
    final payment = ref.read(selectedPaymentProvider);
    final sentOnline = await ref.read(orderRepositoryProvider).createOrder(
          salePointId,
          items,
          clientId: clientId,
          paymentMethod: payment,
        );

    clear();
    ref.read(selectedClientProvider.notifier).state = null;
    ref.read(selectedPaymentProvider.notifier).state = 'dinheiro';
    ref.invalidate(ordersProvider);
    return sentOnline;
  }
}

final cartProvider = NotifierProvider<Cart, List<CartLine>>(Cart.new);

/// Forma de pagamento selecionada para a próxima venda (PDV).
final selectedPaymentProvider = StateProvider<String>((ref) => 'dinheiro');

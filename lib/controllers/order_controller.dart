import 'package:flutter/foundation.dart';
import '../domain/order.dart';
import '../database/order_dao.dart';
import '../services/order_service.dart';

class OrderController {
  final OrderDao _orderDao = OrderDao();
  final OrderService _orderService = OrderService();

  // 🔥 NOTIFIER PARA ATUALIZAR A UI
  final ValueNotifier<List<Order>> orders = ValueNotifier<List<Order>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);

  // ============================================================
  // 🔥 CARREGAR PEDIDOS DO BANCO LOCAL
  // ============================================================
  Future<void> loadOrders() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      
      final ordersList = await _orderService.getLocalOrders();
      orders.value = ordersList;
      
      debugPrint('📋 ${ordersList.length} pedidos carregados');
    } catch (e) {
      errorMessage.value = 'Erro ao carregar pedidos: $e';
      debugPrint('❌ Erro ao carregar pedidos: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // 🔥 CARREGAR PEDIDOS POR DATA
  // ============================================================
  Future<void> loadOrdersByDate(String date) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      
      final ordersList = await _orderService.getLocalOrdersByDate(date);
      orders.value = ordersList;
      
      debugPrint('📋 ${ordersList.length} pedidos carregados para data: $date');
    } catch (e) {
      errorMessage.value = 'Erro ao carregar pedidos: $e';
      debugPrint('❌ Erro ao carregar pedidos por data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ============================================================
  // 🔥 DELETAR PEDIDO
  // ============================================================
  Future<void> deleteOrder(String date, String description) async {
    try {
      await _orderDao.deleteOrder(date, description);
      await loadOrders(); // Recarrega a lista
      debugPrint('🗑️ Pedido deletado: $description - $date');
    } catch (e) {
      debugPrint('❌ Erro ao deletar pedido: $e');
      rethrow;
    }
  }

  // ============================================================
  // 🔥 LIMPAR RECURSOS
  // ============================================================
  void dispose() {
    orders.dispose();
    isLoading.dispose();
    errorMessage.dispose();
  }
}
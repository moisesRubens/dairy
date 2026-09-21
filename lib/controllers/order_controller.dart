import 'package:flutter/foundation.dart';
import '../domain/order2.dart';
import '../database/order_dao.dart';
import '../services/order_service.dart';

class OrderController 
{
  final OrderDao _orderDao = OrderDao();
  final OrderService _orderService = OrderService();

  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);
  final ValueNotifier<List<Order>> _orders = ValueNotifier<List<Order>>([]);

  ValueNotifier<List<Order>> get orders2 => _orders;


  Future<void> loadOrders() async 
  {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      
      final ordersList = await _orderService.getLocalOrders();
      _orders.value = ordersList;
      
      debugPrint('📋 ${ordersList.length} pedidos carregados');
    } 
    catch (e) 
    {
      errorMessage.value = 'Erro ao carregar pedidos: $e';
      debugPrint('❌ Erro ao carregar pedidos: $e');
    } 
    finally 
    {
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
      _orders.value = ordersList;
      
      debugPrint('📋 ${ordersList.length} pedidos carregados para data: $date');
    } catch (e) {
      errorMessage.value = 'Erro ao carregar pedidos: $e';
      debugPrint('❌ Erro ao carregar pedidos por data: $e');
    } finally {
      isLoading.value = false;
    }
  }
  

  Future<void> deleteOrder(Order order) async 
  {
    try 
    {
      await _orderDao.deleteOrder(order.dateTime, order.description);
      await loadOrders(); 
    } 
    catch (e) 
    {
      debugPrint('❌ Erro ao deletar pedido: $e');
      rethrow;
    }
  }

  // ============================================================
  // 🔥 LIMPAR RECURSOS
  // ============================================================
  void dispose() {
    _orders.dispose();
    isLoading.dispose();
    errorMessage.dispose();
  }
}
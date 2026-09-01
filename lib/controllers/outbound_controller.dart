import 'package:dairy/domain/outbound.dart';
import 'package:dairy/domain/product.dart';
import 'package:dairy/services/outbound_service.dart';
import 'package:flutter/material.dart';

class OutboundController extends ChangeNotifier
{
  List<Product>? _list = [];
  bool _isLoading = false;
  final OutboundService _outboundService;

  List<Product>? get outbounds => _list;
  bool get isLoading => _isLoading;

  OutboundController({OutboundService? outboundService}) : _outboundService = outboundService ?? OutboundService();
  

  Future<bool> createOutboundController(List<Product> products, double quantity, String obs) async 
  {
    return await _outboundService.createOutbound(products, quantity, obs);
  }

  Future<void> refreshOutbounds() async
  {
    _isLoading = true;
    notifyListeners();
    try 
    {
      _list = await _outboundService.loadOutboundsByDate(null);
    }
    catch (e)
    {
      debugPrint("Falha ao recarregar retiradas");
    }
    finally
    {
      _isLoading = false;
      notifyListeners();
    }
  }
}
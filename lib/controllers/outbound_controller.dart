import 'package:dairy/domain/outbound.dart';
import 'package:dairy/domain/product.dart';
import 'package:dairy/services/outbound_service.dart';
import 'package:flutter/material.dart';

class OutboundController extends ChangeNotifier
{
  List<Outbound> list = [];
  final OutboundService _outboundService;

  OutboundController({OutboundService? outboundService}) : _outboundService = outboundService ?? OutboundService();
  

  Future<bool> createOutboundController(List<Product> products, double quantity, String obs) async 
  {
    return await _outboundService.createOutbound(products, quantity, obs);
  }

  Future<void> refreshOubounds()
  {
    
  }
}
import 'package:dairy/domain/product.dart';
import 'package:dairy/services/product_service.dart';
import 'package:flutter/material.dart';

class ProductController extends ChangeNotifier
{
  List<Product> _list = [];
  final ProductService _service;
  bool _isLoading = false;

  ProductController({ProductService? service}) : _service = service ?? ProductService() 
  {
    refreshProducts();
  }
  
  bool get isLoading => _isLoading;
  List<Product> get products => List.unmodifiable(_list);

  Future<bool> add(Product product) async
  {
    try
    {
      await _service.createProduct(product);
      await refreshProducts();
      return true;
    } 
    catch(e)
    {
      return false;
    }
  }

  Future<void> refreshProducts() async 
  {
    _isLoading = true;
    notifyListeners();
    try 
    {
      _list = await _service.getProducts();
    }
    catch(e)
    {
      print("EXCECAO NO REFRESH PRODUCTS");
    }
    finally
    {
      _isLoading = false;
      notifyListeners();
    }
  }
}
import 'package:dairy/domain/product.dart';
import 'package:dairy/services/product_service.dart';
import 'package:flutter/material.dart';

class ProductController {
  ValueNotifier<List<Product>> _productsData = ValueNotifier<List<Product>>([]);
  final ProductService _service;
  ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

  ProductController({ProductService? service})
    : _service = service ?? ProductService() {
    refreshProducts();
  }

  ValueNotifier<bool> get isLoading => _isLoading;

  void setIsLoading(bool value) {
    _isLoading.value = value;
  }

  ValueNotifier<List<Product>> get productsData => _productsData;

  Future<bool> add(Product product) async 
  {
    try 
    {
      if (await _service.createProduct(product)) 
      {
        refreshProducts();
      }
      return true;
    } 
    catch (e) 
    {
      return false;
    }
  }

  Future<void> refreshProducts() async 
  {
    _isLoading.value = true;
    try 
    {
      _productsData.value = await _service.getProducts();
    } 
    catch (e) 
    {
      print("EXCECAO NO REFRESH PRODUCTS");
    } finally {
      _isLoading.value = false;
    }
  }
}

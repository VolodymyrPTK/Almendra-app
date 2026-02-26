import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../repositories/products_repository.dart';

enum ProductsStatus { initial, loading, success, loadingMore, error }

class ProductsProvider extends ChangeNotifier {
  ProductsProvider({ProductsRepository? repository})
      : _repository = repository ?? ProductsRepository();

  final ProductsRepository _repository;

  List<Product> _products = [];
  ProductsStatus _status = ProductsStatus.initial;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  String? _errorMessage;

  List<Product> get products => _products;
  ProductsStatus get status => _status;
  bool get hasMore => _hasMore;
  bool get isLoading => _status == ProductsStatus.loading;
  bool get isLoadingMore => _status == ProductsStatus.loadingMore;
  String? get errorMessage => _errorMessage;

  Future<void> loadProducts() async {
    if (_status == ProductsStatus.loading) return;

    _status = ProductsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.fetchFirstPage();
      _products = result.products;
      _lastDocument = result.lastDoc;
      _hasMore = result.products.length >= 15;
      _status = ProductsStatus.success;
    } catch (e) {
      _status = ProductsStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasMore ||
        _status == ProductsStatus.loadingMore ||
        _status == ProductsStatus.loading ||
        _lastDocument == null) {
      return;
    }

    _status = ProductsStatus.loadingMore;
    notifyListeners();

    try {
      final result = await _repository.fetchNextPage(_lastDocument!);
      _products = [..._products, ...result.products];
      _lastDocument = result.lastDoc ?? _lastDocument;
      _hasMore = result.products.length >= 15;
      _status = ProductsStatus.success;
    } catch (e) {
      _status = ProductsStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  void retry() {
    _products = [];
    _lastDocument = null;
    _hasMore = true;
    loadProducts();
  }
}

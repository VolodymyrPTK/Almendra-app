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
  List<String>? _currentCategoryFilter;
  final List<String> _currentBooleanFilters = [];
  bool _fetchingOutOfStockPhase = false;

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
    _fetchingOutOfStockPhase = false;
    notifyListeners();

    try {
      final result = await _repository.fetchFirstPage(
        categoryFilter: _currentCategoryFilter,
        booleanFilters: _currentBooleanFilters,
        outOfStock: false,
      );
      _products = result.products;
      _lastDocument = result.lastDoc;
      _hasMore = result.products.length >= 15;

      // If category is selected and we have no more in-stock, try to start out-of-stock phase
      if (!_hasMore && _currentCategoryFilter != null) {
        final outResult = await _repository.fetchFirstPage(
          categoryFilter: _currentCategoryFilter,
          booleanFilters: _currentBooleanFilters,
          outOfStock: true,
        );
        if (outResult.products.isNotEmpty) {
          _products.addAll(outResult.products);
          _lastDocument = outResult.lastDoc;
          _hasMore = outResult.products.length >= 15;
          _fetchingOutOfStockPhase = true;
        }
      }

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
        _status == ProductsStatus.loading) {
      return;
    }

    _status = ProductsStatus.loadingMore;
    notifyListeners();

    try {
      if (!_fetchingOutOfStockPhase) {
        // Still in In-Stock phase
        if (_lastDocument == null) {
            // This case should theoretically not happen if _hasMore is true but lastDoc is null
            // unless the first page was empty and we didn't transition yet.
            _status = ProductsStatus.success;
            notifyListeners();
            return;
        }
        final result = await _repository.fetchNextPage(
          _lastDocument!,
          categoryFilter: _currentCategoryFilter,
          booleanFilters: _currentBooleanFilters,
          outOfStock: false,
        );
        _products = [..._products, ...result.products];
        _lastDocument = result.lastDoc;
        
        if (result.products.length < 15) {
          // Finished In-Stock. Check if we should start Out-of-Stock phase
          if (_currentCategoryFilter != null) {
            _fetchingOutOfStockPhase = true;
            final outResult = await _repository.fetchFirstPage(
              categoryFilter: _currentCategoryFilter,
              booleanFilters: _currentBooleanFilters,
              outOfStock: true,
            );
            _products.addAll(outResult.products);
            _lastDocument = outResult.lastDoc;
            _hasMore = outResult.products.length >= 15;
          } else {
            _hasMore = false;
          }
        } else {
          _hasMore = true;
        }
      } else {
        // In Out-of-Stock phase
        if (_lastDocument == null) {
            _hasMore = false;
            _status = ProductsStatus.success;
            notifyListeners();
            return;
        }
        final result = await _repository.fetchNextPage(
          _lastDocument!,
          categoryFilter: _currentCategoryFilter,
          booleanFilters: _currentBooleanFilters,
          outOfStock: true,
        );
        _products = [..._products, ...result.products];
        _lastDocument = result.lastDoc;
        _hasMore = result.products.length >= 15;
      }
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

  void setCategoryFilter(List<String>? newFilter) {
    if (_currentCategoryFilter == newFilter) return;
    _currentCategoryFilter = newFilter;
    
    // Reset and reload
    _products = [];
    _lastDocument = null;
    _hasMore = true;
    loadProducts();
  }

  void toggleBooleanFilter(String filterKey) {
    if (_currentBooleanFilters.contains(filterKey)) {
      _currentBooleanFilters.remove(filterKey);
    } else {
      _currentBooleanFilters.add(filterKey);
    }

    _products = [];
    _lastDocument = null;
    _hasMore = true;
    loadProducts();
  }

  bool isFilterActive(String filterKey) {
    return _currentBooleanFilters.contains(filterKey);
  }

  void clearBooleanFilters() {
    if (_currentBooleanFilters.isEmpty) return;
    _currentBooleanFilters.clear();
    
    _products = [];
    _lastDocument = null;
    _hasMore = true;
    loadProducts();
  }

  Future<List<Product>> fetchFavorites(List<String> ids) {
    return _repository.fetchFavorites(ids);
  }

  void _sortProducts() {
    _products.sort((a, b) {
      if (a.outOfStock == b.outOfStock) return 0;
      return a.outOfStock ? 1 : -1;
    });
  }
}

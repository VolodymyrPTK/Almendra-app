import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductsRepository {
  ProductsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const int _pageSize = 15;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('products');

  Future<({List<Product> products, DocumentSnapshot? lastDoc})> fetchFirstPage({
    List<String>? categoryFilter,
    List<String>? booleanFilters,
    bool? outOfStock,
  }) async {
    Query<Map<String, dynamic>> query = _collection;

    if (outOfStock != null) {
      query = query.where('outOfStock', isEqualTo: outOfStock);
    }

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      if (categoryFilter.length == 1) {
        query = query.where('category', isEqualTo: categoryFilter.first);
      } else {
        query = query.where('category', whereIn: categoryFilter.take(10).toList());
      }
    }

    if (booleanFilters != null && booleanFilters.isNotEmpty) {
      for (final filter in booleanFilters) {
        query = query.where(filter, isEqualTo: true);
      }
    }

    // We fetch without orderBy('name') to avoid 64+ composite index requirements in Firestore.
    // Client-side sorting is applied below cleanly.
    final snapshot = await query
        .limit(_pageSize)
        .get(const GetOptions(source: Source.serverAndCache));

    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    
    var docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final nameA = (a.data()['name']?.toString() ?? '').toLowerCase();
      final nameB = (b.data()['name']?.toString() ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });

    final products = docs.map((doc) => Product.fromFirestore(doc)).toList();

    return (products: products, lastDoc: lastDoc);
  }

  /// Fetches the next page after [lastDocument].
  Future<({List<Product> products, DocumentSnapshot? lastDoc})> fetchNextPage(
    DocumentSnapshot lastDocument, {
    List<String>? categoryFilter,
    List<String>? booleanFilters,
    bool? outOfStock,
  }) async {
    Query<Map<String, dynamic>> query = _collection;

    if (outOfStock != null) {
      query = query.where('outOfStock', isEqualTo: outOfStock);
    }
    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      if (categoryFilter.length == 1) {
        query = query.where('category', isEqualTo: categoryFilter.first);
      } else {
        query = query.where('category', whereIn: categoryFilter.take(10).toList());
      }
    }

    if (booleanFilters != null && booleanFilters.isNotEmpty) {
      for (final filter in booleanFilters) {
        query = query.where(filter, isEqualTo: true);
      }
    }

    final snapshot = await query
        .startAfterDocument(lastDocument)
        .limit(_pageSize)
        .get(const GetOptions(source: Source.serverAndCache));

    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    var docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final nameA = (a.data()['name']?.toString() ?? '').toLowerCase();
      final nameB = (b.data()['name']?.toString() ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });

    final products = docs.map((doc) => Product.fromFirestore(doc)).toList();

    return (products: products, lastDoc: lastDoc);
  }

  static List<Product>? _productCache;

  /// Fetches products matching search query.
  Future<List<Product>> fetchSearchResults(String query) async {
    // If not cached, fetch all products once to allow true substring search
    if (_productCache == null) {
      final snapshot = await _collection.get(const GetOptions(source: Source.serverAndCache));
      _productCache = snapshot.docs.map(Product.fromFirestore).toList();
    }

    final lowerQuery = query.toLowerCase();
    
    final nameMatches = <Product>[];
    final brandMatches = <Product>[];
    final detailMatches = <Product>[];
    final categoryMatches = <Product>[];
    final skladMatches = <Product>[];

    for (final p in _productCache!) {
      final nameLower = p.name.toLowerCase();
      final brandLower = p.brand.toLowerCase();
      final detailLower = p.detail.toLowerCase();
      final catLower = (p.category ?? '').toLowerCase();
      final skladLower = (p.sklad ?? '').toLowerCase();

      if (nameLower.contains(lowerQuery)) {
        nameMatches.add(p);
      } else if (brandLower.contains(lowerQuery)) {
        brandMatches.add(p);
      } else if (detailLower.contains(lowerQuery)) {
        detailMatches.add(p);
      } else if (catLower.contains(lowerQuery)) {
        categoryMatches.add(p);
      } else if (skladLower.contains(lowerQuery)) {
        skladMatches.add(p);
      }
    }

    final allMatches = [
      ...nameMatches,
      ...brandMatches,
      ...detailMatches,
      ...categoryMatches,
      ...skladMatches,
    ];

    final inStock = allMatches.where((p) => !p.outOfStock);
    final outOfStock = allMatches.where((p) => p.outOfStock);

    return [...inStock, ...outOfStock];
  }

  /// Fetches products by a list of IDs.
  Future<List<Product>> fetchFavorites(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    // If not cached, fetch all products once
    if (_productCache == null) {
      final snapshot = await _collection.get(const GetOptions(source: Source.serverAndCache));
      _productCache = snapshot.docs.map(Product.fromFirestore).toList();
    }

    return _productCache!.where((p) => ids.contains(p.id)).toList();
  }

  /// Fetches categories and subcategories.
  Future<Map<String, List<String>>> fetchCategories() async {
    final doc = await _firestore.collection('data').doc('categories').get(const GetOptions(source: Source.serverAndCache));
    if (!doc.exists || doc.data() == null) return {};
    
    final data = doc.data()!;
    final result = <String, List<String>>{};
    
    for (final entry in data.entries) {
      if (entry.value is List) {
        result[entry.key] = (entry.value as List).map((e) => e.toString()).toList();
      }
    }
    return result;
  }


}

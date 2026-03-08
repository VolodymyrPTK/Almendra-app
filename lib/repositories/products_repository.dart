import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class ProductsRepository {
  ProductsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const int _pageSize = 15;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('products');

  /// Fetches the first page of products.
  Future<({List<Product> products, DocumentSnapshot? lastDoc})>
  fetchFirstPage() async {
    final snapshot = await _collection
        .orderBy('name')
        .limit(_pageSize)
        .get(const GetOptions(source: Source.serverAndCache));

    return _mapSnapshot(snapshot);
  }

  /// Fetches the next page after [lastDocument].
  Future<({List<Product> products, DocumentSnapshot? lastDoc})> fetchNextPage(
    DocumentSnapshot lastDocument,
  ) async {
    final snapshot = await _collection
        .orderBy('name')
        .startAfterDocument(lastDocument)
        .limit(_pageSize)
        .get(const GetOptions(source: Source.serverAndCache));

    return _mapSnapshot(snapshot);
  }

  static List<Product>? _cachedAllProducts;

  /// Fetches products matching search query.
  Future<List<Product>> fetchSearchResults(String query) async {
    // If not cached, fetch all products once to allow true substring search
    if (_cachedAllProducts == null) {
      final snapshot = await _collection.get(const GetOptions(source: Source.serverAndCache));
      _cachedAllProducts = snapshot.docs.map(Product.fromFirestore).toList();
    }

    final lowerQuery = query.toLowerCase();
    
    final nameMatches = <Product>[];
    final brandMatches = <Product>[];
    final detailMatches = <Product>[];
    final categoryMatches = <Product>[];
    final skladMatches = <Product>[];

    for (final p in _cachedAllProducts!) {
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

    return [
      ...nameMatches,
      ...brandMatches,
      ...detailMatches,
      ...categoryMatches,
      ...skladMatches,
    ];
  }

  ({List<Product> products, DocumentSnapshot? lastDoc}) _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final products = snapshot.docs.map(Product.fromFirestore).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    return (products: products, lastDoc: lastDoc);
  }
}

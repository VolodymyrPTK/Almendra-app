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

  ({List<Product> products, DocumentSnapshot? lastDoc}) _mapSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final products = snapshot.docs.map(Product.fromFirestore).toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    return (products: products, lastDoc: lastDoc);
  }
}

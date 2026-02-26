import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final num sellPrice;
  final String brand;
  final String detail;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.name,
    required this.sellPrice,
    required this.brand,
    required this.detail,
    this.imageUrl,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] as String? ?? '',
      sellPrice: data['sellPrice'] as num? ?? 0,
      brand: data['brand'] as String? ?? '',
      detail: data['detail'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? data['image'] as String?,
    );
  }
}

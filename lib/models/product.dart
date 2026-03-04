import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final num sellPrice;
  final String brand;
  final String detail;
  final String? imageUrl;
  final String? category;
  final String? description;
  final String? vitamins;
  final String? sklad; // ingredients/composition
  final num? kcal;
  final num? fat;
  final num? protein;
  final num? carbo;
  final bool isVegan;
  final bool isProteinik;
  final bool isLowCarbo;
  final bool isFreeGluten;
  final bool isFreeSugar;
  final bool isFreeLactosa;
  final bool isKeto;

  const Product({
    required this.id,
    required this.name,
    required this.sellPrice,
    required this.brand,
    required this.detail,
    this.imageUrl,
    this.category,
    this.description,
    this.vitamins,
    this.sklad,
    this.kcal,
    this.fat,
    this.protein,
    this.carbo,
    this.isVegan = false,
    this.isProteinik = false,
    this.isLowCarbo = false,
    this.isFreeGluten = false,
    this.isFreeSugar = false,
    this.isFreeLactosa = false,
    this.isKeto = false,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
    return Product(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      sellPrice: _toNum(data['sellPrice']) ?? 0,
      brand: data['brand']?.toString() ?? '',
      detail: data['detail']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? data['image']?.toString(),
      category: data['category']?.toString(),
      description: data['description']?.toString(),
      vitamins: data['vitamins']?.toString(),
      sklad: data['sklad']?.toString(),
      kcal: _toNum(data['kcal']),
      fat: _toNum(data['fat']),
      protein: _toNum(data['protein']),
      carbo: _toNum(data['carbo']),
      isVegan: _toBool(data['isVegan'] ?? data['vegan']),
      isProteinik: _toBool(data['isProteinik'] ?? data['proteinik']),
      isLowCarbo: _toBool(data['isLowCarbo'] ?? data['lowCarbo']),
      isFreeGluten: _toBool(data['isFreeGluten'] ?? data['freeGluten']),
      isFreeSugar: _toBool(data['isFreeSugar'] ?? data['freeSugar']),
      isFreeLactosa: _toBool(data['isFreeLactosa'] ?? data['freeLactosa']),
      isKeto: _toBool(data['isKeto'] ?? data['keto']),
    );
  }

  static num? _toNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  /// Collect all active diet tags into a list of labels
  List<String> get dietTags {
    final tags = <String>[];
    if (isVegan) tags.add('Веган');
    if (isProteinik) tags.add('Протеїн');
    if (isLowCarbo) tags.add('Низьковуглеводний');
    if (isFreeGluten) tags.add('Без глютену');
    if (isFreeSugar) tags.add('Без цукру');
    if (isFreeLactosa) tags.add('Без лактози');
    if (isKeto) tags.add('Кето');
    return tags;
  }
}

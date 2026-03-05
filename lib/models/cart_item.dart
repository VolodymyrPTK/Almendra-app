class CartItem {
  final String id;
  final String name;
  final double price;
  final String? image;
  final int quantity;

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    this.quantity = 1,
  });

  CartItem copyWith({int? quantity}) => CartItem(
        id: id,
        name: name,
        price: price,
        image: image,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'image': image,
        'quantity': quantity,
      };

  factory CartItem.fromMap(Map<String, dynamic> m) => CartItem(
        id: m['id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0,
        image: m['image']?.toString(),
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
      );
}

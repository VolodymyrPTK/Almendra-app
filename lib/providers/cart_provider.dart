import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<CartItem> _items = [];
  StreamSubscription<DocumentSnapshot>? _cartSub;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (s, e) => s + e.quantity);
  double get total => _items.fold(0.0, (s, e) => s + e.price * e.quantity);
  bool get isEmpty => _items.isEmpty;
  bool get isLoggedIn => _auth.currentUser != null;

  CartProvider() {
    _auth.authStateChanges().listen((user) {
      _cartSub?.cancel();
      if (user != null) {
        _subscribe(user.uid);
      } else {
        _items = [];
        notifyListeners();
      }
    });
  }

  void _subscribe(String uid) {
    _cartSub = _db
        .collection('profiles')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      final list = doc.data()?['cart'] as List?;
      _items = list == null
          ? []
          : list.whereType<Map<String, dynamic>>().map(CartItem.fromMap).toList();
      notifyListeners();
    }, onError: (e) => debugPrint('CartProvider stream error: $e'));
  }

  @override
  void dispose() {
    _cartSub?.cancel();
    super.dispose();
  }

  /// Returns false if user is not logged in, throws on Firestore error.
  Future<bool> addToCart(Product product) async {
    final uid = _auth.currentUser?.uid;
    debugPrint('addToCart: uid=$uid product=${product.id}');
    if (uid == null) return false;

    final idx = _items.indexWhere((e) => e.id == product.id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity + 1);
    } else {
      _items.add(CartItem(
        id: product.id,
        name: product.name,
        price: product.sellPrice.toDouble(),
        image: product.imageUrl,
      ));
    }
    notifyListeners();
    await _sync(uid); // await so caller gets the error
    return true;
  }

  Future<void> remove(String productId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _items.removeWhere((e) => e.id == productId);
    notifyListeners();
    await _sync(uid);
  }

  Future<void> updateQuantity(String productId, int delta) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final idx = _items.indexWhere((e) => e.id == productId);
    if (idx < 0) return;
    final newQty = _items[idx].quantity + delta;
    if (newQty <= 0) {
      _items.removeAt(idx);
    } else {
      _items[idx] = _items[idx].copyWith(quantity: newQty);
    }
    notifyListeners();
    await _sync(uid);
  }

  Future<void> _sync(String uid) async {
    debugPrint('_sync: writing ${_items.length} items for uid=$uid');
    await _db.collection('profiles').doc(uid).set(
      {'cart': _items.map((e) => e.toMap()).toList()},
      SetOptions(merge: true),
    );
    debugPrint('_sync: done');
  }
}

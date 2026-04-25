import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FavoritesProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  List<String> _favorites = [];
  bool _loading = false;

  List<String> get favorites => _favorites;
  bool get isLoading => _loading;

  FavoritesProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadFavorites(user.uid);
      } else {
        _favorites = [];
        notifyListeners();
      }
    });
  }

  Future<void> _loadFavorites(String uid) async {
    _loading = true;
    notifyListeners();

    try {
      final doc = await _db.collection('profiles').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['favorites'] != null) {
          _favorites = List<String>.from(data['favorites']);
        } else {
          _favorites = [];
        }
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> toggleFavorite(String productId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final isFav = _favorites.contains(productId);

    if (isFav) {
      _favorites.remove(productId);
    } else {
      _favorites.add(productId);
    }
    notifyListeners();

    try {
      await _db.collection('profiles').doc(user.uid).set({
        'favorites': _favorites,
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error saving favorite: $e');
      // revert on failure
      if (isFav) {
        _favorites.add(productId);
      } else {
        _favorites.remove(productId);
      }
      notifyListeners();
      return false;
    }
  }

  bool isFavorite(String productId) {
    return _favorites.contains(productId);
  }
}

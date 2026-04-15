import 'package:flutter/material.dart';

class HomeOverlayProvider extends ChangeNotifier {
  bool _showHomeOverlay = true;

  bool get showHomeOverlay => _showHomeOverlay;

  void show() {
    if (!_showHomeOverlay) {
      _showHomeOverlay = true;
      notifyListeners();
    }
  }

  void hide() {
    if (_showHomeOverlay) {
      _showHomeOverlay = false;
      notifyListeners();
    }
  }

  void toggle() {
    _showHomeOverlay = !_showHomeOverlay;
    notifyListeners();
  }
}

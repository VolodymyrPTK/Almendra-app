import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_overlay_provider.dart';
import 'products_screen.dart';
import 'home_overlay.dart';

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Base layer: Store (Product list)
          const ProductsScreen(),
          
          // Overlay layer: Home Screen
          Positioned.fill(
            child: Consumer<HomeOverlayProvider>(
              builder: (context, overlayProvider, child) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 1.05, end: 1.0).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: overlayProvider.showHomeOverlay
                      ? const HomeOverlay(key: ValueKey('HomeOverlay'))
                      : const SizedBox.shrink(key: ValueKey('EmptyOverlay')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

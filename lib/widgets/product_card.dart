import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import 'product_detail_sheet.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product});
  final Product product;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressAnim;
  bool _added = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pressAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Future<void> _onAddToCart() async {
    await _pressCtrl.forward();
    await _pressCtrl.reverse();
    setState(() => _added = true);
    if (!mounted) return;

    // Pulse feedback or snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('«${widget.product.name}» додано'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );

    // Reset after some time for demo purposes if needed, or keep as added
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Core Neumorphic Colors — bright beige palette
    final Color baseColor = isDark ? const Color(0xFF302B26) : Colors.white;
    final Color lightShadow = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFF5EFE6);
    final Color darkShadow = isDark
        ? Colors.black.withOpacity(0.6)
        : const Color(0xFFAEA598);
    final Color textColor = isDark ? Colors.white : const Color(0xFF3B3228);
    final Color subTextColor = isDark
        ? Colors.white70
        : const Color(0xFF7A6F63);

    return ScaleTransition(
      scale: _pressAnim,
      child: GestureDetector(
        onTap: () => ProductDetailSheet.show(context, widget.product),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              // Top-left highlight (light source)
              BoxShadow(
                color: lightShadow,
                offset: const Offset(-6, -6),
                blurRadius: 12,
              ),
              // Bottom-right deep shadow
              BoxShadow(
                color: darkShadow,
                offset: const Offset(6, 6),
                blurRadius: 12,
              ),
              // Soft ambient shadow for depth
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFFC0B8AB))
                    .withOpacity(0.35),
                offset: const Offset(0, 8),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Product Image ───────────────────────────────────
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: widget.product.imageUrl != null
                      ? Transform.scale(
                          scale: 1.25,
                          child: CachedNetworkImage(
                            imageUrl: widget.product.imageUrl!,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) => Icon(
                              Icons.restaurant_rounded,
                              size: 48,
                              color: textColor.withOpacity(0.2),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.restaurant_rounded,
                          size: 48,
                          color: textColor.withOpacity(0.2),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Product Info ─────────────────────────────────────
              SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.2,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.product.detail.isEmpty
                            ? widget.product.brand
                            : widget.product.detail,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: subTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Buttons Row ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    // Price Tag (wider)
                    Expanded(
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: darkShadow.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [darkShadow.withOpacity(0.15), baseColor],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${widget.product.sellPrice.toStringAsFixed(0)} ₴',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: subTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add to Cart Button (Circular)
                    GestureDetector(
                      onTap: _onAddToCart,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _added
                                ? [
                                    const Color(0xFF6B8E5E),
                                    const Color(0xFF8CAF7B),
                                  ]
                                : [
                                    const Color(0xFFA8C69F),
                                    const Color(0xFF8CAF7B),
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8CAF7B).withOpacity(0.4),
                              offset: const Offset(3, 3),
                              blurRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              offset: const Offset(-2, -2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _added
                                ? Icons.check_rounded
                                : Icons.shopping_cart_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

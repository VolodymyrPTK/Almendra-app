import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import 'auth_sheet.dart';
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
  bool _addedToCart = false;

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
    if (widget.product.outOfStock) return;
    await _pressCtrl.forward();
    await _pressCtrl.reverse();
    if (!mounted) return;

    final cart = context.read<CartProvider>();
    final added = await cart.addToCart(widget.product);

    if (!mounted) return;
    if (!added) {
      AuthSheet.show(context);
      return;
    }

    setState(() => _addedToCart = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '«${widget.product.name}» додано в кошик',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFE8734A),
        duration: const Duration(seconds: 2),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _onToggleFavorite() async {
    await _pressCtrl.forward();
    await _pressCtrl.reverse();
    if (!mounted) return;

    final favs = context.read<FavoritesProvider>();
    final success = await favs.toggleFavorite(widget.product.id);

    if (!mounted) return;
    if (!success) {
      AuthSheet.show(context);
      return;
    }

    if (favs.isFavorite(widget.product.id)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '«${widget.product.name}» додано в улюблені',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFE8734A),
          duration: const Duration(seconds: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Core Neumorphic Colors — bright beige palette
    final Color baseColor = isDark ? const Color(0xFF302B26) : Colors.white;
    final Color lightShadow = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF5EFE6);
    final Color darkShadow = isDark
        ? Colors.black.withValues(alpha: 0.6)
        : const Color(0xFFAEA598);
    final Color textColor = isDark ? Colors.white : const Color(0xFF3B3228);
    final Color subTextColor = isDark
        ? Colors.white70
        : const Color(0xFF7A6F63);

    final isOutOfStock = widget.product.outOfStock;
    final isFavorite =
        context.watch<FavoritesProvider>().isFavorite(widget.product.id);

    return ScaleTransition(
      scale: _pressAnim,
      child: GestureDetector(
        onTap: () => ProductDetailSheet.show(context, widget.product),
        child: Container(
          foregroundDecoration: isOutOfStock
              ? BoxDecoration(
                  color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.2),
                  borderRadius: BorderRadius.circular(28),
                )
              : null,
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
                    .withValues(alpha: 0.35),
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
                      ? ColorFiltered(
                          colorFilter: isOutOfStock
                              ? const ColorFilter.matrix([
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0, 0, 0, 1, 0,
                                ])
                              : const ColorFilter.mode(
                                  Colors.transparent, BlendMode.multiply),
                          child: Transform.scale(
                            scale: 1.25,
                            child: CachedNetworkImage(
                              imageUrl: widget.product.imageUrl!,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (_, __, ___) => Icon(
                                Icons.restaurant_rounded,
                                size: 48,
                                color: textColor.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.restaurant_rounded,
                          size: 48,
                          color: textColor.withValues(alpha: 0.2),
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
                    // Favorite Button (Circular)
                    GestureDetector(
                      onTap: _onToggleFavorite,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: baseColor,
                          border: Border.all(
                            color: darkShadow.withValues(alpha: 0.15),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: darkShadow.withValues(alpha: 0.15),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                            if (isFavorite)
                              BoxShadow(
                                color: const Color(0xFFE8734A).withValues(alpha: 0.2), // gentle red glow
                                offset: const Offset(0, 2),
                                blurRadius: 6,
                              ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: isFavorite
                                ? const Color(0xFFE8734A)
                                : subTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Combined Price & Cart Pill
                    Expanded(
                      child: GestureDetector(
                        onTap: _onAddToCart,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(19),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isOutOfStock
                                  ? [
                                      subTextColor.withValues(alpha: 0.3),
                                      subTextColor.withValues(alpha: 0.4),
                                    ]
                                  : _addedToCart
                                      ? [
                                          const Color(0xFFE8734A)
                                              .withValues(alpha: 0.7),
                                          const Color(0xFFE8734A),
                                        ]
                                      : [
                                          const Color(0xFFF19E81),
                                          const Color(0xFFE8734A),
                                        ],
                            ),
                            boxShadow: [
                              if (!isOutOfStock)
                                BoxShadow(
                                  color: const Color(0xFFE8734A)
                                      .withValues(alpha: 0.35),
                                  offset: const Offset(0, 6),
                                  blurRadius: 16,
                                ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Content
                              Row(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 250),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.2,
                                        ),
                                        child: Text(
                                          '${widget.product.sellPrice.toStringAsFixed(0)} ₴',
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 44,
                                    child: Center(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 200),
                                        child: Icon(
                                          _addedToCart
                                              ? Icons.check_rounded
                                              : isOutOfStock
                                                  ? Icons.not_interested_rounded
                                                  : Icons.shopping_cart_outlined,
                                          key: ValueKey(
                                              '${_addedToCart}_$isOutOfStock'),
                                          size: 20,
                                          color: isOutOfStock
                                              ? Colors.white54
                                              : Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              offset: const Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

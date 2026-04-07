import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/auth_provider.dart' as ap;
import '../providers/cart_provider.dart';
import 'auth_sheet.dart';
import 'checkout_sheet.dart';

class CartSheet extends StatelessWidget {
  const CartSheet({super.key});

  static void show(BuildContext context) {
    final cart = context.read<CartProvider>();
    final auth = context.read<ap.AuthProvider>();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cart',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cart),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: const _CartContent(),
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ── Cart Content ───────────────────────────────────────────────

class _CartContent extends StatelessWidget {
  const _CartContent();

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final cardBg   = isDark ? const Color(0xFF2A2420) : Colors.white;
    final titleCol = isDark ? Colors.white : const Color(0xFF2B2118);
    final subCol   = isDark ? Colors.white70 : const Color(0xFF5A5047);
    final borderCol = isDark ? Colors.white12 : const Color(0xFFDDD6CC);

    final topPad = MediaQuery.of(context).padding.top + 16;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, topPad, 12, 16),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 30,
                offset: const Offset(-6, 0),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Consumer2<CartProvider, ap.AuthProvider>(
              builder: (context, cart, auth, _) => Column(
                    children: [
                      // ── Title ─────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                        child: Text(
                          'Кошик',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: titleCol,
                          ),
                        ),
                      ),

                      // ── Item list ──────────────────────────────
                      Expanded(
                        child: !auth.isLoggedIn
                            ? _NotLoggedIn(titleCol: titleCol, subCol: subCol)
                            : cart.isEmpty
                                ? _EmptyCart(titleCol: titleCol, subCol: subCol)
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    itemCount: cart.items.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (_, i) {
                                      final item = cart.items[i];
                                      return _ItemCard(
                                        item: item,
                                        isDark: isDark,
                                        cardBg: cardBg,
                                        titleCol: titleCol,
                                        subCol: subCol,
                                        borderCol: borderCol,
                                        onRemove: () => cart.remove(item.id),
                                        onDecrement: () =>
                                            cart.updateQuantity(item.id, -1),
                                        onIncrement: () =>
                                            cart.updateQuantity(item.id, 1),
                                      );
                                    },
                                  ),
                      ),

                      // ── Footer ────────────────────────────────
                      if (auth.isLoggedIn)
                        _Footer(
                          cart: cart,
                          titleCol: titleCol,
                          subCol: subCol,
                          borderCol: borderCol,
                          isDark: isDark,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Item Card ─────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.isDark,
    required this.cardBg,
    required this.titleCol,
    required this.subCol,
    required this.borderCol,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
  });

  final CartItem item;
  final bool isDark;
  final Color cardBg;
  final Color titleCol;
  final Color subCol;
  final Color borderCol;
  final VoidCallback onRemove;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final unitPrice = '${item.price.toStringAsFixed(0)} грн';
    final lineTotal =
        '${(item.price * item.quantity).toStringAsFixed(0)} грн';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large Thumbnail on the left
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 65,
                  height: 65,
                  child: item.image != null
                      ? CachedNetworkImage(
                          imageUrl: item.image!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.image_not_supported_outlined,
                            size: 24,
                            color: subCol.withValues(alpha: 0.5),
                          ),
                        )
                      : Icon(
                          Icons.image_not_supported_outlined,
                          size: 24,
                          color: subCol.withValues(alpha: 0.5),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Controls right column
              Expanded(
                child: SizedBox(
                  height: 65, // Enforce fixed vertical layout mirroring the image precisely
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name (Strict 1 line)
                      Padding(
                        padding: const EdgeInsets.only(right: 24, top: 0),
                        child: Text(
                          item.name,
                          textAlign: TextAlign.start,
                          maxLines: 1, // Fix text growth
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15, // Prominent primary naming
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2, // Professional sleek tracking
                            color: titleCol,
                          ),
                        ),
                      ),

                      // Controls row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center, // Vertically center price and total to the middle of the pill
                        children: [
                          // Unit price (Subdued secondary metric)
                          Text(
                            unitPrice,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: subCol.withValues(alpha: 0.8), // Softer base price
                            ),
                          ),
                          
                          // Qty pill
                          Container(
                            height: 34,
                            decoration: BoxDecoration(
                              border: Border.all(color: borderCol, width: 1.2),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _PillBtn(label: '−', onTap: onDecrement, color: subCol),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    '${item.quantity} шт',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: titleCol,
                                    ),
                                  ),
                                ),
                                _PillBtn(label: '+', onTap: onIncrement,
                                    color: const Color(0xFF8CAF7B)),
                              ],
                            ),
                          ),
                          
                          // Line total (Prominent primary metric)
                          Text(
                            lineTotal,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: titleCol,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Delete Button Top Right
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: subCol.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillBtn extends StatelessWidget {
  const _PillBtn(
      {required this.label, required this.onTap, required this.color});
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.cart,
    required this.titleCol,
    required this.subCol,
    required this.borderCol,
    required this.isDark,
  });

  final CartProvider cart;
  final Color titleCol;
  final Color subCol;
  final Color borderCol;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Total
          if (!cart.isEmpty) ...[
            Text(
              'До сплати ${cart.total.toStringAsFixed(0)} грн',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: titleCol,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Buttons row
          Row(
            children: [
              // Оформити
              Expanded(
                child: _OutlineBtn(
                  label: 'Оформити',
                  filled: !cart.isEmpty,
                  onTap: cart.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          CheckoutSheet.show(context);
                        },
                  titleCol: titleCol,
                  borderCol: borderCol,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              // Закрити
              Expanded(
                child: _OutlineBtn(
                  label: 'Закрити',
                  filled: false,
                  onTap: () => Navigator.pop(context),
                  titleCol: titleCol,
                  borderCol: borderCol,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.label,
    required this.filled,
    required this.onTap,
    required this.titleCol,
    required this.borderCol,
    required this.isDark,
  });

  final String label;
  final bool filled;
  final VoidCallback? onTap;
  final Color titleCol;
  final Color borderCol;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF8CAF7B);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: filled ? accentGreen : Colors.transparent,
          border: Border.all(
            color: filled ? accentGreen : borderCol,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : titleCol,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty States ───────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.titleCol, required this.subCol});
  final Color titleCol;
  final Color subCol;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 60,
              color: const Color(0xFF8CAF7B).withValues(alpha: 0.4)),
          const SizedBox(height: 14),
          Text('Кошик порожній',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: titleCol)),
          const SizedBox(height: 6),
          Text('Додайте товари зі списку',
              style: TextStyle(fontSize: 13, color: subCol)),
        ],
      ),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  const _NotLoggedIn({required this.titleCol, required this.subCol});
  final Color titleCol;
  final Color subCol;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 52,
                color: const Color(0xFF8CAF7B).withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            Text('Увійдіть в акаунт',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: titleCol)),
            const SizedBox(height: 6),
            Text('Щоб переглядати та редагувати кошик',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: subCol)),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                AuthSheet.show(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF8CAF7B),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'Увійти',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

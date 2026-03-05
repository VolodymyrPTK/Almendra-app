import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../providers/auth_provider.dart' as ap;
import '../providers/cart_provider.dart';
import 'auth_sheet.dart';

class CartSheet extends StatelessWidget {
  const CartSheet({super.key});

  static void show(BuildContext context) {
    final cart = context.read<CartProvider>();
    final auth = context.read<ap.AuthProvider>();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cart',
      barrierColor: Colors.black54,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1A17) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF3B3228);
    final subText = isDark ? Colors.white60 : const Color(0xFF7A6F63);
    final divider = isDark ? Colors.white12 : const Color(0xFFE8E0D4);
    final itemBg = isDark ? const Color(0xFF2A2420) : const Color(0xFFF8F3EE);
    const accentGreen = Color(0xFF8CAF7B);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          height: double.infinity,
          decoration: BoxDecoration(
            color: bg,
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 32,
                offset: const Offset(-6, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Consumer2<CartProvider, ap.AuthProvider>(
              builder: (context, cart, auth, _) => Column(
                children: [
                  // ── Header ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined,
                            color: accentGreen, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'Кошик',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        if (cart.itemCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentGreen.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${cart.itemCount}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: accentGreen,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        IconButton(
                          icon:
                              Icon(Icons.close_rounded, color: subText, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: divider, height: 20),

                  // ── Body ─────────────────────────────────────
                  Expanded(
                    child: !auth.isLoggedIn
                        ? _NotLoggedIn(
                            accentGreen: accentGreen,
                            textColor: textColor,
                            subText: subText,
                          )
                        : cart.isEmpty
                            ? _EmptyCart(
                                accentGreen: accentGreen,
                                textColor: textColor,
                                subText: subText,
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 4, 16, 16),
                                itemCount: cart.items.length,
                                separatorBuilder: (_, __) =>
                                    Divider(color: divider, height: 20),
                                itemBuilder: (_, i) {
                                  final item = cart.items[i];
                                  return _CartItemRow(
                                    item: item,
                                    isDark: isDark,
                                    textColor: textColor,
                                    subText: subText,
                                    itemBg: itemBg,
                                    onRemove: () => cart.remove(item.id),
                                    onDecrement: () =>
                                        cart.updateQuantity(item.id, -1),
                                    onIncrement: () =>
                                        cart.updateQuantity(item.id, 1),
                                  );
                                },
                              ),
                  ),

                  // ── Footer total + checkout ───────────────────
                  if (auth.isLoggedIn && !cart.isEmpty)
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        16,
                        20,
                        MediaQuery.of(context).padding.bottom + 16,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        border: Border(top: BorderSide(color: divider)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Разом',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: subText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${cart.total.toStringAsFixed(0)} ₴',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFA8C69F),
                                    Color(0xFF8CAF7B),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentGreen.withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Оформити замовлення',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
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
        ),
      ),
    );
  }
}

// ── Cart Item Row ──────────────────────────────────────────────

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.isDark,
    required this.textColor,
    required this.subText,
    required this.itemBg,
    required this.onRemove,
    required this.onDecrement,
    required this.onIncrement,
  });

  final CartItem item;
  final bool isDark;
  final Color textColor;
  final Color subText;
  final Color itemBg;
  final VoidCallback onRemove;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    const accentGreen = Color(0xFF8CAF7B);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Thumbnail
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: itemBg,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: item.image != null
              ? CachedNetworkImage(
                  imageUrl: item.image!,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Icon(
                    Icons.image_not_supported_outlined,
                    size: 24,
                    color: subText.withValues(alpha: 0.4),
                  ),
                )
              : Icon(Icons.image_not_supported_outlined,
                  size: 24, color: subText.withValues(alpha: 0.4)),
        ),
        const SizedBox(width: 12),

        // Name + price
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${item.price.toStringAsFixed(0)} ₴',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: subText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Quantity controls
        Container(
          decoration: BoxDecoration(
            color: itemBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QtyBtn(
                  icon: Icons.remove_rounded,
                  onTap: onDecrement,
                  color: subText),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${item.quantity}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              _QtyBtn(
                  icon: Icons.add_rounded,
                  onTap: onIncrement,
                  color: accentGreen),
            ],
          ),
        ),
        const SizedBox(width: 4),

        // Remove
        IconButton(
          icon: Icon(Icons.delete_outline_rounded,
              size: 20, color: Colors.red[300]),
          onPressed: onRemove,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn(
      {required this.icon, required this.onTap, required this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ── Empty States ───────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  const _EmptyCart(
      {required this.accentGreen,
      required this.textColor,
      required this.subText});
  final Color accentGreen;
  final Color textColor;
  final Color subText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: accentGreen.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Кошик порожній',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
          const SizedBox(height: 6),
          Text('Додайте товари зі списку',
              style: TextStyle(fontSize: 13, color: subText)),
        ],
      ),
    );
  }
}

class _NotLoggedIn extends StatelessWidget {
  const _NotLoggedIn(
      {required this.accentGreen,
      required this.textColor,
      required this.subText});
  final Color accentGreen;
  final Color textColor;
  final Color subText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 56, color: accentGreen.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Увійдіть в акаунт',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
            const SizedBox(height: 6),
            Text('Щоб додавати товари в кошик',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: subText)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                AuthSheet.show(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA8C69F), Color(0xFF8CAF7B)],
                  ),
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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductDetailSheet extends StatelessWidget {
  const ProductDetailSheet({super.key, required this.product});
  final Product product;

  static void show(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductDetailSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1A17) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF3B3228);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF7A6F63);
    final chipBg = isDark ? const Color(0xFF302B26) : const Color(0xFFF3EDE5);
    final dividerColor = isDark ? Colors.white12 : const Color(0xFFE8E0D4);
    final accentGreen = const Color(0xFF8CAF7B);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: subTextColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                children: [
                  // ── Hero Image ─────────────────────────────────
                  if (product.imageUrl != null)
                    Container(
                      height: 260,
                      margin: const EdgeInsets.only(bottom: 20),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.image_not_supported_outlined,
                          size: 48,
                          color: subTextColor.withOpacity(0.3),
                        ),
                      ),
                    ),

                  // ── Diet Tags (under image) ────────────────────
                  if (product.dietTags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.dietTags
                          .map((tag) => _DietTag(label: tag, isDark: isDark))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Product Name (centered, reserved space) ─────
                  Container(
                    constraints: const BoxConstraints(minHeight: 60),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      product.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        height: 1.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Detail text (centered under name) ──────────
                  if (product.detail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        product.detail,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor,
                          height: 1.4,
                        ),
                      ),
                    ),

                  // ── Nutrition Section ──────────────────────────
                  if (_hasNutrition) ...[
                    Row(
                      children: [
                        if (product.kcal != null)
                          _NutritionCircle(
                            label: 'Ккал',
                            value: '${product.kcal!.toStringAsFixed(0)}',
                            color: const Color(0xFFE8734A),
                            isDark: isDark,
                          ),
                        if (product.protein != null)
                          _NutritionCircle(
                            label: 'Білки',
                            value: '${product.protein!.toStringAsFixed(1)}g',
                            color: const Color(0xFF5B9BD5),
                            isDark: isDark,
                          ),
                        if (product.fat != null)
                          _NutritionCircle(
                            label: 'Жири',
                            value: '${product.fat!.toStringAsFixed(1)}g',
                            color: const Color(0xFFEDC55E),
                            isDark: isDark,
                          ),
                        if (product.carbo != null)
                          _NutritionCircle(
                            label: 'Вуглеводи',
                            value: '${product.carbo!.toStringAsFixed(1)}g',
                            color: accentGreen,
                            isDark: isDark,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: dividerColor, height: 1),
                    const SizedBox(height: 20),
                  ],

                  // ── Description ────────────────────────────────
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    _SectionTitle(title: 'Опис', textColor: textColor),
                    const SizedBox(height: 8),
                    Text(
                      product.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: subTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: dividerColor, height: 1),
                    const SizedBox(height: 20),
                  ],

                  // ── Vitamins Section ──────────────────────────
                  if (product.vitamins != null &&
                      product.vitamins!.isNotEmpty) ...[
                    _SectionTitle(title: 'Вітаміни', textColor: textColor),
                    const SizedBox(height: 8),
                    Text(
                      product.vitamins!,
                      style: TextStyle(
                        fontSize: 14,
                        color: subTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: dividerColor, height: 1),
                    const SizedBox(height: 20),
                  ],

                  // ── Sklad (Ingredients / Composition) ─────────
                  if (product.sklad != null && product.sklad!.isNotEmpty) ...[
                    _SectionTitle(title: 'Склад', textColor: textColor),
                    const SizedBox(height: 8),
                    Text(
                      product.sklad!,
                      style: TextStyle(
                        fontSize: 14,
                        color: subTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),

            // ── Bottom Action Bar ────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(top: BorderSide(color: dividerColor)),
              ),
              child: Row(
                children: [
                  // Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ціна',
                        style: TextStyle(
                          fontSize: 12,
                          color: subTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${product.sellPrice.toStringAsFixed(0)} ₴',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Add to Cart Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFA8C69F), Color(0xFF8CAF7B)],
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: accentGreen.withOpacity(0.35),
                              offset: const Offset(0, 6),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 20,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Додати в кошик',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
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
    );
  }

  bool get _hasNutrition =>
      product.kcal != null ||
      product.fat != null ||
      product.protein != null ||
      product.carbo != null;
}

// ── Section Title ──────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.textColor});
  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
    );
  }
}

// ── Diet Tag ───────────────────────────────────────────────────

class _DietTag extends StatelessWidget {
  const _DietTag({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  static const _tagIcons = {
    'Vegan': Icons.eco_outlined,
    'Protein': Icons.fitness_center_outlined,
    'Low Carb': Icons.trending_down_outlined,
    'Gluten Free': Icons.grain_outlined,
    'Sugar Free': Icons.not_interested_outlined,
    'Lactose Free': Icons.water_drop_outlined,
    'Keto': Icons.local_fire_department_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _tagIcons[label] ?? Icons.label_outline;
    final chipBg = isDark ? const Color(0xFF302B26) : const Color(0xFFF3EDE5);
    final chipText = isDark ? Colors.white70 : const Color(0xFF5A5047);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: chipText),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: chipText,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nutrition Circle ───────────────────────────────────────────

class _NutritionCircle extends StatelessWidget {
  const _NutritionCircle({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(isDark ? 0.15 : 0.1),
              border: Border.all(color: color.withOpacity(0.4), width: 2),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : const Color(0xFF7A6F63),
            ),
          ),
        ],
      ),
    );
  }
}

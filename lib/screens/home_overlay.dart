import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_overlay_provider.dart';
import '../providers/products_provider.dart';

class HomeOverlay extends StatelessWidget {
  const HomeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blur background
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: isDark
                      ? Colors.black.withOpacity(0.4)
                      : Colors.white.withOpacity(0.5),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Вітаємо в\nAlmendra',
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -1,
                      color: isDark ? Colors.white : const Color(0xFF3B3228),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Здорова їжа та натуральні продукти',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF6B6258),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _CatalogButton(
                    onTap: () {
                      final provider = context.read<ProductsProvider>();
                      provider.clearBooleanFilters();
                      provider.setCategoryFilter(null);
                      context.read<HomeOverlayProvider>().hide();
                    },
                  ),

                  const SizedBox(height: 16),

                  // Grid of Filters
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.15,
                      children: [
                        _FilterCard(
                          title: 'Без цукру',
                          subtitle: 'Продукти',
                          imageAsset: 'assets/filtericons/sugar-free.webp',
                          color: isDark
                              ? const Color(0xFF4A341F)
                              : const Color(0xFFFFDFB5),
                          onTap: () {
                            _applyFilterAndHide(context, 'freeSugar');
                          },
                        ),
                        _FilterCard(
                          title: 'Без глютену',
                          subtitle: 'Продукти',
                          imageAsset: 'assets/filtericons/gluten-free.webp',
                          color: isDark
                              ? const Color(0xFF1E4024)
                              : const Color(0xFFC3F0CA),
                          onTap: () {
                            _applyFilterAndHide(context, 'freeGluten');
                          },
                        ),
                        _FilterCard(
                          title: 'Веган',
                          subtitle: 'Продукти',
                          imageAsset: 'assets/filtericons/vegan.webp',
                          color: isDark
                              ? const Color(0xFF1C3A4F)
                              : const Color(0xFFCBEBFE),
                          onTap: () {
                            _applyFilterAndHide(context, 'vegan');
                          },
                        ),
                        _FilterCard(
                          title: 'Малокалорійні',
                          subtitle: 'Продукти',
                          imageAsset: 'assets/filtericons/lowcalories.webp',
                          color: isDark
                              ? const Color(0xFF453F1B)
                              : const Color(0xFFFBEFA5),
                          onTap: () {
                            _applyFilterAndHide(context, 'lowKcal');
                          },
                        ),
                        _FilterCard(
                          title: 'Keto',
                          subtitle: 'Продукти',
                          imageAsset: 'assets/filtericons/keto.webp',
                          color: isDark
                              ? const Color(0xFF4D241C)
                              : const Color(0xFFFFE0D9),
                          onTap: () {
                            _applyFilterAndHide(context, 'keto');
                          },
                        ),
                        _FilterCard(
                          title: 'Protein',
                          subtitle: 'Продукти',
                          imageAsset: 'assets/filtericons/protein.webp',
                          color: isDark
                              ? const Color(0xFF332050)
                              : const Color(0xFFE5D5FF),
                          onTap: () {
                            _applyFilterAndHide(context, 'proteinik');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilterAndHide(BuildContext context, String filterKey) {
    // If not already active, toggle it
    final provider = context.read<ProductsProvider>();
    if (!provider.isFilterActive(filterKey)) {
      provider
          .clearBooleanFilters(); // Clear others if we want single-filter focus
      provider.toggleBooleanFilter(filterKey);
    }
    context.read<HomeOverlayProvider>().hide();
  }
}

class _CatalogButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CatalogButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF322E29) : const Color(0xFFF0ECE0);
    final fgColor = isDark ? Colors.white : const Color(0xFF333333);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            spacing: 16,
            children: [
              // Graphic icon
              Image.asset(
                'assets/filtericons/diet.webp',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
              Text(
                'Каталог Всіх Продуктів',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageAsset;
  final Color color;
  final VoidCallback onTap;

  const _FilterCard({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF222222);
    final subtitleColor = isDark ? Colors.white54 : const Color(0xFF888888);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image without outlined circle
              Image.asset(
                imageAsset,
                width: 56,
                height: 56,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

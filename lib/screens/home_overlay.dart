import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
            child: SingleChildScrollView(
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
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                  const SizedBox(height: 24),
                  _AboutSection(),
                ],
              ),
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

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF23201D) : const Color(0xFFF7F5EF);
    final fgColor = isDark ? Colors.white : const Color(0xFF3B3228);
    final accentColor = const Color(0xFF8CAF7B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // About Bento
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.eco_rounded, color: accentColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Про нас',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.5,
                      textBaseline: TextBaseline.alphabetic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Натуральні продукти з користю для вашого здоров'я",
                style: TextStyle(
                  color: fgColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "У світі, де важко знайти щось по-справжньому корисне, ми створили простір, де кожен продукт має сенс. Лише ретельно відібрані товари: суперфуди, корисні солодощі, безглютенові та низьковуглеводні продукти.",
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF6B6258),
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Delivery Full-Width Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(Icons.local_shipping_rounded, color: fgColor, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Доставка по Україні',
                      style: TextStyle(
                        color: fgColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Новою Поштою та УкрПоштою.\nЕкспрес відправка за 48 годин.\nБезкоштовно від 3000 грн.',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF6B6258),
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Contact Full Width Card
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              // Beautiful Mini Map Header
              GestureDetector(
                onTap: () {
                  final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
                  final url = isIOS
                      ? 'http://maps.apple.com/?ll=48.68322,26.58368&q=Almendra'
                      : 'https://www.google.com/maps/search/?api=1&query=48.68322,26.58368';
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
                child: const SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: _MiniMapBlock(),
                ),
              ),
              
              // Contact Action Buttons below Map
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Зв\'яжіться з нами',
                      style: TextStyle(color: fgColor, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => launchUrl(Uri.parse('tel:+380983298507')),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: accentColor.withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.phone_in_talk_rounded, color: accentColor, size: 24),
                                  const SizedBox(height: 4),
                                  Text('Подзвонити', style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => launchUrl(Uri.parse('mailto:almendrasuperfoods@gmail.com')),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.mail_rounded, color: Colors.blueAccent, size: 24),
                                  const SizedBox(height: 4),
                                  const Text('Написати', style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Address Text Block
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04), 
                            shape: BoxShape.circle
                          ),
                          child: Icon(Icons.store_rounded, size: 20, color: fgColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('м. Кам\'янець-Подільський, вул. Лесі Українки, 18', style: TextStyle(color: fgColor, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3)),
                              const SizedBox(height: 4),
                              Text('Без вихідних • 10:00 - 19:00', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _MiniMapBlock extends StatefulWidget {
  const _MiniMapBlock();

  @override
  State<_MiniMapBlock> createState() => _MiniMapBlockState();
}

class _MiniMapBlockState extends State<_MiniMapBlock> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
              body, html { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; border-radius: 24px 24px 0 0; }
              iframe { width: 100%; height: 100%; border: none; pointer-events: none; }
            </style>
          </head>
          <body>
            <iframe 
              src="https://maps.google.com/maps?q=48.68322,26.58368&t=&z=16&ie=UTF8&iwloc=&output=embed" 
              allowfullscreen>
            </iframe>
          </body>
        </html>
      ''');
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Stack(
        children: [
          IgnorePointer(
            ignoring: true, // Prevents intercepting vertical scroll of the main view
            child: WebViewWidget(controller: _controller),
          ),
          // Glass overlay with text
          Container(
            color: Colors.black.withOpacity(0.15),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: Colors.red[500], size: 16),
                      const SizedBox(width: 6),
                      Text(
                        isIOS ? 'Відкрити в Apple Maps' : 'Відкрити в Google Maps', 
                        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w700)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../repositories/products_repository.dart';
import 'product_detail_sheet.dart';

class CustomBottomBar extends StatefulWidget {
  const CustomBottomBar({super.key});

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  List<Product> _searchResults = [];
  bool _isLoading = false;
  
  final ScrollController _scrollController = ScrollController();
  int _displayLimit = 15;
  List<Product> get _displayedResults => _searchResults.take(_displayLimit).toList();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      if (_displayLimit < _searchResults.length) {
        setState(() {
          _displayLimit += 15;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      if (_searchResults.isNotEmpty) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Set loading state after a slight delay to avoid flicker
    setState(() {
      _isLoading = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await ProductsRepository().fetchSearchResults(query);
        if (mounted) {
          setState(() {
            _searchResults = results;
            _displayLimit = 15;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Results (Inverted)
            if (_isSearchExpanded && (_searchResults.isNotEmpty || _isLoading))
              _buildSearchResults(isDark),

            if (_isSearchExpanded && (_searchResults.isNotEmpty || _isLoading))
              const SizedBox(height: 12),

            // Bottom Bar Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 70,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.9),
                              width: 1.5,
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isSearchExpanded
                                ? _buildSearchInput()
                                : Row(
                                    key: const ValueKey('nav_buttons'),
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildNavButton(
                                        context,
                                        label: 'Категорії',
                                        onTap: () {},
                                      ),
                                      _buildNavButton(
                                        context,
                                        label: 'Фільтр',
                                        onTap: () {},
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildSearchButton(context, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    final fgColor = isDark ? Colors.white : Colors.black87;

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shrinkWrap: true,
                  // The prompt asks to have the first result at the bottom
                  reverse: true,
                  itemCount: _displayedResults.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: fgColor.withValues(alpha: 0.1)),
                  itemBuilder: (context, index) {
                    final product = _displayedResults[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      leading: product.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: product.imageUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 40,
                                  height: 40,
                                  color: fgColor.withValues(alpha: 0.1),
                                ),
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.fastfood_rounded,
                                  color: fgColor.withValues(alpha: 0.3),
                                ),
                              ),
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: fgColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.fastfood_rounded,
                                color: fgColor.withValues(alpha: 0.3),
                              ),
                            ),
                      title: Text(
                        product.name,
                        style: TextStyle(
                          color: fgColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${product.sellPrice.toStringAsFixed(0)} ₴',
                        style: TextStyle(
                          color: fgColor.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () {
                        ProductDetailSheet.show(context, product);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : Colors.black87;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      key: const ValueKey('search_input'),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(
            color: fgColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Пошук...',
            hintStyle: TextStyle(color: fgColor.withValues(alpha: 0.5)),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSearchExpanded = !_isSearchExpanded;
          if (!_isSearchExpanded) {
            _searchController.clear();
            _searchResults = [];
            _isLoading = false;
          }
        });
      },
      child: SizedBox(
        width: 90,
        height: 90,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow orb
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6DE8C3).withValues(alpha: 0.6),
                    const Color(0xFF8CAF7B).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
            // Button with shadow
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.6),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          _isSearchExpanded
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          key: ValueKey(_isSearchExpanded),
                          color: isDark
                              ? Colors.white
                              : const Color(0xFFE5395E),
                          size: 28,
                        ),
                      ),
                    ),
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

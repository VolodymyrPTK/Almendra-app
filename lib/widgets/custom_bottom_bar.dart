import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../repositories/products_repository.dart';
import '../providers/products_provider.dart';
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

  bool _isCategoriesExpanded = false;
  Map<String, List<String>> _categories = {};
  String? _selectedCategory;
  bool _isLoadingCategories = false;

  bool _isFilterExpanded = false;

  final ScrollController _scrollController = ScrollController();
  int _displayLimit = 15;
  List<Product> get _displayedResults =>
      _searchResults.take(_displayLimit).toList();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (_displayLimit < _searchResults.length) {
        setState(() {
          _displayLimit += 15;
        });
      }
    }
  }

  Future<void> _onCategoryTapped() async {
    setState(() {
      _isCategoriesExpanded = !_isCategoriesExpanded;
      if (_isCategoriesExpanded) {
        _isSearchExpanded = false; // Close search if opening categories
        _isFilterExpanded = false; 
      } else {
        _selectedCategory = null; 
      }
    });

    if (_isCategoriesExpanded && _categories.isEmpty) {
      setState(() {
        _isLoadingCategories = true;
      });
      try {
        final cats = await ProductsRepository().fetchCategories();
        if (mounted) {
          setState(() {
            _categories = cats;
            _isLoadingCategories = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingCategories = false;
          });
        }
      }
    }
  }

  void _onFilterTapped() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
      if (_isFilterExpanded) {
        _isSearchExpanded = false;
        _isCategoriesExpanded = false;
      }
    });
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
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 2.0, // Reduced bottom padding to move buttons lower
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isSearchExpanded && (_searchResults.isNotEmpty || _isLoading))
              _buildSearchResults(isDark),

            if (_isSearchExpanded && (_searchResults.isNotEmpty || _isLoading))
              const SizedBox(height: 6), 

            if (_isCategoriesExpanded)
              _buildCategoriesMenu(isDark),

            if (_isCategoriesExpanded)
              const SizedBox(height: 6),

            if (_isFilterExpanded)
              _buildFilterMenu(isDark, context),

            if (_isFilterExpanded)
              const SizedBox(height: 6),

            // Bottom Bar Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 30,
                          spreadRadius: 4,
                          offset: const Offset(0, 12),
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
                                        onTap: _onCategoryTapped,
                                      ),
                                      _buildNavButton(
                                        context,
                                        label: 'Фільтр',
                                        onTap: _onFilterTapped,
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

  Widget _buildFilterMenu(bool isDark, BuildContext context) {
    final fgColor = isDark ? Colors.white : Colors.black87;
    final provider = context.watch<ProductsProvider>();

    final filterOptions = {
      'Без цукру': 'freeSugar',
      'Без глютену': 'freeGluten',
      'Без лактози': 'freeLactosa',
      'Низьковуглеводний': 'lowCarbo',
      'Vegan': 'vegan',
      'Protein': 'proteinik',
    };

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
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
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: RawScrollbar(
            thumbVisibility: true,
            thumbColor: fgColor.withValues(alpha: 0.3),
            radius: const Radius.circular(8),
            thickness: 4,
            mainAxisMargin: 12,
            crossAxisMargin: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Фільтри',
                    style: TextStyle(
                      color: fgColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 16,
                        children: filterOptions.entries.map((entry) {
                          final title = entry.key;
                          final filterKey = entry.value;
                          final isActive = provider.isFilterActive(filterKey);

                          return InkWell(
                            onTap: () {
                              provider.toggleBooleanFilter(filterKey);
                            },
                            borderRadius: BorderRadius.circular(100),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: itemWidth,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF6DE8C3),
                                          Color(0xFF8CAF7B),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: isActive
                                    ? null
                                    : fgColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: isActive
                                      ? Colors.white.withValues(alpha: 0.6)
                                      : fgColor.withValues(alpha: 0.15),
                                  width: 1.5,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF6DE8C3).withValues(alpha: 0.4),
                                          blurRadius: 16,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: isActive ? Colors.black87 : fgColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesMenu(bool isDark) {
    final fgColor = isDark ? Colors.white : Colors.black87;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
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
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: _isLoadingCategories
              ? const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _buildCategoriesList(fgColor),
        ),
      ),
    );
  }

  Widget _buildCategoriesList(Color fgColor) {
    if (_selectedCategory == null) {
      // Show main categories
      final catKeys = _categories.keys.toList();
      return RawScrollbar(
        thumbVisibility: true,
        thumbColor: fgColor.withValues(alpha: 0.3),
        radius: const Radius.circular(8),
        thickness: 4,
        mainAxisMargin: 12,
        crossAxisMargin: 6,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Оберіть категорію',
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = null;
                          _isCategoriesExpanded = false;
                        });
                        context.read<ProductsProvider>().setCategoryFilter(null);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8CAF7B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF8CAF7B).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Усі товари',
                                style: TextStyle(
                                  color: Color(0xFF8CAF7B),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.grid_view_rounded,
                              size: 20,
                              color: const Color(0xFF8CAF7B).withValues(alpha: 0.8),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  ...catKeys.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: fgColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: fgColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: fgColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: fgColor.withValues(alpha: 0.5),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
            ],
          ),
        ),
      );
    } else {
      // Show subcategories
      final subs = _categories[_selectedCategory!] ?? [];
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Back Button
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, left: 8, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: fgColor, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    _selectedCategory!,
                    style: TextStyle(
                      color: fgColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: fgColor.withValues(alpha: 0.15)),
          
          Flexible(
            child: RawScrollbar(
              thumbVisibility: true,
              thumbColor: fgColor.withValues(alpha: 0.3),
              radius: const Radius.circular(8),
              thickness: 4,
              mainAxisMargin: 12,
              crossAxisMargin: 6,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: subs.map((sub) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = null;
                            _isCategoriesExpanded = false;
                          });
                          context.read<ProductsProvider>().setCategoryFilter([sub]);
                        },
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: fgColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: fgColor.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            sub,
                            style: TextStyle(
                              color: fgColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8CAF7B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              onPressed: () {
                final subs = _categories[_selectedCategory!] ?? [];
                if (subs.isNotEmpty) {
                  setState(() {
                    _selectedCategory = null;
                    _isCategoriesExpanded = false;
                  });
                  context.read<ProductsProvider>().setCategoryFilter(subs);
                } else {
                  setState(() {
                    _selectedCategory = null;
                    _isCategoriesExpanded = false;
                  });
                  context.read<ProductsProvider>().setCategoryFilter([_selectedCategory!]);
                }
              },
              child: Text(
                'Показати всі ${_selectedCategory?.toLowerCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSearchResults(bool isDark) {
    final fgColor = isDark ? Colors.white : Colors.black87;

    return Container(
      constraints: const BoxConstraints(maxHeight: 270),
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
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 4,
            offset: const Offset(0, 12),
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
              : RawScrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thumbColor: fgColor.withValues(alpha: 0.3),
                  radius: const Radius.circular(8),
                  thickness: 4,
                  mainAxisMargin: 12,
                  crossAxisMargin: 6,
                  child: ListView.separated(
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
                        vertical: 0,
                      ),
                      visualDensity: const VisualDensity(vertical: -2),
                      leading: product.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: product.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  width: 50,
                                  height: 50,
                                  color: fgColor.withValues(alpha: 0.1),
                                ),
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.fastfood_rounded,
                                  size: 28,
                                  color: fgColor.withValues(alpha: 0.3),
                                ),
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: fgColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.fastfood_rounded,
                                size: 28,
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
                      subtitle: Row(
                        children: [
                          Text(
                            '${product.sellPrice.toStringAsFixed(0)} ₴',
                            style: TextStyle(
                              color: fgColor.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          if (product.outOfStock) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Немає в наявності',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () {
                        ProductDetailSheet.show(context, product);
                      },
                    );
                  },
                ),
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
          if (_isSearchExpanded) {
            _isCategoriesExpanded = false;
            _isFilterExpanded = false;
          } else {
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
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
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

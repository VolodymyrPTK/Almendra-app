import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as ap;
import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../widgets/auth_sheet.dart';
import '../widgets/cart_sheet.dart';
import '../widgets/custom_bottom_bar.dart';
import '../widgets/product_card.dart';
import '../services/nova_poshta_service.dart';
import '../widgets/delivery_widgets.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsProvider>().loadProducts();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<ProductsProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showUserMenu(BuildContext context, ap.AuthProvider auth) {
    _UserProfileSheet.show(context, auth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Almendra',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // Cart button
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final hasItems = cart.itemCount > 0;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => CartSheet.show(context),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 40,
                          padding: EdgeInsets.symmetric(
                            horizontal: hasItems ? 14 : 0,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                          ),
                          decoration: BoxDecoration(
                            color: hasItems
                                ? const Color(0xFF8CAF7B).withValues(alpha: 0.7)
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.white.withValues(alpha: 0.7)),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: hasItems
                                  ? const Color(
                                      0xFF8CAF7B,
                                    ).withValues(alpha: 0.9)
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.9)),
                              width: 1.5,
                            ),
                          ),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 20,
                                  color: hasItems
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white
                                            : const Color(0xFF3B3228)),
                                ),
                                if (hasItems) ...[
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${cart.total.toStringAsFixed(0)} грн',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.visible,
                                      softWrap: false,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Consumer<ap.AuthProvider>(
            builder: (context, auth, _) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final textColor = isDark ? Colors.white : const Color(0xFF3B3228);

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => auth.isLoggedIn
                      ? _showUserMenu(context, auth)
                      : AuthSheet.show(context),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.white.withValues(alpha: 0.7),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.9),
                              width: 1.5,
                            ),
                          ),
                          child: auth.isLoggedIn
                              ? Center(
                                  child: Text(
                                    (auth.user!.displayName?.isNotEmpty == true
                                            ? auth.user!.displayName!
                                            : auth.user!.email ?? '?')[0]
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person_outline_rounded,
                                  size: 22,
                                  color: textColor,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white.withValues(alpha: 0.4),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        toolbarHeight: 80,
      ),
      body: Stack(
        children: [
          // Deep aurora background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          const Color(0xFF1A1614),
                          const Color(0xFF1E1A17),
                          const Color(0xFF161210),
                        ]
                      : [
                          const Color(0xFFE8E0D4),
                          const Color(0xFFE3DBD0),
                          const Color(0xFFEDE5DA),
                        ],
                ),
              ),
            ),
          ),
          // Glow orb — top right
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.18),
                    blurRadius: 90,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          // Glow orb — mid left
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.tertiary.withValues(alpha: 0.12),
                    blurRadius: 80,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          // Glow orb — bottom right
          Positioned(
            bottom: 60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.13),
                    blurRadius: 70,
                    spreadRadius: 25,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Consumer<ProductsProvider>(
              builder: (context, provider, _) {
                return switch (provider.status) {
                  ProductsStatus.initial || ProductsStatus.loading =>
                    const Center(child: CircularProgressIndicator()),
                  ProductsStatus.error when provider.products.isEmpty =>
                    _ErrorView(
                      message: provider.errorMessage,
                      onRetry: provider.retry,
                    ),
                  _ => _ProductList(
                    scrollController: _scrollController,
                    provider: provider,
                  ),
                };
              },
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomBar(),
          ),
        ],
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.scrollController, required this.provider});

  final ScrollController scrollController;
  final ProductsProvider provider;

  @override
  Widget build(BuildContext context) {
    final products = provider.products;
    final itemCount = products.length + (provider.hasMore ? 1 : 0);

    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Товарів не знайдено', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadProducts,
      child: GridView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.68,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == products.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return ProductCard(product: products[index]);
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Не вдалося завантажити товари',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                if (message!.contains('https://console.firebase.google.com')) ...[
                  const SizedBox(height: 16),
                  Builder(
                    builder: (btnContext) {
                      final urlRegex = RegExp(r'https://console\.firebase\.google\.com/[^\s]+');
                      final match = urlRegex.firstMatch(message!);
                      if (match != null) {
                        return FilledButton.tonalIcon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: match.group(0)!));
                            ScaffoldMessenger.of(btnContext).showSnackBar(
                              const SnackBar(
                                content: Text('Посилання скопійовано!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Скопіювати посилання'),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторити'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── User Profile Sheet ────────────────────────────────────────────────────────
// Full-panel cart-style sheet with view/edit modes for profile data.

enum _ProfileTab { info, orders }

class _UserProfileSheet extends StatefulWidget {
  const _UserProfileSheet({required this.auth});
  final ap.AuthProvider auth;

  static void show(BuildContext context, ap.AuthProvider auth) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Profile',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => ChangeNotifierProvider.value(
        value: auth,
        child: _UserProfileSheet(auth: auth),
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
  State<_UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<_UserProfileSheet> {
  final _firstNameCtrl  = TextEditingController();
  final _secondNameCtrl = TextEditingController();
  final _phoneCtrl      = TextEditingController();

  _ProfileTab _tab = _ProfileTab.orders;
  bool _editing    = false;
  bool _loading    = true;
  bool _saving     = false;
  
  // -- Delivery State --
  final _novaCityCtrl = TextEditingController();
  final _novaWarehouseCtrl = TextEditingController();
  final _ukrCityCtrl = TextEditingController();
  final _ukrIndexCtrl = TextEditingController();
  
  final _cityFocus = FocusNode();
  final _warehouseFocus = FocusNode();
  
  String _deliveryOption = 'novaPoshta'; // 'novaPoshta' or 'ukrPoshta'
  String _warehouseCategory = 'Warehouse';
  String? _selectedCityRef;
  String? _selectedWarehouseIndex;
  
  List<dynamic> _citySuggestions = [];
  List<dynamic> _warehouseSuggestions = [];
  bool _loadingCities = false;
  bool _loadingWarehouses = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = widget.auth.user?.uid;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles').doc(uid).get();
      final data = doc.data() ?? {};
      if (mounted) {
        _firstNameCtrl.text  = data['firstName']  as String? ?? '';
        _secondNameCtrl.text = data['secondName'] as String? ?? '';
        _phoneCtrl.text      = data['phone']       as String? ?? '';
        
        _deliveryOption = data['deliveryOption'] as String? ?? 'novaPoshta';
        _novaCityCtrl.text = data['city'] as String? ?? '';
        _novaWarehouseCtrl.text = data['warehouse'] as String? ?? '';
        _ukrCityCtrl.text = (data['deliveryOption'] == 'ukrPoshta' ? data['city'] : '') as String? ?? '';
        _ukrIndexCtrl.text = data['cityIndex'] as String? ?? '';
        
        _selectedCityRef = data['cityRef'] as String?;
        _selectedWarehouseIndex = data['warehouseIndex'] as String?;
        _warehouseCategory = data['postType'] as String? ?? 'Warehouse';
        
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Stream<List<Map<String, dynamic>>> _ordersStream() {
    final uid = widget.auth.user?.uid;
    if (uid == null) return const Stream.empty();
    
    // Fallback logic for stream: union if email exists
    return FirebaseFirestore.instance
        .collection('orders')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((doc) => doc.data()).toList();
          
          // Optionally add email matches if list by UID is small/empty
          // (More complex to do real OR query in Stream, but this covers basic UID sync)
          
          list.sort((a, b) {
            final idA = (a['orderId'] as num?)?.toInt() ?? 0;
            final idB = (b['orderId'] as num?)?.toInt() ?? 0;
            return idB.compareTo(idA);
          });
          return list;
        });
  }

  Future<void> _save() async {
    final uid = widget.auth.user?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(uid)
          .set({
            'firstName'      : _firstNameCtrl.text.trim(),
            'secondName'     : _secondNameCtrl.text.trim(),
            'phone'          : _phoneCtrl.text.trim(),
            'deliveryOption' : _deliveryOption,
            'city'           : _deliveryOption == 'novaPoshta' ? _novaCityCtrl.text.trim() : _ukrCityCtrl.text.trim(),
            'warehouse'      : _novaWarehouseCtrl.text.trim(),
            'cityIndex'      : _ukrIndexCtrl.text.trim(),
            'cityRef'        : _selectedCityRef ?? '',
            'warehouseIndex' : _selectedWarehouseIndex ?? '',
            'postType'       : _warehouseCategory,
          }, SetOptions(merge: true));
      if (mounted) setState(() { _saving = false; _editing = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка: $e'),
            backgroundColor: const Color(0xFFE5395E),
          ),
        );
      }
    }
  }
  // -- Delivery Handlers --
  Future<void> _onCitySearch(String query) async {
    if (query.length < 2) {
      setState(() { _citySuggestions = []; _loadingCities = false; });
      return;
    }
    setState(() => _loadingCities = true);
    try {
      final results = await NovaPoshtaService.searchSettlements(query);
      if (mounted) setState(() { _citySuggestions = results; _loadingCities = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  void _onCitySelected(dynamic city) async {
    final name = city['MainDescription'] ?? city['Description'] ?? '';
    _novaCityCtrl.text = name;
    setState(() { _citySuggestions = []; _loadingCities = false; _novaWarehouseCtrl.clear(); _selectedWarehouseIndex = null; });
    String? ref = city['DeliveryCity'];
    if (ref == null || ref.isEmpty) {
      ref = await NovaPoshtaService.resolveCityRef(name, city['AreaDescription'] ?? '');
    }
    setState(() => _selectedCityRef = ref);
    if (ref != null) _fetchWarehouses('', ref);
  }

  Future<void> _fetchWarehouses(String query, String cityRef) async {
    setState(() => _loadingWarehouses = true);
    try {
      final results = await NovaPoshtaService.getWarehouses(cityRef, findByString: query, category: _warehouseCategory);
      if (mounted) setState(() { _warehouseSuggestions = results; _loadingWarehouses = false; });
    } catch (_) { if (mounted) setState(() => _loadingWarehouses = false); }
  }

  void _onWarehouseSelected(dynamic warehouse) {
    setState(() {
      _novaWarehouseCtrl.text = warehouse['Description'] ?? '';
      _selectedWarehouseIndex = warehouse['WarehouseIndex'];
      _warehouseSuggestions = [];
    });
  }
  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _secondNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final panelBg   = isDark ? const Color(0xFF1E1A17) : const Color(0xFFF0EAE2);
    final cardBg    = isDark ? const Color(0xFF2A2420) : Colors.white;
    final titleCol  = isDark ? Colors.white : const Color(0xFF2B2118);
    final subCol    = isDark ? Colors.white70 : const Color(0xFF5A5047);
    final borderCol = isDark ? Colors.white12 : const Color(0xFFDDD6CC);
    const green     = Color(0xFF8CAF7B);
    final topPad    = MediaQuery.of(context).padding.top + 16;
    final bottomPad = MediaQuery.of(context).padding.bottom + 20;

    final fullName = [
      _firstNameCtrl.text.trim(),
      _secondNameCtrl.text.trim(),
    ].where((s) => s.isNotEmpty).join(' ');

    final initial = fullName.isNotEmpty
        ? fullName[0].toUpperCase()
        : (widget.auth.user?.email ?? '?')[0].toUpperCase();

    return Padding(
      padding: EdgeInsets.fromLTRB(12, topPad, 12, 16),
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: panelBg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 30,
                  offset: const Offset(-6, 0),
                ),
              ],
            ),
            child: Column(
              children: [

                // ── Header ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 8, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderCol, width: 1.2),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: titleCol),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(_tab == _ProfileTab.info ? 'Профіль' : 'Замовлення',
                          style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900,
                            color: titleCol,
                          )),
                      ),
                      if (_tab == _ProfileTab.info)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: GestureDetector(
                            onTap: _saving ? null : () {
                              if (_editing) _save();
                              else setState(() => _editing = true);
                            },
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _editing
                                ? _saving
                                  ? const SizedBox(width: 20, height: 20, 
                                      child: CircularProgressIndicator(strokeWidth: 2, 
                                        valueColor: AlwaysStoppedAnimation(green)))
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: green.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text('Зберегти', style: TextStyle(
                                        color: green, fontSize: 13, fontWeight: FontWeight.w800,
                                      )),
                                    )
                                : Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: borderCol, width: 1.2),
                                    ),
                                    child: Icon(Icons.edit_outlined, size: 18, color: titleCol),
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Tab Switcher ──────────────────────────────────────
                if (!_editing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabButton(
                            label: 'Дані',
                            active: _tab == _ProfileTab.info,
                            onTap: () => setState(() => _tab = _ProfileTab.info),
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _TabButton(
                            label: 'Замовлення',
                            active: _tab == _ProfileTab.orders,
                            onTap: () => setState(() => _tab = _ProfileTab.orders),
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Body ───────────────────────────────────────────────
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(green),
                            strokeWidth: 2.5,
                          ))
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _editing
                              // ── EDIT MODE: individual input fields ────────
                              ? SingleChildScrollView(
                                  key: const ValueKey('edit'),
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4, bottom: 10),
                                        child: Text('РЕДАГУВАННЯ ПРОФІЛЮ',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: subCol,
                                            letterSpacing: 1.2,
                                          )),
                                      ),
                                      _ProfileField(
                                        controller: _firstNameCtrl,
                                        label: "Ім'я",
                                        icon: Icons.person_outline_rounded,
                                        editing: true,
                                        isDark: isDark, cardBg: cardBg,
                                        titleCol: titleCol, subCol: subCol,
                                        borderCol: borderCol,
                                        inputFormatters: [_CyrillicNameFmt()],
                                      ),
                                      const SizedBox(height: 10),
                                      _ProfileField(
                                        controller: _secondNameCtrl,
                                        label: 'Прізвище',
                                        icon: Icons.badge_outlined,
                                        editing: true,
                                        isDark: isDark, cardBg: cardBg,
                                        titleCol: titleCol, subCol: subCol,
                                        borderCol: borderCol,
                                        inputFormatters: [_CyrillicNameFmt()],
                                      ),
                                      const SizedBox(height: 10),
                                        const SizedBox(height: 10),
                                        _ProfileField(
                                          controller: _phoneCtrl,
                                          label: 'Телефон',
                                          icon: Icons.phone_outlined,
                                          editing: true,
                                          isDark: isDark, cardBg: cardBg,
                                          titleCol: titleCol, subCol: subCol,
                                          borderCol: borderCol,
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [_UkrPhoneFmt()],
                                        ),
                                        const SizedBox(height: 24),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4, bottom: 10),
                                          child: Text('ДОСТАВКА ЗА ЗАМОВЧУВАННЯМ',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: subCol,
                                              letterSpacing: 1.2,
                                            )),
                                        ),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: DeliveryChip(
                                                label: 'Нова Пошта',
                                                icon: Icons.local_shipping_outlined,
                                                selected: _deliveryOption == 'novaPoshta',
                                                isDark: isDark, cardBg: cardBg,
                                                titleCol: titleCol, borderCol: borderCol,
                                                onTap: () => setState(() => _deliveryOption = 'novaPoshta'),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: DeliveryChip(
                                                label: 'Укрпошта',
                                                icon: Icons.mail_outline_rounded,
                                                selected: _deliveryOption == 'ukrPoshta',
                                                isDark: isDark, cardBg: cardBg,
                                                titleCol: titleCol, borderCol: borderCol,
                                                onTap: () => setState(() => _deliveryOption = 'ukrPoshta'),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        if (_deliveryOption == 'novaPoshta')
                                          NovaFields(
                                            cityCtrl: _novaCityCtrl,
                                            warehouseCtrl: _novaWarehouseCtrl,
                                            isDark: isDark, cardBg: cardBg,
                                            titleCol: titleCol, subCol: subCol, borderCol: borderCol,
                                            cityFocus: _cityFocus, warehouseFocus: _warehouseFocus,
                                            citySuggestions: _citySuggestions, warehouseSuggestions: _warehouseSuggestions,
                                            loadingCities: _loadingCities, loadingWarehouses: _loadingWarehouses,
                                            onCitySearch: _onCitySearch, onCitySelect: _onCitySelected,
                                            onWarehouseSearch: (v) => _fetchWarehouses(v, _selectedCityRef ?? ''),
                                            onWarehouseSelect: _onWarehouseSelected,
                                            category: _warehouseCategory,
                                            onCategoryChange: (c) => setState(() => _warehouseCategory = c),
                                          )
                                        else
                                          UkrFields(
                                            cityCtrl: _ukrCityCtrl,
                                            indexCtrl: _ukrIndexCtrl,
                                            isDark: isDark, cardBg: cardBg,
                                            titleCol: titleCol, subCol: subCol, borderCol: borderCol,
                                          ),
                                      ],
                                    ),
                                  )
                              // ── VIEW MODE ─────────────────────────────────
                              : _tab == _ProfileTab.info 
                               ? SingleChildScrollView(
                                   key: const ValueKey('view_info'),
                                   padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.stretch,
                                     children: [
                                       // Avatar + name header card
                                       Container(
                                         padding: const EdgeInsets.symmetric(
                                             horizontal: 20, vertical: 18),
                                         decoration: BoxDecoration(
                                           color: cardBg,
                                           borderRadius: BorderRadius.circular(20),
                                           border: Border.all(color: borderCol, width: 1.2),
                                           boxShadow: [
                                             BoxShadow(
                                               color: Colors.black.withValues(
                                                   alpha: isDark ? 0.25 : 0.06),
                                               blurRadius: 10,
                                               offset: const Offset(0, 3),
                                             ),
                                           ],
                                         ),
                                         child: Row(
                                           children: [
                                             Container(
                                               width: 56, height: 56,
                                               decoration: BoxDecoration(
                                                 color: green.withValues(alpha: 0.12),
                                                 shape: BoxShape.circle,
                                                 border: Border.all(
                                                     color: green.withValues(alpha: 0.35),
                                                     width: 2),
                                               ),
                                               child: Center(
                                                 child: Text(initial,
                                                   style: const TextStyle(
                                                     fontSize: 24,
                                                     fontWeight: FontWeight.w800,
                                                     color: green,
                                                   )),
                                               ),
                                             ),
                                             const SizedBox(width: 16),
                                             Expanded(
                                               child: Column(
                                                 crossAxisAlignment: CrossAxisAlignment.start,
                                                 children: [
                                                   Text(
                                                     fullName.isNotEmpty
                                                         ? fullName
                                                         : 'Користувач',
                                                     style: TextStyle(
                                                       fontSize: 17,
                                                       fontWeight: FontWeight.w800,
                                                       color: titleCol,
                                                     )),
                                                   if (widget.auth.user?.email != null)
                                                       Text(
                                                         widget.auth.user!.email!,
                                                         style: TextStyle(
                                                           fontSize: 12,
                                                           color: subCol,
                                                         ),
                                                       ),
                                                 ],
                                               ),
                                             ),
                                           ],
                                         ),
                                       ),
                                       const SizedBox(height: 16),

                                       // Contact info card
                                       Container(
                                         decoration: BoxDecoration(
                                           color: cardBg,
                                           borderRadius: BorderRadius.circular(20),
                                           border: Border.all(color: borderCol, width: 1.2),
                                           boxShadow: [
                                             BoxShadow(
                                               color: Colors.black.withValues(
                                                   alpha: isDark ? 0.25 : 0.06),
                                               blurRadius: 10,
                                               offset: const Offset(0, 3),
                                             ),
                                           ],
                                         ),
                                         child: Column(
                                           children: [
                                             _InfoRow(
                                               icon: Icons.person_outline_rounded,
                                               label: "Ім'я",
                                               value: _firstNameCtrl.text.trim().isNotEmpty
                                                   ? _firstNameCtrl.text.trim()
                                                   : '—',
                                               titleCol: titleCol,
                                               subCol: subCol,
                                               borderCol: borderCol,
                                               showDivider: true,
                                             ),
                                             _InfoRow(
                                               icon: Icons.badge_outlined,
                                               label: 'Прізвище',
                                               value: _secondNameCtrl.text.trim().isNotEmpty
                                                   ? _secondNameCtrl.text.trim()
                                                   : '—',
                                               titleCol: titleCol,
                                               subCol: subCol,
                                               borderCol: borderCol,
                                               showDivider: true,
                                             ),
                                             _InfoRow(
                                               icon: Icons.phone_outlined,
                                               label: 'Телефон',
                                               value: _phoneCtrl.text.trim().isNotEmpty
                                                   ? _phoneCtrl.text.trim()
                                                   : '—',
                                               titleCol: titleCol,
                                               subCol: subCol,
                                               borderCol: borderCol,
                                               showDivider: false,
                                             ),
                                           ],
                                         ),
                                       ),
                                       const SizedBox(height: 16),
                                       
                                       // Delivery info card
                                       Container(
                                         padding: const EdgeInsets.symmetric(vertical: 4),
                                         decoration: BoxDecoration(
                                           color: cardBg,
                                           borderRadius: BorderRadius.circular(20),
                                           border: Border.all(color: borderCol, width: 1.2),
                                           boxShadow: [
                                             BoxShadow(
                                               color: Colors.black.withValues(
                                                   alpha: isDark ? 0.25 : 0.06),
                                               blurRadius: 10,
                                               offset: const Offset(0, 3),
                                             ),
                                           ],
                                         ),
                                         child: Column(
                                           children: [
                                             _InfoRow(
                                               icon: _deliveryOption == 'novaPoshta' 
                                                  ? Icons.local_shipping_outlined 
                                                  : Icons.mail_outline_rounded,
                                               label: 'Доставка',
                                               value: _deliveryOption == 'novaPoshta' ? 'Нова Пошта' : 'Укрпошта',
                                               titleCol: titleCol, subCol: subCol, borderCol: borderCol,
                                               showDivider: true,
                                             ),
                                             if (_deliveryOption == 'novaPoshta') ...[
                                               _InfoRow(
                                                 icon: Icons.location_city_outlined,
                                                 label: 'Місто',
                                                 value: _novaCityCtrl.text.isNotEmpty ? _novaCityCtrl.text : '—',
                                                 titleCol: titleCol, subCol: subCol, borderCol: borderCol,
                                                 showDivider: true,
                                               ),
                                               _InfoRow(
                                                 icon: Icons.store_mall_directory_outlined,
                                                 label: 'Відділення',
                                                 value: _novaWarehouseCtrl.text.isNotEmpty ? _novaWarehouseCtrl.text : '—',
                                                 titleCol: titleCol, subCol: subCol, borderCol: borderCol,
                                                 showDivider: false,
                                               ),
                                             ] else ...[
                                               _InfoRow(
                                                 icon: Icons.location_on_outlined,
                                                 label: 'Місто',
                                                 value: _ukrCityCtrl.text.isNotEmpty ? _ukrCityCtrl.text : '—',
                                                 titleCol: titleCol, subCol: subCol, borderCol: borderCol,
                                                 showDivider: true,
                                               ),
                                               _InfoRow(
                                                 icon: Icons.local_post_office_outlined,
                                                 label: 'Індекс',
                                                 value: _ukrIndexCtrl.text.isNotEmpty ? _ukrIndexCtrl.text : '—',
                                                 titleCol: titleCol, subCol: subCol, borderCol: borderCol,
                                                 showDivider: false,
                                               ),
                                             ],
                                           ],
                                         ),
                                       ),
                                     ],
                                   ),
                                 )
                               : StreamBuilder<List<Map<String, dynamic>>>(
                                   stream: _ordersStream(),
                                   builder: (context, snapshot) {
                                     if (snapshot.connectionState == ConnectionState.waiting) {
                                       return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: green));
                                     }
                                     
                                     final ords = snapshot.data ?? [];
                                     
                                     if (ords.isEmpty) {
                                       return Center(
                                         child: Column(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                             Icon(Icons.inventory_2_outlined, size: 48, color: subCol.withValues(alpha: 0.5)),
                                             const SizedBox(height: 12),
                                             Text('Замовлень поки немає', style: TextStyle(color: subCol, fontWeight: FontWeight.w600)),
                                           ],
                                         ),
                                       );
                                     }

                                     return ListView.separated(
                                       key: const ValueKey('view_orders'),
                                       padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                                       itemCount: ords.length,
                                       separatorBuilder: (_, __) => const SizedBox(height: 10),
                                       itemBuilder: (_, i) => _OrderCard(
                                         order: ords[i],
                                         isDark: isDark,
                                         cardBg: cardBg,
                                         titleCol: titleCol,
                                         subCol: subCol,
                                         borderCol: borderCol,
                                         userPhone: _phoneCtrl.text.trim(),
                                       ),
                                     );
                                   },
                                 ),
                        ),  // AnimatedSwitcher
                ),  // Expanded (body)

                // ── Footer ─────────────────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad),
                    child: _editing
                        // ── EDIT MODE: Cancel (left) + Save (right) ──────
                        ? Row(
                            children: [
                              // Cancel — outlined, neutral
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _editing = false;
                                    _loadProfile();
                                  }),
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: borderCol, width: 1.5),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Скасувати',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: subCol,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Save — green, prominent
                              Expanded(
                                child: GestureDetector(
                                  onTap: _saving ? null : _save,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: _saving
                                          ? green.withValues(alpha: 0.6)
                                          : green,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: green.withValues(alpha: 0.4),
                                          blurRadius: 14,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: _saving
                                          ? const SizedBox(
                                              width: 22, height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                        Colors.white),
                                              ))
                                          : const Text(
                                              'Зберегти',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              )),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        // ── VIEW MODE: Edit (green) + Logout (danger text) ─
                        : _tab == _ProfileTab.info 
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Edit button — full width, green
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _editing = true),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: green,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: green.withValues(alpha: 0.4),
                                        blurRadius: 14,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.edit_outlined,
                                          size: 18, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Редагувати',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Logout — text-only, danger, clearly separated
                              TextButton.icon(
                                onPressed: () {
                                  widget.auth.signOut();
                                  Navigator.pop(context);
                                },
                                icon: Icon(Icons.logout_rounded,
                                    size: 16,
                                    color: Colors.red[400]),
                                label: Text(
                                  'Вийти з акаунту',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[400],
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ],
                          )
                        : TextButton.icon(
                            onPressed: () {
                              widget.auth.signOut();
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.logout_rounded,
                                size: 16,
                                color: Colors.red[400]),
                            label: Text(
                              'Вийти з акаунту',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[400],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab Switcher Components ──────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.active,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active 
              ? (isDark ? const Color(0xFF2A2420) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Center(
          child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active 
                  ? (isDark ? Colors.white : const Color(0xFF2B2118))
                  : (isDark ? Colors.white60 : const Color(0xFF5A5047)),
            )),
        ),
      ),
    );
  }
}

// ── Expandable Order Card ───────────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  const _OrderCard({
    required this.order,
    required this.isDark,
    required this.cardBg,
    required this.titleCol,
    required this.subCol,
    required this.borderCol,
    this.userPhone,
  });

  final Map<String, dynamic> order;
  final bool isDark;
  final Color cardBg;
  final Color titleCol;
  final Color subCol;
  final Color borderCol;
  final String? userPhone;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;
  String? _trackingStatus;
  bool _loadingStatus = false;

  @override
  void initState() {
    super.initState();
    _fetchTracking();
  }

  Future<void> _fetchTracking() async {
    final trackingNum = widget.order['trackingNumber'] as String?;
    final phone = (widget.order['phone'] as String?) ?? widget.userPhone;
    if (trackingNum == null || trackingNum.isEmpty || (phone == null || phone.isEmpty)) return;

    // Normalize phone for NP (they usually expect 380...)
    // Our formatter already saves them as +38 (0XX) XXX XXXX or similar
    // We need just digits
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    setState(() => _loadingStatus = true);
    final result = await NovaPoshtaService.getTrackingStatus(trackingNum, digits);
    if (mounted && result != null) {
      setState(() {
        _trackingStatus = result['Status'];
        _loadingStatus = false;
      });
    } else if (mounted) {
      setState(() => _loadingStatus = false);
    }
  }
  String _getPlural(int count) {
    int rem10 = count % 10;
    int rem100 = count % 100;
    if (rem10 == 1 && rem100 != 11) {
      return '$count товар';
    } else if (rem10 >= 2 && rem10 <= 4 && (rem100 < 10 || rem100 >= 20)) {
      return '$count товари';
    } else {
      return '$count товарів';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.order['orderStatus'] as String? ?? 'Processing';
    final total  = (widget.order['total'] as num?)?.toDouble() ?? 0;
    final time   = widget.order['time'] as String? ?? '';
    final items  = widget.order['items'] as List? ?? [];
    final orderId = widget.order['orderId']?.toString() ?? '?';

    final paymentField = widget.order['payment']?.toString();
    final paymentStatus = widget.order['paymentStatus']?.toString();
    
    final delivery = widget.order['deliveryOption'] == 'novaPoshta' ? 'Нова Пошта' : 'Укрпошта';
    final address = widget.order['city'] ?? '';
    final warehouse = widget.order['warehouse'] ?? widget.order['cityIndex'] ?? '';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    
    switch (status) {
      case 'Preparing':
        statusColor = const Color(0xFF5E97E5);
        statusLabel = 'Комплектується';
        statusIcon = Icons.inventory_2_outlined;
        break;
      case 'Prepared':
        statusColor = const Color(0xFFAE7BCF);
        statusLabel = 'Комплектовано';
        statusIcon = Icons.auto_awesome_outlined;
        break;
      case 'Shipped':
        statusColor = const Color(0xFFE5A15E);
        statusLabel = 'Відправлено';
        statusIcon = Icons.local_shipping_outlined;
        break;
      case 'Received':
        statusColor = const Color(0xFF8CAF7B);
        statusLabel = 'Отримано';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'Paid':
        statusColor = const Color(0xFF4DB6AC);
        statusLabel = 'Оплачено';
        statusIcon = Icons.wallet_outlined;
        break;
      default:
        statusColor = const Color(0xFF90A4AE);
        statusLabel = 'Обробляється';
        statusIcon = Icons.hourglass_empty_rounded;
    }

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.borderCol.withValues(alpha: _expanded ? 1.0 : 0.4),
            width: _expanded ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.04),
              blurRadius: _expanded ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // --- Premium Header ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('№$orderId', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900, color: widget.titleCol, letterSpacing: 0.5
                    )),
                    const SizedBox(height: 2),
                    Text(time, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: widget.subCol.withValues(alpha: 0.8)
                    )),
                  ]
                ),
                _StatusPill(label: statusLabel, icon: statusIcon, color: statusColor),
              ]
            ),
            
            const SizedBox(height: 18),
            
            // --- Collapsed Preview (Always visible) ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnails Stack
                SizedBox(
                  width: 80, height: 44,
                  child: Stack(
                    children: [
                      for (int i = 0; i < (items.length > 3 ? 3 : items.length); i++)
                        Positioned(
                          left: i * 20.0,
                          child: _ItemThumb(imageUrl: items[i]['image'], subCol: widget.subCol, borderCol: widget.borderCol, size: 44),
                        ),
                      if (items.length > 3)
                        Positioned(
                          left: 3 * 20.0,
                          top: 12,
                          child: Text('+${items.length - 3}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: widget.titleCol)),
                        ),
                    ]
                  )
                ),
                const SizedBox(width: 8),
                // Total and items count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${total.toStringAsFixed(0)} ₴', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: widget.titleCol)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(_getPlural(items.length), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.subCol)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.circle, size: 4, color: widget.subCol.withValues(alpha: 0.3)),
                          ),
                          Text(paymentStatus == 'success' ? 'ОПЛАЧЕНО' : 'ПІСЛЯПЛАТА', 
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: paymentStatus == 'success' ? const Color(0xFF8CAF7B) : const Color(0xFFE5A15E))),
                        ]
                      )
                    ]
                  )
                ),
                // Expand Icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.borderCol.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 20, color: widget.titleCol.withValues(alpha: 0.6)),
                )
              ]
            ),

            // Detailed view (when expanded)
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          Divider(height: 1, color: widget.borderCol),
                          const SizedBox(height: 16),
                          
                          // --- Products ---
                          _SectionTitle('ТОВАРИ', items.length.toString()),
                          const SizedBox(height: 8),
                          for (int i = 0; i < items.length; i++) ...[
                            _OrderItemRow(
                              item: Map<String, dynamic>.from(items[i]), 
                              titleCol: widget.titleCol, 
                              subCol: widget.subCol
                            ),
                            if (i < items.length - 1) 
                              Divider(height: 1, color: widget.borderCol.withValues(alpha: 0.4), indent: 56),
                          ],
                          
                          // --- Shipping & Logistics ---
                          const SizedBox(height: 20),
                          _SectionTitle('ДОСТАВКА ТА ЛОГІСТИКА', null),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: widget.borderCol.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8CAF7B).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(widget.order['deliveryOption'] == 'novaPoshta' 
                                        ? Icons.local_shipping_outlined 
                                        : Icons.mail_outline_rounded, 
                                        size: 16, color: const Color(0xFF8CAF7B)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(delivery, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: widget.titleCol)),
                                          Text('$address, $warehouse', style: TextStyle(fontSize: 11, color: widget.subCol)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.order['trackingNumber'] != null) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(height: 1),
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.qr_code_scanner_rounded, size: 16, color: statusColor),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text('ТТН: ${widget.order['trackingNumber']}', 
                                                  style: TextStyle(fontSize: 13, color: widget.titleCol, fontWeight: FontWeight.w800)),
                                                if (_loadingStatus)
                                                   const Padding(
                                                     padding: EdgeInsets.only(left: 8.0),
                                                     child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF8CAF7B))),
                                                   ),
                                              ],
                                            ),
                                            if (_trackingStatus != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(_trackingStatus!, 
                                                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w700),
                                                  overflow: TextOverflow.ellipsis, maxLines: 1),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (widget.order['sentDate'] != null || widget.order['receivedDate'] != null) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(height: 1),
                                  ),
                                  Row(
                                    children: [
                                      if (widget.order['sentDate'] != null)
                                        Expanded(
                                          child: _Milestone(
                                            icon: Icons.outbox_rounded,
                                            label: 'Відправлено',
                                            date: '${widget.order['sentDate']}',
                                            subCol: widget.subCol,
                                          ),
                                        ),
                                      if (widget.order['receivedDate'] != null)
                                        Expanded(
                                          child: _Milestone(
                                            icon: Icons.task_alt_rounded,
                                            label: 'Отримано',
                                            date: '${widget.order['receivedDate']}',
                                            subCol: widget.subCol,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // --- Footer Summary ---
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('СУМА ДО ОПЛАТИ', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: widget.subCol, letterSpacing: 1)),
                                    const SizedBox(height: 2),
                                    Text(paymentField == 'paylater' || paymentField == 'payLater' ? 'Оплата при отриманні' : 'Оплата онлайн', 
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.subCol)),
                                  ],
                                ),
                                Text('${total.toStringAsFixed(0)} грн', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: widget.titleCol)),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Components for Order Card ─────────────────────────────────────────

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item, required this.titleCol, required this.subCol});
  final Map<String, dynamic> item;
  final Color titleCol, subCol;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item['image'] != null
                ? Image.network(item['image'], width: 44, height: 44, fit: BoxFit.cover, 
                    errorBuilder: (_, __, ___) => _Placeholder(subCol))
                : _Placeholder(subCol),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '', 
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: titleCol), 
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${item['quantity']} × ${item['price']} грн', 
                  style: TextStyle(fontSize: 12, color: subCol)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.col); final Color col;
  @override
  Widget build(BuildContext context) => Container(
    width: 44, height: 44, 
    color: col.withValues(alpha: 0.1), 
    child: Icon(Icons.inventory_2_outlined, size: 20, color: col.withValues(alpha: 0.3)));
}

// ── Profile field: read-only card ↔ editable input ───────────────────────────

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.editing,
    required this.isDark,
    required this.cardBg,
    required this.titleCol,
    required this.subCol,
    required this.borderCol,
    this.keyboardType,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool editing;
  final bool isDark;
  final Color cardBg;
  final Color titleCol;
  final Color subCol;
  final Color borderCol;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: editing
              ? const Color(0xFF8CAF7B).withValues(alpha: 0.5)
              : borderCol,
          width: editing ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: editing,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        autocorrect: false,
        enableSuggestions: false,
        style: TextStyle(
          color: titleCol,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: editing
                ? const Color(0xFF8CAF7B)
                : subCol,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon,
              color: editing
                  ? const Color(0xFF8CAF7B)
                  : subCol,
              size: 20),
          filled: false,
          border: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ── Tiny formatters re-used from checkout (private to this file) ──────────────

class _CyrillicNameFmt extends TextInputFormatter {
  static final _ok = RegExp(r'[\u0400-\u04FF\u0027\- ]');
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue o, TextEditingValue n) {
    final src = n.text;
    final buf = StringBuffer();
    int cur = n.selection.baseOffset.clamp(0, src.length);
    int rm = 0;
    for (int i = 0; i < src.length; i++) {
      if (_ok.hasMatch(src[i])) { buf.write(src[i]); }
      else { if (i < cur) rm++; }
    }
    String r = buf.toString();
    if (r.isNotEmpty) r = r[0].toUpperCase() + r.substring(1);
    final off = (cur - rm).clamp(0, r.length);
    return TextEditingValue(
        text: r, selection: TextSelection.collapsed(offset: off));
  }
}

class _UkrPhoneFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue o, TextEditingValue n) {
    final raw = n.text;
    String local;
    if (raw.startsWith('+38') || raw.startsWith('380')) {
      local = raw
          .replaceFirst(RegExp(r'^\+?38[\s(]*'), '')
          .replaceAll(RegExp(r'\D'), '');
    } else {
      local = raw.replaceAll(RegExp(r'\D'), '');
    }
    if (local.length >= 2 && !local.startsWith('0')) local = '0$local';
    if (local.length > 10) local = local.substring(0, 10);
    final buf = StringBuffer('+38 ');
    if (local.isNotEmpty) {
      buf.write('(');
      if (local.length <= 3) { buf.write(local); }
      else {
        buf.write('${local.substring(0, 3)}) ');
        if (local.length <= 6) { buf.write(local.substring(3)); }
        else {
          buf.write('${local.substring(3, 6)} ');
          buf.write(local.substring(6));
        }
      }
    }
    final res = buf.toString();
    return TextEditingValue(
        text: res, selection: TextSelection.collapsed(offset: res.length));
  }
}

// ── Info row: view-mode label+value inside the profile card ──────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.titleCol,
    required this.subCol,
    required this.borderCol,
    required this.showDivider,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color titleCol;
  final Color subCol;
  final Color borderCol;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: subCol),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: subCol,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: titleCol,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: borderCol, indent: 50),
      ],
    );
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone({
    required this.icon,
    required this.label,
    required this.date,
    required this.subCol,
  });

  final IconData icon;
  final String label;
  final String date;
  final Color subCol;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: subCol),
            const SizedBox(width: 8),
            Text(label.toUpperCase(), style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w800, color: subCol, letterSpacing: 0.5
            )),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Text(date, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: subCol.withValues(alpha: 0.8)
          )),
        ),
      ],
    );
  }
}
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w800, color: color
          )),
        ],
      ),
    );
  }
}

class _ItemThumb extends StatelessWidget {
  const _ItemThumb({this.imageUrl, required this.subCol, required this.borderCol, this.size = 32});
  final String? imageUrl;
  final Color subCol, borderCol;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: borderCol.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4, offset: const Offset(0, 1)
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _Placeholder(subCol))
          : _Placeholder(subCol),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.badge);
  final String title;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subCol = isDark ? Colors.white70 : const Color(0xFF7C7267);

    return Row(
      children: [
        Text(title, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w900, color: subCol, letterSpacing: 1.2
        )),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: subCol.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(badge!, style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w900, color: subCol
            )),
          ),
        ],
      ],
    );
  }
}

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

  bool _editing   = false;
  bool _loading   = true;
  bool _saving    = false;

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
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
            'firstName'  : _firstNameCtrl.text.trim(),
            'secondName' : _secondNameCtrl.text.trim(),
            'phone'      : _phoneCtrl.text.trim(),
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
                        child: Text('Профіль',
                          style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900,
                            color: titleCol,
                          )),
                      ),
                    ],
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
                                    ],
                                  ),
                                )
                              // ── VIEW MODE: single info card ───────────────
                              : SingleChildScrollView(
                                  key: const ValueKey('view'),
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                                    ],
                                  ),
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
                        : Column(
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

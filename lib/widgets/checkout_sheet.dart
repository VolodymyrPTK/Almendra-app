import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart' as ap;

enum _Delivery { nova, ukr }

class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({super.key});

  static void show(BuildContext context) {
    final cart = context.read<CartProvider>();
    final auth = context.read<ap.AuthProvider>();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Checkout',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cart),
          ChangeNotifierProvider.value(value: auth),
        ],
        child: const CheckoutSheet(),
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
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _secondNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Nova Poshta
  final _novaCityCtrl = TextEditingController(); // short city name (city)
  final _novaWarehouseCtrl =
      TextEditingController(); // warehouse number (warehouse)

  // Ukr Poshta
  final _ukrCityCtrl = TextEditingController(); // city
  final _ukrIndexCtrl = TextEditingController(); // postal index (cityIndex)

  _Delivery _delivery = _Delivery.nova;
  bool _isLoading = false;
  bool _success = false;

  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _warehouseFocus = FocusNode();

  // Nova Poshta Search State
  List<dynamic> _citySuggestions = [];
  List<dynamic> _warehouseSuggestions = [];
  bool _loadingCities = false;
  bool _loadingWarehouses = false;
  String? _selectedCityRef;
  String? _selectedWarehouseIndex; // "цифрова адресса"
  String _warehouseCategory = 'Warehouse'; // 'Warehouse' or 'Postomat'

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
    _cityFocus.addListener(_onFocusChange);
    _warehouseFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_cityFocus.hasFocus || _warehouseFocus.hasFocus) {
      // Delay slightly to allow the keyboard to show
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        final FocusNode currentFocus = _cityFocus.hasFocus ? _cityFocus : _warehouseFocus;
        final context = currentFocus.context;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.0, // Move it to the very top of the scroll viewport
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _prefillFromProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data == null || !mounted) return;
      _firstNameCtrl.text = data['firstName'] as String? ?? '';
      _secondNameCtrl.text = data['secondName'] as String? ?? '';
      _phoneCtrl.text = data['phone'] as String? ?? '';
      final delOption = data['deliveryOption'] as String? ?? '';
      if (delOption == 'ukrPoshta') {
        setState(() => _delivery = _Delivery.ukr);
        _ukrCityCtrl.text = data['city'] as String? ?? '';
        _ukrIndexCtrl.text = data['cityIndex'] as String? ?? '';
      } else if (delOption == 'novaPoshta') {
        setState(() => _delivery = _Delivery.nova);
        _novaCityCtrl.text = data['city'] as String? ?? '';
        _novaWarehouseCtrl.text = data['warehouse'] as String? ?? '';
        _selectedWarehouseIndex = data['warehouseIndex'] as String?;
        // Note: Refs are not stored in profile usually, so we might need to re-search or just preserve text
      }
    } catch (_) {
      // silently ignore pre-fill errors
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _cityFocus.dispose();
    _warehouseFocus.dispose();
    _firstNameCtrl.dispose();
    _secondNameCtrl.dispose();
    _phoneCtrl.dispose();
    _novaCityCtrl.dispose();
    _novaWarehouseCtrl.dispose();
    _ukrCityCtrl.dispose();
    _ukrIndexCtrl.dispose();
    super.dispose();
  }

  static String _formatOrderTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$d/$mo/$y, $h:$mi';
  }

  Future<void> _submit(CartProvider cart) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not logged in');

      final db = FirebaseFirestore.instance;
      final profileRef = db.collection('profiles').doc(uid);

      // Build flat profile fields matching the exact Firestore schema
      final Map<String, dynamic> profileFields = {
        'firstName': _firstNameCtrl.text.trim(),
        'secondName': _secondNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        if (_delivery == _Delivery.nova) ...{
          'deliveryOption': 'novaPoshta',
          'city': _novaCityCtrl.text.trim(),
          'warehouse': _novaWarehouseCtrl.text.trim(),
          'postType': _warehouseCategory,
          'warehouseIndex': _selectedWarehouseIndex ?? '',
        } else ...{
          'deliveryOption': 'ukrPoshta',
          'city': _ukrCityCtrl.text.trim(),
          'cityIndex': _ukrIndexCtrl.text.trim(),
        },
      };

      // Fetch the next orderId (matches web: orders collection, ordered by orderId)
      // Falls back gracefully if the Firestore index doesn't exist yet.
      final ordersCol = db.collection('orders');
      int lastId = 0;
      try {
        final lastSnap = await ordersCol
            .orderBy('orderId', descending: true)
            .limit(1)
            .get();
        if (lastSnap.docs.isNotEmpty) {
          lastId = (lastSnap.docs.first.data()['orderId'] as int? ?? 0);
        }
      } catch (_) {
        // Index not yet created — orderId will be 1 for first order
        lastId = 0;
      }

      final orderRef = ordersCol.doc();
      final orderData = {
        'orderId': lastId + 1,
        'documentId': orderRef.id,
        'uid': uid,
        'firstName': _firstNameCtrl.text.trim(),
        'secondName': _secondNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
        'deliveryOption': _delivery == _Delivery.nova
            ? 'novaPoshta'
            : 'ukrPoshta',
        'city': _delivery == _Delivery.nova
            ? _novaCityCtrl.text.trim()
            : _ukrCityCtrl.text.trim(),
        if (_delivery == _Delivery.nova) ...{
          'warehouse': _novaWarehouseCtrl.text.trim(),
          'postType': _warehouseCategory,
          'warehouseIndex': _selectedWarehouseIndex ?? '',
        } else ...{
          'cityIndex': _ukrIndexCtrl.text.trim(),
        },
        'items': cart.items.map((e) => e.toMap()).toList(),
        'total': cart.total,
        'payment': 'payLater',
        'orderStatus': 'Processing',
        'paymentStatus': 'cash_on_delivery',
        'userType': 'authenticated',
        'oblast': '',
        'raion': '',
        'time': _formatOrderTime(DateTime.now()),
      };

      // 1. Write order to top-level 'orders' collection (matches web)
      await orderRef.set(orderData);

      // 2. Persist contact + delivery info to profile doc (merge so cart is untouched)
      await profileRef.set(profileFields, SetOptions(merge: true));

      // 3. Clear the cart
      await db.collection('profiles').doc(uid).update({'cart': []});

      if (mounted)
        setState(() {
          _isLoading = false;
          _success = true;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка: $e'),
            backgroundColor: const Color(0xFFE5395E),
          ),
        );
      }
    }
  }

  // ── Nova Poshta API Logic ──────────────────────────────────────────

  Future<void> _searchCities(String query) async {
    if (query.length < 2) {
      setState(() {
        _citySuggestions = [];
        _loadingCities = false;
      });
      return;
    }
    setState(() => _loadingCities = true);
    try {
      final normalizedQuery = query.trim().toLowerCase();
      var results = await _NovaService.searchSettlements(query);

      // Fallback: If full query returns nothing but has spaces, search by first word and filter locally
      if (results.isEmpty && query.trim().contains(' ')) {
        final firstWord = query.trim().split(' ').first;
        if (firstWord.length >= 2) {
          final broadResults = await _NovaService.searchSettlements(firstWord);
          final queryParts = normalizedQuery.split(' ');
          
          results = broadResults.where((item) {
            final desc = (item['Description'] ?? '').toString().toLowerCase();
            final area = (item['AreaDescription'] ?? '').toString().toLowerCase();
            final region = (item['RegionsDescription'] ?? '').toString().toLowerCase();
            final fullText = "$desc $area $region";
            // Must contain all typed words anywhere in the settlement details
            return queryParts.every((part) => fullText.contains(part));
          }).toList();
        }
      }

      // Sort: Cities first, then Urban settlements, then Towns/Villages
      results.sort((a, b) {
        final tA = (a['SettlementTypeDescription'] ?? '').toString().toLowerCase();
        final tB = (b['SettlementTypeDescription'] ?? '').toString().toLowerCase();

        int score(String t) {
          if (t.contains('місто')) return 0;
          if (t.contains('селище міського типу')) return 1;
          if (t.contains('селище')) return 2;
          return 3; // село usually
        }

        return score(tA).compareTo(score(tB));
      });

      setState(() {
        _citySuggestions = results;
        _loadingCities = false;
      });
    } catch (_) {
      setState(() => _loadingCities = false);
    }
  }

  Future<void> _onCitySelected(dynamic city) async {
    final name = city['Present'] ?? city['Description'] ?? '';
    _novaCityCtrl.text = name;
    setState(() {
      _citySuggestions = [];
      _loadingCities = false;
      _novaWarehouseCtrl.clear();
      _selectedWarehouseIndex = null;
      _warehouseSuggestions = [];
    });

    // Resolve CityRef for warehouses
    String? ref = city['DeliveryCity'];
    if (ref == null || ref.isEmpty) {
      ref = await _NovaService.resolveCityRef(
        name,
        city['AreaDescription'] ?? '',
      );
    }

    setState(() => _selectedCityRef = ref);
    if (ref != null) {
      _fetchWarehouses('', ref);
    }
  }

  Future<void> _fetchWarehouses(String query, String cityRef) async {
    setState(() => _loadingWarehouses = true);
    try {
      final results = await _NovaService.getWarehouses(
        cityRef,
        findByString: query,
        category: _warehouseCategory,
      );
      setState(() {
        _warehouseSuggestions = results;
        _loadingWarehouses = false;
      });
    } catch (_) {
      setState(() => _loadingWarehouses = false);
    }
  }

  void _onWarehouseSelected(dynamic warehouse) {
    setState(() {
      _novaWarehouseCtrl.text = warehouse['Description'] ?? '';
      _selectedWarehouseIndex = warehouse['WarehouseIndex'];
      _warehouseSuggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = isDark ? const Color(0xFF1E1A17) : const Color(0xFFF0EAE2);
    final cardBg = isDark ? const Color(0xFF2A2420) : Colors.white;
    final titleCol = isDark ? Colors.white : const Color(0xFF2B2118);
    final subCol = isDark ? Colors.white70 : const Color(0xFF5A5047);
    final borderCol = isDark ? Colors.white12 : const Color(0xFFDDD6CC);
    final topPad = MediaQuery.of(context).padding.top + 16;

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
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 30,
                  offset: const Offset(-6, 0),
                ),
              ],
            ),
            child: Consumer<CartProvider>(
              builder: (context, cart, _) {
                if (_success) {
                  return _SuccessView(
                    titleCol: titleCol,
                    subCol: subCol,
                    onClose: () => Navigator.pop(context),
                  );
                }
                return Column(
                  children: [
                    // ── Header ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 8, 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: borderCol,
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: titleCol,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Оформлення',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: titleCol,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Order summary strip ───────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderCol, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.25 : 0.06,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${cart.itemCount} товар(ів)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: subCol,
                              ),
                            ),
                            Text(
                              'До сплати ${cart.total.toStringAsFixed(0)} грн',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: titleCol,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Form ─────────────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Contact section ──────────────
                              _SectionLabel(
                                label: 'Контактні дані',
                                subCol: subCol,
                              ),
                              const SizedBox(height: 10),
                              _InputCard(
                                controller: _firstNameCtrl,
                                label: 'Ім\'я',
                                icon: Icons.person_outline_rounded,
                                keyboardType: TextInputType.text,
                                inputFormatters: [_CyrillicNameFormatter()],
                                autocorrect: false,
                                isDark: isDark,
                                cardBg: cardBg,
                                titleCol: titleCol,
                                subCol: subCol,
                                borderCol: borderCol,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Введіть ім\'я'
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              _InputCard(
                                controller: _secondNameCtrl,
                                label: 'Прізвище',
                                icon: Icons.badge_outlined,
                                keyboardType: TextInputType.text,
                                inputFormatters: [_CyrillicNameFormatter()],
                                autocorrect: false,
                                isDark: isDark,
                                cardBg: cardBg,
                                titleCol: titleCol,
                                subCol: subCol,
                                borderCol: borderCol,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Введіть прізвище'
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              _InputCard(
                                controller: _phoneCtrl,
                                label: 'Телефон',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [_UkrainianPhoneFormatter()],
                                autocorrect: false,
                                isDark: isDark,
                                cardBg: cardBg,
                                titleCol: titleCol,
                                subCol: subCol,
                                borderCol: borderCol,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Введіть телефон';
                                  }
                                  // +38 (0XX) XXX XXXX = 10 local digits
                                  final digits = v.replaceAll(
                                    RegExp(r'\D'),
                                    '',
                                  );
                                  if (digits.length < 12)
                                    return 'Некоректний номер';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // ── Delivery section ─────────────
                              _SectionLabel(
                                label: 'Спосіб доставки',
                                subCol: subCol,
                              ),
                              const SizedBox(height: 10),

                              // Toggle chips
                              Row(
                                children: [
                                  Expanded(
                                    child: _DeliveryChip(
                                      label: 'Нова Пошта',
                                      icon: Icons.local_shipping_outlined,
                                      selected: _delivery == _Delivery.nova,
                                      isDark: isDark,
                                      cardBg: cardBg,
                                      titleCol: titleCol,
                                      borderCol: borderCol,
                                      onTap: () => setState(
                                        () => _delivery = _Delivery.nova,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _DeliveryChip(
                                      label: 'Укрпошта',
                                      icon: Icons.mail_outline_rounded,
                                      selected: _delivery == _Delivery.ukr,
                                      isDark: isDark,
                                      cardBg: cardBg,
                                      titleCol: titleCol,
                                      borderCol: borderCol,
                                      onTap: () => setState(
                                        () => _delivery = _Delivery.ukr,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Dynamic fields per delivery option
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(
                                      opacity: anim,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.08),
                                          end: Offset.zero,
                                        ).animate(anim),
                                        child: child,
                                      ),
                                    ),
                                child: _delivery == _Delivery.nova
                                    ? _NovaFields(
                                        key: const ValueKey('nova'),
                                        cityCtrl: _novaCityCtrl,
                                        warehouseCtrl: _novaWarehouseCtrl,
                                        isDark: isDark,
                                        cardBg: cardBg,
                                        titleCol: titleCol,
                                        subCol: subCol,
                                        borderCol: borderCol,
                                        cityFocus: _cityFocus,
                                        warehouseFocus: _warehouseFocus,
                                        citySuggestions: _citySuggestions,
                                        warehouseSuggestions:
                                            _warehouseSuggestions,
                                        loadingCities: _loadingCities,
                                        loadingWarehouses: _loadingWarehouses,
                                        onCitySearch: _searchCities,
                                        onCitySelect: _onCitySelected,
                                        onWarehouseSearch: (q) =>
                                            _selectedCityRef != null
                                            ? _fetchWarehouses(
                                                q,
                                                _selectedCityRef!,
                                              )
                                            : null,
                                        onWarehouseSelect: _onWarehouseSelected,
                                        category: _warehouseCategory,
                                        onCategoryChange: (c) {
                                          setState(
                                            () => _warehouseCategory = c,
                                          );
                                          if (_selectedCityRef != null)
                                            _fetchWarehouses(
                                              '',
                                              _selectedCityRef!,
                                            );
                                        },
                                      )
                                    : _UkrFields(
                                        key: const ValueKey('ukr'),
                                        cityCtrl: _ukrCityCtrl,
                                        indexCtrl: _ukrIndexCtrl,
                                        isDark: isDark,
                                        cardBg: cardBg,
                                        titleCol: titleCol,
                                        subCol: subCol,
                                        borderCol: borderCol,
                                      ),
                              ),
                              const SizedBox(height: 8),
                              // Spacer to allow scrolling past the keyboard
                              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 100),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Bottom CTA ────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        MediaQuery.of(context).padding.bottom + 20,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _isLoading ? null : () => _submit(cart),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _isLoading
                                      ? const Color(
                                          0xFF8CAF7B,
                                        ).withOpacity(0.6)
                                      : const Color(0xFF8CAF7B),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF8CAF7B,
                                      ).withOpacity(0.4),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Підтвердити замовлення',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: borderCol,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: subCol,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable Input Card ────────────────────────────────────────────

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    required this.cardBg,
    required this.titleCol,
    required this.subCol,
    required this.borderCol,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.autocorrect = true,
    this.onChanged,
    this.suffix,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final Color cardBg;
  final Color titleCol;
  final Color subCol;
  final Color borderCol;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool autocorrect;
  final void Function(String)? onChanged;
  final Widget? suffix;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        autocorrect: autocorrect,
        enableSuggestions: autocorrect,
        onChanged: onChanged,
        style: TextStyle(
          color: titleCol,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: subCol,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: subCol, size: 20),
          suffixIcon: suffix,
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          errorStyle: const TextStyle(
            color: Color(0xFFE5395E),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Delivery Option Chip ──────────────────────────────────────────

class _DeliveryChip extends StatelessWidget {
  const _DeliveryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.cardBg,
    required this.titleCol,
    required this.borderCol,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final Color cardBg;
  final Color titleCol;
  final Color borderCol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF8CAF7B);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? green.withOpacity(0.12) : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? green : borderCol,
            width: selected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? green.withOpacity(0.20)
                  : Colors.black.withOpacity(isDark ? 0.22 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? green : titleCol.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? green : titleCol,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── NovaPoshta Fields ────────────────────────────────────────────

class _NovaFields extends StatelessWidget {
  const _NovaFields({
    super.key,
    required this.cityCtrl,
    required this.warehouseCtrl,
    required this.isDark,
    required this.cardBg,
    required this.titleCol,
    required this.subCol,
    required this.borderCol,
    required this.cityFocus,
    required this.warehouseFocus,
    required this.citySuggestions,
    required this.warehouseSuggestions,
    required this.loadingCities,
    required this.loadingWarehouses,
    required this.onCitySearch,
    required this.onCitySelect,
    required this.onWarehouseSearch,
    required this.onWarehouseSelect,
    required this.category,
    required this.onCategoryChange,
  });

  final TextEditingController cityCtrl;
  final TextEditingController warehouseCtrl;
  final bool isDark;
  final Color cardBg;
  final Color titleCol;
  final Color subCol;
  final Color borderCol;
  final FocusNode cityFocus;
  final FocusNode warehouseFocus;
  final List<dynamic> citySuggestions;
  final List<dynamic> warehouseSuggestions;
  final bool loadingCities;
  final bool loadingWarehouses;
  final Function(String) onCitySearch;
  final Function(dynamic) onCitySelect;
  final Function(String) onWarehouseSearch;
  final Function(dynamic) onWarehouseSelect;
  final String category;
  final Function(String) onCategoryChange;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF8CAF7B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── City Search ──────────────────
        _InputCard(
          controller: cityCtrl,
          focusNode: cityFocus,
          label: 'Населений пункт',
          icon: Icons.location_city_outlined,
          isDark: isDark,
          cardBg: cardBg,
          titleCol: titleCol,
          subCol: subCol,
          borderCol: borderCol,
          onChanged: onCitySearch,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Введіть місто' : null,
          suffix: loadingCities
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(green),
                  ),
                )
              : null,
        ),
        if (citySuggestions.isNotEmpty)
          _SuggestionList(
            suggestions: citySuggestions,
            isDark: isDark,
            cardBg: cardBg,
            titleCol: titleCol,
            subCol: subCol,
            onSelect: onCitySelect,
            itemBuilder: (city) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city['Present'] ?? city['Description'] ?? '',
                  style: TextStyle(
                    color: titleCol,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (city['AreaDescription'] != null)
                  Text(
                    '${city['RegionsDescription'] ?? ''} ${city['AreaDescription']} обл.',
                    style: TextStyle(color: subCol, fontSize: 11),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // ── Category Tabs ────────────────
        Row(
          children: [
            _MiniTab(
              label: 'Відділення',
              selected: category == 'Warehouse',
              onTap: () => onCategoryChange('Warehouse'),
              isDark: isDark,
              cardBg: cardBg,
              borderCol: borderCol,
            ),
            const SizedBox(width: 8),
            _MiniTab(
              label: 'Поштомат',
              selected: category == 'Postomat',
              onTap: () => onCategoryChange('Postomat'),
              isDark: isDark,
              cardBg: cardBg,
              borderCol: borderCol,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Warehouse Search ─────────────
        _InputCard(
          controller: warehouseCtrl,
          focusNode: warehouseFocus,
          label: category == 'Warehouse' ? 'Відділення' : 'Поштомат',
          icon: Icons.store_mall_directory_outlined,
          isDark: isDark,
          cardBg: cardBg,
          titleCol: titleCol,
          subCol: subCol,
          borderCol: borderCol,
          onChanged: onWarehouseSearch,
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Виберіть місце доставки'
              : null,
          suffix: loadingWarehouses
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(green),
                  ),
                )
              : null,
        ),
        if (warehouseSuggestions.isNotEmpty)
          _SuggestionList(
            suggestions: warehouseSuggestions,
            isDark: isDark,
            cardBg: cardBg,
            titleCol: titleCol,
            subCol: subCol,
            onSelect: onWarehouseSelect,
            itemBuilder: (w) => Text(
              w['Description'] ?? '',
              style: TextStyle(
                color: titleCol,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniTab extends StatelessWidget {
  const _MiniTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
    required this.cardBg,
    required this.borderCol,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardBg;
  final Color borderCol;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF8CAF7B);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? green.withOpacity(0.15) : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? green : borderCol, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected
                ? green
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({
    required this.suggestions,
    required this.onSelect,
    required this.itemBuilder,
    required this.isDark,
    required this.cardBg,
    required this.titleCol,
    required this.subCol,
  });
  final List<dynamic> suggestions;
  final Function(dynamic) onSelect;
  final Widget Function(dynamic) itemBuilder;
  final bool isDark;
  final Color cardBg;
  final Color titleCol;
  final Color subCol;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.black12,
          ),
          itemBuilder: (context, index) {
            final item = suggestions[index];
            return InkWell(
              onTap: () => onSelect(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: itemBuilder(item),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── UkrPoshta Fields ────────────────────────────────────────────

class _UkrFields extends StatelessWidget {
  const _UkrFields({
    super.key,
    required this.cityCtrl,
    required this.indexCtrl,
    required this.isDark,
    required this.cardBg,
    required this.titleCol,
    required this.subCol,
    required this.borderCol,
  });

  final TextEditingController cityCtrl;
  final TextEditingController indexCtrl;
  final bool isDark;
  final Color cardBg;
  final Color titleCol;
  final Color subCol;
  final Color borderCol;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InputCard(
          controller: cityCtrl,
          label: 'Населений пункт',
          icon: Icons.location_city_outlined,
          isDark: isDark,
          cardBg: cardBg,
          titleCol: titleCol,
          subCol: subCol,
          borderCol: borderCol,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Введіть населений пункт' : null,
        ),
        const SizedBox(height: 10),
        _InputCard(
          controller: indexCtrl,
          label: 'Поштовий індекс',
          icon: Icons.markunread_mailbox_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          isDark: isDark,
          cardBg: cardBg,
          titleCol: titleCol,
          subCol: subCol,
          borderCol: borderCol,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Введіть індекс';
            if (v.trim().length < 5) return 'Індекс має містити 5 цифр';
            return null;
          },
        ),
      ],
    );
  }
}

// ── Section Label ────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.subCol});
  final String label;
  final Color subCol;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: subCol,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Success Screen ───────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.titleCol,
    required this.subCol,
    required this.onClose,
  });

  final Color titleCol;
  final Color subCol;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF8CAF7B).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 44,
                color: Color(0xFF8CAF7B),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Замовлення прийнято!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: titleCol,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Ми зв\'яжемось з вами найближчим часом для підтвердження.',
              style: TextStyle(fontSize: 14, color: subCol, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8CAF7B),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8CAF7B).withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Text(
                  'Чудово!',
                  style: TextStyle(
                    fontSize: 16,
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

// ── Cyrillic Name Formatter ─────────────────────────────────────────────────
// Only allows Cyrillic letters, spaces, hyphens, apostrophes.
// Auto-capitalizes the very first character.

class _CyrillicNameFormatter extends TextInputFormatter {
  static final _allowed = RegExp(r'[\u0400-\u04FF\u0027\- ]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final src = newValue.text;
    final buf = StringBuffer();
    int cursorOffset = newValue.selection.baseOffset.clamp(0, src.length);
    int removed = 0;

    for (int i = 0; i < src.length; i++) {
      if (_allowed.hasMatch(src[i])) {
        buf.write(src[i]);
      } else {
        if (i < cursorOffset) removed++;
      }
    }

    String result = buf.toString();
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }

    final newOffset = (cursorOffset - removed).clamp(0, result.length);
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

// ── Ukrainian Phone Formatter ────────────────────────────────────────────────
// Formats input live as: +38 (0XX) XXX XXXX

class _UkrainianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text;

    // ── Strip the display prefix at TEXT level ────────────────────────────────
    // The formatted output always starts with "+38 (" so we strip it first.
    // This prevents the "38" from the visual prefix from being extracted as
    // digits and incorrectly treated as (part of) the country code.
    String localDigits;
    if (rawText.startsWith('+38') || rawText.startsWith('380')) {
      // Remove "+38 (", "+38(", "380", "+38" etc. from the start
      final afterPrefix = rawText.replaceFirst(RegExp(r'^\+?38[\s(]*'), '');
      localDigits = afterPrefix.replaceAll(RegExp(r'\D'), '');
    } else {
      // Field is being typed fresh (no prefix yet) — just get digits
      localDigits = rawText.replaceAll(RegExp(r'\D'), '');
    }

    // ── Ensure operator code starts with '0' ─────────────────────────────────
    // Ukrainian codes: 050, 063, 066–068, 073, 091–099, etc. — all start with 0.
    // If user typed "68..." auto-prefix to "068...".
    // Wait until ≥2 digits so a lone "6" isn't prematurely forced to "06".
    if (localDigits.length >= 2 && !localDigits.startsWith('0')) {
      localDigits = '0$localDigits';
    }

    // ── Clamp to 10 local digits ──────────────────────────────────────────────
    if (localDigits.length > 10) localDigits = localDigits.substring(0, 10);

    // ── Build formatted string: +38 (0XX) XXX XXXX ───────────────────────────
    final buf = StringBuffer('+38 ');
    if (localDigits.isNotEmpty) {
      buf.write('(');
      if (localDigits.length <= 3) {
        buf.write(localDigits);
      } else {
        buf.write('${localDigits.substring(0, 3)}) ');
        if (localDigits.length <= 6) {
          buf.write(localDigits.substring(3));
        } else {
          buf.write('${localDigits.substring(3, 6)} ');
          buf.write(localDigits.substring(6));
        }
      }
    }

    final result = buf.toString();
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
// ── Nova Poshta Service ─────────────────────────────────────────────────────

class _NovaService {
  static const String endpoint = 'https://api.novaposhta.ua/v2.0/json/';

  // Publicly available search might not require a key if calling getSettlements,
  // but for consistency we use an empty key or proxy if provided.
  static const String _apiKey = 'd4096c654147d373e43076e0e9ef2be4';

  static Future<List<dynamic>> searchSettlements(String query) async {
    final body = {
      "apiKey": _apiKey,
      "modelName": "Address",
      "calledMethod": "getSettlements",
      "methodProperties": {"FindByString": query, "Limit": 150},
    };
    final resp = await http.post(Uri.parse(endpoint), body: jsonEncode(body));
    final data = jsonDecode(resp.body);
    if (data['success'] == true) return data['data'];
    return [];
  }

  static Future<String?> resolveCityRef(String name, String area) async {
    final body = {
      "apiKey": _apiKey,
      "modelName": "Address",
      "calledMethod": "getCities",
      "methodProperties": {"FindByString": name},
    };
    final resp = await http.post(Uri.parse(endpoint), body: jsonEncode(body));
    final data = jsonDecode(resp.body);
    if (data['success'] == true && data['data'] != null) {
      final list = data['data'] as List;
      final match = list.firstWhere(
        (c) => c['AreaDescription'] == area || list.length == 1,
        orElse: () => null,
      );
      return match?['Ref'];
    }
    return null;
  }

  static Future<List<dynamic>> getWarehouses(
    String cityRef, {
    String findByString = '',
    String category = 'Warehouse',
  }) async {
    final body = {
      "apiKey": _apiKey,
      "modelName": "AddressGeneral",
      "calledMethod": "getWarehouses",
      "methodProperties": {
        "CityRef": cityRef,
        "FindByString": findByString,
        "CategoryOfWarehouse": category,
      },
    };
    final resp = await http.post(Uri.parse(endpoint), body: jsonEncode(body));
    final data = jsonDecode(resp.body);
    if (data['success'] == true) return data['data'];
    return [];
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart' as ap;
import 'payment_options_view.dart';
import '../services/nova_poshta_service.dart';
import 'delivery_widgets.dart';
import 'liqpay_webview.dart';

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
      TextEditingController(); // warehouse description (warehouse)

  // Ukr Poshta
  final _ukrCityCtrl = TextEditingController(); // city
  final _ukrIndexCtrl = TextEditingController(); // postal index (cityIndex)

  _Delivery _delivery = _Delivery.nova;
  bool _isLoading = false;
  bool _success = false;
  bool _showPaymentOptions = false;

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
  String _oblast = '';
  String _raion = '';
  String _settlementType = 'Місто';

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
        if (context != null && context.mounted) {
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
      _phoneCtrl.text = _UkrainianPhoneFormatter.format(data['phone'] as String? ?? '');
      final delOption = data['deliveryOption'] as String? ?? '';
      if (delOption == 'ukrPoshta') {
        setState(() => _delivery = _Delivery.ukr);
        _ukrCityCtrl.text = data['city'] as String? ?? '';
        _ukrIndexCtrl.text = data['cityIndex'] as String? ?? '';
      } else if (delOption == 'novaPoshta') {
        final city = data['city'] as String? ?? '';
        final warehouse = data['warehouse'] as String? ?? '';
        setState(() {
          _delivery = _Delivery.nova;
          _selectedCityRef = data['cityRef'] as String?;
          _selectedWarehouseIndex = data['warehouseIndex'] as String?;
          _warehouseCategory = data['postType'] as String? ?? 'Warehouse';
          _oblast = data['oblast'] as String? ?? '';
          _raion = data['raion'] as String? ?? '';
          _settlementType = data['settlementType'] as String? ?? 'Місто';
        });
        _novaCityCtrl.text = city;
        _novaWarehouseCtrl.text = warehouse;
        
        if (city.isNotEmpty) {
          if (_selectedCityRef == null) {
            // Resolve city first, then warehouse
            _resolveCityAndMaybeWarehouse(city, warehouse);
          } else if (warehouse.isNotEmpty && RegExp(r'^\d+$').hasMatch(warehouse)) {
            // CityRef already known, just resolve warehouse description
            _fetchAndSetWarehouseDescription(_selectedCityRef!, warehouse);
          }
        }
      }
    } catch (_) {
      // silently ignore pre-fill errors
    }
  }

  Future<void> _fetchAndSetWarehouseDescription(String cityRef, String warehouseNum) async {
    try {
      final results = await NovaPoshtaService.getWarehouses(
        cityRef,
        findByString: warehouseNum,
        category: _warehouseCategory,
      );
      if (results.isNotEmpty && mounted) {
        // Find exact match by number if possible, or just take first
        final match = results.firstWhere(
          (w) => w['Number'] == warehouseNum || w['WarehouseIndex'] == warehouseNum || results.length == 1,
          orElse: () => results.first,
        );
        setState(() {
          _novaWarehouseCtrl.text = match['Description'] ?? warehouseNum;
          _selectedWarehouseIndex = match['WarehouseIndex'];
        });
      }
    } catch (_) {}
  }

  Future<void> _resolveCityAndMaybeWarehouse(String cityName, String warehouseNum) async {
    try {
      final cityRef = await NovaPoshtaService.resolveCityRef(cityName, '');
      if (cityRef != null && mounted) {
        setState(() => _selectedCityRef = cityRef);
        if (warehouseNum.isNotEmpty && RegExp(r'^\d+$').hasMatch(warehouseNum)) {
          _fetchAndSetWarehouseDescription(cityRef, warehouseNum);
        }
      }
    } catch (_) {}
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
    return '$d.$mo.$y, $h:$mi';
  }

  Future<bool> _runLiqPayFlow(double amount, int orderId) async {
    const publicKey = 'sandbox_i56605069158';
    const privateKey = 'sandbox_8d0buaoFZlnm5t3zDZ7IrpdVuNZrsnlZZSr0nIHN';
    final liqpayOrderId = '${orderId}_${DateTime.now().millisecondsSinceEpoch}';
    
    final jsonString = jsonEncode({
      'version': 3,
      'public_key': publicKey,
      'action': 'pay',
      'amount': amount,
      'currency': 'UAH',
      'description': 'Замовлення #$orderId',
      'order_id': liqpayOrderId,
      'result_url': 'https://almendra-app.web.app/payment-success',
    });
    
    final data = base64Encode(utf8.encode(jsonString));
    final signString = privateKey + data + privateKey;
    final signature = base64Encode(sha1.convert(utf8.encode(signString)).bytes);

    if (!mounted) return false;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => LiqPayWebView(data: data, signature: signature)),
    );
    
    // Webview closed. Verify actual status via Server-to-Server request
    return await _verifyLiqPayStatus(liqpayOrderId);
  }

  Future<bool> _verifyLiqPayStatus(String orderId) async {
    const publicKey = 'sandbox_i56605069158';
    const privateKey = 'sandbox_8d0buaoFZlnm5t3zDZ7IrpdVuNZrsnlZZSr0nIHN';
    final jsonString = jsonEncode({
      'action': 'status',
      'version': 3,
      'public_key': publicKey,
      'order_id': orderId,
    });
    
    final data = base64Encode(utf8.encode(jsonString));
    final signString = privateKey + data + privateKey;
    final signature = base64Encode(sha1.convert(utf8.encode(signString)).bytes);

    try {
      final response = await http.post(
        Uri.parse('https://www.liqpay.ua/api/request'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': data, 'signature': signature},
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final status = decoded['status'];
        return status == 'success' || status == 'sandbox' || status == 'wait_accept' || status == 'wait_secure';
      }
    } catch (_) {}
    return false;
  }

  Future<void> _submit(CartProvider cart, String paymentMethod) async {
    // If it's already shown the payment options, form is valid.
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
          'cityRef': _selectedCityRef ?? '',
          'warehouse': _novaWarehouseCtrl.text.trim(),
          'postType': _warehouseCategory,
          'warehouseIndex': _selectedWarehouseIndex ?? '',
        } else ...{
          'deliveryOption': 'ukrPoshta',
          'city': _ukrCityCtrl.text.trim(),
          'cityIndex': _ukrIndexCtrl.text.trim(),
        },
        'oblast': _oblast,
        'raion': _raion,
        'settlementType': _settlementType,
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

      if (paymentMethod == 'liqpay') {
        final success = await _runLiqPayFlow(cart.total, lastId + 1);
        if (!success) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Оплату скасовано')));
          }
          return;
        }
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
        'payment': paymentMethod == 'liqpay' ? 'payNow' : 'payLater',
        'orderStatus': 'Processing',
        'paymentStatus': paymentMethod == 'liqpay' ? 'success' : 'pending',
        'userType': 'authenticated',
        'oblast': _oblast,
        'raion': _raion,
        'settlementType': _settlementType,
        'time': _formatOrderTime(DateTime.now()),
        'orderOnApp': true,
      };

      // 1. Write order to top-level 'orders' collection (matches web)
      await orderRef.set(orderData);

      // 2. Persist contact + delivery info to profile doc (merge so cart is untouched)
      await profileRef.set(profileFields, SetOptions(merge: true));

      // 3. Clear the cart
      await db.collection('profiles').doc(uid).update({'cart': []});

      if (mounted) {
        setState(() {
          _isLoading = false;
          _success = true;
          _showPaymentOptions = false;
        });
      }
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
      var results = await NovaPoshtaService.searchSettlements(query);

      // Fallback: If full query returns nothing but has spaces, search by first word and filter locally
      if (results.isEmpty && query.trim().contains(' ')) {
        final firstWord = query.trim().split(' ').first;
        if (firstWord.length >= 2) {
          final broadResults = await NovaPoshtaService.searchSettlements(firstWord);
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
      _oblast = city['AreaDescription'] ?? '';
      _raion = city['RegionsDescription'] ?? '';
      _settlementType = city['SettlementTypeDescription'] ?? 'Місто';
    });

    // Resolve CityRef for warehouses
    String? ref = city['DeliveryCity'];
    if (ref == null || ref.isEmpty) {
      ref = await NovaPoshtaService.resolveCityRef(
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
      final results = await NovaPoshtaService.getWarehouses(
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
                  color: Colors.black.withValues(alpha: 0.20),
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
                if (_showPaymentOptions) {
                  final contactName = '${_firstNameCtrl.text} ${_secondNameCtrl.text}';
                  final deliveryText = _delivery == _Delivery.nova
                      ? 'Нова Пошта: ${[_raion.isNotEmpty ? '$_raion р-н' : '', _oblast, _novaCityCtrl.text].where((s) => s.isNotEmpty).join(', ')}, ${_novaWarehouseCtrl.text}'
                      : 'Укрпошта: ${_ukrCityCtrl.text}, Індекс ${_ukrIndexCtrl.text}';
                  
                  return PaymentOptionsView(
                    cart: cart,
                    isDark: isDark,
                    contactName: contactName,
                    deliveryText: deliveryText,
                    onBack: () => setState(() => _showPaymentOptions = false),
                    onPayLiqPay: () => _submit(cart, 'liqpay'),
                    onPayCash: () => _submit(cart, 'cash'),
                    isLoading: _isLoading,
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
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.25 : 0.06,
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
                              InputCard(
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
                              InputCard(
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
                              InputCard(
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
                                  if (digits.length < 12) {
                                    return 'Некоректний номер';
                                  }
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
                                    child: DeliveryChip(
                                      label: 'Нова Пошта',
                                      icon: Icons.local_shipping_outlined,
                                      selected: _delivery == _Delivery.nova,
                                      isDark: isDark, cardBg: cardBg,
                                      titleCol: titleCol, borderCol: borderCol,
                                      onTap: () => setState(() => _delivery = _Delivery.nova),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DeliveryChip(
                                      label: 'Укрпошта',
                                      icon: Icons.mail_outline_rounded,
                                      selected: _delivery == _Delivery.ukr,
                                      isDark: isDark, cardBg: cardBg,
                                      titleCol: titleCol, borderCol: borderCol,
                                      onTap: () => setState(() => _delivery = _Delivery.ukr),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Dynamic fields per delivery option
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                transitionBuilder: (child, anim) => FadeTransition(
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
                                    ? NovaFields(
                                        key: const ValueKey('nova'),
                                        cityCtrl: _novaCityCtrl,
                                        warehouseCtrl: _novaWarehouseCtrl,
                                        isDark: isDark, cardBg: cardBg,
                                        titleCol: titleCol, subCol: subCol, borderCol: borderCol,
                                        cityFocus: _cityFocus, warehouseFocus: _warehouseFocus,
                                        citySuggestions: _citySuggestions, warehouseSuggestions: _warehouseSuggestions,
                                        loadingCities: _loadingCities, loadingWarehouses: _loadingWarehouses,
                                        onCitySearch: _searchCities, onCitySelect: _onCitySelected,
                                        onWarehouseSearch: (q) => _selectedCityRef != null ? _fetchWarehouses(q, _selectedCityRef!) : null,
                                        onWarehouseSelect: _onWarehouseSelected,
                                        category: _warehouseCategory,
                                        onCategoryChange: (c) {
                                          setState(() => _warehouseCategory = c);
                                          if (_selectedCityRef != null) _fetchWarehouses('', _selectedCityRef!);
                                        },
                                        oblast: _oblast,
                                        raion: _raion,
                                        settlementType: _settlementType,
                                      )
                                    : UkrFields(
                                        key: const ValueKey('ukr'),
                                        cityCtrl: _ukrCityCtrl,
                                        indexCtrl: _ukrIndexCtrl,
                                        isDark: isDark, cardBg: cardBg,
                                        titleCol: titleCol, subCol: subCol, borderCol: borderCol,
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
                              onTap: _isLoading ? null : () {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                                // validate delivery selection
                                if (_delivery == _Delivery.nova && (_novaCityCtrl.text.isEmpty || _novaWarehouseCtrl.text.isEmpty)) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Оберіть відділення Нової Пошти')));
                                  return;
                                }
                                if (_delivery == _Delivery.ukr && (_ukrCityCtrl.text.isEmpty || _ukrIndexCtrl.text.isEmpty)) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введіть місто та індекс Укрпошти')));
                                  return;
                                }
                                setState(() => _showPaymentOptions = true);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _isLoading
                                      ? const Color(
                                          0xFFE8734A,
                                        ).withValues(alpha: 0.6)
                                      : const Color(0xFFE8734A),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFE8734A,
                                      ).withValues(alpha: 0.4),
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

// Reusable components moved to delivery_widgets.dart


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
                color: const Color(0xFFE8734A).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 44,
                color: Color(0xFFE8734A),
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
                  color: const Color(0xFFE8734A),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE8734A).withValues(alpha: 0.4),
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
  static String format(String raw) {
    if (raw.isEmpty) return '';
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
      if (local.length <= 3) {
        buf.write(local);
      } else {
        buf.write('${local.substring(0, 3)}) ');
        if (local.length <= 6) {
          buf.write(local.substring(3));
        } else {
          buf.write('${local.substring(3, 6)} ');
          buf.write(local.substring(6));
        }
      }
    }
    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final res = format(newValue.text);
    return TextEditingValue(
      text: res,
      selection: TextSelection.collapsed(offset: res.length),
    );
  }
}

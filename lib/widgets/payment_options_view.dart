import 'package:flutter/material.dart';
import '../providers/cart_provider.dart';

class PaymentOptionsView extends StatefulWidget {
  final CartProvider cart;
  final bool isDark;
  final String contactName;
  final String deliveryText;
  final VoidCallback onBack;
  final VoidCallback onPayLiqPay;
  final VoidCallback onPayCash;
  final bool isLoading;

  const PaymentOptionsView({
    super.key,
    required this.cart,
    required this.isDark,
    required this.contactName,
    required this.deliveryText,
    required this.onBack,
    required this.onPayLiqPay,
    required this.onPayCash,
    required this.isLoading,
  });

  @override
  State<PaymentOptionsView> createState() => _PaymentOptionsViewState();
}

class _PaymentOptionsViewState extends State<PaymentOptionsView> {
  String _selectedPayment = 'liqpay'; // default to LiqPay

  @override
  Widget build(BuildContext context) {
    final titleCol = widget.isDark ? Colors.white : const Color(0xFF2B2118);
    final subCol = widget.isDark ? Colors.white70 : const Color(0xFF5A5047);
    final cardBg = widget.isDark ? const Color(0xFF2A2420) : Colors.white;
    final borderCol = widget.isDark ? Colors.white12 : const Color(0xFFDDD6CC);
    final highlightCol = const Color(0xFFE8734A);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 8, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.isLoading ? null : widget.onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderCol, width: 1.2),
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
                  'Оплата та підтвердження',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: titleCol,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Order Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: widget.isDark ? 0.25 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Дані замовлення', style: TextStyle(color: subCol, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.person_outline_rounded, size: 18, color: titleCol),
                          const SizedBox(width: 8),
                          Expanded(child: Text(widget.contactName, style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w500))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined, size: 18, color: titleCol),
                          const SizedBox(width: 8),
                          Expanded(child: Text(widget.deliveryText, style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w500))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 18, color: titleCol),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${widget.cart.itemCount} товар(ів)', style: TextStyle(color: titleCol, fontSize: 14, fontWeight: FontWeight.w500))),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('До сплати', style: TextStyle(color: titleCol, fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('${widget.cart.total.toStringAsFixed(0)} грн', style: TextStyle(color: titleCol, fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Payment Selection
                Text('Спосіб оплати', style: TextStyle(color: subCol, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                
                // LiqPay Option
                GestureDetector(
                  onTap: () => setState(() => _selectedPayment = 'liqpay'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedPayment == 'liqpay' ? highlightCol.withValues(alpha: 0.1) : cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedPayment == 'liqpay' ? highlightCol : borderCol,
                        width: _selectedPayment == 'liqpay' ? 2 : 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Center(
                            child: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/LiqPay_logo.svg/200px-LiqPay_logo.svg.png',
                              width: 30,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.payment, color: Colors.blueAccent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Оплатити зараз', style: TextStyle(color: titleCol, fontSize: 15, fontWeight: FontWeight.bold)),
                              Text('LiqPay (Картка, Приват24, Apple Pay)', style: TextStyle(color: subCol, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(
                          _selectedPayment == 'liqpay' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: _selectedPayment == 'liqpay' ? highlightCol : subCol.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                
                // Cash on Delivery Option
                GestureDetector(
                  onTap: () => setState(() => _selectedPayment = 'cash'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedPayment == 'cash' ? highlightCol.withValues(alpha: 0.1) : cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedPayment == 'cash' ? highlightCol : borderCol,
                        width: _selectedPayment == 'cash' ? 2 : 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.money, color: titleCol.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Оплата при отриманні', style: TextStyle(color: titleCol, fontSize: 15, fontWeight: FontWeight.bold)),
                              Text('Готівкою або карткою на пошті', style: TextStyle(color: subCol, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(
                          _selectedPayment == 'cash' ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: _selectedPayment == 'cash' ? highlightCol : subCol.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
                
              ],
            ),
          ),
        ),

        // Bottom CTA
        Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
          child: GestureDetector(
            onTap: widget.isLoading
                ? null
                : () {
                    if (_selectedPayment == 'liqpay') {
                      widget.onPayLiqPay();
                    } else {
                      widget.onPayCash();
                    }
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 52,
              decoration: BoxDecoration(
                color: widget.isLoading ? highlightCol.withValues(alpha: 0.6) : highlightCol,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: highlightCol.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _selectedPayment == 'liqpay' ? 'Оплатити ${widget.cart.total.toStringAsFixed(0)} грн' : 'Замовити без оплати',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

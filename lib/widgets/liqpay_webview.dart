import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LiqPayWebView extends StatefulWidget {
  final String data;
  final String signature;

  const LiqPayWebView({super.key, required this.data, required this.signature});

  @override
  State<LiqPayWebView> createState() => _LiqPayWebViewState();
}

class _LiqPayWebViewState extends State<LiqPayWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // Dismiss spinner once the checkout page starts loading
            if (url.contains('liqpay.ua')) {
               if (mounted) setState(() => _isLoading = false);
            }
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('LiqPayWebView Error: ${error.description}');
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://almendra-app.web.app/payment-success') ||
                request.url.contains('payment-success')) {
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    final String postBody = 'data=${Uri.encodeQueryComponent(widget.data)}&signature=${Uri.encodeQueryComponent(widget.signature)}';

    _controller.loadRequest(
      Uri.parse('https://www.liqpay.ua/api/3/checkout'),
      method: LoadRequestMethod.post,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: Uint8List.fromList(utf8.encode(postBody)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оплата LiqPay', style: TextStyle(fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1A17) : Colors.white,
        elevation: 1,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF8CAF7B)),
            ),
        ],
      ),
    );
  }
}


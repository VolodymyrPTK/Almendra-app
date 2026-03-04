import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as ap;

class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ap.AuthProvider>(),
        child: const AuthSheet(),
      ),
    );
  }

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet>
    with SingleTickerProviderStateMixin {
  bool _isSignIn = true;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  late final AnimationController _tabAnim;
  late final Animation<double> _tabSlide;

  @override
  void initState() {
    super.initState();
    _tabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _tabSlide = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _tabAnim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _tabAnim.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isSignIn = !_isSignIn);
    _isSignIn ? _tabAnim.reverse() : _tabAnim.forward();
    context.read<ap.AuthProvider>().clearError();
  }

  Future<void> _submit() async {
    final auth = context.read<ap.AuthProvider>();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return;

    final ok = _isSignIn
        ? await auth.signInWithEmail(email, pass)
        : await auth.signUpWithEmail(email, pass);
    if (ok && mounted) Navigator.pop(context);
  }

  Future<void> _googleSignIn() async {
    final ok = await context.read<ap.AuthProvider>().signInWithGoogle();
    if (ok && mounted) Navigator.pop(context);
  }

  Future<void> _facebookSignIn() async {
    final ok = await context.read<ap.AuthProvider>().signInWithFacebook();
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1A17) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF3B3228);
    final subText = isDark ? Colors.white60 : const Color(0xFF7A6F63);
    final fieldBg = isDark ? const Color(0xFF2A2420) : const Color(0xFFF3EDE5);
    final accentGreen = const Color(0xFF8CAF7B);

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: subText.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Toggle tab
                Consumer<ap.AuthProvider>(
                  builder: (_, auth, __) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ToggleTab(
                        isSignIn: _isSignIn,
                        onToggle: auth.isLoading ? null : _toggleMode,
                        textColor: textColor,
                        accentGreen: accentGreen,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),

                      // Email field
                      _InputField(
                        controller: _emailCtrl,
                        hint: 'Email',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        fieldBg: fieldBg,
                        textColor: textColor,
                        subText: subText,
                        enabled: !auth.isLoading,
                      ),
                      const SizedBox(height: 12),

                      // Password field
                      _InputField(
                        controller: _passCtrl,
                        hint: 'Пароль',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscure,
                        fieldBg: fieldBg,
                        textColor: textColor,
                        subText: subText,
                        enabled: !auth.isLoading,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: subText,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Error message
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: auth.error != null
                            ? Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                          Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  auth.error!,
                                  style: TextStyle(
                                    color: Colors.red[300],
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: GestureDetector(
                          onTap: auth.isLoading ? null : _submit,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: auth.isLoading
                                    ? [
                                        accentGreen.withValues(alpha: 0.5),
                                        accentGreen.withValues(alpha: 0.5),
                                      ]
                                    : [
                                        const Color(0xFFA8C69F),
                                        accentGreen,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: accentGreen.withValues(alpha: 0.3),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isSignIn ? 'Увійти' : 'Зареєструватися',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: subText.withValues(alpha: 0.25))),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'або',
                              style:
                                  TextStyle(color: subText, fontSize: 13),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: subText.withValues(alpha: 0.25))),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Google button
                      _SocialButton(
                        label: 'Продовжити з Google',
                        icon: _GoogleIcon(),
                        onTap: auth.isLoading ? null : _googleSignIn,
                        isDark: isDark,
                        textColor: textColor,
                        fieldBg: fieldBg,
                      ),
                      const SizedBox(height: 10),

                      // Facebook button
                      _SocialButton(
                        label: 'Продовжити з Facebook',
                        icon: const Icon(Icons.facebook_rounded,
                            size: 22, color: Color(0xFF1877F2)),
                        onTap: auth.isLoading ? null : _facebookSignIn,
                        isDark: isDark,
                        textColor: textColor,
                        fieldBg: fieldBg,
                      ),
                    ],
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

// ── Toggle Tab ─────────────────────────────────────────────────

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.isSignIn,
    required this.onToggle,
    required this.textColor,
    required this.accentGreen,
    required this.isDark,
  });

  final bool isSignIn;
  final VoidCallback? onToggle;
  final Color textColor;
  final Color accentGreen;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final trackBg =
        isDark ? const Color(0xFF2A2420) : const Color(0xFFF3EDE5);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: trackBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          // Animated pill
          AnimatedAlign(
            alignment:
                isSignIn ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: accentGreen,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: accentGreen.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isSignIn ? null : onToggle,
                  child: Center(
                    child: Text(
                      'Увійти',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSignIn ? Colors.white : textColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isSignIn ? onToggle : null,
                  child: Center(
                    child: Text(
                      'Реєстрація',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: !isSignIn ? Colors.white : textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Input Field ────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.fieldBg,
    required this.textColor,
    required this.subText,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color fieldBg;
  final Color textColor;
  final Color subText;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        enabled: enabled,
        style: TextStyle(color: textColor, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: subText, fontSize: 15),
          prefixIcon: Icon(icon, size: 20, color: subText),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ── Social Button ──────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.textColor,
    required this.fieldBg,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final bool isDark;
  final Color textColor;
  final Color fieldBg;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Google Icon (coloured G) ───────────────────────────────────

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Draw coloured arc segments
    final segments = [
      (0.0, 0.52, const Color(0xFF4285F4)),   // blue  (right)
      (0.52, 0.52, const Color(0xFF34A853)),  // green (bottom)
      (1.04, 0.52, const Color(0xFFFBBC05)),  // yellow (left)
      (1.56, 0.52, const Color(0xFFEA4335)),  // red (top)
    ];

    for (final (start, sweep, color) in segments) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.18;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.75),
        start * 2,
        sweep * 2,
        false,
        paint,
      );
    }

    // White cutout for the G bar
    final barPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - size.height * 0.09, r * 0.75, size.height * 0.18),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(_GooglePainter _) => false;
}

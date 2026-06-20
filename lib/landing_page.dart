import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'login_page.dart';

class _LC {
  static const accent   = Color(0xFFe8184a);
  static const accent2  = Color(0xFFff4466);
  static const accent3  = Color(0xFFff8099);
  static const bg       = Color(0xFF08080f);
  static const text     = Color(0xFFe8eaf0);
  static const textDim  = Color(0x66E8EAF0);
  static const textDim2 = Color(0x33E8EAF0);
  static const border   = Color(0x4DE8184A);
}

const String _heroImageUrl = 'https://files.catbox.moe/vijqk3.png';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _particleController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;

  bool _showHero    = false;
  bool _showTitle   = false;
  bool _showDivider = false;
  bool _showButtons = false;
  bool _showFooter  = false;
  bool _heroImageLoaded = false;

  @override
  void initState() {
    super.initState();

    _orbController = AnimationController(
      vsync: this, duration: const Duration(seconds: 20),
    )..repeat();

    _particleController = AnimationController(
      vsync: this, duration: const Duration(seconds: 30),
    )..repeat();

    _floatController = AnimationController(
      vsync: this, duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this, duration: const Duration(seconds: 3),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 100),  () { if (mounted) setState(() => _showHero    = true); });
    Future.delayed(const Duration(milliseconds: 350),  () { if (mounted) setState(() => _showTitle   = true); });
    Future.delayed(const Duration(milliseconds: 550),  () { if (mounted) setState(() => _showDivider = true); });
    Future.delayed(const Duration(milliseconds: 700),  () { if (mounted) setState(() => _showButtons = true); });
    Future.delayed(const Duration(milliseconds: 900),  () { if (mounted) setState(() => _showFooter  = true); });
  }

  @override
  void dispose() {
    _orbController.dispose();
    _particleController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Error launching $uri");
    }
  }

  Widget _fadeUp({
    required bool show,
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    double slidePixels = 25.0,
  }) {
    return AnimatedSlide(
      offset: show ? Offset.zero : Offset(0, slidePixels / 500),
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: show ? 1.0 : 0.0,
        duration: duration,
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;

    return Scaffold(
      backgroundColor: _LC.bg,
      body: Stack(
        children: [
          _buildBackground(sw, sh),
          _buildParticles(sw, sh),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            _buildHeroImage(),
                            _buildTitleBlock(),
                            _buildDivider(),
                            _buildButtons(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BACKGROUND — hapus semua boxShadow, pakai gradient + grid + orb
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBackground(double w, double h) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0c0d1a),
                Color(0xFF151425),
                Color(0xFF0e0c1a),
                Color(0xFF08080f),
              ],
              stops: [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),
        CustomPaint(size: Size(w, h), painter: _GridPainter()),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: h * 0.6,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -1.0),
                radius: 1.2,
                colors: [_LC.accent.withOpacity(0.08), Colors.transparent],
                stops: const [0.0, 0.6],
              ),
            ),
          ),
        ),
        _buildOrb(w * 0.1,  h * 0.05, 220, _LC.accent.withOpacity(0.06),  0.8, 22),
        _buildOrb(w * 0.8,  h * 0.35, 180, _LC.accent2.withOpacity(0.04), 0.6, 18),
        _buildOrb(w * 0.4,  h * 0.65, 250, _LC.accent3.withOpacity(0.03), 0.5, 25),
      ],
    );
  }

  Widget _buildOrb(double x, double y, double size, Color color, double speed, double offset) {
    return Positioned(
      left: x, top: y,
      child: AnimatedBuilder(
        animation: _orbController,
        builder: (ctx, _) {
          final t  = _orbController.value * 2 * math.pi;
          final dx = 25 * math.sin(t * speed + offset);
          final dy = -20 * math.cos(t * speed + offset);
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Container(
              width: size, height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PARTICLES — hapus boxShadow pada dots
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildParticles(double w, double h) {
    final colors = [
      _LC.accent.withOpacity(0.35),
      _LC.accent2.withOpacity(0.25),
      _LC.accent3.withOpacity(0.18),
      _LC.accent.withOpacity(0.12),
    ];
    return Stack(
      children: List.generate(25, (i) {
        final sz = 1.2 + (i % 4) * 0.5;
        final px = (i * 97 % 100) / 100 * w;
        final py = (20 + i * 53 % 60) / 100 * h;
        final dur   = 8.0 + (i % 14);
        final delay = (i % 10).toDouble();
        return Positioned(
          left: px, top: py,
          child: AnimatedBuilder(
            animation: _particleController,
            builder: (ctx, _) {
              final raw = _particleController.value * 30 + delay;
              final t   = (raw % dur) / dur;
              final opacity = t < 0.15
                  ? t / 0.15 * 0.4
                  : t > 0.85
                      ? (1 - t) / 0.15 * 0.4
                      : 0.4;
              return Transform.translate(
                offset: Offset(0, -120 * t),
                child: Transform.scale(
                  scale: 0.5 + 0.6 * t,
                  child: Container(
                    width: sz, height: sz,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // ← boxShadow dihapus
                      color: colors[i % 4].withOpacity(opacity.clamp(0.0, 1.0)),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HERO IMAGE — hapus gradient hitam di bawah gambar
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHeroImage() {
    return _fadeUp(
      show: _showHero,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (ctx, child) => Transform.translate(
          offset: Offset(0, -8.0 * _floatController.value),
          child: child,
        ),
        child: Container(
          width: double.infinity,
          color: Colors.transparent,
          child: Stack(
            children: [
              if (_heroImageLoaded)
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Image.network(
                    _heroImageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              if (!_heroImageLoaded)
                SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: Center(
                    child: FutureBuilder(
                      future: _preloadImage(),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.done) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _heroImageLoaded = true);
                          });
                        }
                        return SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _LC.accent.withOpacity(0.3),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // ← Positioned gradient hitam di bawah gambar DIHAPUS
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _preloadImage() async {
    await precacheImage(NetworkImage(_heroImageUrl), context);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TITLE BLOCK — hapus semua shadow pada Text
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTitleBlock() {
    return _fadeUp(
      show: _showTitle,
      duration: const Duration(milliseconds: 850),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: -46),
        child: Column(
          children: [
            Text(
              'ARE - YOU - READY?',
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 11,
                letterSpacing: 3,
                color: _LC.accent3,
                // ← shadow dihapus
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'SYAHID',
              style: TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontWeight: FontWeight.w900,
                fontSize: _titleFontSize(),
                letterSpacing: -1,
                color: _LC.text,
                // ← shadow dihapus
              ),
            ),
            Text(
              'ALLCRASH',
              style: TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontWeight: FontWeight.w900,
                fontSize: _titleFontSize(),
                letterSpacing: -1,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 1.5
                  ..color = _LC.accent.withOpacity(0.7),
                // ← shadow dihapus
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Selamat datang!\nVersi kali ini masih tahap BETA\nyang belum sepenuhnya sempurna',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: _LC.textDim,
                letterSpacing: 1,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _titleFontSize() {
    final w = MediaQuery.of(context).size.width;
    if (w < 360) return 42;
    if (w < 420) return 52;
    return 60;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DIVIDER — hapus shadow pada Icon
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildDivider() {
    return _fadeUp(
      show: _showDivider,
      duration: const Duration(milliseconds: 850),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 32),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            FaIcon(
              FontAwesomeIcons.bolt,
              color: _LC.accent,
              size: 11,
              // ← shadow dihapus
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUTTONS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildButtons() {
    return _fadeUp(
      show: _showButtons,
      duration: const Duration(milliseconds: 850),
      child: Column(
        children: [
          _buildPrimaryButton(),
          const SizedBox(height: 14),
          _buildSecondaryButton(),
        ],
      ),
    );
  }

  // Primary — warna merah solid, hapus boxShadow & shimmer & Text shadow
  Widget _buildPrimaryButton() {
    return GestureDetector(
      onTap: _navigateToLogin,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: _LC.accent,            // ← merah solid, tanpa gradient berat
          borderRadius: BorderRadius.circular(18),
          // ← boxShadow dihapus
        ),
        child: Stack(
          children: [
            // Highlight tipis di atas saja (ringan, cukup 1 layer)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
            // ← Shimmer AnimatedBuilder DIHAPUS (berat)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MULAI SEKARANG',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: Colors.white,
                      // ← shadow dihapus
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: Colors.black.withOpacity(0.2),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.white, size: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Secondary — hapus BackdropFilter blur (berat), ganti dengan warna solid transparan
  Widget _buildSecondaryButton() {
    return GestureDetector(
      onTap: () => _openUrl('https://t.me/TESTIALLTEAMNEW'),
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          color: Colors.white.withOpacity(0.04), // ← ganti BackdropFilter blur
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Center(
                  child: FaIcon(FontAwesomeIcons.telegram, color: _LC.text, size: 14),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'JOIN COMMUNITY',
                style: TextStyle(
                  fontFamily: 'MADEEvolveSansEVO',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: _LC.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
        settings: const RouteSettings(name: '/login'),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  FOOTER — hapus semua boxShadow, hapus BackdropFilter blur
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFooter() {
    return _fadeUp(
      show: _showFooter,
      duration: const Duration(milliseconds: 850),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0C12),  // ← solid, tanpa blur/shadow
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
                // ← boxShadow dihapus
              ),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _LC.accent.withOpacity(0.1),
                      border: Border.all(color: _LC.border),
                      // ← boxShadow dihapus
                    ),
                    child: Center(
                      child: FaIcon(FontAwesomeIcons.shieldHalved, color: _LC.accent, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SYAHID',
                          style: TextStyle(
                            fontFamily: 'MADEEvolveSansEVO',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            color: _LC.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ALLCRASH · V8.0 · SECURE',
                          style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 9,
                            color: _LC.accent3,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFooterLink(icon: FontAwesomeIcons.telegram, onTap: () => _openUrl('https://t.me/SQUADCIT')),
                      const SizedBox(width: 8),
                      _buildFooterLink(icon: FontAwesomeIcons.code, onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '© 2026 SYAHID ALLCRASH · @SQUADCIT',
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 9,
                color: _LC.textDim2,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLink({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withOpacity(0.03),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          // ← boxShadow dihapus
        ),
        child: Center(
          child: FaIcon(icon, color: _LC.textDim, size: 14),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  GRID PAINTER
// ═══════════════════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;
    const spacing = 30.0;
    const offset  = -15.0;
    for (double x = offset; x < size.width;  x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = offset; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
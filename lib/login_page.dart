// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';

const String baseUrl = "http://104.207.64.203:2001";

// ── CHARACTER IMAGES ────────────────────────────────────────────────
const CHAR_IMAGES = [
  'https://files.catbox.moe/tjnnik.png',
  'https://files.catbox.moe/u9589z.png',
  'https://files.catbox.moe/0xrvh7.png',
  'https://files.catbox.moe/7q928f.png',
  'https://files.catbox.moe/ga4ie1.png',
  'https://files.catbox.moe/1wdshl.png',
  'https://files.catbox.moe/dxwjkx.png',
  'https://files.catbox.moe/ugnm4v.png',
];

// ── COLOR SCHEME ────────────────────────────────────────────────────
class _LC {
  static const accent = Color(0xFFe8184a);
  static const accent2 = Color(0xFFff4466);
  static const accent3 = Color(0xFFff8099);
  static const bg = Color(0xFF08080f);
  static const text = Color(0xFFe8eaf0);
  static const textDim = Color(0x66E8EAF0);
}

// ── LOGIN PAGE ──────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  String? androidId;
  bool _isObscure = true;

  // ── Flow State ──────────────────────────────────────────────────
  int _charIdx = -1;
  String _typedText = '';
  bool _showCursor = true;
  bool _isLoadingDots = false;
  bool _showUsernameInput = false;
  bool _showPasswordInput = false;
  bool _showConfirmBtns = false;
  bool _showSingleBtn = false;
  String _singleBtnText = 'CONTACT ADMIN';
  bool _dialogueVisible = false;
  bool _charVisible = false;
  bool _brandVisible = false;
  bool _nextBtnVisible = false;
  bool _flowRunning = false;
  bool _skipRequested = false;
  bool _fullSkip = false; // Skip ALL welcome → straight to login
  bool _showSplash = false;
  double _splashImageOpacity = 0.0;
  String _currentCharSrc = '';
  bool _charFading = false;
  bool _showSkipBtn = true; // Show skip button during welcome phase

  // Completers for async flow
  Completer<void>? _nextCompleter;
  Completer<String>? _inputCompleter;
  Completer<String>? _choiceCompleter;
  Completer<void>? _singleBtnCompleter;

  // Animation controllers
  late AnimationController _orbController;
  late AnimationController _cursorBlinkController;
  late AnimationController _particleController;
  late AnimationController _skipPulseController;

  static const _typingSpeed = 40;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _cursorBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _skipPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    initLogin();
  }

  @override
  void dispose() {
    _orbController.dispose();
    _cursorBlinkController.dispose();
    _particleController.dispose();
    _skipPulseController.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  // ── Skip Logic ─────────────────────────────────────────────────
  /// Tap anywhere: complete current text instantly
  void _onTapAnywhere() {
    if (_showSplash) return; // Don't skip during splash
    _skipRequested = true;
    if (_nextBtnVisible &&
        _nextCompleter != null &&
        !_nextCompleter!.isCompleted) {
      _nextCompleter!.complete();
    }
  }

  /// SKIP button: skip ALL welcome → jump to username/password
  void _skipFullToLogin() {
    if (_showSplash) return;
    _fullSkip = true;
    _skipRequested = true;
    if (_nextCompleter != null && !_nextCompleter!.isCompleted) {
      _nextCompleter!.complete();
    }
    setState(() => _showSkipBtn = false);
  }

  // ── Data Loading ────────────────────────────────────────────────
  Future<void> initLogin() async {
    androidId = await _getAndroidId();
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null) {
      try {
        final res = await http.get(
          Uri.parse(
            "$baseUrl/api/auth/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey",
          ),
        );
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(
            context,
            '/splash',
            arguments: {
              'username': savedUser,
              'password': savedPass,
              'role': data['role'],
              'key': data['key'],
              'expiredDate': data['expiredDate'],
              'listBug': data['listBug'] ?? [],
              'listPayload': data['listPayload'] ?? [],
              'listDDoS': data['listDDoS'] ?? [],
              'news': data['news'] ?? [],
            },
          );
          return;
        }
      } catch (_) {}
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) startLoginFlow();
  }

  Future<String> _getAndroidId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      return android.id;
    } catch (_) {
      return 'unknown_device';
    }
  }

  // ── Character Image ──────────────────────────────────────────────
  void _nextCharacter() {
    _charIdx++;
    final newSrc = CHAR_IMAGES[_charIdx % CHAR_IMAGES.length];
    if (!_charVisible) {
      setState(() {
        _currentCharSrc = newSrc;
        _charVisible = true;
      });
      return;
    }
    setState(() => _charFading = true);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _currentCharSrc = newSrc;
        _charFading = false;
      });
    });
  }

  // ── Typing Effect ────────────────────────────────────────────────
  Future<void> _typeText(String text) async {
    _skipRequested = false;
    _nextCharacter();
    setState(() {
      _typedText = '';
      _showCursor = true;
      _nextBtnVisible = false;
      _isLoadingDots = false;
    });
    for (int i = 0; i < text.length; i++) {
      if (_skipRequested) {
        if (mounted) setState(() => _typedText = text);
        _skipRequested = false;
        break;
      }
      final ch = text[i];
      int ms = _typingSpeed + math.Random().nextInt(20);
      if ('.!?,;:—'.contains(ch)) ms = _typingSpeed * 5;
      await Future.delayed(Duration(milliseconds: ms));
      if (!mounted) return;
      setState(() => _typedText = text.substring(0, i + 1));
    }
    if (!mounted) return;
    setState(() {
      _showCursor = false;
      _nextBtnVisible = true;
    });
    _nextCompleter = Completer<void>();
    await _nextCompleter!.future;
    if (mounted) setState(() => _nextBtnVisible = false);
  }

  Future<void> _typeTextRaw(String text) async {
    _skipRequested = false;
    _nextCharacter();
    setState(() {
      _typedText = '';
      _showCursor = true;
      _nextBtnVisible = false;
      _isLoadingDots = false;
    });
    for (int i = 0; i < text.length; i++) {
      if (_skipRequested) {
        if (mounted) setState(() => _typedText = text);
        _skipRequested = false;
        break;
      }
      await Future.delayed(
        Duration(milliseconds: _typingSpeed + math.Random().nextInt(20)),
      );
      if (!mounted) return;
      setState(() => _typedText = text.substring(0, i + 1));
    }
    if (mounted) setState(() => _showCursor = false);
  }

  // ── Wait Functions ───────────────────────────────────────────────
  Future<String> _waitForUsername() async {
    userController.clear();
    setState(() {
      _showUsernameInput = true;
      _showSkipBtn = false; // Hide skip during login
    });
    _inputCompleter = Completer<String>();
    final result = await _inputCompleter!.future;
    if (mounted) setState(() => _showUsernameInput = false);
    return result;
  }

  Future<String> _waitForPassword() async {
    passController.clear();
    _isObscure = true;
    setState(() => _showPasswordInput = true);
    _inputCompleter = Completer<String>();
    final result = await _inputCompleter!.future;
    if (mounted) setState(() => _showPasswordInput = false);
    return result;
  }

  Future<String> _waitForChoice() async {
    setState(() => _showConfirmBtns = true);
    _choiceCompleter = Completer<String>();
    final result = await _choiceCompleter!.future;
    if (mounted) setState(() => _showConfirmBtns = false);
    return result;
  }

  Future<void> _waitForSingleBtn() async {
    setState(() => _showSingleBtn = true);
    _singleBtnCompleter = Completer<void>();
    await _singleBtnCompleter!.future;
    if (mounted) setState(() => _showSingleBtn = false);
  }

  // ── Login API ────────────────────────────────────────────────────
  Future<void> _attemptLogin(String username, String password) async {
    try {
      final validate = await http.post(
        Uri.parse("$baseUrl/api/auth/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      );
      final data = jsonDecode(validate.body);

      if (data['expired'] == true) {
        await _typeText('Maaf yaaa, akses kamu sudah expired nihh..');
        await _typeText(
          'Silahkan hubungi admin ajaa buat minta perpanjang yakk',
        );
        _singleBtnText = 'CONTACT ADMIN';
        await _waitForSingleBtn();
        _openTelegramBot();
        _flowRunning = false;
        return;
      }

      if (data['valid'] != true) {
        await _typeText(
          'Yahhh, username atau password nyaa salah tauu, coba inget² lagii..',
        );
        _retryLogin(username);
        return;
      }

      // Valid!
      final prefs = await SharedPreferences.getInstance();
      prefs.setString("username", username);
      prefs.setString("password", password);
      prefs.setString("key", data['key']);

      await _typeText('Mantapp!!, akses udaaa bener nihhh');
      await _typeText('Mau langsung lanjut?');
      final choice = await _waitForChoice();
      if (choice == 'continue') {
        await _typeTextRaw('Yoshh! Melanjutkan...');
        _navigateToDashboard(data, username, password);
      } else {
        await _typeText('Okeii, mengulang dari awal ya...');
        _retryLogin('');
      }
    } catch (_) {
      await _typeText('Hmm, kayanyaa gagal terhubung ke server nihh...');
      await _typeText('Coba lagi nanti yaakk');
      _singleBtnText = 'COBA LAGI';
      await _waitForSingleBtn();
      _retryLogin('');
    }
  }

  void _navigateToDashboard(Map data, String username, String password) {
    if (!mounted) return;
    setState(() {
      _showSplash = true;
      _splashImageOpacity = 0.0;
    });

    // Fade in (0.8s)
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      setState(() => _splashImageOpacity = 1.0);
    });

    // Fade out start at 2.2s → fade out (0.8s)
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() => _splashImageOpacity = 0.0);
    });

    // Navigate at 3s total
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/splash',
        arguments: {
          'username': username,
          'password': password,
          'role': data['role'],
          'key': data['key'],
          'expiredDate': data['expiredDate'],
          'listBug': data['listBug'] ?? [],
          'listPayload': data['listPayload'] ?? [],
          'listDDoS': data['listDDoS'] ?? [],
          'news': data['news'] ?? [],
        },
      );
    });
  }

  void _retryLogin(String prefill) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) startLoginFlow(retryUser: prefill);
  }

  void _openTelegramBot() async {
    final uri = Uri.parse("tg://resolve?domain=mizukiszn");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(
        Uri.parse("https://t.me/mizukiszn"),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ── Main Flow ────────────────────────────────────────────────────
  Future<void> startLoginFlow({String retryUser = ''}) async {
    if (_flowRunning) return;
    _flowRunning = true;
    _fullSkip = false;
    setState(() {
      _showUsernameInput = false;
      _showPasswordInput = false;
      _showConfirmBtns = false;
      _showSingleBtn = false;
      _nextBtnVisible = false;
      _brandVisible = true;
      _showSkipBtn = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) {
      _flowRunning = false;
      return;
    }
    setState(() => _dialogueVisible = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) {
      _flowRunning = false;
      return;
    }

    // ── Welcome Phase (skippable via SKIP button) ──────────────────
    if (!_fullSkip) {
      await _typeText('Haii, selamat datang di SYAHID ALLCRASH...');
      if (!mounted || _fullSkip) {
        /* fall through to login */
      } else {
        await _typeText('Sebelum mauu lanjutt, kamu harus login dulu yakk...');
      }
    }
    if (!mounted) {
      _flowRunning = false;
      return;
    }

    // Hide skip button once we reach login phase
    setState(() => _showSkipBtn = false);

    // ── Login Phase ────────────────────────────────────────────────
    String retryU = retryUser;
    while (mounted) {
      if (!_fullSkip) {
        await _typeText('Coba masukin username kamu duluu');
      } else {
        _fullSkip = false;
        // Show character + clear text for login phase
        _nextCharacter();
        setState(() {
          _typedText = '';
          _showCursor = false;
          _nextBtnVisible = false;
        });
      }
      if (!mounted) break;
      if (retryU.isNotEmpty) userController.text = retryU;
      final username = await _waitForUsername();
      if (!mounted) break;
      retryU = username;

      await _typeText('Okeii.. Sekarang masukin password nya ya..');
      if (!mounted) break;
      final password = await _waitForPassword();
      if (!mounted) break;

      if (username.isEmpty || password.isEmpty) {
        await _typeText(
          'Ehh!!, username sama password tuh harus diisi yaaa...',
        );
        continue;
      }

      await _typeTextRaw('Waitt iaaa...');
      if (!mounted) break;
      setState(() => _isLoadingDots = true);
      await _attemptLogin(username, password);
      setState(() => _isLoadingDots = false);
      break;
    }
    _flowRunning = false;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;

    return GestureDetector(
      onTap: _onTapAnywhere,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: _LC.bg,
        body: Stack(
          children: [
            // Background
            _buildBackground(sw, sh),
            // Particles
            _buildParticles(sw, sh),
            // Brand text
            if (_brandVisible)
              Positioned(
                top: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'SYAHID',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 14,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
            // Character
            _buildCharacter(sw, sh),
            // Dialogue box
            _buildDialogueBox(),
            // Version tag
            Positioned(
              bottom: 6,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'SYAHID BUG v8.0 · SECURE',
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 7,
                    color: Colors.white.withOpacity(0.06),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            // Skip button (top right — only during welcome phase)
            if (_showSkipBtn && _dialogueVisible && !_showSplash)
              Positioned(
                top: 14,
                right: 14,
                child: GestureDetector(
                  onTap: _skipFullToLogin,
                  child: AnimatedBuilder(
                    animation: _skipPulseController,
                    builder: (ctx, _) {
                      final v = _skipPulseController.value;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.black.withOpacity(0.5),
                          border: Border.all(
                            color: _LC.accent.withOpacity(0.3 + v * 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _LC.accent.withOpacity(0.08 + v * 0.06),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.forward,
                              color: _LC.accent3,
                              size: 10,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SKIP',
                              style: TextStyle(
                                fontFamily: 'MADEEvolveSansEVO',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.5,
                                color: _LC.accent3.withOpacity(0.7 + v * 0.3),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            // Splash overlay
            if (_showSplash) _buildSplashOverlay(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BACKGROUND
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
        _buildOrb(
          w * 0.1,
          h * 0.05,
          220,
          _LC.accent.withOpacity(0.06),
          0.8,
          22,
        ),
        _buildOrb(
          w * 0.8,
          h * 0.3,
          180,
          _LC.accent2.withOpacity(0.04),
          0.6,
          18,
        ),
        _buildOrb(
          w * 0.4,
          h * 0.65,
          250,
          _LC.accent3.withOpacity(0.03),
          0.5,
          25,
        ),
      ],
    );
  }

  Widget _buildOrb(
    double x,
    double y,
    double size,
    Color color,
    double speed,
    double offset,
  ) {
    return Positioned(
      left: x,
      top: y,
      child: AnimatedBuilder(
        animation: _orbController,
        builder: (ctx, _) {
          final t = _orbController.value * 2 * math.pi;
          final dx = 25 * math.sin(t * speed + offset);
          final dy = -20 * math.cos(t * speed + offset);
          return Transform.translate(
            offset: Offset(dx, dy),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PARTICLES
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildParticles(double w, double h) {
    final colors = [
      _LC.accent.withOpacity(0.3),
      _LC.accent2.withOpacity(0.22),
      _LC.accent3.withOpacity(0.18),
      _LC.accent.withOpacity(0.12),
    ];
    return Stack(
      children: List.generate(22, (i) {
        final sz = 1.2 + (i % 4) * 0.5;
        final px = (i * 97 % 100) / 100 * w;
        final py = (20 + i * 53 % 60) / 100 * h;
        final dur = 8.0 + (i % 14);
        final delay = (i % 10).toDouble();
        return Positioned(
          left: px,
          top: py,
          child: AnimatedBuilder(
            animation: _particleController,
            builder: (ctx, _) {
              final raw = _particleController.value * 30 + delay;
              final t = (raw % dur) / dur;
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
                    width: sz,
                    height: sz,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors[i % 4].withOpacity(opacity.clamp(0.0, 1.0)),
                      boxShadow: [
                        BoxShadow(
                          color: colors[i % 4].withOpacity(opacity * 0.5),
                          blurRadius: 5,
                        ),
                      ],
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
  //  CHARACTER IMAGE
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCharacter(double sw, double sh) {
    if (_currentCharSrc.isEmpty) return const SizedBox.shrink();
    return Positioned(
      bottom: 140,
      left: 0,
      width: sw * 0.48,
      height: sh * 0.6,
      child: AnimatedOpacity(
        opacity: _charVisible ? (_charFading ? 0.0 : 1.0) : 0.0,
        duration: const Duration(milliseconds: 400),
        child: Image.network(
          _currentCharSrc,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DIALOGUE BOX (Glassmorphism — improved)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildDialogueBox() {
    return Positioned(
      bottom: 18,
      left: 12,
      right: 12,
      child: AnimatedOpacity(
        opacity: _dialogueVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 600),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: _dialogueVisible ? 25.0 : 0.0, end: 0.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          builder: (ctx, offset, child) =>
              Transform.translate(offset: Offset(0, offset), child: child),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                constraints: const BoxConstraints(minHeight: 90),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                decoration: BoxDecoration(
                  color: const Color(0xB80E0E18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border(
                    bottom: BorderSide(
                      color: _LC.accent.withOpacity(0.12),
                      width: 1,
                    ),
                    top: BorderSide(color: Colors.white.withOpacity(0.06)),
                    left: BorderSide(color: Colors.white.withOpacity(0.03)),
                    right: BorderSide(color: Colors.white.withOpacity(0.03)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 40,
                      offset: const Offset(0, -4),
                    ),
                    BoxShadow(
                      color: _LC.accent.withOpacity(0.03),
                      blurRadius: 60,
                      spreadRadius: -20,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Typed text + cursor
                    _buildTypedLine(),
                    // Loading dots
                    if (_isLoadingDots) ...[
                      const SizedBox(height: 8),
                      _buildLoadingDots(),
                    ],
                    // Username input
                    if (_showUsernameInput) ...[
                      const SizedBox(height: 14),
                      _buildUsernameInput(),
                    ],
                    // Password input
                    if (_showPasswordInput) ...[
                      const SizedBox(height: 14),
                      _buildPasswordInput(),
                    ],
                    // Confirm buttons
                    if (_showConfirmBtns) ...[
                      const SizedBox(height: 14),
                      _buildConfirmBtns(),
                    ],
                    // Single button
                    if (_showSingleBtn) ...[
                      const SizedBox(height: 12),
                      _buildSingleActionBtn(),
                    ],
                    // Spacer + Next button
                    const SizedBox(height: 38),
                    if (_nextBtnVisible)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: _buildNextBtn(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypedLine() {
    return SizedBox(
      width: double.infinity,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: _typedText,
              style: const TextStyle(
                fontSize: 15,
                height: 1.75,
                color: _LC.text,
                letterSpacing: 0.15,
              ),
            ),
            if (_showCursor)
              WidgetSpan(
                child: AnimatedBuilder(
                  animation: _cursorBlinkController,
                  builder: (ctx, _) {
                    final on = _cursorBlinkController.value < 0.5;
                    return Opacity(
                      opacity: on ? 1.0 : 0.0,
                      child: Text(
                        '|',
                        style: TextStyle(
                          color: _LC.accent,
                          fontWeight: FontWeight.w200,
                          fontSize: 15,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _cursorBlinkController,
          builder: (ctx, _) {
            final phase = (_cursorBlinkController.value * 3 + i * 0.33) % 1.0;
            final opacity = phase < 0.4
                ? 0.12 + (phase / 0.4) * 0.88
                : 1.0 - ((phase - 0.4) / 0.6) * 0.88;
            final scale = phase < 0.4
                ? 0.7 + (phase / 0.4) * 0.6
                : 1.3 - ((phase - 0.4) / 0.6) * 0.6;
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _LC.accent.withOpacity(opacity.clamp(0.12, 1.0)),
              ),
              child: Transform.scale(
                scale: scale.clamp(0.7, 1.3),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _LC.accent,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ── Input Fields (Improved styling) ───────────────────────────────
  Widget _buildUsernameInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _LC.accent.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 3, 3, 3),
      child: Row(
        children: [
          Icon(FontAwesomeIcons.user, color: _LC.accent, size: 13),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: userController,
              autofocus: true,
              style: const TextStyle(
                color: _LC.text,
                fontFamily: 'ShareTechMono',
                fontSize: 13,
                letterSpacing: 1,
              ),
              cursorColor: _LC.accent,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'USERNAME',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.16),
                  fontSize: 11,
                  fontFamily: 'ShareTechMono',
                ),
              ),
              onSubmitted: (_) {
                if (_inputCompleter != null && !_inputCompleter!.isCompleted) {
                  _inputCompleter!.complete(userController.text.trim());
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          _buildInputSubmitButton(() {
            if (_inputCompleter != null && !_inputCompleter!.isCompleted) {
              _inputCompleter!.complete(userController.text.trim());
            }
          }),
        ],
      ),
    );
  }

  Widget _buildPasswordInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _LC.accent.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 3, 3, 3),
      child: Row(
        children: [
          Icon(FontAwesomeIcons.lock, color: _LC.accent, size: 13),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: passController,
              obscureText: _isObscure,
              autofocus: true,
              style: const TextStyle(
                color: _LC.text,
                fontFamily: 'ShareTechMono',
                fontSize: 13,
                letterSpacing: 1,
              ),
              cursorColor: _LC.accent,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'PASSWORD',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.16),
                  fontSize: 11,
                  fontFamily: 'ShareTechMono',
                ),
              ),
              onSubmitted: (_) {
                if (_inputCompleter != null && !_inputCompleter!.isCompleted) {
                  _inputCompleter!.complete(passController.text.trim());
                }
              },
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _isObscure = !_isObscure),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                _isObscure ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
                color: _LC.accent.withOpacity(0.4),
                size: 13,
              ),
            ),
          ),
          const SizedBox(width: 4),
          _buildInputSubmitButton(() {
            if (_inputCompleter != null && !_inputCompleter!.isCompleted) {
              _inputCompleter!.complete(passController.text.trim());
            }
          }),
        ],
      ),
    );
  }

  Widget _buildInputSubmitButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          gradient: const LinearGradient(colors: [_LC.accent, _LC.accent2]),
          boxShadow: [
            BoxShadow(color: _LC.accent.withOpacity(0.25), blurRadius: 10),
          ],
        ),
        child: const Icon(Icons.arrow_forward, color: Colors.white, size: 13),
      ),
    );
  }

  // ── Confirm Buttons (BATAL / LANJUTKAN) ──────────────────────────
  Widget _buildConfirmBtns() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_choiceCompleter != null && !_choiceCompleter!.isCompleted) {
                _choiceCompleter!.complete('cancel');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.035),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close, color: _LC.textDim, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'BATAL',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: _LC.textDim,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_choiceCompleter != null && !_choiceCompleter!.isCompleted) {
                _choiceCompleter!.complete('continue');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_LC.accent, _LC.accent2],
                ),
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: _LC.accent.withOpacity(0.25),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'LANJUTKAN',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Single Action Button ─────────────────────────────────────────
  Widget _buildSingleActionBtn() {
    return GestureDetector(
      onTap: () {
        if (_singleBtnCompleter != null && !_singleBtnCompleter!.isCompleted) {
          _singleBtnCompleter!.complete();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _LC.accent.withOpacity(0.2)),
          color: _LC.accent.withOpacity(0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.headset, color: _LC.accent3, size: 13),
            const SizedBox(width: 7),
            Text(
              _singleBtnText,
              style: TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: _LC.accent3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Next Button (LANJUT) ─────────────────────────────────────────
  Widget _buildNextBtn() {
    return GestureDetector(
      onTap: () {
        if (_nextCompleter != null && !_nextCompleter!.isCompleted) {
          _nextCompleter!.complete();
        }
      },
      child: AnimatedBuilder(
        animation: _cursorBlinkController,
        builder: (ctx, child) {
          final v = _cursorBlinkController.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  _LC.accent.withOpacity(0.06),
                  _LC.accent2.withOpacity(0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: _LC.accent.withOpacity(0.3 + v * 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LANJUT',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.5,
                    color: _LC.accent3,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: _LC.accent3, size: 11),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SPLASH OVERLAY — Foto fade in → tunda → fade out (3 detik total)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSplashOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: AnimatedOpacity(
          opacity: _splashImageOpacity,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          child: Image.asset(
            'assets/images/bokep.png',
            width: MediaQuery.of(context).size.width * 0.85,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

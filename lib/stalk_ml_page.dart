import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

// ── COLOR SCHEME (ML Blue Theme — beda dari GitHub purple) ────────────────
class _MLC {
  static const bg       = Color(0xFF060810);
  static const bg2      = Color(0xFF0B0D17);
  static const surface  = Color(0xFF0F1220);
  static const card     = Color(0xFF141827);
  static const accent   = Color(0xFF0088FF);
  static const accent2  = Color(0xFF339DFF);
  static const accent3  = Color(0xFF66B3FF);
  static const gold     = Color(0xFFFFD447);
  static const danger   = Color(0xFFFF4D6D);
  static const text     = Color(0xFFE2EAF5);
  static const muted    = Color(0x88E2EAF5);
  static const muted2   = Color(0x33E2EAF5);
  static const border   = Color(0x220088FF);
  static const border2  = Color(0x14FFFFFF);
  static const greenG1  = Color(0xFF3FB950);
  static const blueG1   = Color(0xFF229ED9);
  static const purpleG1 = Color(0xFF9C27B0);
  static const orangeG1 = Color(0xFFFF8C00);
  static const cyanG1   = Color(0xFF00BCD4);
  static const tealG1   = Color(0xFF009688);
  static const redG1    = Color(0xFFFF4D6D);
  static const mlGold   = Color(0xFFFFD447);
}

// ── ML STALK API ─────────────────────────────────────────────────────────
class _MLStalkApi {
  static const String _baseUrl =
      'https://api.deline.web.id/stalker/stalkml';

  static Future<Map<String, dynamic>?> stalk(
      String userId, String zone) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'id': userId,
        'zone': zone,
      });
      debugPrint('[MLStalkAPI] GET $uri');
      final res =
          await http.get(uri).timeout(const Duration(seconds: 15));
      debugPrint('[MLStalkAPI] ${res.statusCode} len=${res.body.length}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data is Map<String, dynamic> ? data : null;
      }
      return null;
    } catch (e) {
      debugPrint('[MLStalkAPI] Error: $e');
      return null;
    }
  }
}

// ── STALK ML PAGE ────────────────────────────────────────────────────────
class StalkMLPage extends StatefulWidget {
  const StalkMLPage({super.key});

  @override
  State<StalkMLPage> createState() => _StalkMLPageState();
}

class _StalkMLPageState extends State<StalkMLPage>
    with TickerProviderStateMixin {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  final FocusNode _userIdFocus = FocusNode();
  final FocusNode _zoneFocus = FocusNode();

  Map<String, dynamic>? _stalkResult;
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  // simpan input buat ditampilkan di result
  String _lastUserId = '';
  String _lastZone = '';

  late AnimationController _glowController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _userIdFocus.addListener(() => setState(() {}));
    _zoneFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _userIdController.dispose();
    _zoneController.dispose();
    _userIdFocus.dispose();
    _zoneFocus.dispose();
    super.dispose();
  }

  // ── STALK ─────────────────────────────────────────────────────────────
  Future<void> _doStalk() async {
    final userId = _userIdController.text.trim();
    final zone = _zoneController.text.trim();

    if (userId.isEmpty) {
      _showSnackBar('User ID wajib diisi', isError: true);
      return;
    }
    if (zone.isEmpty) {
      _showSnackBar('Zone / Server ID wajib diisi', isError: true);
      return;
    }

    _lastUserId = userId;
    _lastZone = zone;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = null;
      _stalkResult = null;
    });

    final data = await _MLStalkApi.stalk(userId, zone);
    if (!mounted) return;

    if (data == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Gagal terhubung ke API. Cek koneksi internet kamu.';
      });
      return;
    }

    if (data['status'] == false) {
      final msg = data['message'] ?? 'API error';
      setState(() {
        _isLoading = false;
        _errorMessage = msg.toString();
      });
      return;
    }

    final resultData = data['result'];
    if (resultData == null || resultData['success'] != true) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User ID atau Zone ID tidak ditemukan.';
      });
      return;
    }

    setState(() {
      _stalkResult =
          resultData is Map<String, dynamic> ? resultData : null;
      _isLoading = false;
      _fadeController.forward(from: 0);
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isError ? _MLC.danger : _MLC.greenG1,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style:
                      const TextStyle(color: _MLC.text, fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: _MLC.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError
                ? _MLC.danger.withOpacity(0.4)
                : _MLC.accent.withOpacity(0.4),
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _MLC.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _MLC.bg.withOpacity(0.92),
            border: Border(
              bottom: BorderSide(
                color: _MLC.accent.withOpacity(0.18),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _MLC.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _MLC.border2),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _MLC.muted, size: 15),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [_MLC.accent2, _MLC.accent3],
                      ).createShader(b),
                      child: const Text(
                        'STALK MOBILE LEGENDS',
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const Text(
                      'ML PROFILE LOOKUP',
                      style: TextStyle(
                        fontSize: 9,
                        color: _MLC.muted,
                        letterSpacing: 1.5,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _glowController,
                builder: (_, __) => Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _MLC.accent.withOpacity(
                        0.08 + _glowController.value * 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _MLC.accent.withOpacity(
                          0.2 + _glowController.value * 0.25),
                    ),
                  ),
                  child: Icon(
                    Icons.sports_esports_rounded,
                    color: _MLC.accent.withOpacity(
                        0.55 + _glowController.value * 0.45),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  BODY
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildBody() {
    if (_isLoading) return _buildShimmerLoading();
    if (_errorMessage != null && _stalkResult == null) return _buildErrorView();
    if (_stalkResult != null) return _buildResultView();
    return _buildInputView();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  INPUT VIEW
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildInputView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        children: [
          _buildHeroBanner(),
          const SizedBox(height: 16),
          _buildInputCard(),
          const SizedBox(height: 14),
          _buildStalkButton(),
          if (!_hasSearched) ...[
            const SizedBox(height: 20),
            _buildInfoCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: _MLC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _MLC.border, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _MLC.card,
            _MLC.accent.withOpacity(0.04),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _glowController,
                builder: (_, __) {
                  final v = _glowController.value;
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _MLC.accent.withOpacity(0.1 + v * 0.07),
                      border: Border.all(
                          color:
                              _MLC.accent.withOpacity(0.28 + v * 0.15),
                          width: 1.5),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.gps_fixed_rounded,
                        color: _MLC.accent
                            .withOpacity(0.65 + v * 0.35),
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ML STALKER',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: _MLC.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 48,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_MLC.accent, Colors.transparent]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: _MLC.border2),
          const SizedBox(height: 14),
          const Text(
            'Masukkan User ID dan Zone ID untuk melihat profil Mobile Legends.',
            style:
                TextStyle(fontSize: 12, color: _MLC.muted, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    final userIdOk = _userIdController.text.trim().isNotEmpty;
    final zoneOk = _zoneController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _MLC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _MLC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(Icons.keyboard_rounded, 'INPUT DATA'),
          const SizedBox(height: 18),

          // ── User ID ──
          const Text(
            'USER ID',
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 10,
              color: _MLC.muted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _MLC.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _userIdFocus.hasFocus
                    ? _MLC.accent.withOpacity(0.7)
                    : _MLC.border2,
                width: _userIdFocus.hasFocus ? 1.5 : 1.0,
              ),
              boxShadow: _userIdFocus.hasFocus
                  ? [
                      BoxShadow(
                        color: _MLC.accent.withOpacity(0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: TextField(
              controller: _userIdController,
              focusNode: _userIdFocus,
              style: const TextStyle(
                color: _MLC.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'ShareTechMono',
                letterSpacing: 2,
              ),
              keyboardType: TextInputType.number,
              cursorColor: _MLC.accent,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '1343331387',
                hintStyle: const TextStyle(
                    color: _MLC.muted2,
                    fontSize: 14,
                    letterSpacing: 2),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.person_rounded,
                      color: _MLC.accent, size: 18),
                ),
                suffixIcon: userIdOk
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.check_circle_rounded,
                            color: _MLC.greenG1, size: 18),
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Zone ID ──
          const Text(
            'ZONE / SERVER ID',
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 10,
              color: _MLC.muted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _MLC.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _zoneFocus.hasFocus
                    ? _MLC.cyanG1.withOpacity(0.7)
                    : _MLC.border2,
                width: _zoneFocus.hasFocus ? 1.5 : 1.0,
              ),
              boxShadow: _zoneFocus.hasFocus
                  ? [
                      BoxShadow(
                        color: _MLC.cyanG1.withOpacity(0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: TextField(
              controller: _zoneController,
              focusNode: _zoneFocus,
              style: const TextStyle(
                color: _MLC.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'ShareTechMono',
                letterSpacing: 2,
              ),
              keyboardType: TextInputType.number,
              cursorColor: _MLC.cyanG1,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '15397',
                hintStyle: const TextStyle(
                    color: _MLC.muted2,
                    fontSize: 14,
                    letterSpacing: 2),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.dns_rounded,
                      color: _MLC.cyanG1, size: 18),
                ),
                suffixIcon: zoneOk
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.check_circle_rounded,
                            color: _MLC.greenG1, size: 18),
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Tip ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _MLC.accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _MLC.accent.withOpacity(0.13)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: _MLC.accent.withOpacity(0.75), size: 14),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'User ID dan Zone bisa dilihat di profil game Mobile Legends.',
                    style: TextStyle(
                        fontSize: 11, color: _MLC.muted, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStalkButton() {
    final userIdOk = _userIdController.text.trim().isNotEmpty;
    final zoneOk = _zoneController.text.trim().isNotEmpty;
    final canStalk = userIdOk && zoneOk;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: canStalk ? _doStalk : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: _MLC.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: canStalk
                ? const LinearGradient(
                    colors: [Color(0xFF0066CC), Color(0xFF339DFF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: canStalk ? null : _MLC.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canStalk
                  ? _MLC.accent.withOpacity(0.3)
                  : _MLC.border2,
            ),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.gps_fixed_rounded,
                  size: 17,
                  color: canStalk ? Colors.white : _MLC.muted2,
                ),
                const SizedBox(width: 10),
                Text(
                  'STALK SEKARANG',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: canStalk ? Colors.white : _MLC.muted2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _MLC.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _MLC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(Icons.help_outline_rounded, 'CARA MENGGUNAKAN'),
          const SizedBox(height: 14),
          _buildStepRow('1', 'Buka Mobile Legends di HP kamu'),
          _buildStepRow('2', 'Tap icon profil di pojok kiri atas'),
          _buildStepRow('3', 'User ID ada di bawah nama, tap "Copy"'),
          _buildStepRow('4', 'Zone ID ada di sebelah User ID'),
          _buildStepRow('5', 'Paste kedua ID di form di atas & tap Stalk'),
        ],
      ),
    );
  }

  Widget _buildStepRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _MLC.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _MLC.accent.withOpacity(0.22)),
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _MLC.accent,
                    fontFamily: 'ShareTechMono',
                  )),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, color: _MLC.muted, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RESULT VIEW
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildResultView() {
    final result = _stalkResult!;
    final username = result['username'] as String? ?? '-';
    final region = result['region'] as String? ?? '-';
    final countryCode = result['country_code'] as String? ?? '-';

    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Card ──
            _buildProfileCard(username, region, countryCode),
            const SizedBox(height: 14),

            // ── Stats Row ──
            _buildStatsRow(username, region, countryCode),
            const SizedBox(height: 14),

            // ── Details Card ──
            _buildDetailsCard(username, region, countryCode),
            const SizedBox(height: 24),

            // ── Back / Re-search ──
            _buildBackButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Profile Card ──
  Widget _buildProfileCard(
      String username, String region, String countryCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_MLC.card, _MLC.accent.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _MLC.border, width: 1),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _MLC.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                  border:
                      Border.all(color: _MLC.accent.withOpacity(0.25)),
                ),
                child: const Center(
                  child: Icon(Icons.sports_esports_rounded,
                      color: _MLC.accent, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ML PLAYER PROFILE',
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _MLC.text,
                          letterSpacing: 1.5,
                        )),
                    Text('Mobile Legends: Bang Bang',
                        style: const TextStyle(
                            fontSize: 10,
                            color: _MLC.muted,
                            fontFamily: 'ShareTechMono')),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _MLC.greenG1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: _MLC.greenG1.withOpacity(0.22)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded,
                        color: _MLC.greenG1, size: 11),
                    SizedBox(width: 4),
                    Text('FOUND',
                        style: TextStyle(
                          color: _MLC.greenG1,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'MADEEvolveSansEVO',
                          letterSpacing: 1,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(height: 1, color: _MLC.border2),
          const SizedBox(height: 22),

          // Avatar with pulse
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              final v = _pulseController.value;
              return Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _MLC.accent.withOpacity(0.08 + v * 0.05),
                  border: Border.all(
                      color:
                          _MLC.accent.withOpacity(0.22 + v * 0.18),
                      width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: _MLC.accent.withOpacity(0.08 + v * 0.1),
                      blurRadius: 22 + v * 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.sports_esports_rounded,
                    color:
                        _MLC.accent.withOpacity(0.55 + v * 0.45),
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // Username (big)
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [_MLC.accent2, _MLC.accent3],
            ).createShader(b),
            child: Text(
              username,
              style: const TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          const Text('In-Game Username',
              style: TextStyle(
                  fontSize: 12,
                  color: _MLC.muted,
                  fontFamily: 'ShareTechMono',
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  // ── Stats Row ──
  Widget _buildStatsRow(
      String username, String region, String countryCode) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
              Icons.person_rounded, 'USERNAME', username, _MLC.accent),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatBox(
              Icons.public_rounded, 'REGION', region, _MLC.orangeG1),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatBox(Icons.flag_rounded, 'COUNTRY',
              countryCode.toUpperCase(), _MLC.cyanG1),
        ),
      ],
    );
  }

  Widget _buildStatBox(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: _MLC.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_MLC.card, color.withOpacity(0.04)],
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 9),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'ShareTechMono',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                fontSize: 7,
                color: _MLC.muted,
                fontFamily: 'ShareTechMono',
                letterSpacing: 1,
              )),
        ],
      ),
    );
  }

  // ── Details Card ──
  Widget _buildDetailsCard(
      String username, String region, String countryCode) {
    final details = <Map<String, dynamic>>[
      {
        'icon': Icons.fingerprint_rounded,
        'label': 'USER ID',
        'value': _lastUserId,
        'color': _MLC.accent
      },
      {
        'icon': Icons.dns_rounded,
        'label': 'ZONE ID',
        'value': _lastZone,
        'color': _MLC.cyanG1
      },
      {
        'icon': Icons.person_rounded,
        'label': 'USERNAME',
        'value': username,
        'color': _MLC.blueG1
      },
      {
        'icon': Icons.public_rounded,
        'label': 'REGION',
        'value': region,
        'color': _MLC.orangeG1
      },
      {
        'icon': Icons.flag_rounded,
        'label': 'COUNTRY CODE',
        'value': countryCode.toUpperCase(),
        'color': _MLC.greenG1
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _MLC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _MLC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(Icons.info_outline_rounded, 'DETAILS'),
          const SizedBox(height: 16),
          Container(height: 1, color: _MLC.border2),
          const SizedBox(height: 16),
          ...details.map((item) {
            final icon = item['icon'] as IconData;
            final label = item['label'] as String;
            final value = item['value'] as String;
            final color = item['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Center(
                        child: Icon(icon, color: color, size: 15)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                              fontSize: 9,
                              color: _MLC.muted,
                              fontFamily: 'ShareTechMono',
                              letterSpacing: 1.2,
                            )),
                        const SizedBox(height: 3),
                        Text(value,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _MLC.text,
                              fontFamily: 'ShareTechMono',
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Back Button ──
  Widget _buildBackButton() {
    return Center(
      child: GestureDetector(
        onTap: () => setState(() {
          _stalkResult = null;
          _hasSearched = false;
          _errorMessage = null;
        }),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
          decoration: BoxDecoration(
            color: _MLC.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _MLC.border2),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded,
                  color: _MLC.muted, size: 15),
              SizedBox(width: 8),
              Text('STALK LAGI',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _MLC.text,
                    letterSpacing: 1.5,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  ERROR VIEW
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildErrorView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _MLC.danger.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _MLC.danger.withOpacity(0.25), width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.warning_amber_rounded,
                    color: _MLC.danger, size: 34),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Oops!',
                style: TextStyle(
                  color: _MLC.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MADEEvolveSansEVO',
                  letterSpacing: 1,
                )),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _MLC.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _MLC.border),
              ),
              child: Text(
                _errorMessage ?? 'Terjadi kesalahan',
                style: const TextStyle(
                    color: _MLC.muted, fontSize: 13, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => setState(() {
                _errorMessage = null;
                _hasSearched = false;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF0066CC), Color(0xFF339DFF)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('COBA LAGI',
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: _MLC.card,
      highlightColor: _MLC.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 390,
              decoration: BoxDecoration(
                  color: _MLC.card,
                  borderRadius: BorderRadius.circular(20)),
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(3, (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  height: 94,
                  decoration: BoxDecoration(
                    color: _MLC.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                  color: _MLC.card,
                  borderRadius: BorderRadius.circular(20)),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildSectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_MLC.accent, _MLC.accent2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: _MLC.accent, size: 14),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
              fontFamily: 'MADEEvolveSansEVO',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _MLC.text,
              letterSpacing: 1.2,
            )),
      ],
    );
  }
}
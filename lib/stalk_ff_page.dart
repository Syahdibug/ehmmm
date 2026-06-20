import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';

// ── COLOR SCHEME ─────────────────────────────────────────────────────────────
class _FFC {
  static const bg       = Color(0xFF080910);
  static const bg2      = Color(0xFF0D0E18);
  static const surface  = Color(0xFF111320);
  static const card     = Color(0xFF161929);
  static const accent   = Color(0xFFFF9100);
  static const accent2  = Color(0xFFFFAB33);
  static const accent3  = Color(0xFFFFC266);
  static const gold     = Color(0xFFFFD447);
  static const danger   = Color(0xFFFF4D6D);
  static const text     = Color(0xFFE2EAF5);
  static const muted    = Color(0x88E2EAF5);
  static const muted2   = Color(0x33E2EAF5);
  static const border   = Color(0x22FF9100);
  static const border2  = Color(0x14FFFFFF);
  static const greenG1  = Color(0xFF25D366);
  static const blueG1   = Color(0xFF229ED9);
  static const purpleG1 = Color(0xFF9C27B0);
  static const orangeG1 = Color(0xFFFF8C00);
  static const cyanG1   = Color(0xFF00BCD4);
  static const tealG1   = Color(0xFF009688);
  static const redG1    = Color(0xFFFF4D6D);
}

// ── FF STALK API ──────────────────────────────────────────────────────────────
class _FFStalkApi {
  static const String _baseUrl = 'https://api.deline.web.id/stalker/stalkff';

  static Future<Map<String, dynamic>?> stalk(String playerId) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {'id': playerId});
      debugPrint('[FFStalkAPI] GET $uri');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      debugPrint('[FFStalkAPI] ${res.statusCode} len=${res.body.length}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data is Map<String, dynamic> ? data : null;
      }
      return null;
    } catch (e) {
      debugPrint('[FFStalkAPI] Error: $e');
      return null;
    }
  }
}

// ── STALK FF PAGE ─────────────────────────────────────────────────────────────
class StalkFFPage extends StatefulWidget {
  const StalkFFPage({super.key});

  @override
  State<StalkFFPage> createState() => _StalkFFPageState();
}

class _StalkFFPageState extends State<StalkFFPage>
    with TickerProviderStateMixin {
  final TextEditingController _playerIdController = TextEditingController();
  final FocusNode _playerIdFocus = FocusNode();

  Map<String, dynamic>? _stalkResult;
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  late AnimationController _glowController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _playerIdFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _playerIdController.dispose();
    _playerIdFocus.dispose();
    super.dispose();
  }

  // ── STALK ────────────────────────────────────────────────────────────────
  Future<void> _doStalk() async {
    final playerId = _playerIdController.text.trim();
    if (playerId.isEmpty) {
      _showSnackBar('Player ID wajib diisi', isError: true);
      return;
    }
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = null;
      _stalkResult = null;
    });

    final data = await _FFStalkApi.stalk(playerId);
    if (!mounted) return;

    if (data == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal terhubung ke API. Cek koneksi internet kamu.';
      });
      return;
    }
    if (data['status'] == false) {
      setState(() {
        _isLoading = false;
        _errorMessage = (data['message'] ?? 'API error').toString();
      });
      return;
    }
    final result = data['result'];
    if (result == null || result is! Map<String, dynamic>) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Player ID tidak ditemukan.';
      });
      return;
    }
    setState(() {
      _stalkResult = result;
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
              color: isError ? _FFC.danger : _FFC.greenG1,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: _FFC.text, fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: _FFC.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError
                ? _FFC.danger.withOpacity(0.4)
                : _FFC.accent.withOpacity(0.4),
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FFC.bg,
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

  // ═══════════════════════════════════════════════════════════════════════════
  //  HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _FFC.bg.withOpacity(0.92),
            border: Border(
              bottom: BorderSide(color: _FFC.accent.withOpacity(0.18), width: 1),
            ),
          ),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _FFC.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _FFC.border2),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _FFC.muted, size: 15),
                ),
              ),
              const SizedBox(width: 14),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [_FFC.accent, _FFC.accent3],
                      ).createShader(b),
                      child: const Text(
                        'STALK FREE FIRE',
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
                      'FF PLAYER LOOKUP',
                      style: TextStyle(
                        fontSize: 9,
                        color: _FFC.muted,
                        letterSpacing: 1.5,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ],
                ),
              ),

              // Animated icon badge
              AnimatedBuilder(
                animation: _glowController,
                builder: (_, __) => Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _FFC.accent.withOpacity(
                        0.08 + _glowController.value * 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _FFC.accent.withOpacity(
                          0.2 + _glowController.value * 0.25),
                    ),
                  ),
                  child: Icon(
                    Icons.gps_fixed_rounded,
                    color: _FFC.accent.withOpacity(
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

  // ═══════════════════════════════════════════════════════════════════════════
  //  BODY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBody() {
    if (_isLoading) return _buildShimmerLoading();
    if (_errorMessage != null && _stalkResult == null) return _buildErrorView();
    if (_stalkResult != null) return _buildResultView();
    return _buildInputView();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  INPUT VIEW
  // ═══════════════════════════════════════════════════════════════════════════
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
        color: _FFC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _FFC.border, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_FFC.card, _FFC.accent.withOpacity(0.04)],
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
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _FFC.accent.withOpacity(0.1 + v * 0.07),
                      border: Border.all(
                          color: _FFC.accent.withOpacity(0.28 + v * 0.15),
                          width: 1.5),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.sports_esports_rounded,
                        color: _FFC.accent.withOpacity(0.65 + v * 0.35),
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
                    'FREE FIRE STALKER',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: _FFC.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 48, height: 2,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_FFC.accent, Colors.transparent]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: _FFC.border2),
          const SizedBox(height: 14),
          const Text(
            'Masukkan Player ID untuk melihat profil Free Fire secara detail.',
            style: TextStyle(fontSize: 12, color: _FFC.muted, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    final isOk = _playerIdController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _FFC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _FFC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(Icons.input_rounded, 'INPUT DATA'),
          const SizedBox(height: 18),

          const Text(
            'PLAYER ID',
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 10,
              color: _FFC.muted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _FFC.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _playerIdFocus.hasFocus
                    ? _FFC.accent.withOpacity(0.7)
                    : _FFC.border2,
                width: _playerIdFocus.hasFocus ? 1.5 : 1.0,
              ),
              boxShadow: _playerIdFocus.hasFocus
                  ? [
                      BoxShadow(
                        color: _FFC.accent.withOpacity(0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: TextField(
              controller: _playerIdController,
              focusNode: _playerIdFocus,
              style: const TextStyle(
                color: _FFC.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'ShareTechMono',
                letterSpacing: 2,
              ),
              keyboardType: TextInputType.number,
              cursorColor: _FFC.accent,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _doStalk(),
              decoration: InputDecoration(
                hintText: '1247264816',
                hintStyle: const TextStyle(
                    color: _FFC.muted2, fontSize: 14, letterSpacing: 2),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.tag_rounded,
                      color: _FFC.accent, size: 18),
                ),
                suffixIcon: isOk
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.check_circle_rounded,
                            color: _FFC.greenG1, size: 18),
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _FFC.accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _FFC.accent.withOpacity(0.13)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: _FFC.accent.withOpacity(0.75), size: 14),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Player ID bisa dilihat di profil game Free Fire.',
                    style: TextStyle(
                        fontSize: 11, color: _FFC.muted, height: 1.5),
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
    final canStalk = _playerIdController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: canStalk ? _doStalk : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: _FFC.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: canStalk
                ? const LinearGradient(
                    colors: [Color(0xFFE67E00), Color(0xFFFFAB33)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: canStalk ? null : _FFC.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canStalk
                  ? _FFC.accent.withOpacity(0.3)
                  : _FFC.border2,
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
                  color: canStalk ? Colors.white : _FFC.muted2,
                ),
                const SizedBox(width: 10),
                Text(
                  'STALK SEKARANG',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: canStalk ? Colors.white : _FFC.muted2,
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
        color: _FFC.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _FFC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(Icons.help_outline_rounded, 'CARA MENGGUNAKAN'),
          const SizedBox(height: 14),
          _buildStepRow('1', 'Buka Free Fire di HP kamu'),
          _buildStepRow('2', 'Tap icon profil di pojok kanan atas'),
          _buildStepRow('3', 'Player ID ada di bawah foto profil'),
          _buildStepRow('4', 'Tap "Copy" pada Player ID'),
          _buildStepRow('5', 'Paste Player ID di form di atas & tap Stalk'),
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
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: _FFC.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _FFC.accent.withOpacity(0.22)),
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _FFC.accent,
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
                      fontSize: 12, color: _FFC.muted, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  RESULT VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildResultView() {
    final result   = _stalkResult!;
    final nickname = result['nickname'] as String? ?? '-';
    final playerId = result['player_id'] as String? ?? '-';
    final game     = result['game'] as String? ?? '-';
    final status   = result['status'] as String? ?? '-';

    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          children: [
            _buildResultCard(nickname, status),
            const SizedBox(height: 14),
            _buildStatsRow(playerId, nickname, game),
            const SizedBox(height: 24),
            _buildBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String nickname, String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_FFC.card, _FFC.accent.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _FFC.border, width: 1),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _FFC.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _FFC.accent.withOpacity(0.25)),
                ),
                child: const Center(
                  child: Icon(Icons.local_fire_department_rounded,
                      color: _FFC.accent, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PLAYER FOUND',
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _FFC.text,
                          letterSpacing: 1.5,
                        )),
                    Text('Garena Free Fire',
                        style: TextStyle(
                            fontSize: 10,
                            color: _FFC.muted,
                            fontFamily: 'ShareTechMono')),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _FFC.greenG1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _FFC.greenG1.withOpacity(0.22)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded,
                        color: _FFC.greenG1, size: 11),
                    SizedBox(width: 4),
                    Text('VERIFIED',
                        style: TextStyle(
                          color: _FFC.greenG1,
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
          const SizedBox(height: 24),
          Container(height: 1, color: _FFC.border2),
          const SizedBox(height: 24),

          // Pulsing avatar circle
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              final v = _pulseController.value;
              return Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _FFC.accent.withOpacity(0.08 + v * 0.06),
                  border: Border.all(
                      color: _FFC.accent.withOpacity(0.22 + v * 0.18),
                      width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: _FFC.accent.withOpacity(0.1 + v * 0.1),
                      blurRadius: 22 + v * 12,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.shield_rounded,
                    color: _FFC.accent.withOpacity(0.55 + v * 0.45),
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // Nickname
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [_FFC.accent, _FFC.accent3],
            ).createShader(b),
            child: Text(
              nickname,
              style: const TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          const Text('In-Game Nickname',
              style: TextStyle(
                  fontSize: 11,
                  color: _FFC.muted,
                  fontFamily: 'ShareTechMono')),
          const SizedBox(height: 16),

          // Status badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: _FFC.greenG1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _FFC.greenG1.withOpacity(0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, color: _FFC.greenG1, size: 8),
                const SizedBox(width: 6),
                Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: _FFC.greenG1,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'MADEEvolveSansEVO',
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String playerId, String nickname, String game) {
    return Row(
      children: [
        Expanded(child: _buildInfoChip(
            Icons.tag_rounded, 'PLAYER ID', playerId, _FFC.blueG1)),
        const SizedBox(width: 10),
        Expanded(child: _buildInfoChip(
            Icons.person_rounded, 'NICKNAME', nickname, _FFC.accent)),
        const SizedBox(width: 10),
        Expanded(child: _buildInfoChip(
            Icons.sports_esports_rounded, 'GAME', game.toUpperCase(), _FFC.orangeG1)),
      ],
    );
  }

  Widget _buildInfoChip(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: _FFC.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_FFC.card, color.withOpacity(0.04)],
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(height: 7),
          Text(label,
              style: const TextStyle(
                fontSize: 8,
                color: _FFC.muted,
                fontFamily: 'ShareTechMono',
                letterSpacing: 1,
              )),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'ShareTechMono',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
            color: _FFC.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _FFC.border2),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded, color: _FFC.muted, size: 15),
              SizedBox(width: 8),
              Text('STALK LAGI',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _FFC.text,
                    letterSpacing: 1.5,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ERROR VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildErrorView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _FFC.danger.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _FFC.danger.withOpacity(0.25), width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.warning_amber_rounded,
                    color: _FFC.danger, size: 34),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Oops!',
                style: TextStyle(
                  color: _FFC.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MADEEvolveSansEVO',
                  letterSpacing: 1,
                )),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _FFC.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _FFC.border),
              ),
              child: Text(
                _errorMessage ?? 'Terjadi kesalahan',
                style: const TextStyle(
                    color: _FFC.muted, fontSize: 13, height: 1.6),
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
                      colors: [Color(0xFFE67E00), Color(0xFFFFAB33)]),
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

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHIMMER LOADING
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: _FFC.card,
      highlightColor: _FFC.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity, height: 320,
              decoration: BoxDecoration(
                  color: _FFC.card,
                  borderRadius: BorderRadius.circular(20)),
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(3, (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 10),
                  height: 86,
                  decoration: BoxDecoration(
                    color: _FFC.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 3, height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_FFC.accent, _FFC.accent2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: _FFC.accent, size: 14),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
              fontFamily: 'MADEEvolveSansEVO',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _FFC.text,
              letterSpacing: 1.2,
            )),
      ],
    );
  }
}

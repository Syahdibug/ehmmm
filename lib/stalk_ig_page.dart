import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

// ── COLOR SCHEME (Instagram Pink-Orange — beda dari GitHub purple & ML blue) ──
class _IGC {
  static const bg       = Color(0xFF060810);
  static const bg2      = Color(0xFF0B0D17);
  static const surface  = Color(0xFF0F1220);
  static const card     = Color(0xFF141827);
  static const accent   = Color(0xFFE1306C);
  static const accent2  = Color(0xFFF77737);
  static const accent3  = Color(0xFF833AB4);
  static const gold     = Color(0xFFFFD447);
  static const danger   = Color(0xFFFF4D6D);
  static const text     = Color(0xFFE2EAF5);
  static const muted    = Color(0x88E2EAF5);
  static const muted2   = Color(0x33E2EAF5);
  static const border   = Color(0x22E1306C);
  static const border2  = Color(0x14FFFFFF);
  static const greenG1  = Color(0xFF3FB950);
  static const blueG1   = Color(0xFF229ED9);
  static const purpleG1 = Color(0xFF9C27B0);
  static const orangeG1 = Color(0xFFFF8C00);
  static const cyanG1   = Color(0xFF00BCD4);
  static const tealG1   = Color(0xFF009688);
  static const redG1    = Color(0xFFFF4D6D);
  static const igPink   = Color(0xFFE1306C);
  static const igOrange = Color(0xFFF77737);
}

// ── INSTAGRAM STALK API ──────────────────────────────────────────────────
class _IGStalkApi {
  static const String _baseUrl =
      'https://api.zenzxz.my.id/stalker/instagram';

  static Future<Map<String, dynamic>?> stalk(String username) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'username': username,
      });
      debugPrint('[IGStalkAPI] GET $uri');
      final res =
          await http.get(uri).timeout(const Duration(seconds: 15));
      debugPrint('[IGStalkAPI] ${res.statusCode} len=${res.body.length}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data is Map<String, dynamic> ? data : null;
      }
      return null;
    } catch (e) {
      debugPrint('[IGStalkAPI] Error: $e');
      return null;
    }
  }
}

// ── STALK INSTAGRAM PAGE ─────────────────────────────────────────────────
class StalkIGPage extends StatefulWidget {
  const StalkIGPage({super.key});

  @override
  State<StalkIGPage> createState() => _StalkIGPageState();
}

class _StalkIGPageState extends State<StalkIGPage>
    with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();

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
    _usernameFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _usernameController.dispose();
    _usernameFocus.dispose();
    super.dispose();
  }

  // ── STALK ─────────────────────────────────────────────────────────────
  Future<void> _doStalk() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showSnackBar('Username wajib diisi', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = null;
      _stalkResult = null;
    });

    final data = await _IGStalkApi.stalk(username);
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
    if (resultData == null || resultData is! Map<String, dynamic>) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Username Instagram tidak ditemukan.';
      });
      return;
    }

    setState(() {
      _stalkResult = resultData;
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
              color: isError ? _IGC.danger : _IGC.greenG1,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style:
                      const TextStyle(color: _IGC.text, fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: _IGC.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError
                ? _IGC.danger.withOpacity(0.4)
                : _IGC.accent.withOpacity(0.4),
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
      backgroundColor: _IGC.bg,
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
            color: _IGC.bg.withOpacity(0.92),
            border: Border(
              bottom: BorderSide(
                color: _IGC.accent.withOpacity(0.18),
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
                    color: _IGC.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _IGC.border2),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _IGC.muted, size: 15),
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
                        colors: [_IGC.accent, _IGC.accent2],
                      ).createShader(b),
                      child: const Text(
                        'STALK INSTAGRAM',
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
                      'IG PROFILE LOOKUP',
                      style: TextStyle(
                        fontSize: 9,
                        color: _IGC.muted,
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
                    color: _IGC.accent.withOpacity(
                        0.08 + _glowController.value * 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _IGC.accent.withOpacity(
                          0.2 + _glowController.value * 0.25),
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: _IGC.accent.withOpacity(
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
        color: _IGC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _IGC.border, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _IGC.card,
            _IGC.accent.withOpacity(0.04),
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
                      color: _IGC.accent.withOpacity(0.1 + v * 0.07),
                      border: Border.all(
                          color:
                              _IGC.accent.withOpacity(0.28 + v * 0.15),
                          width: 1.5),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.gps_fixed_rounded,
                        color: _IGC.accent
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
                    'INSTAGRAM STALKER',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: _IGC.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 48,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_IGC.accent, Colors.transparent]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: _IGC.border2),
          const SizedBox(height: 14),
          const Text(
            'Masukkan username Instagram untuk melihat profil lengkapnya.',
            style:
                TextStyle(fontSize: 12, color: _IGC.muted, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    final isOk = _usernameController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _IGC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _IGC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(Icons.keyboard_rounded, 'INPUT DATA'),
          const SizedBox(height: 18),

          const Text(
            'INSTAGRAM USERNAME',
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 10,
              color: _IGC.muted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _IGC.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _usernameFocus.hasFocus
                    ? _IGC.accent.withOpacity(0.7)
                    : _IGC.border2,
                width: _usernameFocus.hasFocus ? 1.5 : 1.0,
              ),
              boxShadow: _usernameFocus.hasFocus
                  ? [
                      BoxShadow(
                        color: _IGC.accent.withOpacity(0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: TextField(
              controller: _usernameController,
              focusNode: _usernameFocus,
              style: const TextStyle(
                color: _IGC.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'ShareTechMono',
                letterSpacing: 1,
              ),
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.none,
              cursorColor: _IGC.accent,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _doStalk(),
              decoration: InputDecoration(
                hintText: 'fachrinc',
                hintStyle:
                    const TextStyle(color: _IGC.muted2, fontSize: 14),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.alternate_email_rounded,
                      color: _IGC.accent, size: 18),
                ),
                suffixIcon: isOk
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.check_circle_rounded,
                            color: _IGC.greenG1, size: 18),
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

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _IGC.accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _IGC.accent.withOpacity(0.13)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: _IGC.accent.withOpacity(0.75), size: 14),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Username tanpa @.\nContoh: instagram.com/fachrinc → fachrinc',
                    style: TextStyle(
                        fontSize: 11, color: _IGC.muted, height: 1.5),
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
    final canStalk = _usernameController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: canStalk ? _doStalk : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: _IGC.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: canStalk
                ? const LinearGradient(
                    colors: [Color(0xFFC13584), Color(0xFFF77737)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: canStalk ? null : _IGC.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canStalk
                  ? _IGC.accent.withOpacity(0.3)
                  : _IGC.border2,
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
                  color: canStalk ? Colors.white : _IGC.muted2,
                ),
                const SizedBox(width: 10),
                Text(
                  'STALK SEKARANG',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: canStalk ? Colors.white : _IGC.muted2,
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
        color: _IGC.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _IGC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(Icons.help_outline_rounded, 'CARA MENGGUNAKAN'),
          const SizedBox(height: 14),
          _buildStepRow('1', 'Buka profil Instagram target'),
          _buildStepRow('2', 'Copy username dari URL profil'),
          _buildStepRow('3', 'Contoh: instagram.com/fachrinc → fachrinc'),
          _buildStepRow('4', 'Paste username di form di atas & tap Stalk'),
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
              color: _IGC.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _IGC.accent.withOpacity(0.22)),
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _IGC.accent,
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
                      fontSize: 12, color: _IGC.muted, height: 1.5)),
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
    final d = _stalkResult!;
    final username = d['username'] as String? ?? '-';
    final name = d['name'] as String?;
    final bio = d['bio'] as String? ?? '';
    final followers = d['followers']?.toString() ?? '0';
    final following = d['following']?.toString() ?? '0';
    final posts = d['posts']?.toString() ?? '0';
    final profilePic = d['profile_pic'] as String? ?? '';
    final verified = d['verified'] == true;
    final engagementRate = d['engagement_rate'];

    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Card ──
            _buildProfileCard(
                username, name, bio, profilePic, verified),
            const SizedBox(height: 14),

            // ── Stats Grid ──
            _buildStatsGrid(posts, followers, following),
            const SizedBox(height: 14),

            // ── Engagement Card ──
            if (engagementRate != null)
              _buildEngagementCard(engagementRate),
            if (engagementRate != null) const SizedBox(height: 14),

            // ── Details Card ──
            _buildDetailsCard(username, name, bio, verified),
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
  Widget _buildProfileCard(String username, String? name, String bio,
      String profilePic, bool verified) {
    final displayName = (name != null &&
            name.isNotEmpty &&
            name != '-')
        ? name
        : username;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_IGC.card, _IGC.accent.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _IGC.border, width: 1),
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
                  color: _IGC.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                  border:
                      Border.all(color: _IGC.accent.withOpacity(0.25)),
                ),
                child: const Center(
                  child: Icon(Icons.camera_alt_rounded,
                      color: _IGC.accent, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INSTAGRAM PROFILE',
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _IGC.text,
                          letterSpacing: 1.5,
                        )),
                    Text('instagram.com/$username',
                        style: const TextStyle(
                            fontSize: 10,
                            color: _IGC.muted,
                            fontFamily: 'ShareTechMono')),
                  ],
                ),
              ),
              if (verified)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _IGC.blueG1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _IGC.blueG1.withOpacity(0.22)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          color: _IGC.blueG1, size: 11),
                      SizedBox(width: 4),
                      Text('VERIFIED',
                          style: TextStyle(
                            color: _IGC.blueG1,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'MADEEvolveSansEVO',
                            letterSpacing: 1,
                          )),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _IGC.greenG1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _IGC.greenG1.withOpacity(0.22)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          color: _IGC.greenG1, size: 11),
                      SizedBox(width: 4),
                      Text('FOUND',
                          style: TextStyle(
                            color: _IGC.greenG1,
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
          Container(height: 1, color: _IGC.border2),
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
                  color: _IGC.accent.withOpacity(0.08 + v * 0.05),
                  border: Border.all(
                      color:
                          _IGC.accent.withOpacity(0.22 + v * 0.18),
                      width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: _IGC.accent.withOpacity(0.08 + v * 0.1),
                      blurRadius: 22 + v * 12,
                    ),
                  ],
                  image: profilePic.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(profilePic),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: profilePic.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: _IGC.accent
                              .withOpacity(0.55 + v * 0.45),
                          size: 40,
                        ),
                      )
                    : null,
              );
            },
          ),
          const SizedBox(height: 18),

          // Display name
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [_IGC.accent, _IGC.accent2],
            ).createShader(b),
            child: Text(
              displayName,
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
          Text('@$username',
              style: const TextStyle(
                  fontSize: 12,
                  color: _IGC.muted,
                  fontFamily: 'ShareTechMono',
                  letterSpacing: 1)),
          const SizedBox(height: 12),

          // Bio
          if (bio.isNotEmpty && bio != '-')
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _IGC.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _IGC.border2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote_rounded,
                      color: _IGC.accent.withOpacity(0.45), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(bio,
                        style: const TextStyle(
                            fontSize: 12,
                            color: _IGC.muted,
                            height: 1.6)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Stats Grid ──
  Widget _buildStatsGrid(
      String posts, String followers, String following) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
              Icons.image_rounded, 'POSTS', posts, _IGC.igOrange),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatBox(Icons.group_rounded, 'FOLLOWERS',
              followers, _IGC.igPink),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatBox(Icons.person_add_rounded, 'FOLLOWING',
              following, _IGC.accent3),
        ),
      ],
    );
  }

  Widget _buildStatBox(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: _IGC.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_IGC.card, color.withOpacity(0.04)],
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 9),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'ShareTechMono',
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                fontSize: 7,
                color: _IGC.muted,
                fontFamily: 'ShareTechMono',
                letterSpacing: 1,
              )),
        ],
      ),
    );
  }

  // ── Engagement Card ──
  Widget _buildEngagementCard(dynamic rate) {
    final rateNum = (rate is num) ? rate : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _IGC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _IGC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(
              Icons.show_chart_rounded, 'ENGAGEMENT RATE'),
          const SizedBox(height: 16),
          Container(height: 1, color: _IGC.border2),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _IGC.igOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _IGC.igOrange.withOpacity(0.25)),
                ),
                child: Center(
                  child: Icon(Icons.trending_up_rounded,
                      color: _IGC.igOrange, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RATE',
                        style: TextStyle(
                          fontSize: 9,
                          color: _IGC.muted,
                          fontFamily: 'ShareTechMono',
                          letterSpacing: 1.2,
                        )),
                    const SizedBox(height: 3),
                    Text('${rateNum.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _IGC.igOrange,
                          fontFamily: 'ShareTechMono',
                        )),
                  ],
                ),
              ),
              // Mini bar indicator
              Container(
                width: 80,
                height: 6,
                decoration: BoxDecoration(
                  color: _IGC.surface,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (rateNum / 10).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_IGC.accent, _IGC.igOrange],
                      ),
                      borderRadius: BorderRadius.circular(3),
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

  // ── Details Card ──
  Widget _buildDetailsCard(
      String username, String? name, String bio, bool verified) {
    final details = <Map<String, dynamic>>[
      {
        'icon': Icons.alternate_email_rounded,
        'label': 'USERNAME',
        'value': '@$username',
        'color': _IGC.accent
      },
      {
        'icon': Icons.person_rounded,
        'label': 'FULL NAME',
        'value': (name != null && name.isNotEmpty) ? name : '-',
        'color': _IGC.igOrange
      },
      {
        'icon': Icons.verified_rounded,
        'label': 'VERIFIED',
        'value': verified ? 'YES' : 'NO',
        'color': verified ? _IGC.blueG1 : _IGC.muted
      },
      {
        'icon': Icons.image_rounded,
        'label': 'TOTAL POSTS',
        'value': _stalkResult?['posts']?.toString() ?? '0',
        'color': _IGC.accent3
      },
      {
        'icon': Icons.group_rounded,
        'label': 'FOLLOWERS',
        'value': _stalkResult?['followers']?.toString() ?? '0',
        'color': _IGC.igPink
      },
      {
        'icon': Icons.person_add_rounded,
        'label': 'FOLLOWING',
        'value': _stalkResult?['following']?.toString() ?? '0',
        'color': _IGC.tealG1
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _IGC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _IGC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(Icons.info_outline_rounded, 'DETAILS'),
          const SizedBox(height: 16),
          Container(height: 1, color: _IGC.border2),
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
                              color: _IGC.muted,
                              fontFamily: 'ShareTechMono',
                              letterSpacing: 1.2,
                            )),
                        const SizedBox(height: 3),
                        Text(value,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _IGC.text,
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
            color: _IGC.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _IGC.border2),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded,
                  color: _IGC.muted, size: 15),
              SizedBox(width: 8),
              Text('STALK LAGI',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _IGC.text,
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
                color: _IGC.danger.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _IGC.danger.withOpacity(0.25), width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.warning_amber_rounded,
                    color: _IGC.danger, size: 34),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Oops!',
                style: TextStyle(
                  color: _IGC.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MADEEvolveSansEVO',
                  letterSpacing: 1,
                )),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _IGC.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _IGC.border),
              ),
              child: Text(
                _errorMessage ?? 'Terjadi kesalahan',
                style: const TextStyle(
                    color: _IGC.muted, fontSize: 13, height: 1.6),
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
                      colors: [Color(0xFFC13584), Color(0xFFF77737)]),
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
      baseColor: _IGC.card,
      highlightColor: _IGC.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                  color: _IGC.card,
                  borderRadius: BorderRadius.circular(20)),
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(3, (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  height: 94,
                  decoration: BoxDecoration(
                    color: _IGC.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                  color: _IGC.card,
                  borderRadius: BorderRadius.circular(20)),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                  color: _IGC.card,
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
                colors: [_IGC.accent, _IGC.accent2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: _IGC.accent, size: 14),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
              fontFamily: 'MADEEvolveSansEVO',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _IGC.text,
              letterSpacing: 1.2,
            )),
      ],
    );
  }
}
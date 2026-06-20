import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

// ── COLOR SCHEME (Roblox Red — beda dari GitHub purple, ML blue, IG pink) ──
class _RBC {
  static const bg       = Color(0xFF060810);
  static const bg2      = Color(0xFF0B0D17);
  static const surface  = Color(0xFF0F1220);
  static const card     = Color(0xFF141827);
  static const accent   = Color(0xFFE2231A);
  static const accent2  = Color(0xFFFF3B30);
  static const accent3  = Color(0xFFFF6259);
  static const gold     = Color(0xFFFFD447);
  static const danger   = Color(0xFFFF4D6D);
  static const text     = Color(0xFFE2EAF5);
  static const muted    = Color(0x88E2EAF5);
  static const muted2   = Color(0x33E2EAF5);
  static const border   = Color(0x22E2231A);
  static const border2  = Color(0x14FFFFFF);
  static const greenG1  = Color(0xFF3FB950);
  static const blueG1   = Color(0xFF229ED9);
  static const purpleG1 = Color(0xFF9C27B0);
  static const orangeG1 = Color(0xFFFF8C00);
  static const cyanG1   = Color(0xFF00BCD4);
  static const tealG1   = Color(0xFF009688);
  static const redG1    = Color(0xFFFF4D6D);
  static const pinkG1   = Color(0xFFE91E63);
  static const rbRed    = Color(0xFFE2231A);
}

// ── ROBLOX STALK API ─────────────────────────────────────────────────────
class _RobloxStalkApi {
  static const String _baseUrl =
      'https://api.zenzxz.my.id/stalker/roblox';

  static Future<Map<String, dynamic>?> stalk(String username) async {
    try {
      final uri = Uri.parse('$_baseUrl').replace(queryParameters: {
        'user': username,
      });
      debugPrint('[RobloxAPI] GET $uri');
      final res =
          await http.get(uri).timeout(const Duration(seconds: 15));
      debugPrint('[RobloxAPI] ${res.statusCode} len=${res.body.length}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data is Map<String, dynamic> ? data : null;
      }
      return null;
    } catch (e) {
      debugPrint('[RobloxAPI] Error: $e');
      return null;
    }
  }

  static String presenceType(int type) {
    switch (type) {
      case 0:
        return 'Offline';
      case 1:
        return 'Online';
      case 2:
        return 'In Game';
      case 3:
        return 'In Studio';
      default:
        return 'Unknown';
    }
  }

  static String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}

// ── STALK ROBLOX PAGE ────────────────────────────────────────────────────
class StalkRobloxPage extends StatefulWidget {
  const StalkRobloxPage({super.key});

  @override
  State<StalkRobloxPage> createState() => _StalkRobloxPageState();
}

class _StalkRobloxPageState extends State<StalkRobloxPage>
    with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();

  Map<String, dynamic>? _resultData;
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
      _resultData = null;
    });

    final data = await _RobloxStalkApi.stalk(username);
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

    final result = data['result'];
    if (result == null || result is! Map<String, dynamic>) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User tidak ditemukan.';
      });
      return;
    }

    setState(() {
      _resultData = result;
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
              color: isError ? _RBC.danger : _RBC.greenG1,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style:
                      const TextStyle(color: _RBC.text, fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: _RBC.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError
                ? _RBC.danger.withOpacity(0.4)
                : _RBC.accent.withOpacity(0.4),
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
      backgroundColor: _RBC.bg,
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
            color: _RBC.bg.withOpacity(0.92),
            border: Border(
              bottom: BorderSide(
                color: _RBC.accent.withOpacity(0.18),
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
                    color: _RBC.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _RBC.border2),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _RBC.muted, size: 15),
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
                        colors: [_RBC.accent, _RBC.accent2],
                      ).createShader(b),
                      child: const Text(
                        'STALK ROBLOX',
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
                      'PLAYER PROFILE LOOKUP',
                      style: TextStyle(
                        fontSize: 9,
                        color: _RBC.muted,
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
                    color: _RBC.accent.withOpacity(
                        0.08 + _glowController.value * 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _RBC.accent.withOpacity(
                          0.2 + _glowController.value * 0.25),
                    ),
                  ),
                  child: Icon(
                    Icons.view_in_ar_rounded,
                    color: _RBC.accent.withOpacity(
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
    if (_errorMessage != null && _resultData == null) return _buildErrorView();
    if (_resultData != null) return _buildResultView();
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
        color: _RBC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _RBC.border, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _RBC.card,
            _RBC.accent.withOpacity(0.04),
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
                      color:
                          _RBC.accent.withOpacity(0.1 + v * 0.07),
                      border: Border.all(
                          color: _RBC.accent
                              .withOpacity(0.28 + v * 0.15),
                          width: 1.5),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.gps_fixed_rounded,
                        color: _RBC.accent
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
                    'ROBLOX STALKER',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: _RBC.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 48,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_RBC.accent, Colors.transparent]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: _RBC.border2),
          const SizedBox(height: 14),
          const Text(
            'Masukkan username Roblox untuk melihat profil lengkapnya.',
            style:
                TextStyle(fontSize: 12, color: _RBC.muted, height: 1.6),
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
        color: _RBC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _RBC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(Icons.keyboard_rounded, 'INPUT DATA'),
          const SizedBox(height: 18),

          const Text(
            'ROBLOX USERNAME',
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 10,
              color: _RBC.muted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _RBC.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _usernameFocus.hasFocus
                    ? _RBC.accent.withOpacity(0.7)
                    : _RBC.border2,
                width: _usernameFocus.hasFocus ? 1.5 : 1.0,
              ),
              boxShadow: _usernameFocus.hasFocus
                  ? [
                      BoxShadow(
                        color: _RBC.accent.withOpacity(0.08),
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
                color: _RBC.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'ShareTechMono',
                letterSpacing: 1,
              ),
              textInputAction: TextInputAction.search,
              cursorColor: _RBC.accent,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _doStalk(),
              decoration: InputDecoration(
                hintText: 'nggi_noy',
                hintStyle:
                    const TextStyle(color: _RBC.muted2, fontSize: 14),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.alternate_email_rounded,
                      color: _RBC.accent, size: 18),
                ),
                suffixIcon: isOk
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.check_circle_rounded,
                            color: _RBC.greenG1, size: 18),
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
              color: _RBC.accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _RBC.accent.withOpacity(0.13)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: _RBC.accent.withOpacity(0.75), size: 14),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Masukkan username Roblox, bukan display name.',
                    style: TextStyle(
                        fontSize: 11, color: _RBC.muted, height: 1.5),
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
          disabledBackgroundColor: _RBC.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: canStalk
                ? const LinearGradient(
                    colors: [Color(0xFFC41E13), Color(0xFFFF3B30)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: canStalk ? null : _RBC.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canStalk
                  ? _RBC.accent.withOpacity(0.3)
                  : _RBC.border2,
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
                  color: canStalk ? Colors.white : _RBC.muted2,
                ),
                const SizedBox(width: 10),
                Text(
                  'STALK SEKARANG',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: canStalk ? Colors.white : _RBC.muted2,
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
        color: _RBC.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _RBC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(
              Icons.help_outline_rounded, 'CARA MENGGUNAKAN'),
          const SizedBox(height: 14),
          _buildStepRow('1', 'Buka Roblox di browser atau app'),
          _buildStepRow('2', 'Cari player yang ingin di-stalk'),
          _buildStepRow('3', 'Copy username dari URL profil mereka'),
          _buildStepRow('4', 'URL: roblox.com/users/[id]/profile'),
          _buildStepRow('5', 'Paste username di form di atas & tap Stalk'),
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
              color: _RBC.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: _RBC.accent.withOpacity(0.22)),
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _RBC.accent,
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
                      fontSize: 12, color: _RBC.muted, height: 1.5)),
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
    final data = _resultData!;
    final basic = data['basic'] as Map<String, dynamic>? ?? {};
    final social = data['social'] as Map<String, dynamic>? ?? {};
    final presence =
        data['presence'] as Map<String, dynamic>? ?? {};
    final groups = data['groups'] as Map<String, dynamic>? ?? {};
    final avatar = data['avatar'] as Map<String, dynamic>? ?? {};
    final achievements =
        data['achievements'] as Map<String, dynamic>? ?? {};

    final headshotUrl = _getAvatarUrl(avatar, 'headshot');
    final fullBodyUrl = _getAvatarUrl(avatar, 'fullBody');

    final presences =
        presence['userPresences'] as List? ?? [];
    final firstPresence = presences.isNotEmpty
        ? presences[0] as Map<String, dynamic>
        : <String, dynamic>{};
    final presType =
        firstPresence['userPresenceType'] as int? ?? 0;
    final lastLocation =
        firstPresence['lastLocation'] as String? ?? 'Unknown';

    final friends = _getCount(social['friends']);
    final followers = _getCount(social['followers']);
    final following = _getCount(social['following']);

    final groupList =
        groups['list'] as Map<String, dynamic>? ?? {};
    final groupData = groupList['data'] as List? ?? [];

    final robloxBadges =
        achievements['robloxBadges'] as List? ?? [];

    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(basic, headshotUrl, fullBodyUrl,
                presType, lastLocation),
            const SizedBox(height: 14),
            _buildSocialStats(friends, followers, following),
            const SizedBox(height: 14),
            _buildDetailsCard(basic),
            const SizedBox(height: 14),
            if (groupData.isNotEmpty) ...[
              _buildGroupsCard(groupData),
              const SizedBox(height: 14),
            ],
            if (robloxBadges.isNotEmpty) ...[
              _buildBadgesCard(robloxBadges),
              const SizedBox(height: 14),
            ],
            _buildBackButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getAvatarUrl(Map<String, dynamic> avatar, String type) {
    final section =
        avatar[type] as Map<String, dynamic>? ?? {};
    final data = section['data'] as List? ?? [];
    if (data.isNotEmpty) {
      final item = data[0] as Map<String, dynamic>;
      return item['imageUrl'] as String? ?? '';
    }
    return '';
  }

  int _getCount(dynamic obj) {
    if (obj == null) return 0;
    if (obj is Map) return obj['count'] as int? ?? 0;
    return 0;
  }

  // ── Profile Card ──
  Widget _buildProfileCard(
      Map<String, dynamic> basic,
      String headshotUrl,
      String fullBodyUrl,
      int presType,
      String lastLocation) {
    final name = basic['name'] as String? ?? '-';
    final displayName = basic['displayName'] as String? ?? '-';
    final isBanned = basic['isBanned'] == true;
    final hasVerified = basic['hasVerifiedBadge'] == true;
    final presLabel = _RobloxStalkApi.presenceType(presType);
    final presColor = presType == 0
        ? _RBC.muted2
        : presType == 1
            ? _RBC.greenG1
            : _RBC.gold;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_RBC.card, _RBC.accent.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _RBC.border, width: 1),
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
                  color: _RBC.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                      color: _RBC.accent.withOpacity(0.25)),
                ),
                child: const Center(
                  child: Icon(Icons.view_in_ar_rounded,
                      color: _RBC.accent, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ROBLOX PROFILE',
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _RBC.text,
                          letterSpacing: 1.5,
                        )),
                    Text('roblox.com/users/profile',
                        style: const TextStyle(
                            fontSize: 10,
                            color: _RBC.muted,
                            fontFamily: 'ShareTechMono')),
                  ],
                ),
              ),
              if (isBanned)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _RBC.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _RBC.danger.withOpacity(0.22)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block_rounded,
                          color: _RBC.danger, size: 11),
                      SizedBox(width: 4),
                      Text('BANNED',
                          style: TextStyle(
                            color: _RBC.danger,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'MADEEvolveSansEVO',
                            letterSpacing: 1,
                          )),
                    ],
                  ),
                )
              else if (hasVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _RBC.blueG1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _RBC.blueG1.withOpacity(0.22)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          color: _RBC.blueG1, size: 11),
                      SizedBox(width: 4),
                      Text('VERIFIED',
                          style: TextStyle(
                            color: _RBC.blueG1,
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
                    color: _RBC.greenG1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _RBC.greenG1.withOpacity(0.22)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          color: _RBC.greenG1, size: 11),
                      SizedBox(width: 4),
                      Text('FOUND',
                          style: TextStyle(
                            color: _RBC.greenG1,
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
          Container(height: 1, color: _RBC.border2),
          const SizedBox(height: 22),

          // Headshot + info row
          Row(
            children: [
              // Headshot avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: _RBC.accent.withOpacity(0.3),
                      width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _RBC.accent.withOpacity(0.1),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: headshotUrl.isNotEmpty
                      ? Image.network(headshotUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _avatarPlaceholder())
                      : _avatarPlaceholder(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [_RBC.accent, _RBC.accent2],
                      ).createShader(b),
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('@$name',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _RBC.muted,
                          fontFamily: 'ShareTechMono',
                          letterSpacing: 1,
                        )),
                    const SizedBox(height: 8),
                    // Presence indicator
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) {
                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: presColor,
                                boxShadow: presType != 0
                                    ? [
                                        BoxShadow(
                                          color: presColor
                                              .withOpacity(0.4 +
                                                  _pulseController
                                                          .value *
                                                      0.4),
                                          blurRadius: 6,
                                        )
                                      ]
                                    : [],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(presLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'ShareTechMono',
                              fontWeight: FontWeight.bold,
                              color: presColor,
                              letterSpacing: 1,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Full body avatar
          if (fullBodyUrl.isNotEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _RBC.border2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Image.network(fullBodyUrl,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox()),
                ),
              ),
            ),
          ],

          // Last location
          if (lastLocation != 'Unknown' &&
              lastLocation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded,
                      color: _RBC.muted2, size: 13),
                  const SizedBox(width: 5),
                  Text('Last seen: $lastLocation',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _RBC.muted,
                        fontFamily: 'ShareTechMono',
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _RBC.surface,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Center(
        child: Icon(Icons.view_in_ar_rounded,
            color: _RBC.muted2, size: 30),
      ),
    );
  }

  // ── Social Stats ──
  Widget _buildSocialStats(
      int friends, int followers, int following) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
              Icons.group_rounded, 'FRIENDS', '$friends', _RBC.blueG1),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatBox(Icons.people_rounded, 'FOLLOWERS',
              '$followers', _RBC.rbRed),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatBox(Icons.person_add_rounded, 'FOLLOWING',
              '$following', _RBC.cyanG1),
        ),
      ],
    );
  }

  Widget _buildStatBox(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: _RBC.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_RBC.card, color.withOpacity(0.04)],
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
                color: _RBC.muted,
                fontFamily: 'ShareTechMono',
                letterSpacing: 1,
              )),
        ],
      ),
    );
  }

  // ── Details Card ──
  Widget _buildDetailsCard(Map<String, dynamic> basic) {
    final description = basic['description'] as String? ?? '';
    final created =
        _RobloxStalkApi.formatDate(basic['created'] as String?);
    final externalApp =
        basic['externalAppDisplayName'] as String? ?? '';

    final details = <Map<String, dynamic>>[
      {
        'icon': Icons.tag_rounded,
        'label': 'USER ID',
        'value': '${basic['id'] ?? 'N/A'}',
        'color': _RBC.blueG1
      },
      {
        'icon': Icons.person_rounded,
        'label': 'USERNAME',
        'value': '@${basic['name'] ?? 'N/A'}',
        'color': _RBC.rbRed
      },
      {
        'icon': Icons.edit_note_rounded,
        'label': 'DISPLAY NAME',
        'value': basic['displayName'] ?? 'N/A',
        'color': _RBC.cyanG1
      },
      {
        'icon': Icons.calendar_today_rounded,
        'label': 'JOINED',
        'value': created,
        'color': _RBC.greenG1
      },
      {
        'icon': Icons.person_outline_rounded,
        'label': 'AVATAR TYPE',
        'value': basic['playerAvatarType'] ?? 'N/A',
        'color': _RBC.purpleG1
      },
    ];

    if (externalApp.isNotEmpty) {
      details.add({
        'icon': Icons.phone_android_rounded,
        'label': 'EXTERNAL APP',
        'value': externalApp,
        'color': _RBC.orangeG1
      });
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _RBC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _RBC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(
              Icons.badge_rounded, 'DETAILS'),
          const SizedBox(height: 16),
          Container(height: 1, color: _RBC.border2),
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
                      border: Border.all(
                          color: color.withOpacity(0.2)),
                    ),
                    child: Center(
                        child:
                            Icon(icon, color: color, size: 15)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                              fontSize: 9,
                              color: _RBC.muted,
                              fontFamily: 'ShareTechMono',
                              letterSpacing: 1.2,
                            )),
                        const SizedBox(height: 3),
                        Text(value,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _RBC.text,
                              fontFamily: 'ShareTechMono',
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          // Bio section
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _RBC.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _RBC.border2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_quote_rounded,
                          color: _RBC.accent.withOpacity(0.45),
                          size: 14),
                      const SizedBox(width: 6),
                      const Text('BIO',
                          style: TextStyle(
                            fontSize: 9,
                            fontFamily: 'ShareTechMono',
                            color: _RBC.muted,
                            letterSpacing: 1.2,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 12,
                          color: _RBC.muted,
                          height: 1.6)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Groups Card ──
  Widget _buildGroupsCard(List groupData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _RBC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _RBC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _RBC.orangeG1.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _RBC.orangeG1.withOpacity(0.25)),
                ),
                child: const Center(
                  child: Icon(Icons.groups_rounded,
                      color: _RBC.orangeG1, size: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GROUPS',
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _RBC.text,
                          letterSpacing: 1.2,
                        )),
                    Text('${groupData.length} group joined',
                        style: const TextStyle(
                            fontSize: 10, color: _RBC.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: _RBC.border2),
          const SizedBox(height: 14),
          ...groupData.map<Widget>((item) {
            final group =
                item['group'] as Map<String, dynamic>? ?? {};
            final role =
                item['role'] as Map<String, dynamic>? ?? {};
            final groupName = group['name'] ?? 'Unknown';
            final memberCount = group['memberCount'] ?? 0;
            final roleName = role['name'] ?? 'Member';
            final owner =
                group['owner'] as Map<String, dynamic>? ?? {};
            final ownerName = owner['username'] ?? 'Unknown';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _RBC.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _RBC.orangeG1.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _RBC.orangeG1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(groupName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _RBC.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 18),
                      _miniStat(Icons.label_rounded, roleName,
                          _RBC.orangeG1),
                      const SizedBox(width: 14),
                      _miniStat(Icons.people_rounded,
                          '$memberCount members', _RBC.muted),
                      const SizedBox(width: 14),
                      _miniStat(Icons.star_rounded,
                          'by $ownerName', _RBC.gold),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 10),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 10,
                color: color,
                fontFamily: 'ShareTechMono')),
      ],
    );
  }

  // ── Badges Card ──
  Widget _buildBadgesCard(List badges) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _RBC.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _RBC.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _RBC.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _RBC.gold.withOpacity(0.25)),
                ),
                child: const Center(
                  child: Icon(Icons.emoji_events_rounded,
                      color: _RBC.gold, size: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ROBLOX BADGES',
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _RBC.text,
                          letterSpacing: 1.2,
                        )),
                    Text('${badges.length} badge earned',
                        style: const TextStyle(
                            fontSize: 10, color: _RBC.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: _RBC.border2),
          const SizedBox(height: 14),
          ...badges.map<Widget>((badge) {
            final name = badge['name'] ?? 'Unknown Badge';
            final desc = badge['description'] ?? '';
            final imgUrl = badge['imageUrl'] as String? ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _RBC.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _RBC.gold.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _RBC.gold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: imgUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(9),
                            child: Image.network(imgUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Center(
                                      child: Icon(
                                          Icons
                                              .emoji_events_rounded,
                                          color: _RBC.gold,
                                          size: 18),
                                    )))
                        : Center(
                            child: Icon(
                                Icons.emoji_events_rounded,
                                color: _RBC.gold,
                                size: 18),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _RBC.text,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(desc,
                              style: const TextStyle(
                                fontSize: 10,
                                color: _RBC.muted,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis),
                        ],
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
          _resultData = null;
          _hasSearched = false;
          _errorMessage = null;
        }),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
          decoration: BoxDecoration(
            color: _RBC.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _RBC.border2),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded,
                  color: _RBC.muted, size: 15),
              SizedBox(width: 8),
              Text('STALK LAGI',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _RBC.text,
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
                color: _RBC.danger.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _RBC.danger.withOpacity(0.25), width: 1.5),
              ),
              child: const Center(
                child: Icon(Icons.warning_amber_rounded,
                    color: _RBC.danger, size: 34),
              ),
            ),
            const SizedBox(height: 18),
            const Text('Oops!',
                style: TextStyle(
                  color: _RBC.text,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MADEEvolveSansEVO',
                  letterSpacing: 1,
                )),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _RBC.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _RBC.border),
              ),
              child: Text(
                _errorMessage ?? 'Terjadi kesalahan',
                style: const TextStyle(
                    color: _RBC.muted, fontSize: 13, height: 1.6),
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
                      colors: [Color(0xFFC41E13), Color(0xFFFF3B30)]),
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
      baseColor: _RBC.card,
      highlightColor: _RBC.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 380,
              decoration: BoxDecoration(
                  color: _RBC.card,
                  borderRadius: BorderRadius.circular(20)),
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(3, (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                  height: 94,
                  decoration: BoxDecoration(
                    color: _RBC.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                  color: _RBC.card,
                  borderRadius: BorderRadius.circular(20)),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                  color: _RBC.card,
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
                colors: [_RBC.accent, _RBC.accent2],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: _RBC.accent, size: 14),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
              fontFamily: 'MADEEvolveSansEVO',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _RBC.text,
              letterSpacing: 1.2,
            )),
      ],
    );
  }
}
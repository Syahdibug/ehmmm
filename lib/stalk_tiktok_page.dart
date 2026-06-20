import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TikTok Stalker Page — Production-Quality Flutter Widget
// Color scheme: TikTok pink / cyan dark theme
// Icons: Material ONLY (no FontAwesome)
// Fonts: MADEEvolveSansEVO + ShareTechMono
// ─────────────────────────────────────────────────────────────────────────────

// ═══════════════════════════════════════════════════════════════════════════════
// COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════════
class _TKC {
  static const bg = Color(0xFF0c0d15);
  static const bg2 = Color(0xFF11121c);
  static const surface = Color(0xFF161823);
  static const card = Color(0xFF1a1c29);
  static const accent = Color(0xFFFE2C55); // TikTok pink
  static const accent2 = Color(0xFF25F4EE); // TikTok cyan
  static const accent3 = Color(0xFFFF0050); // Deep pink
  static const gold = Color(0xFFFFD447);
  static const danger = Color(0xFFFF4D6D);
  static const text = Color(0xFFE2EAF5);
  static const muted = Color(0x88E2EAF5);
  static const muted2 = Color(0x33E2EAF5);
  static const border = Color(0x22FE2C55);
  static const border2 = Color(0x14FFFFFF);
  static const greenG1 = Color(0xFF25D366);
  static const blueG1 = Color(0xFF229ED9);
  static const purpleG1 = Color(0xFF9C27B0);
  static const orangeG1 = Color(0xFFFF8C00);
  static const cyanG1 = Color(0xFF00BCD4);
  static const tealG1 = Color(0xFF009688);
  static const redG1 = Color(0xFFFF4D6D);
}

// ═══════════════════════════════════════════════════════════════════════════════
// FONT CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════
const _kFontPrimary = 'MADEEvolveSansEVO';
const _kFontMono = 'ShareTechMono';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _TikTokUser {
  final String uniqueId;
  final String nickname;
  final String signature;
  final String avatarMedium;
  final String avatarLarger;
  final bool verified;
  final bool privateAccount;
  final int createTime;

  const _TikTokUser({
    required this.uniqueId,
    required this.nickname,
    required this.signature,
    required this.avatarMedium,
    required this.avatarLarger,
    required this.verified,
    required this.privateAccount,
    required this.createTime,
  });

  factory _TikTokUser.fromJson(Map<String, dynamic> json) {
    return _TikTokUser(
      uniqueId: json['uniqueId'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      signature: json['signature'] as String? ?? '',
      avatarMedium: json['avatarMedium'] as String? ?? '',
      avatarLarger: json['avatarLarger'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      privateAccount: json['privateAccount'] as bool? ?? false,
      createTime: json['createTime'] as int? ?? 0,
    );
  }
}

class _TikTokStats {
  final int followerCount;
  final int followingCount;
  final int heart;
  final int videoCount;

  const _TikTokStats({
    required this.followerCount,
    required this.followingCount,
    required this.heart,
    required this.videoCount,
  });

  factory _TikTokStats.fromJson(Map<String, dynamic> json) {
    return _TikTokStats(
      followerCount: json['followerCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      heart: json['heart'] as int? ?? 0,
      videoCount: json['videoCount'] as int? ?? 0,
    );
  }
}

class _StalkResult {
  final _TikTokUser user;
  final _TikTokStats stats;

  const _StalkResult({required this.user, required this.stats});
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class StalkTikTokPage extends StatefulWidget {
  const StalkTikTokPage({super.key});

  @override
  State<StalkTikTokPage> createState() => _StalkTikTokPageState();
}

class _StalkTikTokPageState extends State<StalkTikTokPage>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _hasResult = false;
  bool _hasError = false;
  String _errorMessage = '';
  _StalkResult? _result;

  // ── Animation Controllers ─────────────────────────────────────────────────
  late AnimationController _headerBadgeController;
  late AnimationController _glowController;
  late AnimationController _pulseController;
  late AnimationController _slideInController;

  bool _isInputFocused = false;

  @override
  void initState() {
    super.initState();

    _headerBadgeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _slideInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _inputFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _inputFocusNode.removeListener(_onFocusChange);
    _inputFocusNode.dispose();
    _headerBadgeController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    _slideInController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isInputFocused = _inputFocusNode.hasFocus;
    });
  }

  // ── API Call ─────────────────────────────────────────────────────────────
  Future<void> _stalkUser() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _hasResult = false;
      _errorMessage = '';
      _result = null;
    });

    _inputFocusNode.unfocus();

    try {
      final uri = Uri.parse(
        'https://api.siputzx.my.id/api/stalk/tiktok?username=$username',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned status ${response.statusCode}. Please try again.',
        );
      }

      final body = json.decode(response.body) as Map<String, dynamic>;

      if (body['status'] != true) {
        throw Exception('User "$username" not found on TikTok.');
      }

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Unexpected response format. Please try again.');
      }

      final userData = data['user'] as Map<String, dynamic>?;
      final statsData = data['stats'] as Map<String, dynamic>?;

      if (userData == null || statsData == null) {
        throw Exception('Incomplete profile data received.');
      }

      final user = _TikTokUser.fromJson(userData);
      final stats = _TikTokStats.fromJson(statsData);

      setState(() {
        _result = _StalkResult(user: user, stats: stats);
        _hasResult = true;
        _isLoading = false;
      });

      _slideInController.forward(from: 0);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _hasResult = false;
      _hasError = false;
      _errorMessage = '';
      _result = null;
      _usernameController.clear();
    });
  }

  // ── Number Formatting ────────────────────────────────────────────────────
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDate(int timestamp) {
    if (timestamp <= 0) return 'Unknown';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TKC.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    if (!_hasResult && !_hasError) ...[
                      _buildHeroBanner(),
                      const SizedBox(height: 24),
                      _buildInputCard(),
                      const SizedBox(height: 20),
                      _buildStalkButton(),
                      const SizedBox(height: 24),
                      _buildInfoCard(),
                      const SizedBox(height: 32),
                    ],
                    if (_isLoading) ...[
                      _buildShimmerLoading(),
                    ],
                    if (_hasError && !_isLoading) ...[
                      _buildErrorView(),
                    ],
                    if (_hasResult && !_isLoading && _result != null) ...[
                      _buildProfileCard(),
                      const SizedBox(height: 16),
                      _buildStatsGrid(),
                      const SizedBox(height: 16),
                      _buildDetailsCard(),
                      const SizedBox(height: 24),
                      _buildBackButton(),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER — 62px height, BackdropFilter blur, gradient title, back button,
  //           animated icon badge
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return SizedBox(
      height: 62,
      child: Stack(
        children: [
          // Blur background
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 62,
                decoration: BoxDecoration(
                  color: _TKC.bg.withOpacity(0.7),
                  border: Border(
                    bottom: BorderSide(
                      color: _TKC.border2,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Back button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _TKC.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _TKC.border2, width: 0.5),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: _TKC.text,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Title with gradient
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [_TKC.accent, _TKC.accent2],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      'TikTok Stalker',
                      style: const TextStyle(
                        fontFamily: _kFontPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Animated badge icon
                AnimatedBuilder(
                  animation: _headerBadgeController,
                  builder: (context, child) {
                    final value = _headerBadgeController.value;
                    return Transform.rotate(
                      angle: value * 0.3,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              _TKC.accent.withOpacity(0.15 + value * 0.1),
                              _TKC.accent2.withOpacity(0.15 + value * 0.1),
                            ],
                          ),
                          border: Border.all(
                            color: _TKC.accent.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: _TKC.accent,
                          size: 18,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HERO BANNER — Platform icon (animated glow circle), title, description
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroBanner() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            // Animated glow circle with TikTok icon
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final glow = _glowController.value;
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _TKC.accent.withOpacity(0.08 + glow * 0.12),
                        _TKC.accent2.withOpacity(0.08 + glow * 0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _TKC.accent.withOpacity(glow * 0.35),
                        blurRadius: 24 + glow * 16,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: _TKC.accent2.withOpacity(glow * 0.25),
                        blurRadius: 20 + glow * 12,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: _TKC.accent.withOpacity(0.2 + glow * 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.music_note_rounded,
                      color: _TKC.accent,
                      size: 34,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            // Title
            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [_TKC.accent, _TKC.accent2, _TKC.accent],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: const Text(
                'Stalk TikTok Profile',
                style: TextStyle(
                  fontFamily: _kFontPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              'Enter a TikTok username to reveal their\nprofile details, stats, and more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _kFontMono,
                fontSize: 12,
                color: _TKC.muted,
                height: 1.6,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INPUT CARD — Section label with gradient bar, text field with focus
  //               animation (box shadow), info tip
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _TKC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _TKC.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label with gradient bar
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [_TKC.accent, _TKC.accent2],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.input_rounded,
                color: _TKC.accent2,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Target Username',
                style: TextStyle(
                  fontFamily: _kFontPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _TKC.text,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Text field with focus animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: _TKC.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isInputFocused ? _TKC.accent : _TKC.border2,
                width: _isInputFocused ? 1.5 : 0.5,
              ),
              boxShadow: _isInputFocused
                  ? [
                      BoxShadow(
                        color: _TKC.accent.withOpacity(0.15),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: _TKC.accent2.withOpacity(0.08),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: TextField(
              controller: _usernameController,
              focusNode: _inputFocusNode,
              style: const TextStyle(
                fontFamily: _kFontMono,
                fontSize: 14,
                color: _TKC.text,
                letterSpacing: 0.5,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. khaby_lame',
                hintStyle: TextStyle(
                  fontFamily: _kFontMono,
                  fontSize: 13,
                  color: _TKC.muted2,
                  letterSpacing: 0.5,
                ),
                prefixIcon: const Icon(
                  Icons.alternate_email_rounded,
                  color: _TKC.accent,
                  size: 20,
                ),
                suffixIcon: _usernameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _TKC.muted,
                          size: 18,
                        ),
                        onPressed: () {
                          _usernameController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _stalkUser(),
              textInputAction: TextInputAction.go,
            ),
          ),
          const SizedBox(height: 10),
          // Info tip
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: _TKC.accent2,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Enter the exact TikTok username without the @ symbol.',
                  style: TextStyle(
                    fontFamily: _kFontMono,
                    fontSize: 11,
                    color: _TKC.muted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STALK BUTTON — Gradient button (not flat!), disabled state with muted colors
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStalkButton() {
    final isEmpty = _usernameController.text.trim().isEmpty;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: isEmpty
              ? LinearGradient(
                  colors: [
                    _TKC.accent.withOpacity(0.3),
                    _TKC.accent2.withOpacity(0.3),
                  ],
                )
              : const LinearGradient(
                  colors: [Color(0xFFFE2C55), Color(0xFF25F4EE)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          boxShadow: isEmpty
              ? []
              : [
                  BoxShadow(
                    color: _TKC.accent.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: _TKC.accent2.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isEmpty ? null : _stalkUser,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.gps_fixed_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Start Stalking',
                    style: TextStyle(
                      fontFamily: _kFontPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isEmpty
                          ? _TKC.muted.withOpacity(0.6)
                          : Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INFO CARD — Step-by-step instructions
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInfoCard() {
    final steps = [
      (
        icon: Icons.search_rounded,
        color: _TKC.accent,
        title: '1. Find Username',
        desc: 'Get the target\'s TikTok @username from their profile link.',
      ),
      (
        icon: Icons.input_rounded,
        color: _TKC.accent2,
        title: '2. Enter Username',
        desc: 'Type the username in the field above (without @ symbol).',
      ),
      (
        icon: Icons.gps_fixed_rounded,
        color: _TKC.purpleG1,
        title: '3. Hit Stalk',
        desc: 'Tap the button and wait for the profile data to load.',
      ),
      (
        icon: Icons.data_usage_rounded,
        color: _TKC.gold,
        title: '4. View Results',
        desc: 'See follower count, likes, bio, join date, and more.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _TKC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _TKC.border2, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [_TKC.gold, _TKC.orangeG1],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.help_outline_rounded,
                color: _TKC.gold,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'How to Use',
                style: TextStyle(
                  fontFamily: _kFontPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _TKC.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Steps
          ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: step.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: step.color.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        step.icon,
                        color: step.color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: const TextStyle(
                              fontFamily: _kFontPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _TKC.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.desc,
                            style: TextStyle(
                              fontFamily: _kFontMono,
                              fontSize: 11,
                              color: _TKC.muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PROFILE CARD (result) — Header row with icon+title+badge, divider,
  //                          animated pulse avatar, nickname, username, bio quote
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProfileCard() {
    final user = _result!.user;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideInController,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: _slideInController,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _TKC.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _TKC.border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: _TKC.accent.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon+title+badge
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        colors: [_TKC.accent, _TKC.accent3],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.person_search_rounded,
                    color: _TKC.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Profile Found',
                    style: TextStyle(
                      fontFamily: _kFontPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _TKC.text,
                    ),
                  ),
                  const Spacer(),
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _TKC.greenG1.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _TKC.greenG1.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _TKC.greenG1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: TextStyle(
                            fontFamily: _kFontMono,
                            fontSize: 10,
                            color: _TKC.greenG1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Divider
              Divider(
                height: 1,
                thickness: 0.5,
                color: _TKC.border2,
              ),
              const SizedBox(height: 20),
              // Avatar with pulse + info
              Center(
                child: Column(
                  children: [
                    // Animated pulse avatar
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulse = _pulseController.value;
                        return Container(
                          padding: EdgeInsets.all(3 + pulse * 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                _TKC.accent,
                                _TKC.accent2,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _TKC.accent.withOpacity(0.2 + pulse * 0.15),
                                blurRadius: 16 + pulse * 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _TKC.bg,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                user.avatarLarger.isNotEmpty
                                    ? user.avatarLarger
                                    : user.avatarMedium,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: _TKC.surface,
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: _TKC.muted,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    // Nickname
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.nickname.isNotEmpty ? user.nickname : 'N/A',
                          style: const TextStyle(
                            fontFamily: _kFontPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _TKC.text,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (user.verified) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _TKC.accent.withOpacity(0.15),
                              border: Border.all(
                                color: _TKC.accent,
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: _TKC.accent,
                              size: 14,
                            ),
                          ),
                        ],
                        if (user.privateAccount) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _TKC.gold.withOpacity(0.15),
                              border: Border.all(
                                color: _TKC.gold,
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: _TKC.gold,
                              size: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Username
                    Text(
                      user.uniqueId.isNotEmpty
                          ? '@${user.uniqueId}'
                          : '@unknown',
                      style: const TextStyle(
                        fontFamily: _kFontMono,
                        fontSize: 13,
                        color: _TKC.accent2,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bio quote
                    if (user.signature.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _TKC.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _TKC.border2,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.format_quote_rounded,
                              color: _TKC.accent.withOpacity(0.5),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                user.signature,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontFamily: _kFontMono,
                                  fontSize: 12,
                                  color: _TKC.muted,
                                  height: 1.5,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATS GRID — 4 stat boxes (Followers, Following, Likes, Videos)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsGrid() {
    final stats = _result!.stats;
    final statItems = [
      (
        icon: Icons.group_rounded,
        label: 'Followers',
        value: _formatCount(stats.followerCount),
        color: _TKC.accent,
        bgColor: _TKC.accent.withOpacity(0.1),
      ),
      (
        icon: Icons.person_add_rounded,
        label: 'Following',
        value: _formatCount(stats.followingCount),
        color: _TKC.accent2,
        bgColor: _TKC.accent2.withOpacity(0.1),
      ),
      (
        icon: Icons.favorite_rounded,
        label: 'Likes',
        value: _formatCount(stats.heart),
        color: _TKC.danger,
        bgColor: _TKC.danger.withOpacity(0.1),
      ),
      (
        icon: Icons.videocam_rounded,
        label: 'Videos',
        value: _formatCount(stats.videoCount),
        color: _TKC.gold,
        bgColor: _TKC.gold.withOpacity(0.1),
      ),
    ];

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideInController,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: _slideInController,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: statItems.length,
          itemBuilder: (context, index) {
            final item = statItems[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _TKC.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: item.color.withOpacity(0.15),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon box
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Value
                  Text(
                    item.value,
                    style: TextStyle(
                      fontFamily: _kFontPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _TKC.text,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Label
                  Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: _kFontMono,
                      fontSize: 11,
                      color: _TKC.muted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DETAILS CARD — Join date with icon boxes (34x34) per row
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDetailsCard() {
    final user = _result!.user;
    final stats = _result!.stats;

    final details = [
      (
        icon: Icons.calendar_today_rounded,
        color: _TKC.accent,
        label: 'Joined',
        value: _formatDate(user.createTime),
      ),
      (
        icon: Icons.lock_rounded,
        color: user.privateAccount ? _TKC.gold : _TKC.greenG1,
        label: 'Account',
        value: user.privateAccount ? 'Private' : 'Public',
      ),
      (
        icon: Icons.verified_rounded,
        color: user.verified ? _TKC.accent : _TKC.muted2,
        label: 'Status',
        value: user.verified ? 'Verified' : 'Unverified',
      ),
      (
        icon: Icons.smart_display_rounded,
        color: _TKC.accent2,
        label: 'Total Videos',
        value: stats.videoCount.toString(),
      ),
      (
        icon: Icons.favorite_rounded,
        color: _TKC.danger,
        label: 'Total Likes',
        value: _formatCount(stats.heart),
      ),
      (
        icon: Icons.diversity_3_rounded,
        color: _TKC.purpleG1,
        label: 'Following',
        value: _formatCount(stats.followingCount),
      ),
    ];

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideInController,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: _slideInController,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _TKC.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _TKC.border2, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        colors: [_TKC.accent2, _TKC.cyanG1],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.info_outline_rounded,
                    color: _TKC.accent2,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Profile Details',
                    style: TextStyle(
                      fontFamily: _kFontPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _TKC.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                thickness: 0.5,
                color: _TKC.border2,
              ),
              const SizedBox(height: 14),
              // Detail rows
              ...details.map((detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        // 34x34 icon box
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: detail.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: detail.color.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            detail.icon,
                            color: detail.color,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Label
                        Text(
                          detail.label,
                          style: TextStyle(
                            fontFamily: _kFontMono,
                            fontSize: 12,
                            color: _TKC.muted,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        // Value
                        Text(
                          detail.value,
                          style: TextStyle(
                            fontFamily: _kFontPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _TKC.text,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BACK BUTTON — Center button to stalk again
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBackButton() {
    return Center(
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              _TKC.accent.withOpacity(0.15),
              _TKC.accent2.withOpacity(0.15),
            ],
          ),
          border: Border.all(
            color: _TKC.accent.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _reset,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    color: _TKC.accent2,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Stalk Another User',
                    style: TextStyle(
                      fontFamily: _kFontPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _TKC.accent2,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ERROR VIEW — Circle warning icon, error message, retry button with gradient
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            // Circle warning icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _TKC.danger.withOpacity(0.1),
                border: Border.all(
                  color: _TKC.danger.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _TKC.danger.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: _TKC.danger,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            // Error message
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _kFontMono,
                  fontSize: 13,
                  color: _TKC.muted,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Retry button with gradient
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [_TKC.accent, _TKC.accent2],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _TKC.accent.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _stalkUser,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Try Again',
                          style: TextStyle(
                            fontFamily: _kFontPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHIMMER LOADING — Placeholder skeleton cards
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildShimmerLoading() {
    final baseColor = _TKC.surface;
    final highlightColor = _TKC.card;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton profile card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _TKC.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _TKC.border2, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row skeleton
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: _TKC.muted2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _TKC.muted2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _TKC.muted2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: _TKC.border2,
                ),
                const SizedBox(height: 20),
                // Avatar skeleton
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _TKC.muted2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _TKC.muted2,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _TKC.muted2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 200,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _TKC.muted2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Skeleton stats grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _TKC.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _TKC.border2, width: 0.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _TKC.muted2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 60,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _TKC.muted2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 50,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _TKC.muted2,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Skeleton details card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _TKC.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _TKC.border2, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: _TKC.muted2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _TKC.muted2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 90,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _TKC.muted2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: _TKC.border2,
                ),
                const SizedBox(height: 14),
                // Skeleton rows
                ...List.generate(4, (_) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _TKC.muted2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 60,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _TKC.muted2,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 70,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _TKC.muted2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

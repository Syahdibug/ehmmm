import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Twitter/X Stalker Page — Production-Quality Flutter Widget
// Color scheme: Twitter/X sky blue dark theme
// Icons: Material ONLY (no FontAwesome)
// Fonts: MADEEvolveSansEVO + ShareTechMono
// ─────────────────────────────────────────────────────────────────────────────

// ═══════════════════════════════════════════════════════════════════════════════
// COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════════
class _TXC {
  static const bg = Color(0xFF0A0E14);
  static const bg2 = Color(0xFF0F1922);
  static const surface = Color(0xFF141E2A);
  static const card = Color(0xFF192634);
  static const accent = Color(0xFF1DA1F2); // Twitter blue
  static const accent2 = Color(0xFF657786); // Twitter gray
  static const accent3 = Color(0xFFAAB8C2); // Light gray
  static const gold = Color(0xFFFFD447);
  static const danger = Color(0xFFFF4D6D);
  static const text = Color(0xFFE7E9EA);
  static const muted = Color(0x88E7E9EA);
  static const muted2 = Color(0x33E7E9EA);
  static const border = Color(0x221DA1F2);
  static const border2 = Color(0x14FFFFFF);
  static const greenG1 = Color(0xFF17BF63); // Twitter green
  static const blueG1 = Color(0xFF1DA1F2);
  static const purpleG1 = Color(0xFF9C27B0);
  static const orangeG1 = Color(0xFFFF8C00);
  static const cyanG1 = Color(0xFF1DA1F2);
  static const tealG1 = Color(0xFF009688);
  static const redG1 = Color(0xFFE0245E); // Twitter red
}

// ═══════════════════════════════════════════════════════════════════════════════
// FONT CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════
const _kFontPrimary = 'MADEEvolveSansEVO';
const _kFontMono = 'ShareTechMono';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _TwitterCore {
  final String screenName;
  final String name;
  final String createdAt;

  const _TwitterCore({
    required this.screenName,
    required this.name,
    required this.createdAt,
  });

  factory _TwitterCore.fromJson(Map<String, dynamic> json) {
    return _TwitterCore(
      screenName: json['screen_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class _TwitterLegacy {
  final String description;
  final int followersCount;
  final int friendsCount;
  final int favouritesCount;
  final int statusesCount;
  final int mediaCount;

  const _TwitterLegacy({
    required this.description,
    required this.followersCount,
    required this.friendsCount,
    required this.favouritesCount,
    required this.statusesCount,
    required this.mediaCount,
  });

  factory _TwitterLegacy.fromJson(Map<String, dynamic> json) {
    return _TwitterLegacy(
      description: json['description'] as String? ?? '',
      followersCount: json['followers_count'] as int? ?? 0,
      friendsCount: json['friends_count'] as int? ?? 0,
      favouritesCount: json['favourites_count'] as int? ?? 0,
      statusesCount: json['statuses_count'] as int? ?? 0,
      mediaCount: json['media_count'] as int? ?? 0,
    );
  }
}

class _TwitterUser {
  final _TwitterCore core;
  final _TwitterLegacy legacy;
  final String avatarUrl;
  final bool verified;
  final bool isBlueVerified;
  final String restId;

  const _TwitterUser({
    required this.core,
    required this.legacy,
    required this.avatarUrl,
    required this.verified,
    required this.isBlueVerified,
    required this.restId,
  });

  factory _TwitterUser.fromJson(Map<String, dynamic> json) {
    final coreData = json['core'] as Map<String, dynamic>? ?? {};
    final legacyData = json['legacy'] as Map<String, dynamic>? ?? {};
    final avatarData = json['avatar'] as Map<String, dynamic>? ?? {};
    final verificationData = json['verification'] as Map<String, dynamic>? ?? {};

    return _TwitterUser(
      core: _TwitterCore.fromJson(coreData),
      legacy: _TwitterLegacy.fromJson(legacyData),
      avatarUrl: avatarData['image_url'] as String? ?? '',
      verified: verificationData['verified'] as bool? ?? false,
      isBlueVerified: json['is_blue_verified'] as bool? ?? false,
      restId: json['rest_id'] as String? ?? '',
    );
  }
}

class _StalkResult {
  final _TwitterUser user;

  const _StalkResult({required this.user});
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class StalkTwitterPage extends StatefulWidget {
  const StalkTwitterPage({super.key});

  @override
  State<StalkTwitterPage> createState() => _StalkTwitterPageState();
}

class _StalkTwitterPageState extends State<StalkTwitterPage>
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
        'https://api.deline.web.id/stalker/twitter?username=$username',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned status ${response.statusCode}. Please try again.',
        );
      }

      final body = json.decode(response.body) as Map<String, dynamic>;

      if (body['status'] != true) {
        throw Exception('User "$username" not found on Twitter/X.');
      }

      final resultData = body['result'] as Map<String, dynamic>?;
      if (resultData == null) {
        throw Exception('Unexpected response format. Please try again.');
      }

      final user = _TwitterUser.fromJson(resultData);

      setState(() {
        _result = _StalkResult(user: user);
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

  // ── Twitter Date Parsing ────────────────────────────────────────────────
  // Input: "Mon Feb 06 07:05:28 +0000 2023"
  // Output: "06/02/2023" (DD/MM/YYYY)
  String _parseTwitterDate(String dateString) {
    if (dateString.isEmpty) return 'Unknown';
    try {
      // Format: EEE MMM dd HH:mm:ss Z yyyy
      // e.g. "Mon Feb 06 07:05:28 +0000 2023"
      final parts = dateString.split(' ');
      if (parts.length >= 6) {
        final dayStr = parts[2]; // "06"
        final monthStr = parts[1]; // "Feb"
        final yearStr = parts[5]; // "2023"

        final months = {
          'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
          'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
          'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12',
        };

        final monthNum = months[monthStr] ?? '01';
        return '$dayStr/$monthNum/$yearStr';
      }
      return dateString;
    } catch (_) {
      return dateString;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _TXC.bg,
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
  // HEADER — 62px height, BackdropFilter blur, gradient title (blue→gray),
  //           back button, animated icon badge
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
                  color: _TXC.bg.withOpacity(0.7),
                  border: Border(
                    bottom: BorderSide(
                      color: _TXC.border2,
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
                        color: _TXC.surface,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: _TXC.border2, width: 0.5),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: _TXC.text,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Title with gradient (blue → gray)
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [_TXC.accent, _TXC.accent2],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: const Text(
                      'Twitter/X Stalker',
                      style: TextStyle(
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
                              _TXC.accent
                                  .withOpacity(0.15 + value * 0.1),
                              _TXC.accent2
                                  .withOpacity(0.15 + value * 0.1),
                            ],
                          ),
                          border: Border.all(
                            color: _TXC.accent.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.alternate_email_rounded,
                          color: _TXC.accent,
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
  // HERO BANNER — Platform icon (animated glow circle), title "TWITTER/X
  //               STALKER", description
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroBanner() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            // Animated glow circle with Twitter/X icon
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
                        _TXC.accent
                            .withOpacity(0.08 + glow * 0.12),
                        _TXC.accent2
                            .withOpacity(0.08 + glow * 0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            _TXC.accent.withOpacity(glow * 0.35),
                        blurRadius: 24 + glow * 16,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color:
                            _TXC.accent2.withOpacity(glow * 0.25),
                        blurRadius: 20 + glow * 12,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: _TXC.accent
                          .withOpacity(0.2 + glow * 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.alternate_email_rounded,
                      color: _TXC.accent,
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
                  colors: [_TXC.accent, _TXC.accent2, _TXC.accent],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: const Text(
                'TWITTER/X STALKER',
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
              'Enter a Twitter/X username to reveal their\nprofile details, stats, and more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _kFontMono,
                fontSize: 12,
                color: _TXC.muted,
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
        color: _TXC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _TXC.border, width: 0.5),
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
                    colors: [_TXC.accent, _TXC.accent2],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.input_rounded,
                color: _TXC.accent2,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Target Username',
                style: TextStyle(
                  fontFamily: _kFontPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _TXC.text,
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
              color: _TXC.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isInputFocused ? _TXC.accent : _TXC.border2,
                width: _isInputFocused ? 1.5 : 0.5,
              ),
              boxShadow: _isInputFocused
                  ? [
                      BoxShadow(
                        color: _TXC.accent.withOpacity(0.15),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: _TXC.accent2.withOpacity(0.08),
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
                color: _TXC.text,
                letterSpacing: 0.5,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. elonmusk',
                hintStyle: TextStyle(
                  fontFamily: _kFontMono,
                  fontSize: 13,
                  color: _TXC.muted2,
                  letterSpacing: 0.5,
                ),
                prefixIcon: const Icon(
                  Icons.alternate_email_rounded,
                  color: _TXC.accent,
                  size: 20,
                ),
                suffixIcon: _usernameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _TXC.muted,
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
                color: _TXC.accent2,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Enter the exact Twitter/X username without the @ symbol.',
                  style: TextStyle(
                    fontFamily: _kFontMono,
                    fontSize: 11,
                    color: _TXC.muted,
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
  // STALK BUTTON — Blue gradient [Color(0xFF1DA1F2), Color(0xFF657786)]
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
                    _TXC.accent.withOpacity(0.3),
                    _TXC.accent2.withOpacity(0.3),
                  ],
                )
              : const LinearGradient(
                  colors: [Color(0xFF1DA1F2), Color(0xFF657786)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          boxShadow: isEmpty
              ? []
              : [
                  BoxShadow(
                    color: _TXC.accent.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: _TXC.accent2.withOpacity(0.2),
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
                          ? _TXC.muted.withOpacity(0.6)
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
  // INFO CARD — 5-step instructions
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInfoCard() {
    final steps = [
      (
        icon: Icons.search_rounded,
        color: _TXC.accent,
        title: '1. Find Username',
        desc: 'Get the target\'s Twitter/X @username from their profile link.',
      ),
      (
        icon: Icons.input_rounded,
        color: _TXC.accent2,
        title: '2. Enter Username',
        desc: 'Type the username in the field above (without @ symbol).',
      ),
      (
        icon: Icons.gps_fixed_rounded,
        color: _TXC.purpleG1,
        title: '3. Hit Stalk',
        desc: 'Tap the button and wait for the profile data to load.',
      ),
      (
        icon: Icons.data_usage_rounded,
        color: _TXC.gold,
        title: '4. View Results',
        desc: 'See followers, tweets, likes, bio, join date, and more.',
      ),
      (
        icon: Icons.fingerprint_rounded,
        color: _TXC.tealG1,
        title: '5. Verify Data',
        desc: 'Cross-check the results with the actual profile for accuracy.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _TXC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _TXC.border2, width: 0.5),
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
                    colors: [_TXC.gold, _TXC.orangeG1],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.help_outline_rounded,
                color: _TXC.gold,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'How to Use',
                style: TextStyle(
                  fontFamily: _kFontPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _TXC.text,
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
                              color: _TXC.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.desc,
                            style: TextStyle(
                              fontFamily: _kFontMono,
                              fontSize: 11,
                              color: _TXC.muted,
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
  // PROFILE CARD — Header row with icon+title+badge, divider, verified/blue
  //                  badge, pulse avatar, display name, @username, bio quote
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProfileCard() {
    final user = _result!.user;
    final core = user.core;
    final legacy = user.legacy;

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
            color: _TXC.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _TXC.border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: _TXC.accent.withOpacity(0.06),
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
                        colors: [_TXC.accent, _TXC.accent3],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.person_search_rounded,
                    color: _TXC.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Profile Found',
                    style: TextStyle(
                      fontFamily: _kFontPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _TXC.text,
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
                      color: _TXC.greenG1.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _TXC.greenG1.withOpacity(0.3),
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
                            color: _TXC.greenG1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: TextStyle(
                            fontFamily: _kFontMono,
                            fontSize: 10,
                            color: _TXC.greenG1,
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
                color: _TXC.border2,
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
                                _TXC.accent,
                                _TXC.accent2,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _TXC.accent.withOpacity(0.2 + pulse * 0.15),
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
                                color: _TXC.bg,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                user.avatarUrl.isNotEmpty
                                    ? user.avatarUrl
                                    : '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: _TXC.surface,
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: _TXC.muted,
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
                    // Display name with verified/blue badges
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          core.name.isNotEmpty ? core.name : 'N/A',
                          style: const TextStyle(
                            fontFamily: _kFontPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _TXC.text,
                            letterSpacing: 0.3,
                          ),
                        ),
                        // Verified badge
                        if (user.verified) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _TXC.accent.withOpacity(0.15),
                              border: Border.all(
                                color: _TXC.accent,
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: _TXC.accent,
                              size: 14,
                            ),
                          ),
                        ],
                        // Blue verified badge
                        if (user.isBlueVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _TXC.blueG1.withOpacity(0.15),
                              border: Border.all(
                                color: _TXC.blueG1,
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.alternate_email_rounded,
                              color: _TXC.blueG1,
                              size: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // @username
                    Text(
                      core.screenName.isNotEmpty
                          ? '@${core.screenName}'
                          : '@unknown',
                      style: const TextStyle(
                        fontFamily: _kFontMono,
                        fontSize: 13,
                        color: _TXC.accent2,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bio quote
                    if (legacy.description.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _TXC.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _TXC.border2,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.format_quote_rounded,
                              color: _TXC.accent.withOpacity(0.5),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                legacy.description,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontFamily: _kFontMono,
                                  fontSize: 12,
                                  color: _TXC.muted,
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
  // STATS GRID — 4 stat boxes: Followers (blue), Following (gray-blue),
  //               Likes (red), Tweets (cyan)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsGrid() {
    final legacy = _result!.user.legacy;
    final statItems = [
      (
        icon: Icons.group_rounded,
        label: 'Followers',
        value: _formatCount(legacy.followersCount),
        color: _TXC.blueG1,
        bgColor: _TXC.blueG1.withOpacity(0.1),
      ),
      (
        icon: Icons.person_add_rounded,
        label: 'Following',
        value: _formatCount(legacy.friendsCount),
        color: _TXC.accent2,
        bgColor: _TXC.accent2.withOpacity(0.1),
      ),
      (
        icon: Icons.favorite_rounded,
        label: 'Likes',
        value: _formatCount(legacy.favouritesCount),
        color: _TXC.redG1,
        bgColor: _TXC.redG1.withOpacity(0.1),
      ),
      (
        icon: Icons.mode_comment_rounded,
        label: 'Tweets',
        value: _formatCount(legacy.statusesCount),
        color: _TXC.cyanG1,
        bgColor: _TXC.cyanG1.withOpacity(0.1),
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
                color: _TXC.card,
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
                    style: const TextStyle(
                      fontFamily: _kFontPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _TXC.text,
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
                      color: _TXC.muted,
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
  // DETAILS CARD — Rest ID, Media count, Joined date with 34x34 icon boxes
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDetailsCard() {
    final user = _result!.user;
    final legacy = user.legacy;

    final details = [
      (
        icon: Icons.fingerprint_rounded,
        color: _TXC.accent,
        label: 'Rest ID',
        value: user.restId.isNotEmpty ? user.restId : 'N/A',
      ),
      (
        icon: Icons.image_rounded,
        color: _TXC.purpleG1,
        label: 'Media Count',
        value: legacy.mediaCount.toString(),
      ),
      (
        icon: Icons.calendar_today_rounded,
        color: _TXC.gold,
        label: 'Joined',
        value: _parseTwitterDate(user.core.createdAt),
      ),
      (
        icon: Icons.mode_comment_rounded,
        color: _TXC.cyanG1,
        label: 'Total Tweets',
        value: _formatCount(legacy.statusesCount),
      ),
      (
        icon: Icons.favorite_rounded,
        color: _TXC.redG1,
        label: 'Total Likes',
        value: _formatCount(legacy.favouritesCount),
      ),
      (
        icon: Icons.verified_rounded,
        color: user.verified ? _TXC.accent : _TXC.muted2,
        label: 'Verification',
        value: user.verified
            ? 'Verified'
            : (user.isBlueVerified ? 'Blue Verified' : 'Unverified'),
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
            color: _TXC.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _TXC.border2, width: 0.5),
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
                        colors: [_TXC.accent2, _TXC.cyanG1],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.info_outline_rounded,
                    color: _TXC.accent2,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Profile Details',
                    style: TextStyle(
                      fontFamily: _kFontPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _TXC.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                thickness: 0.5,
                color: _TXC.border2,
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
                            color: _TXC.muted,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const Spacer(),
                        // Value
                        Flexible(
                          child: Text(
                            detail.value,
                            style: const TextStyle(
                              fontFamily: _kFontPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _TXC.text,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
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
  // BACK BUTTON — "STALK LAGI"
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
              _TXC.accent.withOpacity(0.15),
              _TXC.accent2.withOpacity(0.15),
            ],
          ),
          border: Border.all(
            color: _TXC.accent.withOpacity(0.25),
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
                    color: _TXC.accent2,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'STALK LAGI',
                    style: TextStyle(
                      fontFamily: _kFontPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _TXC.accent2,
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
  // ERROR VIEW — Circle warning icon, error message, gradient retry
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
                color: _TXC.danger.withOpacity(0.1),
                border: Border.all(
                  color: _TXC.danger.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _TXC.danger.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: _TXC.danger,
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
                  color: _TXC.muted,
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
                  colors: [_TXC.accent, _TXC.accent2],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _TXC.accent.withOpacity(0.25),
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
    final baseColor = _TXC.surface;
    final highlightColor = _TXC.card;

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
              color: _TXC.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _TXC.border2, width: 0.5),
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
                        color: _TXC.muted2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _TXC.muted2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _TXC.muted2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: _TXC.border2,
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
                          color: _TXC.muted2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: 120,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _TXC.muted2,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _TXC.muted2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 200,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _TXC.muted2,
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
                  color: _TXC.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _TXC.border2, width: 0.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _TXC.muted2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _TXC.muted2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 50,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _TXC.muted2,
                        borderRadius: BorderRadius.circular(4),
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
              color: _TXC.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _TXC.border2, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header skeleton
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: _TXC.muted2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _TXC.muted2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 90,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _TXC.muted2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: _TXC.border2,
                ),
                const SizedBox(height: 14),
                // Detail row skeletons
                ...List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _TXC.muted2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 70,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _TXC.muted2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 100,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _TXC.muted2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

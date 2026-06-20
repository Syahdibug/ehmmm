import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// YouTube Stalker Page — Production-Quality Flutter Widget
// Color scheme: YouTube red dark theme
// Icons: Material ONLY (no FontAwesome)
// Fonts: MADEEvolveSansEVO + ShareTechMono
// ─────────────────────────────────────────────────────────────────────────────

// ═══════════════════════════════════════════════════════════════════════════════
// COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════════
class _YTC {
  static const bg       = Color(0xFF0F0F0F);
  static const bg2      = Color(0xFF151515);
  static const surface  = Color(0xFF1A1A1A);
  static const card     = Color(0xFF212121);
  static const accent   = Color(0xFFFF0000); // YouTube red
  static const accent2  = Color(0xFFCC0000); // Dark red
  static const accent3  = Color(0xFFFF4444); // Light red
  static const gold     = Color(0xFFFFD447);
  static const danger   = Color(0xFFFF4D6D);
  static const text     = Color(0xFFF1F1F1);
  static const muted    = Color(0x88F1F1F1);
  static const muted2   = Color(0x33F1F1F1);
  static const border   = Color(0x22FF0000);
  static const border2  = Color(0x14FFFFFF);
  static const greenG1  = Color(0xFF25D366);
  static const blueG1   = Color(0xFF229ED9);
  static const purpleG1 = Color(0xFF9C27B0);
  static const orangeG1  = Color(0xFFFF8C00);
  static const cyanG1   = Color(0xFF00BCD4);
  static const tealG1   = Color(0xFF009688);
  static const redG1    = Color(0xFFFF4D6D);
}

// ═══════════════════════════════════════════════════════════════════════════════
// FONT CONSTANTS
// ═══════════════════════════════════════════════════════════════════════════════
const _kFontPrimary = 'MADEEvolveSansEVO';
const _kFontMono = 'ShareTechMono';

// ═══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _YTChannel {
  final String username;
  final String name;
  final int subscriberCount;
  final int videoCount;
  final String avatarUrl;
  final String channelUrl;
  final String description;

  const _YTChannel({
    required this.username,
    required this.name,
    required this.subscriberCount,
    required this.videoCount,
    required this.avatarUrl,
    required this.channelUrl,
    required this.description,
  });

  factory _YTChannel.fromJson(Map<String, dynamic> json) {
    return _YTChannel(
      username: json['username'] as String? ?? '',
      name: json['name'] as String? ?? '',
      subscriberCount: json['subscriberCount'] as int? ?? 0,
      videoCount: json['videoCount'] as int? ?? 0,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      channelUrl: json['channelUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class _YTVideo {
  final String title;
  final String videoId;

  const _YTVideo({
    required this.title,
    required this.videoId,
  });

  factory _YTVideo.fromJson(Map<String, dynamic> json) {
    return _YTVideo(
      title: json['title'] as String? ?? 'Untitled',
      videoId: json['videoId'] as String? ?? '',
    );
  }
}

class _StalkResult {
  final _YTChannel channel;
  final List<_YTVideo> latestVideos;

  const _StalkResult({
    required this.channel,
    required this.latestVideos,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class StalkYouTubePage extends StatefulWidget {
  const StalkYouTubePage({super.key});

  @override
  State<StalkYouTubePage> createState() => _StalkYouTubePageState();
}

class _StalkYouTubePageState extends State<StalkYouTubePage>
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
  Future<void> _stalkChannel() async {
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
        'https://api.siputzx.my.id/api/stalk/youtube?username=$username',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned status ${response.statusCode}. Please try again.',
        );
      }

      final body = json.decode(response.body) as Map<String, dynamic>;

      if (body['status'] != true) {
        throw Exception('Channel "$username" not found on YouTube.');
      }

      final data = body['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Unexpected response format. Please try again.');
      }

      final channelData = data['channel'] as Map<String, dynamic>?;
      final videosData = data['latest_videos'] as List<dynamic>?;

      if (channelData == null) {
        throw Exception('Incomplete channel data received.');
      }

      final channel = _YTChannel.fromJson(channelData);
      final videos = videosData
              ?.map((v) => _YTVideo.fromJson(v as Map<String, dynamic>))
              .toList() ??
          [];

      setState(() {
        _result = _StalkResult(channel: channel, latestVideos: videos);
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

  // ── URL Launcher ─────────────────────────────────────────────────────────
  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _YTC.bg,
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
                      if (_result!.channel.description.isNotEmpty) ...[
                        _buildDescriptionCard(),
                        const SizedBox(height: 16),
                      ],
                      if (_result!.latestVideos.isNotEmpty) ...[
                        _buildLatestVideosCard(),
                        const SizedBox(height: 16),
                      ],
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
                  color: _YTC.bg.withOpacity(0.7),
                  border: Border(
                    bottom: BorderSide(
                      color: _YTC.border2,
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
                        color: _YTC.surface,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: _YTC.border2, width: 0.5),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: _YTC.text,
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
                        colors: [_YTC.accent, _YTC.accent3],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.srcIn,
                    child: const Text(
                      'YouTube Stalker',
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
                              _YTC.accent
                                  .withOpacity(0.15 + value * 0.1),
                              _YTC.accent2
                                  .withOpacity(0.15 + value * 0.1),
                            ],
                          ),
                          border: Border.all(
                            color: _YTC.accent.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.play_circle_filled_rounded,
                          color: _YTC.accent,
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
  // HERO BANNER — Play circle icon (animated glow), "YOUTUBE STALKER", desc
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroBanner() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            // Animated glow circle with play icon
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
                        _YTC.accent
                            .withOpacity(0.08 + glow * 0.12),
                        _YTC.accent3
                            .withOpacity(0.08 + glow * 0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            _YTC.accent.withOpacity(glow * 0.35),
                        blurRadius: 24 + glow * 16,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: _YTC.accent3
                            .withOpacity(glow * 0.25),
                        blurRadius: 20 + glow * 12,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: _YTC.accent
                          .withOpacity(0.2 + glow * 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_filled_rounded,
                      color: _YTC.accent,
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
                  colors: [_YTC.accent, _YTC.accent3, _YTC.accent],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: const Text(
                'YOUTUBE STALKER',
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
              'Enter a YouTube channel username to reveal their\nsubscriber count, videos, description, and more.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _kFontMono,
                fontSize: 12,
                color: _YTC.muted,
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
        color: _YTC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _YTC.border, width: 0.5),
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
                    colors: [_YTC.accent, _YTC.accent2],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.input_rounded,
                color: _YTC.accent2,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Target Channel',
                style: TextStyle(
                  fontFamily: _kFontPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _YTC.text,
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
              color: _YTC.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isInputFocused ? _YTC.accent : _YTC.border2,
                width: _isInputFocused ? 1.5 : 0.5,
              ),
              boxShadow: _isInputFocused
                  ? [
                      BoxShadow(
                        color: _YTC.accent.withOpacity(0.15),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: _YTC.accent3.withOpacity(0.08),
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
                color: _YTC.text,
                letterSpacing: 0.5,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. AiKeche',
                hintStyle: TextStyle(
                  fontFamily: _kFontMono,
                  fontSize: 13,
                  color: _YTC.muted2,
                  letterSpacing: 0.5,
                ),
                prefixIcon: const Icon(
                  Icons.play_circle_filled_rounded,
                  color: _YTC.accent,
                  size: 20,
                ),
                suffixIcon: _usernameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _YTC.muted,
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
              onSubmitted: (_) => _stalkChannel(),
              textInputAction: TextInputAction.go,
            ),
          ),
          const SizedBox(height: 10),
          // Info tip
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: _YTC.accent2,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Enter the YouTube channel username without the @ symbol.',
                  style: TextStyle(
                    fontFamily: _kFontMono,
                    fontSize: 11,
                    color: _YTC.muted,
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
  // STALK BUTTON — Red gradient, disabled state with muted colors
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
                    _YTC.accent.withOpacity(0.3),
                    _YTC.accent3.withOpacity(0.3),
                  ],
                )
              : const LinearGradient(
                  colors: [Color(0xFFFF0000), Color(0xFFFF4444)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          boxShadow: isEmpty
              ? []
              : [
                  BoxShadow(
                    color: _YTC.accent.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: _YTC.accent3.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isEmpty ? null : _stalkChannel,
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
                          ? _YTC.muted.withOpacity(0.6)
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
        color: _YTC.accent,
        title: '1. Find Channel',
        desc: 'Get the target\'s YouTube @username from their channel URL.',
      ),
      (
        icon: Icons.input_rounded,
        color: _YTC.accent3,
        title: '2. Enter Username',
        desc: 'Type the username in the field above (without @ symbol).',
      ),
      (
        icon: Icons.gps_fixed_rounded,
        color: _YTC.purpleG1,
        title: '3. Hit Stalk',
        desc: 'Tap the button and wait for the channel data to load.',
      ),
      (
        icon: Icons.data_usage_rounded,
        color: _YTC.gold,
        title: '4. View Results',
        desc: 'See subscriber count, video count, description, and more.',
      ),
      (
        icon: Icons.movie_rounded,
        color: _YTC.orangeG1,
        title: '5. Watch Videos',
        desc: 'Browse the latest 5 videos directly from the results.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _YTC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _YTC.border2, width: 0.5),
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
                    colors: [_YTC.gold, _YTC.orangeG1],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.help_outline_rounded,
                color: _YTC.gold,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'How to Use',
                style: TextStyle(
                  fontFamily: _kFontPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _YTC.text,
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
                              color: _YTC.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.desc,
                            style: TextStyle(
                              fontFamily: _kFontMono,
                              fontSize: 11,
                              color: _YTC.muted,
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
  // PROFILE CARD (result) — Header row with icon+title+"CHANNEL" badge,
  //                          divider, animated pulse avatar, channel name,
  //                          @username, "Buka di YouTube" button
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProfileCard() {
    final channel = _result!.channel;

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
            color: _YTC.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _YTC.border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: _YTC.accent.withOpacity(0.06),
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
                        colors: [_YTC.accent, _YTC.accent3],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.play_circle_filled_rounded,
                    color: _YTC.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Channel Found',
                    style: TextStyle(
                      fontFamily: _kFontPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _YTC.text,
                    ),
                  ),
                  const Spacer(),
                  // CHANNEL badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _YTC.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _YTC.accent.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: _YTC.accent,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CHANNEL',
                          style: TextStyle(
                            fontFamily: _kFontMono,
                            fontSize: 10,
                            color: _YTC.accent,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
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
                color: _YTC.border2,
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
                            gradient: const LinearGradient(
                              colors: [_YTC.accent, _YTC.accent2],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _YTC.accent.withOpacity(0.2 + pulse * 0.15),
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
                                color: _YTC.bg,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: channel.avatarUrl.isNotEmpty
                                  ? Image.network(
                                      channel.avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                        color: _YTC.surface,
                                        child: const Icon(
                                          Icons
                                              .play_circle_filled_rounded,
                                          color: _YTC.muted,
                                          size: 40,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: _YTC.surface,
                                      child: const Icon(
                                        Icons
                                            .play_circle_filled_rounded,
                                        color: _YTC.muted,
                                        size: 40,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    // Channel Name (shader mask)
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [_YTC.accent, _YTC.accent3],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        channel.name.isNotEmpty
                            ? channel.name
                            : channel.username,
                        style: const TextStyle(
                          fontFamily: _kFontPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Username
                    Text(
                      channel.username.isNotEmpty
                          ? channel.username
                          : '@unknown',
                      style: const TextStyle(
                        fontFamily: _kFontMono,
                        fontSize: 13,
                        color: _YTC.accent3,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // "Buka di YouTube" button
                    if (channel.channelUrl.isNotEmpty)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () =>
                              _launchUrl(channel.channelUrl),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _YTC.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _YTC.accent.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.open_in_new_rounded,
                                  color: _YTC.accent,
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Buka di YouTube',
                                  style: TextStyle(
                                    fontFamily: _kFontPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _YTC.accent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
  // STATS GRID — 2 stat boxes (Subscribers, Videos)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsGrid() {
    final channel = _result!.channel;
    final statItems = [
      (
        icon: Icons.group_rounded,
        label: 'SUBSCRIBERS',
        value: _formatCount(channel.subscriberCount),
        color: _YTC.accent,
        bgColor: _YTC.accent.withOpacity(0.1),
      ),
      (
        icon: Icons.videocam_rounded,
        label: 'VIDEOS',
        value: _formatCount(channel.videoCount),
        color: _YTC.accent3,
        bgColor: _YTC.accent3.withOpacity(0.1),
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
        child: Row(
          children: statItems.map((item) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: statItems.indexOf(item) == 0 ? 0 : 6,
                  right: statItems.indexOf(item) == statItems.length - 1
                      ? 0
                      : 6,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: _YTC.card,
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
                      const SizedBox(height: 12),
                      // Value
                      Text(
                        item.value,
                        style: TextStyle(
                          fontFamily: _kFontPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: item.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Label
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: _kFontMono,
                          fontSize: 11,
                          color: _YTC.muted,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DESCRIPTION CARD — Section label, channel description text
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDescriptionCard() {
    final channel = _result!.channel;

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
            color: _YTC.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _YTC.border2, width: 0.5),
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
                        colors: [_YTC.accent, _YTC.accent3],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.description_rounded,
                    color: _YTC.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Channel Description',
                    style: TextStyle(
                      fontFamily: _kFontPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _YTC.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Divider
              Divider(
                height: 1,
                thickness: 0.5,
                color: _YTC.border2,
              ),
              const SizedBox(height: 14),
              // Description text
              Text(
                channel.description,
                style: TextStyle(
                  fontFamily: _kFontMono,
                  fontSize: 12,
                  color: _YTC.muted,
                  height: 1.6,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LATEST VIDEOS CARD — List of latest 5 videos with play icon, title,
  //                        open link button
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLatestVideosCard() {
    final videos = _result!.latestVideos;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
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
            color: _YTC.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _YTC.border2, width: 0.5),
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
                        colors: [_YTC.accent, _YTC.accent3],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.movie_rounded,
                    color: _YTC.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Latest Videos',
                    style: TextStyle(
                      fontFamily: _kFontPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _YTC.text,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _YTC.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _YTC.accent.withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      '${videos.length} video${videos.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontFamily: _kFontMono,
                        fontSize: 10,
                        color: _YTC.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Divider
              Divider(
                height: 1,
                thickness: 0.5,
                color: _YTC.border2,
              ),
              const SizedBox(height: 14),
              // Video list
              ...videos.take(5).map((video) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: video.videoId.isNotEmpty
                            ? () => _launchUrl(
                                'https://youtube.com/watch?v=${video.videoId}',
                              )
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _YTC.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _YTC.border2,
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Play icon
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _YTC.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: _YTC.accent,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Title
                              Expanded(
                                child: Text(
                                  video.title,
                                  style: const TextStyle(
                                    fontFamily: _kFontPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _YTC.text,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Open link icon
                              if (video.videoId.isNotEmpty)
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: _YTC.accent.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Icon(
                                    Icons.open_in_new_rounded,
                                    color: _YTC.muted,
                                    size: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
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
              _YTC.accent.withOpacity(0.15),
              _YTC.accent2.withOpacity(0.15),
            ],
          ),
          border: Border.all(
            color: _YTC.accent.withOpacity(0.25),
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
                    Icons.arrow_back_rounded,
                    color: _YTC.accent3,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'STALK LAGI',
                    style: TextStyle(
                      fontFamily: _kFontPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _YTC.accent3,
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
  // ERROR VIEW — Warning circle, error message, gradient retry
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
                color: _YTC.danger.withOpacity(0.1),
                border: Border.all(
                  color: _YTC.danger.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _YTC.danger.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: _YTC.danger,
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
                  color: _YTC.muted,
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
                  colors: [_YTC.accent, _YTC.accent3],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _YTC.accent.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _stalkChannel,
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
    final baseColor = _YTC.surface;
    final highlightColor = _YTC.card;

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
              color: _YTC.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _YTC.border2, width: 0.5),
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
                        color: _YTC.muted2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _YTC.muted2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _YTC.muted2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: _YTC.border2,
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
                          color: _YTC.muted2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: 140,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _YTC.muted2,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 80,
                        height: 14,
                        decoration: BoxDecoration(
                          color: _YTC.muted2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 140,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _YTC.muted2,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Skeleton stats grid (2 boxes)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: _YTC.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _YTC.border2, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _YTC.muted2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 60,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _YTC.muted2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 70,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _YTC.muted2,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: _YTC.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _YTC.border2, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _YTC.muted2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 60,
                        height: 18,
                        decoration: BoxDecoration(
                          color: _YTC.muted2,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 50,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _YTC.muted2,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Skeleton description card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _YTC.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _YTC.border2, width: 0.5),
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
                        color: _YTC.muted2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _YTC.muted2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _YTC.muted2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: _YTC.border2,
                ),
                const SizedBox(height: 14),
                // Description lines skeleton
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _YTC.muted2,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 250,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _YTC.muted2,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _YTC.muted2,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Skeleton latest videos card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _YTC.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _YTC.border2, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: _YTC.muted2,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _YTC.muted2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 90,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _YTC.muted2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: _YTC.border2,
                ),
                const SizedBox(height: 14),
                // Video row skeletons
                ...List.generate(3, (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _YTC.muted2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: _YTC.muted2,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _YTC.muted2,
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

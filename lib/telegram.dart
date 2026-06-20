// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TelegramSpamPage extends StatefulWidget {
  final String sessionKey;

  const TelegramSpamPage({super.key, required this.sessionKey});

  @override
  State<TelegramSpamPage> createState() => _TelegramSpamPageState();
}

class _TelegramSpamPageState extends State<TelegramSpamPage>
    with SingleTickerProviderStateMixin {
  // --- Controllers ---
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _authController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _reportTextController = TextEditingController(
    text:
        "This account is violating Telegram's terms of service through spam and scam activities.",
  );
  final TextEditingController _reportLinkController = TextEditingController();
  final TextEditingController _reportCountController = TextEditingController(
    text: "50",
  );

  // Controller untuk password manual di session
  final Map<String, TextEditingController> _sessionPasswordControllers = {};

  // Video Controller
  VideoPlayerController? _videoController;

  // --- State Variables ---
  List<TelegramSession> _sessions = [];
  bool _isLoading = false;
  bool _isLoggingIn = false;
  bool _isRefreshing = false;
  bool _isReporting = false;

  // State untuk login
  String _currentLoginPhone = "";
  String _currentLoginId = "";
  String _loginErrorMessage = "";
  String _currentLoginStep = "wait_code";
  bool _canResendOtp = true;
  int _resendOtpCooldown = 30;

  // Report State
  int _reportProgress = 0;
  int _reportTotal = 0;
  String _reportStatus = "";
  String _currentReportId = "";
  Timer? _statusCheckTimer;
  Timer? _resendOtpTimer;
  Timer? _loginStatusTimer;

  // --- UI Controller ---
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Premium Color Theme
  final Color _primaryColor = const Color(0xFF00E5FF); // Cyan Neon
  final Color _secondaryColor = const Color(0xFF7C4DFF); // Purple
  final Color _accentColor = const Color(0xFFFF3366); // Pink/Red
  final Color _cardColor = const Color(0xFF1A1A2E);

  // Animation
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging || _tabController.animation != null) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    _initializeAnimations();
    _loadSessions();
    _initVideoBackground();
  }

  void _initializeAnimations() {
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowController.repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A0E27),
                  const Color(0xFF1A1A3E),
                  const Color(0xFF000000),
                ],
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.85),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _resendOtpTimer?.cancel();
    _loginStatusTimer?.cancel();
    _tabController.dispose();
    _glowController.dispose();
    _phoneController.dispose();
    _authController.dispose();
    _targetController.dispose();
    _reportTextController.dispose();
    _reportLinkController.dispose();
    _reportCountController.dispose();
    _videoController?.dispose();
    for (var controller in _sessionPasswordControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- API Calls (TETAP UTUH) ---
  Future<void> _loadSessions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'http://104.207.64.203:2001/api/tools/telegram/sessions?key=${widget.sessionKey}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _sessions = (data['sessions'] as List)
                .map((session) => TelegramSession.fromJson(session))
                .toList();
            _isLoading = false;
          });

          for (var session in _sessions) {
            _sessionPasswordControllers.putIfAbsent(
              session.phone,
              () => TextEditingController(),
            );
          }
        } else {
          if (mounted)
            _showSnackBar(
              data['message'] ?? 'Failed to load sessions',
              isError: true,
            );
          setState(() => _isLoading = false);
        }
      } else {
        if (mounted)
          _showSnackBar('Server error: ${response.statusCode}', isError: true);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted)
        _showSnackBar('Error loading sessions: ${e.toString()}', isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initiateLogin({bool isResend = false}) async {
    if (!isResend && _phoneController.text.trim().isEmpty) {
      setState(() => _loginErrorMessage = "Please enter a phone number.");
      return;
    }
    setState(() {
      _isLoggingIn = true;
      _loginErrorMessage = "";
    });

    try {
      final phone = _currentLoginPhone.isEmpty
          ? _phoneController.text.trim()
          : _currentLoginPhone;
      final response = await http.get(
        Uri.parse(
          'http://104.207.64.203:2001/api/tools/telegram/login?key=${widget.sessionKey}&phone=$phone',
        ),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _currentLoginPhone = phone;
            _currentLoginId = data['loginId'];
            _currentLoginStep = data['step'] ?? 'wait_code';
            _isLoggingIn = false;
          });
          _authController.clear();
          if (isResend) {
            if (mounted) _showSnackBar('OTP code resent');
          } else {
            if (mounted) _showSnackBar('OTP code sent to your phone');
            Navigator.of(context).pop();
            _showAuthDialog();
          }
          _startLoginStatusPolling();
        } else {
          setState(() {
            _loginErrorMessage = data['message'] ?? 'Failed to initiate login';
            _isLoggingIn = false;
          });
        }
      } else {
        setState(() {
          _loginErrorMessage = 'Server error: ${response.statusCode}';
          _isLoggingIn = false;
        });
      }
    } catch (e) {
      setState(() {
        _loginErrorMessage = 'Error: ${e.toString()}';
        _isLoggingIn = false;
      });
    }
  }

  Future<void> _submitAuth() async {
    if (_authController.text.trim().isEmpty) {
      setState(() => _loginErrorMessage = "Please enter the code or password.");
      return;
    }
    setState(() {
      _isLoggingIn = true;
      _loginErrorMessage = "";
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://104.207.64.203:2001/api/tools/telegram/auth?key=${widget.sessionKey}&loginId=$_currentLoginId&input=${_authController.text.trim()}',
        ),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _currentLoginStep = data['step'] ?? 'completed';
            _isLoggingIn = false;
          });

          if (_currentLoginStep == 'wait_password') {
            _authController.clear();
            if (mounted)
              _showSnackBar('OTP verified. Please enter your 2FA password.');
            return;
          } else if (_currentLoginStep == 'completed') {
            _handleLoginSuccess();
            return;
          }
        } else {
          setState(() {
            _loginErrorMessage = data['message'] ?? 'Failed to verify';
            _isLoggingIn = false;
          });
        }
      } else {
        setState(() {
          _loginErrorMessage = 'Server error: ${response.statusCode}';
          _isLoggingIn = false;
        });
      }
    } catch (e) {
      setState(() {
        _loginErrorMessage = 'Error: ${e.toString()}';
        _isLoggingIn = false;
      });
    }
  }

  void _startLoginStatusPolling() {
    _loginStatusTimer?.cancel();
    _loginStatusTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      try {
        final response = await http.get(
          Uri.parse(
            'http://104.207.64.203:2001/api/tools/telegram/status?key=${widget.sessionKey}&loginId=$_currentLoginId',
          ),
        );
        final data = jsonDecode(response.body);
        if (data['valid'] == true && data['completed'] == true) {
          timer.cancel();
          _handleLoginSuccess();
        }
      } catch (e) {
        // Continue polling
      }
    });
  }

  Future<void> _verifySessionPassword(String phone) async {
    final passwordController = _sessionPasswordControllers[phone];
    if (passwordController == null || passwordController.text.trim().isEmpty) {
      _showSnackBar('Please enter 2FA password', isError: true);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(
          'http://104.207.64.203:2001/api/tools/telegram/verify-session-password',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': widget.sessionKey,
          'phone': phone,
          'password': passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (data['valid'] == true) {
        _showSnackBar('Session verified successfully');
        passwordController.clear();
        _loadSessions();
      } else {
        _showSnackBar(
          data['message'] ?? 'Failed to verify session',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  void _handleLoginSuccess() {
    _loginStatusTimer?.cancel();
    if (mounted) _showSnackBar('Login successful! Session saved.');
    _phoneController.clear();
    _authController.clear();
    Navigator.of(context).pop();
    _resetLoginState();
    _loadSessions();
  }

  void _resetLoginState() {
    _loginStatusTimer?.cancel();
    setState(() {
      _currentLoginPhone = "";
      _currentLoginId = "";
      _currentLoginStep = "wait_code";
      _isLoggingIn = false;
      _loginErrorMessage = "";
    });
  }

  void _startResendOtpCooldown() {
    setState(() {
      _canResendOtp = false;
    });
    _resendOtpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendOtpCooldown--;
      });
      if (_resendOtpCooldown <= 0) {
        timer.cancel();
        setState(() {
          _canResendOtp = true;
          _resendOtpCooldown = 30;
        });
      }
    });
  }

  Future<void> _refreshSessions() async {
    setState(() => _isRefreshing = true);
    try {
      final response = await http.get(
        Uri.parse(
          'http://104.207.64.203:2001/api/tools/telegram/refresh-sessions?key=${widget.sessionKey}',
        ),
      );
      final data = jsonDecode(response.body);
      if (data['valid'] == true) {
        if (mounted)
          _showSnackBar(
            'Sessions refreshed. ${data['inactiveSessions'].length} inactive sessions removed.',
          );
        _loadSessions();
      } else {
        if (mounted)
          _showSnackBar(
            data['message'] ?? 'Failed to refresh sessions',
            isError: true,
          );
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: ${e.toString()}', isError: true);
    }
    setState(() => _isRefreshing = false);
  }

  Future<void> _deleteSession(String phone) async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://104.207.64.203:2001/api/tools/telegram/remove-ses?key=${widget.sessionKey}&phone=$phone',
        ),
      );
      final data = jsonDecode(response.body);
      if (data['valid'] == true) {
        if (mounted) _showSnackBar('Session deleted');
        _sessionPasswordControllers.remove(phone)?.dispose();
        _loadSessions();
      } else {
        if (mounted)
          _showSnackBar(
            data['message'] ?? 'Failed to delete session',
            isError: true,
          );
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  Future<void> _startSpamReport() async {
    if (_targetController.text.trim().isEmpty) {
      _showSnackBar(
        'Please enter a target (username or user ID)',
        isError: true,
      );
      return;
    }
    if (_sessions.isEmpty) {
      _showSnackBar('No active sessions available', isError: true);
      return;
    }

    final reportCount = int.tryParse(_reportCountController.text) ?? 50;
    if (reportCount <= 0 || reportCount > 1000) {
      _showSnackBar('Report count must be between 1 and 1000', isError: true);
      return;
    }

    setState(() {
      _isReporting = true;
      _reportProgress = 0;
      _reportTotal = _sessions.length * 10;
      _reportStatus = "Initializing...";
    });

    try {
      final response = await http.post(
        Uri.parse('http://104.207.64.203:2001/api/tools/telegram/spam-report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'key': widget.sessionKey,
          'target': _targetController.text.trim(),
          'count': reportCount,
          'message': _reportTextController.text.trim(),
          'link': _reportLinkController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (data['valid'] == true) {
        setState(() => _currentReportId = data['reportId']);
        _startStatusPolling();
        if (mounted) _showSnackBar('Spam report started successfully!');
      } else {
        if (mounted)
          _showSnackBar(
            data['message'] ?? 'Failed to start spam report',
            isError: true,
          );
        setState(() => _isReporting = false);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: ${e.toString()}', isError: true);
      setState(() => _isReporting = false);
    }
  }

  void _startStatusPolling() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) async {
      try {
        final response = await http.get(
          Uri.parse(
            'http://104.207.64.203:2001/api/tools/telegram/report-status?key=${widget.sessionKey}&reportId=$_currentReportId',
          ),
        );
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          final report = data['report'];
          if (mounted) {
            setState(() {
              _reportProgress = report['progress'] ?? 0;
              _reportTotal = report['total'] ?? 0;
              _reportStatus = report['status'] ?? "Processing...";
            });
          }
          if (report['completed'] == true) {
            timer.cancel();
            setState(() => _isReporting = false);
            if (mounted) _showCompletionDialog(report['status']);
          }
        }
      } catch (e) {
        // Continue polling
      }
    });
  }

  // --- UI Helpers ---
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'ShareTechMono'),
        ),
        backgroundColor: isError
            ? _accentColor.withOpacity(0.9)
            : _primaryColor.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showCompletionDialog(String status) {
    final bool isBanned =
        status.contains('frozen') || status.contains('banned');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: _primaryColor.withOpacity(0.4), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isBanned
                      ? [_primaryColor, _secondaryColor]
                      : [_accentColor, const Color(0xFFE91E63)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isBanned ? Icons.check_circle : Icons.info,
                color: Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Report Completed",
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'MADEEvolveSansEVO',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'ShareTechMono',
              ),
            ),
            if (isBanned) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: _primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Target successfully frozen!",
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryColor, _secondaryColor],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "CLOSE",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MADEEvolveSansEVO',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _primaryColor.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.2 * _glowAnimation.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _buildGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryColor, _secondaryColor],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.telegram,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "TELEGRAM SPAM",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: "MADEEvolveSansEVO",
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_sessions.length} Active Sessions",
                            style: TextStyle(
                              color: _primaryColor.withOpacity(0.8),
                              fontSize: 12,
                              fontFamily: "ShareTechMono",
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.refresh, color: _primaryColor),
                      onPressed: _isRefreshing ? null : _refreshSessions,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: _buildGlassCard(
        child: Row(
          children: [
            _buildTabItem("SESSIONS", 0, Icons.phone_android),
            _buildTabItem("REPORT", 1, Icons.report),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, int index, IconData icon) {
    final bool isActive = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() => _currentTabIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(colors: [_primaryColor, _secondaryColor])
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.black : Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MADEEvolveSansEVO',
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _showPhoneDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  "ADD SESSION",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'MADEEvolveSansEVO',
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                )
              : _sessions.isEmpty
              ? _buildEmptyState(
                  'No Sessions',
                  'Add a Telegram account to start spamming',
                  FontAwesomeIcons.telegram,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return _buildSessionCard(session);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(TelegramSession session) {
    final isActive = session.isActive;
    final passwordController =
        _sessionPasswordControllers[session.phone] ?? TextEditingController();
    bool showPasswordInput = false;

    return StatefulBuilder(
      builder: (context, setStateCard) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildGlassCard(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? LinearGradient(
                              colors: [_primaryColor, _secondaryColor],
                            )
                          : LinearGradient(
                              colors: [_accentColor, const Color(0xFFE91E63)],
                            ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      FontAwesomeIcons.telegram,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    session.phone,
                    style: TextStyle(
                      color: isActive ? Colors.white : _accentColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ShareTechMono',
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    'Last active: ${_formatDate(session.lastModified)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          showPasswordInput
                              ? Icons.keyboard_arrow_up
                              : FontAwesomeIcons.lock,
                          color: Colors.white70,
                          size: 18,
                        ),
                        onPressed: () => setStateCard(
                          () => showPasswordInput = !showPasswordInput,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFFF3366),
                        ),
                        onPressed: () => _deleteSession(session.phone),
                      ),
                    ],
                  ),
                ),
                if (showPasswordInput)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Enter 2FA password',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: _primaryColor.withOpacity(0.6),
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.4),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () =>
                              _verifySessionPassword(session.phone),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "VERIFY",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'MADEEvolveSansEVO',
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primaryColor, _secondaryColor],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "REPORT CONFIGURATION",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: "MADEEvolveSansEVO",
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildPremiumInputField(
                    icon: Icons.person,
                    label: "Target",
                    hint: "@username or user ID",
                    controller: _targetController,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumInputField(
                    icon: Icons.message,
                    label: "Report Message",
                    hint: "Optional custom message",
                    controller: _reportTextController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumInputField(
                    icon: Icons.link,
                    label: "Evidence Link",
                    hint: "Optional evidence link",
                    controller: _reportLinkController,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumInputField(
                    icon: Icons.numbers,
                    label: "Report Count",
                    hint: "1-1000",
                    controller: _reportCountController,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isReporting ? null : _startSpamReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isReporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FontAwesomeIcons.play, size: 18),
                      SizedBox(width: 12),
                      Text(
                        "START SPAM REPORT",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'MADEEvolveSansEVO',
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
          ),
          if (_isReporting) ...[
            const SizedBox(height: 20),
            _buildGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "REPORT PROGRESS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: "MADEEvolveSansEVO",
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _reportTotal > 0
                            ? _reportProgress / _reportTotal
                            : 0.0,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00E5FF),
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress: $_reportProgress / $_reportTotal',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontFamily: 'ShareTechMono',
                            fontSize: 12,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _reportStatus,
                            style: TextStyle(
                              color: _primaryColor,
                              fontFamily: 'ShareTechMono',
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
          _buildFooter(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPremiumInputField({
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _primaryColor.withOpacity(0.8),
            fontSize: 12,
            fontFamily: 'ShareTechMono',
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primaryColor.withOpacity(0.3), width: 1),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            cursorColor: _primaryColor,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: Icon(
                icon,
                color: _primaryColor.withOpacity(0.6),
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.black.withOpacity(0.4),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white24, size: 60),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'MADEEvolveSansEVO',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white38,
              fontFamily: 'ShareTechMono',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

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
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.green, blurRadius: 5)],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "SECURE CONNECTION",
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontFamily: 'MADEEvolveSansEVO',
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.fingerprint,
              color: Colors.white.withOpacity(0.2),
              size: 14,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "SPAMS NOCURE",
          style: TextStyle(
            color: Colors.white.withOpacity(0.15),
            fontSize: 9,
            fontFamily: 'ShareTechMono',
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // --- Dialogs ---
  void _showPhoneDialog() {
    _resetLoginState();
    _phoneController.clear();
    _authController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPhoneDialog(),
    );
  }

  Widget _buildPhoneDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: _buildGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _secondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.telegram,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "ADD SESSION",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MADEEvolveSansEVO',
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPremiumInputField(
                icon: Icons.phone,
                label: "Phone Number",
                hint: "+628123456789",
                controller: _phoneController,
              ),
              if (_loginErrorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  _loginErrorMessage,
                  style: TextStyle(
                    color: _accentColor,
                    fontFamily: 'ShareTechMono',
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetLoginState();
                    },
                    child: const Text(
                      "CANCEL",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoggingIn ? null : _initiateLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoggingIn
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            "SEND OTP",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'MADEEvolveSansEVO',
                              letterSpacing: 1,
                            ),
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

  void _showAuthDialog() {
    _loginErrorMessage = "";
    _authController.clear();
    _startResendOtpCooldown();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isPasswordStep = _currentLoginStep == 'wait_password';
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: _buildGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPasswordStep
                                ? [_accentColor, const Color(0xFFE91E63)]
                                : [_primaryColor, _secondaryColor],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isPasswordStep ? Icons.lock : FontAwesomeIcons.key,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        isPasswordStep
                            ? "2FA VERIFICATION"
                            : "OTP VERIFICATION",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'MADEEvolveSansEVO',
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isPasswordStep
                        ? '2FA Password Required for $_currentLoginPhone'
                        : 'Code sent to $_currentLoginPhone',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumInputField(
                    icon: isPasswordStep ? Icons.lock : Icons.pin,
                    label: isPasswordStep ? "2FA Password" : "OTP Code",
                    hint: isPasswordStep
                        ? "Enter your 2FA password"
                        : "Enter 5-digit code",
                    controller: _authController,
                  ),
                  if (_loginErrorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _loginErrorMessage,
                      style: TextStyle(
                        color: _accentColor,
                        fontFamily: 'ShareTechMono',
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isPasswordStep)
                        IconButton(
                          icon: _isLoggingIn || !_canResendOtp
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh,
                                  color: Colors.white70,
                                ),
                          onPressed: _isLoggingIn || !_canResendOtp
                              ? null
                              : () => _initiateLogin(isResend: true),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _resetLoginState();
                        },
                        child: const Text(
                          "CANCEL",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoggingIn ? null : _submitAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoggingIn
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isPasswordStep ? "LOGIN" : "VERIFY",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'MADEEvolveSansEVO',
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildNeonHeader(),
                _buildCustomTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildSessionsTab(), _buildReportTab()],
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

// --- Data Model ---
class TelegramSession {
  final String phone;
  final DateTime lastModified;
  final bool isActive;

  TelegramSession({
    required this.phone,
    required this.lastModified,
    required this.isActive,
  });

  factory TelegramSession.fromJson(Map<String, dynamic> json) {
    return TelegramSession(
      phone: json['phone'] ?? '',
      lastModified: DateTime.parse(json['lastModified']),
      isActive: json['isActive'] ?? true,
    );
  }
}

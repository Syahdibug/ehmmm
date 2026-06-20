// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:http/http.dart' as http;
import 'package:battery_plus/battery_plus.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';

import 'telegram.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'ddos_page.dart';
import 'chat_page.dart';
import 'login_page.dart';
import 'custom_bug.dart';
import 'bug_group.dart';
import 'ddos_panel.dart';
import 'sender_page.dart';
import 'spams_page.dart';
import 'public_page.dart';
import 'device_dashboard.dart';
import 'anime.dart'; // ═══════════ ANIME IMPORT ═══════════

// ── COLOR SCHEME ──────────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF0c0d15);
  static const bg2 = Color(0xFF11121c);
  static const surface = Color(0xFF161823);
  static const card = Color(0xFF1a1c29);
  static const accent = Color(0xFFe8184a);
  static const accent2 = Color(0xFFff4466);
  static const accent3 = Color(0xFFff8099);
  static const gold = Color(0xFFFFD447);
  static const danger = Color(0xFFFF4D6D);
  static const text = Color(0xFFE2EAE5);
  static const muted = Color(0x73E2EAE5);
  static const muted2 = Color(0x38E2EAE5);
  static const border = Color(0x1AE8184A);
  static const border2 = Color(0x0FFFFFFF);
  static const greenG1 = Color(0xFF25D366);
  static const greenG2 = Color(0xFF18a84c);
  static const blueG1 = Color(0xFF229ED9);
  static const blueG2 = Color(0xFF0072aa);
  static const purpleG1 = Color(0xFF9C27B0);
  static const purpleG2 = Color(0xFF6a1a80);
  static const orangeG1 = Color(0xFFFF8C00);
  static const orangeG2 = Color(0xFFcc6a00);
  static const redG1 = Color(0xFFFF4D6D);
  static const redG2 = Color(0xFFcc2244);
  static const fanGreen1 = Color(0xFF2BE67A);
  static const fanBlue1 = Color(0xFF3AB8F5);
  static const fanPurple1 = Color(0xFFB84FDB);
  // Soft quick access
  static const qaGreen1 = Color(0xFF1a4d32);
  static const qaGreen2 = Color(0xFF0d2b1c);
  static const qaOrange1 = Color(0xFF5c3300);
  static const qaOrange2 = Color(0xFF341d00);
  static const qaBlue1 = Color(0xFF14456b);
  static const qaBlue2 = Color(0xFF0a2a42);
  static const qaRed1 = Color(0xFF5c1422);
  static const qaRed2 = Color(0xFF330b13);
}

// ── DASHBOARD PAGE ────────────────────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listPayload;
  final List<Map<String, dynamic>> listDDoS;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listPayload,
    required this.listDDoS,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
  late String _username;
  late String _password;
  late String _role;
  late String _sessionKey;
  late String _expiredDate;
  late List<Map<String, dynamic>> _listBug;
  late List<Map<String, dynamic>> _listPayload;
  late List<Map<String, dynamic>> _listDDoS;
  late List<dynamic> _newsList;
  String _uid = '';
  int _activeCount = 0;
  int _totalCount = 0;

  // Real-time device info
  String _deviceTemp = '--°C';
  String _batteryLevel = '--%';
  BatteryState _batteryState = BatteryState.unknown;
  final Battery _battery = Battery();
  static const _deviceChannel = MethodChannel('com.SYAHID/device');
  Timer? _tempTimer;

  // Prayer schedule
  Map<String, String> _prayerTimes = {};
  String _nextPrayerKey = '';
  String _prayerCountdown = '--:--:--';
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  bool _prayerLoading = true;
  String _prayerError = '';
  static const _prayerKeys = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  static const _prayerLabels = {
    'Fajr': 'SUBUH',
    'Dhuhr': 'DZUHUR',
    'Asr': 'ASHAR',
    'Maghrib': 'MAGHRIB',
    'Isha': 'ISYA',
  };
  static const _prayerIcons = {
    'Fajr': FontAwesomeIcons.moon,
    'Dhuhr': FontAwesomeIcons.sun,
    'Asr': FontAwesomeIcons.cloudSun,
    'Maghrib': FontAwesomeIcons.sunPlantWilt,
    'Isha': FontAwesomeIcons.solidMoon,
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // ═══ ANIME LATEST DATA ═══════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════════════════
  List<dynamic> _latestAnime = [];
  bool _animeLoading = true;
  final ScrollController _animeScrollController = ScrollController();

  bool _isSidebarOpen = false;
  bool _isFanMenuOpen = false;
  int _currentNavIndex = 0;
  int _currentNewsIndex = 0;
  bool _isMusicPlaying = false;
  String _currentPage = 'home';

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  // WebSocket
  WebSocketChannel? _wsChannel;
  bool _wsConnected = false;

  // Animation controllers
  late AnimationController _pulseRingController;
  late AnimationController _dashRingController;
  late AnimationController _fanMenuController;
  late AnimationController _fanStaggerController;
  late AnimationController _sidebarController;

  // News
  final PageController _newsController = PageController();
  final ScrollController _quickAccessController = ScrollController();

  // Settings
  bool _settingsNotif = true;
  bool _settingsSound = true;
  bool _settingsAutoConnect = false;
  bool _settingsDarkMode = true;

  // ── Init ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _pulseRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _dashRingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _fanMenuController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addListener(() {
          if (mounted) setState(() {});
        });

    _fanStaggerController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 400),
        )..addListener(() {
          if (mounted) setState(() {});
        });

    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _username = widget.username;
    _password = widget.password;
    _role = widget.role;
    _sessionKey = widget.sessionKey;
    _expiredDate = widget.expiredDate;
    _listBug = widget.listBug;
    _listPayload = widget.listPayload;
    _listDDoS = widget.listDDoS;
    _newsList = widget.news;

    _loadUserData();
    _connectWebSocket();
    _initBattery();
    _initTempMonitor();
    _fetchPrayerTimes();
    _startClockTimer();
    _initAudio();
    _fetchLatestAnime(); // ═══════════ ANIME FETCH ═══════════
  }

  @override
  void dispose() {
    _pulseRingController.dispose();
    _dashRingController.dispose();
    _fanMenuController.dispose();
    _fanStaggerController.dispose();
    _sidebarController.dispose();
    _newsController.dispose();
    _quickAccessController.dispose();
    _animeScrollController.dispose();
    _audioPlayer.dispose();
    _wsChannel?.sink.close(status.goingAway);
    _tempTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ═══ FETCH LATEST ANIME ══════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _fetchLatestAnime() async {
    setState(() => _animeLoading = true);
    try {
      final response = await http
          .get(Uri.parse('https://www.sankavollerei.com/anime/home'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final ongoingList = jsonData['data']?['ongoing']?['animeList'] ?? [];
        final completedList =
            jsonData['data']?['completed']?['animeList'] ?? [];
        // Ambil 10 pertama dari ongoing + 5 dari completed untuk variasi
        final List<dynamic> combined = [];
        combined.addAll(ongoingList.take(10));
        combined.addAll(completedList.take(5));
        if (mounted) {
          setState(() {
            _latestAnime = combined;
            _animeLoading = false;
          });
        }
      } else {
        throw Exception('status ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _animeLoading = false);
      }
    }
  }

  // ── Real-time Battery ─────────────────────────────────────────────────────
  Future<void> _initBattery() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      if (mounted) {
        setState(() {
          _batteryLevel = '$level%';
          _batteryState = state;
        });
      }
      _battery.onBatteryStateChanged.listen((s) async {
        final lvl = await _battery.batteryLevel;
        if (mounted) {
          setState(() {
            _batteryLevel = '$lvl%';
            _batteryState = s;
          });
        }
      });
    } catch (_) {
      if (mounted) setState(() => _batteryLevel = '--');
    }
  }

  // ── Real-time Temperature ─────────────────────────────────────────────────
  // Requires native MethodChannel — lihat catatan di bawah file
  void _initTempMonitor() {
    _fetchDeviceTemp();
    _tempTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchDeviceTemp(),
    );
  }

  Future<void> _fetchDeviceTemp() async {
    try {
      final temp = await _deviceChannel.invokeMethod<double>('getBatteryTemp');
      if (temp != null && mounted) {
        setState(() => _deviceTemp = '${temp.toStringAsFixed(1)}°C');
      }
    } catch (_) {
      if (mounted && _deviceTemp == '--°C') setState(() => _deviceTemp = 'N/A');
    }
  }

  // ── Prayer Schedule ───────────────────────────────────────────────────────
  void _startClockTimer() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          _updateNextPrayer();
        });
      }
    });
  }

  Future<void> _fetchPrayerTimes() async {
    setState(() {
      _prayerLoading = true;
      _prayerError = '';
    });
    try {
      final now = DateTime.now();
      final ts = now.millisecondsSinceEpoch ~/ 1000;
      final url =
          'https://api.aladhan.com/v1/timings/$ts?latitude=-6.2088&longitude=106.8456&method=11';
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final timings = body['data']['timings'] as Map<String, dynamic>;
        final Map<String, String> times = {};
        for (final k in _prayerKeys) {
          final raw = timings[k]?.toString() ?? '';
          // strip timezone suffix if present e.g. "04:32 (WIB)" -> "04:32"
          times[k] = raw.contains(' ') ? raw.split(' ').first : raw;
        }
        if (mounted) {
          setState(() {
            _prayerTimes = times;
            _prayerLoading = false;
            _updateNextPrayer();
          });
        }
      } else {
        throw Exception('status ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _prayerLoading = false;
          _prayerError = 'Gagal memuat jadwal';
        });
      }
    }
  }

  void _updateNextPrayer() {
    if (_prayerTimes.isEmpty) return;
    final now = _now;
    String? nextKey;
    Duration? minDiff;

    for (final k in _prayerKeys) {
      final t = _prayerTimes[k];
      if (t == null) continue;
      final parts = t.split(':');
      if (parts.length < 2) continue;
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      var prayerDt = DateTime(now.year, now.month, now.day, h, m);
      if (prayerDt.isBefore(now)) {
        prayerDt = prayerDt.add(const Duration(days: 1));
      }
      final diff = prayerDt.difference(now);
      if (minDiff == null || diff < minDiff) {
        minDiff = diff;
        nextKey = k;
      }
    }

    _nextPrayerKey = nextKey ?? '';
    if (minDiff != null) {
      final h = minDiff.inHours.toString().padLeft(2, '0');
      final m = (minDiff.inMinutes % 60).toString().padLeft(2, '0');
      final s = (minDiff.inSeconds % 60).toString().padLeft(2, '0');
      _prayerCountdown = '$h:$m:$s';
    }
  }

  bool _isPrayerPassed(String key) {
    final t = _prayerTimes[key];
    if (t == null) return false;
    final parts = t.split(':');
    if (parts.length < 2) return false;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final prayerDt = DateTime(_now.year, _now.month, _now.day, h, m);
    return prayerDt.isBefore(_now);
  }

  // ── Data Loading ──────────────────────────────────────────────────────────
  Future<void> _loadUserData() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      _uid = androidInfo.id;
    } catch (_) {
      _uid = 'unknown';
    }
    if (mounted) setState(() {});
  }

  // ── WebSocket ─────────────────────────────────────────────────────────────
  void _connectWebSocket() {
    try {
      _wsChannel = WebSocketChannel.connect(
        Uri.parse('http://104.207.64.203:2001'),
      );
      _wsChannel!.sink.add(
        jsonEncode({'type': 'validate', 'key': _sessionKey, 'androidId': _uid}),
      );
      _wsChannel!.sink.add(jsonEncode({'type': 'stats'}));
      _wsChannel!.stream.listen(
        (msg) => _handleWsMessage(jsonDecode(msg)),
        onDone: () {
          setState(() => _wsConnected = false);
          Future.delayed(const Duration(seconds: 5), _connectWebSocket);
        },
        onError: (_) {
          setState(() => _wsConnected = false);
          Future.delayed(const Duration(seconds: 5), _connectWebSocket);
        },
      );
      setState(() => _wsConnected = true);
    } catch (_) {
      setState(() => _wsConnected = false);
    }
  }

  void _handleWsMessage(Map<String, dynamic> data) {
    if (data['type'] == 'myInfo' && data['valid'] == false) {
      String msg = 'Session invalid. Please login again.';
      if (data['reason'] == 'androidIdMismatch')
        msg = 'Your account has logged on another device.';
      else if (data['reason'] == 'keyInvalid')
        msg = 'Key is not valid. Please login again.';
      _handleInvalidSession(msg);
    }
  }

  Future<void> _handleInvalidSession(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _C.surface.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _C.accent.withOpacity(0.5), width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _C.accent),
            const SizedBox(width: 10),
            const Text(
              'Session Expired',
              style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 16),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (r) => false,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Audio ─────────────────────────────────────────────────────────────────
  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setSourceUrl('https://files.catbox.moe/yfd2b4.mp3');
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(0.3);
    } catch (_) {}
  }

  Future<void> _toggleMusic() async {
    if (_isMusicPlaying)
      await _audioPlayer.pause();
    else
      await _audioPlayer.resume();
    setState(() => _isMusicPlaying = !_isMusicPlaying);
  }

  // ── Sidebar ───────────────────────────────────────────────────────────────
  void _openSidebar() {
    setState(() => _isSidebarOpen = true);
    _sidebarController.forward();
  }

  void _closeSidebar() {
    _sidebarController.reverse().then((_) {
      if (mounted) setState(() => _isSidebarOpen = false);
    });
  }

  void _selectFromDrawer(String page) {
    _closeSidebar();
    _navigateTo(page);
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void _navigateTo(String page) {
    setState(() => _currentPage = page);
    switch (page) {
      case 'home':
        setState(() => _currentNavIndex = 0);
        break;
      case 'bug':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AttackPage(
              username: _username,
              password: _password,
              listBug: _listBug,
              role: _role,
              expiredDate: _expiredDate,
              sessionKey: _sessionKey,
            ),
          ),
        );
        break;
      case 'custom_bug':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomAttackPage(
              username: _username,
              password: _password,
              listPayload: _listPayload,
              role: _role,
              expiredDate: _expiredDate,
              sessionKey: _sessionKey,
            ),
          ),
        );
        break;
      case 'group_bug':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GroupBugPage(
              username: _username,
              password: _password,
              role: _role,
              expiredDate: _expiredDate,
              sessionKey: _sessionKey,
            ),
          ),
        );
        break;
      case 'telegram':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TelegramSpamPage(sessionKey: _sessionKey),
          ),
        );
        break;
      case 'rat':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DeviceDashboardPage(
              username: _username,
              sessionKey: _sessionKey,
            ),
          ),
        );
        break;
      case 'ddos':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                AttackPanel(sessionKey: _sessionKey, listDDoS: _listDDoS),
          ),
        );
        break;
      case 'tools':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ToolsPage(
              sessionKey: _sessionKey,
              userRole: _role,
              username: _username,
              listDDoS: _listDDoS,
            ),
          ),
        );
        break;
      case 'seller':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SellerPage(keyToken: _sessionKey)),
        );
        break;
      case 'admin':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AdminPage(sessionKey: _sessionKey)),
        );
        break;
      case 'sender':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SenderPage(sessionKey: _sessionKey),
          ),
        );
        break;
      case 'change_password':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChangePasswordPage(
              username: _username,
              sessionKey: _sessionKey,
            ),
          ),
        );
        break;
      case 'settings':
        _showSettingsPage();
        break;
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        setState(() {
          _currentNavIndex = 0;
          _currentPage = 'home';
        });
        break;
      case 1:
        setState(() => _currentNavIndex = 1);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ToolsPage(
              sessionKey: _sessionKey,
              userRole: _role,
              username: _username,
              listDDoS: _listDDoS,
            ),
          ),
        );
        break;
      case 2:
        break;
      case 3:
        setState(() => _currentNavIndex = 3);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DeviceDashboardPage(
              username: _username,
              sessionKey: _sessionKey,
            ),
          ),
        );
        break;
      case 4:
        _showSettingsPage();
        break;
    }
  }

  void _toggleFanMenu() {
    setState(() => _isFanMenuOpen = !_isFanMenuOpen);
    if (_isFanMenuOpen) {
      _fanMenuController.forward();
      _fanStaggerController.forward();
    } else {
      _fanMenuController.reverse();
      _fanStaggerController.reverse();
    }
  }

  void _closeFanMenu() {
    if (_isFanMenuOpen) {
      setState(() => _isFanMenuOpen = false);
      _fanMenuController.reverse();
      _fanStaggerController.reverse();
    }
  }

  void _copyUid() {
    Clipboard.setData(ClipboardData(text: _uid));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('UID copied!', style: TextStyle(color: _C.text)),
        backgroundColor: _C.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _wsChannel?.sink.close(status.goingAway);
    await _audioPlayer.stop();
    if (mounted)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (r) => false,
      );
  }

  // ── Battery icon helper ───────────────────────────────────────────────────
  IconData _batteryIcon() {
    final lvl = int.tryParse(_batteryLevel.replaceAll('%', '')) ?? 100;
    if (_batteryState == BatteryState.charging)
      return Icons.battery_charging_full;
    if (lvl >= 80) return Icons.battery_full;
    if (lvl >= 50) return Icons.battery_4_bar;
    if (lvl >= 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  Color _batteryColor() {
    final lvl = int.tryParse(_batteryLevel.replaceAll('%', '')) ?? 100;
    if (_batteryState == BatteryState.charging) return const Color(0xFF00D2FF);
    if (lvl >= 50) return const Color(0xFF4CAF50);
    if (lvl >= 20) return _C.gold;
    return _C.danger;
  }

  // ── MODALS ────────────────────────────────────────────────────────────────
  void _showBugTypeModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _C.muted2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'SELECT BUG TYPE',
              style: TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _C.text,
              ),
            ),
            const SizedBox(height: 20),
            _bugTypeOption(FontAwesomeIcons.user, 'Contact Bug', () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AttackPage(
                    username: _username,
                    password: _password,
                    listBug: _listBug,
                    role: _role,
                    expiredDate: _expiredDate,
                    sessionKey: _sessionKey,
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            _bugTypeOption(FontAwesomeIcons.usersSlash, 'Group Bug', () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GroupBugPage(
                    username: _username,
                    password: _password,
                    role: _role,
                    expiredDate: _expiredDate,
                    sessionKey: _sessionKey,
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            _bugTypeOption(FontAwesomeIcons.terminal, 'Custom Bug', () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomAttackPage(
                    username: _username,
                    password: _password,
                    listPayload: _listPayload,
                    role: _role,
                    expiredDate: _expiredDate,
                    sessionKey: _sessionKey,
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _bugTypeOption(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _C.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _C.accent, size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: _C.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: _C.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _C.muted2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _C.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(FontAwesomeIcons.user, color: _C.accent, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              _username.toUpperCase(),
              style: TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _C.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _role.toUpperCase(),
              style: TextStyle(fontSize: 11, color: _C.muted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangePasswordPage(
                        username: _username,
                        sessionKey: _sessionKey,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'CHANGE PASSWORD',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'LOGOUT',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSettingsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SettingsPage(
          username: _username,
          sessionKey: _sessionKey,
          notif: _settingsNotif,
          sound: _settingsSound,
          autoConnect: _settingsAutoConnect,
          darkMode: _settingsDarkMode,
          onToggleNotif: (v) => setState(() => _settingsNotif = v),
          onToggleSound: (v) => setState(() => _settingsSound = v),
          onToggleAutoConnect: (v) => setState(() => _settingsAutoConnect = v),
          onToggleDarkMode: (v) => setState(() => _settingsDarkMode = v),
          onToggleMusic: _toggleMusic,
          isMusicPlaying: _isMusicPlaying,
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          SafeArea(
            top: true,
            child: GestureDetector(
              onTap: _closeFanMenu,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBanner(),
                          const SizedBox(height: 14),
                          _buildActionCardsRow(),
                          const SizedBox(height: 14),
                          _buildProfileCard(),
                          const SizedBox(height: 20),
                          _buildQuickAccess(screenWidth),
                          const SizedBox(height: 20),
                          _buildLatestNews(),
                          const SizedBox(height: 20),
                          // ═══════════ LATEST ANIME SECTION ═══════════
                          _buildLatestAnime(),
                          const SizedBox(height: 20),
                          // PRAYER SCHEDULE (ganti Activity Log)
                          _buildPrayerSchedule(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            child: SafeArea(top: false, child: _buildBottomNav(screenWidth)),
          ),
          if (_isFanMenuOpen || _fanMenuController.value > 0)
            _buildFanMenuOverlay(screenWidth),
          if (_isSidebarOpen)
            AnimatedBuilder(
              animation: _sidebarController,
              builder: (ctx, child) => Opacity(
                opacity: _sidebarController.value * 0.6,
                child: child,
              ),
              child: GestureDetector(
                onTap: _closeSidebar,
                child: Container(
                  color: Colors.black,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          if (_isSidebarOpen) _buildSidebar(),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 1. HEADER
  // ═════════════════════════════════════════════════════════════════════════
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
          child: Container(
            height: 62,
            padding: const EdgeInsets.only(left: 6, right: 14),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _openSidebar,
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://files.catbox.moe/futxxr.jpg',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'SYAHID',
                          style: TextStyle(
                            fontFamily: 'MADEEvolveSansEVO',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(color: _C.accent, blurRadius: 8)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _headerIconButton(FontAwesomeIcons.bars, _openSidebar),
                const SizedBox(width: 8),
                _headerIconButton(FontAwesomeIcons.user, _showAccountModal),
                const SizedBox(width: 8),
                _headerIconButton(FontAwesomeIcons.gear, _showSettingsPage),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.border2),
        ),
        child: Icon(icon, color: _C.muted, size: 15),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 2. TOP BANNER
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildTopBanner() {
    final String? bannerUrl = _newsList.isNotEmpty
        ? (_newsList[0]['image'] ??
                  _newsList[0]['img'] ??
                  _newsList[0]['thumbnail'] ??
                  _newsList[0]['banner'])
              ?.toString()
        : null;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 200),
      child: ClipRRect(
        child: bannerUrl != null && bannerUrl.isNotEmpty
            ? Image.network(
                bannerUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: _C.bg2,
                  child: Center(
                    child: Icon(Icons.image, color: _C.muted2, size: 32),
                  ),
                ),
              )
            : Container(
                height: 120,
                color: _C.bg2,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: _C.muted2,
                    size: 32,
                  ),
                ),
              ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 3. ACTION CARDS ROW
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildActionCardsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: _actionCard(
              'WA CRASH',
              _C.greenG1,
              _C.greenG2,
              FontAwesomeIcons.whatsapp,
              () => _showBugTypeModal(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionCard(
              'TG SPAM',
              _C.blueG1,
              _C.blueG2,
              FontAwesomeIcons.telegram,
              () => _navigateTo('telegram'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _actionCard(
              'RAT CTRL',
              _C.purpleG1,
              _C.purpleG2,
              FontAwesomeIcons.android,
              () => _navigateTo('rat'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    String label,
    Color g1,
    Color g2,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(colors: [g1, g2]),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              top: -10,
              child: Icon(
                icon,
                size: 50,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 4. PROFILE CARD (real-time battery & temp)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://files.catbox.moe/ycw0o4.png',
                    width: 48,
                    height: 48 * 16 / 9,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 85,
                      color: _C.surface,
                      child: Icon(Icons.person, color: _C.muted2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WELCOME BACK',
                        style: TextStyle(
                          fontSize: 11,
                          color: _C.muted,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _username.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _C.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _C.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: _C.accent,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _role.toUpperCase(),
                              style: TextStyle(
                                color: _C.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Opacity(
                  opacity: 0.75,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      'https://files.catbox.moe/cjfq3b.png',
                      width: 130,
                      height: 90,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Container(width: 130, height: 130, color: _C.surface),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: _C.border2),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _statBox('ACTIVE', '$_activeCount', _C.accent)),
                const SizedBox(width: 8),
                Expanded(child: _statBox('TOTAL', '$_totalCount', _C.text)),
                const SizedBox(width: 8),
                Expanded(child: _statBox('UNTIL', _expiredDate, _C.gold)),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom row: UID + real-time temp & battery
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'UID: ',
                        style: TextStyle(fontSize: 11, color: _C.muted),
                      ),
                      Flexible(
                        child: Text(
                          _uid,
                          style: TextStyle(
                            fontSize: 11,
                            color: _C.text,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: _copyUid,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: _C.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.copy, color: _C.muted, size: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                // Real-time device info
                Row(
                  children: [
                    Icon(
                      Icons.thermostat,
                      color: _deviceTemp == 'N/A'
                          ? _C.muted2
                          : const Color(0xFFFF8C00),
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _deviceTemp,
                      style: TextStyle(
                        fontSize: 11,
                        color: _deviceTemp == 'N/A' ? _C.muted2 : _C.text,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(_batteryIcon(), color: _batteryColor(), size: 13),
                    const SizedBox(width: 3),
                    Text(
                      _batteryLevel,
                      style: TextStyle(fontSize: 11, color: _batteryColor()),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9, color: _C.muted, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 5. QUICK ACCESS
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildQuickAccess(double screenWidth) {
    final cardWidth = screenWidth * 0.5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Text(
                'QUICK ACCESS',
                style: TextStyle(
                  fontFamily: 'MADEEvolveSansEVO',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _C.text,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text('See All', style: TextStyle(fontSize: 11, color: _C.muted)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView(
            controller: _quickAccessController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              _quickAccessCard(
                'SENDER',
                'Kirim pesan massal',
                const [Color(0xFF1a4d32), Color(0xFF0d2b1c)],
                FontAwesomeIcons.paperPlane,
                () => _navigateTo('sender'),
                cardWidth,
              ),
              const SizedBox(width: 10),
              _quickAccessCard(
                'TOOLS',
                'Utilitas & fitur',
                const [Color(0xFF5c3300), Color(0xFF341d00)],
                FontAwesomeIcons.toolbox,
                () => _navigateTo('tools'),
                cardWidth,
              ),
              const SizedBox(width: 10),
              _quickAccessCard(
                'COMMUNITY',
                'Grup & channel',
                const [Color(0xFF14456b), Color(0xFF0a2a42)],
                FontAwesomeIcons.peopleGroup,
                () => _navigateTo('telegram'),
                cardWidth,
              ),
              const SizedBox(width: 10),
              _quickAccessCard(
                'SECURITY',
                'Keamanan akun',
                const [Color(0xFF5c1422), Color(0xFF330b13)],
                FontAwesomeIcons.shieldHalved,
                () => _navigateTo('settings'),
                cardWidth,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickAccessCard(
    String label,
    String subtitle,
    List<Color> gradientColors,
    IconData icon,
    VoidCallback onTap,
    double width,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: gradientColors[0].withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.04),
        child: Ink(
          width: width,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: gradientColors[0].withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                bottom: -12,
                child: Icon(
                  icon,
                  size: 80,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white.withOpacity(0.85),
                            size: 15,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withOpacity(0.25),
                          size: 11,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontFamily: 'MADEEvolveSansEVO',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'ShareTechMono',
                            fontSize: 9,
                            color: Colors.white.withOpacity(0.45),
                          ),
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
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 6. LATEST NEWS
  // ═════════════════════════════════════════════════════════════════════════
  static const _newsAssets = [
    {
      'asset': 'assets/images/news1.jpg',
      'title': 'Update Terbaru',
      'tag': 'NEW',
    },
    {
      'asset': 'assets/images/news2.jpg',
      'title': 'Maintenance Server',
      'tag': 'INFO',
    },
    {
      'asset': 'assets/images/news3.jpg',
      'title': 'Fitur Baru Tersedia',
      'tag': 'NEW',
    },
  ];

  Widget _buildLatestNews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Text(
                'PREMIUM NEWS',
                style: TextStyle(
                  fontFamily: 'MADEEvolveSansEVO',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _C.text,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                'View All',
                style: TextStyle(fontSize: 11, color: _C.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _newsController,
            onPageChanged: (i) => setState(() => _currentNewsIndex = i),
            itemCount: _newsAssets.length,
            itemBuilder: (ctx, i) {
              final item = _newsAssets[i];
              final isRed = item['tag'] == 'NEW';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _C.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          item['asset']!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: _C.bg2,
                            child: Center(
                              child: Icon(
                                Icons.newspaper,
                                color: _C.muted2,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.85),
                              ],
                              stops: const [0.4, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 14,
                          left: 14,
                          right: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isRed
                                          ? _C.accent.withOpacity(0.85)
                                          : _C.surface.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item['tag']!,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isRed ? Colors.white : _C.muted,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white54,
                                    size: 12,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['title']!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                    ),
                                  ],
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
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _newsAssets.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentNewsIndex == i ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentNewsIndex == i ? _C.accent : _C.muted2,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 7. LATEST ANIME (NEW SECTION)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildLatestAnime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _C.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _C.accent.withOpacity(0.25)),
                ),
                child: const Icon(
                  FontAwesomeIcons.tv,
                  color: _C.accent,
                  size: 13,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'LATEST ANIME',
                style: TextStyle(
                  fontFamily: 'MADEEvolveSansEVO',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _C.text,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Navigate to full anime home page
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HomeAnimePage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _C.border2),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(fontSize: 10, color: _C.muted),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, color: _C.muted, size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Anime horizontal list ──
        if (_animeLoading)
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: 6,
              itemBuilder: (_, __) => Container(
                width: 125,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 125,
                      height: 170,
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _C.border2),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _C.accent.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 125,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_latestAnime.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _C.border),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: _C.muted2, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load anime',
                      style: TextStyle(fontSize: 12, color: _C.muted),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _fetchLatestAnime,
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: _C.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 240,
            child: ListView.builder(
              controller: _animeScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _latestAnime.length,
              itemBuilder: (context, index) {
                final anime = _latestAnime[index];
                final String title = anime['title'] ?? 'Unknown';
                final String poster = anime['poster'] ?? '';
                final String slug = anime['animeId'] ?? '';
                final String? episodes = anime['episodes']?.toString();
                final String? status = anime['status'];
                final String? score = anime['score'];
                final bool isOngoing = status?.toLowerCase() == 'ongoing';

                return Container(
                  width: 128,
                  margin: const EdgeInsets.only(right: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AnimeDetailPage(slug: slug),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Poster image ──
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 128,
                                  height: 175,
                                  decoration: BoxDecoration(
                                    color: _C.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _C.border2),
                                  ),
                                  child: poster.isNotEmpty
                                      ? Image.network(
                                          poster,
                                          width: 128,
                                          height: 175,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: _C.muted2,
                                              size: 28,
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.movie,
                                            color: _C.muted2,
                                            size: 28,
                                          ),
                                        ),
                                ),
                              ),

                              // ── Score badge (top-left) ──
                              if (score != null && score.isNotEmpty)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _C.gold.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.4),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.black87,
                                          size: 10,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          score,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'ShareTechMono',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // ── Status badge (top-right) ──
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOngoing
                                        ? _C.accent.withOpacity(0.85)
                                        : const Color(
                                            0xFF25D366,
                                          ).withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    (status ?? '?').toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'MADEEvolveSansEVO',
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),

                              // ── Play overlay ──
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.6),
                                      ],
                                      stops: const [0.5, 0.7, 1.0],
                                    ),
                                  ),
                                ),
                              ),

                              // ── Episodes count (bottom) ──
                              if (episodes != null)
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.55),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.play_circle_outline,
                                          color: _C.accent3,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${episodes} Eps',
                                          style: TextStyle(
                                            color: _C.text,
                                            fontSize: 10,
                                            fontFamily: 'ShareTechMono',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // ── Title ──
                          SizedBox(
                            width: 128,
                            child: Text(
                              title,
                              style: TextStyle(
                                color: _C.text,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 8. JADWAL SHOLAT (ganti Activity Log)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildPrayerSchedule() {
    final hh = _now.hour.toString().padLeft(2, '0');
    final mm = _now.minute.toString().padLeft(2, '0');
    final ss = _now.second.toString().padLeft(2, '0');

    // Day names in Indonesian
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final dayName = days[_now.weekday % 7];
    final dateStr =
        '$dayName, ${_now.day} ${months[_now.month - 1]} ${_now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Text(
                'JADWAL SHOLAT',
                style: TextStyle(
                  fontFamily: 'MADEEvolveSansEVO',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _C.text,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _fetchPrayerTimes,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _C.border2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: _C.muted, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        'Refresh',
                        style: TextStyle(fontSize: 10, color: _C.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              children: [
                // ── TOP: jam + lokasi + tanggal ──
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1a2540),
                        const Color(0xFF0f1525),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Jam digital
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$hh:$mm:$ss',
                            style: TextStyle(
                              fontFamily: 'ShareTechMono',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: const Color(
                                    0xFF4a9eff,
                                  ).withOpacity(0.6),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: _C.muted,
                              fontFamily: 'ShareTechMono',
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Lokasi + next prayer countdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: const Color(0xFF4a9eff),
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Jakarta, ID',
                                style: TextStyle(fontSize: 11, color: _C.muted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (!_prayerLoading && _nextPrayerKey.isNotEmpty) ...[
                            Text(
                              _prayerLabels[_nextPrayerKey] ?? _nextPrayerKey,
                              style: TextStyle(
                                fontFamily: 'MADEEvolveSansEVO',
                                fontSize: 9,
                                color: const Color(0xFF4a9eff),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _prayerCountdown,
                              style: TextStyle(
                                fontFamily: 'ShareTechMono',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'menuju waktu berikutnya',
                              style: TextStyle(fontSize: 9, color: _C.muted),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // ── DIVIDER ──
                Container(height: 1, color: _C.border2),

                // ── PRAYER LIST ──
                if (_prayerLoading)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _C.accent,
                        ),
                      ),
                    ),
                  )
                else if (_prayerError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.wifi_off, color: _C.muted2, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          _prayerError,
                          style: TextStyle(color: _C.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _fetchPrayerTimes,
                          child: Text(
                            'Coba lagi',
                            style: TextStyle(color: _C.accent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: _prayerKeys.map((k) => _prayerTile(k)).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _prayerTile(String key) {
    final isNext = key == _nextPrayerKey;
    final isPassed = _isPrayerPassed(key) && !isNext;
    final time = _prayerTimes[key] ?? '--:--';
    final label = _prayerLabels[key] ?? key;
    final icon = _prayerIcons[key] ?? FontAwesomeIcons.mosque;

    Color iconColor;
    Color labelColor;
    Color timeColor;
    Color bgColor;
    Color borderColor;

    if (isNext) {
      iconColor = const Color(0xFF4a9eff);
      labelColor = Colors.white;
      timeColor = const Color(0xFF4a9eff);
      bgColor = const Color(0xFF4a9eff).withOpacity(0.08);
      borderColor = const Color(0xFF4a9eff).withOpacity(0.25);
    } else if (isPassed) {
      iconColor = _C.muted2;
      labelColor = _C.muted;
      timeColor = _C.muted;
      bgColor = Colors.transparent;
      borderColor = Colors.transparent;
    } else {
      iconColor = _C.muted;
      labelColor = _C.text;
      timeColor = _C.text;
      bgColor = Colors.transparent;
      borderColor = Colors.transparent;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isNext ? 1 : 0),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isNext
                  ? const Color(0xFF4a9eff).withOpacity(0.12)
                  : _C.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 12),
          // Label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 11,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                    color: labelColor,
                  ),
                ),
                if (isNext) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4a9eff).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'BERIKUTNYA',
                      style: TextStyle(
                        fontSize: 8,
                        color: const Color(0xFF4a9eff),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Time
          Text(
            time,
            style: TextStyle(
              fontFamily: 'ShareTechMono',
              fontSize: 15,
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
              color: timeColor,
            ),
          ),
          const SizedBox(width: 8),
          // Status indicator
          if (isPassed)
            Icon(Icons.check_circle, color: _C.muted2, size: 14)
          else if (isNext)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4a9eff),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4a9eff).withOpacity(0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.muted2,
              ),
            ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 9. BOTTOM NAV
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildBottomNav(double screenWidth) {
    return SizedBox(
      height: 130,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              image: DecorationImage(
                image: NetworkImage('https://files.catbox.moe/x5ccbo.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0x9E0A0A14),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _navItem(FontAwesomeIcons.house, 'HOME', 0),
                      _navItem(FontAwesomeIcons.wrench, 'TOOLS', 1),
                      const SizedBox(width: 48),
                      _navItem(FontAwesomeIcons.android, 'RAT', 3),
                      _navItem(FontAwesomeIcons.sliders, 'SETTINGS', 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            child: Container(
              width: screenWidth * 0.38,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0x12FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Center button — lowered
          Positioned(
            bottom: 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseRingController,
                  builder: (ctx, child) {
                    final v = _pulseRingController.value;
                    return Container(
                      width: 104 + v * 6,
                      height: 104 + v * 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _C.accent.withOpacity(0.06 + v * 0.04),
                          width: 1,
                        ),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _dashRingController,
                  builder: (ctx, child) {
                    return Transform.rotate(
                      angle: _dashRingController.value * 6.283,
                      child: CustomPaint(
                        size: const Size(84, 84),
                        painter: _DashedCirclePainter(
                          color: _C.accent.withOpacity(0.18),
                        ),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _pulseRingController,
                  builder: (ctx, child) {
                    final v = _pulseRingController.value;
                    return Container(
                      width: 90 + v * 4,
                      height: 90 + v * 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _C.accent.withOpacity(0.12 + v * 0.06),
                          width: 1.2,
                        ),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _pulseRingController,
                  builder: (ctx, child) {
                    final v = _pulseRingController.value;
                    return Container(
                      width: 76 + v * 3,
                      height: 76 + v * 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _C.accent.withOpacity(0.3 + v * 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _C.accent.withOpacity(0.15 + v * 0.1),
                            blurRadius: 12 + v * 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: _toggleFanMenu,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2c2c40), Color(0xFF141420)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border.all(
                        color: const Color(0x99464664),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _C.accent.withOpacity(0.2),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    child: Icon(
                      FontAwesomeIcons.whatsapp,
                      color: Colors.white,
                      size: 22,
                      shadows: [
                        Shadow(
                          color: _C.accent.withOpacity(0.5),
                          blurRadius: 8,
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

  Widget _navItem(IconData icon, String label, int index) {
    final active = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? Colors.white : const Color(0x66FFFFFF),
              size: 17,
              shadows: active
                  ? [Shadow(color: _C.accent.withOpacity(0.6), blurRadius: 6)]
                  : [],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? Colors.white : const Color(0x66FFFFFF),
              ),
            ),
            if (active) ...[
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: _C.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 10. FAN MENU
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildFanMenuOverlay(double screenWidth) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _closeFanMenu,
            behavior: HitTestBehavior.opaque,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black54),
              ),
            ),
          ),
        ),
        _fanButtonPositioned(
          screenWidth: screenWidth,
          icon: FontAwesomeIcons.user,
          label: 'CONTACT',
          g1: _C.fanGreen1,
          g2: _C.greenG2,
          angle: 150,
          radius: 90,
          delay: 0,
          onTap: () {
            _closeFanMenu();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AttackPage(
                  username: _username,
                  password: _password,
                  listBug: _listBug,
                  role: _role,
                  expiredDate: _expiredDate,
                  sessionKey: _sessionKey,
                ),
              ),
            );
          },
        ),
        _fanButtonPositioned(
          screenWidth: screenWidth,
          icon: FontAwesomeIcons.users,
          label: 'GROUP',
          g1: _C.fanBlue1,
          g2: _C.blueG2,
          angle: 90,
          radius: 100,
          delay: 70,
          onTap: () {
            _closeFanMenu();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupBugPage(
                  username: _username,
                  password: _password,
                  role: _role,
                  expiredDate: _expiredDate,
                  sessionKey: _sessionKey,
                ),
              ),
            );
          },
        ),
        _fanButtonPositioned(
          screenWidth: screenWidth,
          icon: FontAwesomeIcons.code,
          label: 'CUSTOM',
          g1: _C.fanPurple1,
          g2: _C.purpleG2,
          angle: 30,
          radius: 90,
          delay: 140,
          onTap: () {
            _closeFanMenu();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CustomAttackPage(
                  username: _username,
                  password: _password,
                  listPayload: _listPayload,
                  role: _role,
                  expiredDate: _expiredDate,
                  sessionKey: _sessionKey,
                ),
              ),
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 30,
          child: Center(
            child: GestureDetector(
              onTap: _closeFanMenu,
              child: AnimatedBuilder(
                animation: _fanStaggerController,
                builder: (ctx, child) {
                  final v = Curves.easeOut.transform(
                    (_fanStaggerController.value - 0.5).clamp(0.0, 1.0),
                  );
                  return Opacity(
                    opacity: v.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: (0.8 + v * 0.2).clamp(0.8, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.accent,
                    boxShadow: [
                      BoxShadow(
                        color: _C.accent.withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fanButtonPositioned({
    required double screenWidth,
    required IconData icon,
    required String label,
    required Color g1,
    required Color g2,
    required int angle,
    required double radius,
    required int delay,
    required VoidCallback onTap,
  }) {
    final rad = angle * math.pi / 180;
    final targetDx = radius * math.cos(rad);
    final targetDy = radius * math.sin(rad);
    const originBottom = 110.0;
    return AnimatedBuilder(
      animation: _fanStaggerController,
      builder: (ctx, child) {
        final delayFraction = delay / 400.0;
        final adjusted = (_fanStaggerController.value - delayFraction).clamp(
          0.0,
          1.0,
        );
        final curved = Curves.easeOutBack.transform(adjusted);
        final leftPos = (screenWidth / 2) + targetDx * curved - 28;
        final bottomPos = originBottom + targetDy * curved - 28;
        return Positioned(
          left: leftPos,
          bottom: bottomPos,
          child: Opacity(opacity: curved.clamp(0.0, 1.0), child: child),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [g1, g2],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(color: g1.withOpacity(0.3), blurRadius: 12),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                  ),
                  Icon(icon, color: Colors.white, size: 19),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 7,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // 11. SIDEBAR (tanpa History)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildSidebar() {
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      child: SlideTransition(
        position:
            Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: _sidebarController,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
            ),
        child: Container(
          width: 260,
          decoration: BoxDecoration(
            color: _C.bg2,
            border: Border(right: BorderSide(color: _C.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                child: Row(
                  children: [
                    Text(
                      'NAVIGATE',
                      style: TextStyle(
                        fontFamily: 'MADEEvolveSansEVO',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _C.accent,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _closeSidebar,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _C.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.close, color: _C.muted, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: _C.border, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _sidebarItem(
                      FontAwesomeIcons.store,
                      'Seller Panel',
                      'seller',
                    ),
                    _sidebarItem(FontAwesomeIcons.crown, 'Admin', 'admin'),
                    _sidebarItem(
                      FontAwesomeIcons.paperPlane,
                      'Sender Hub',
                      'sender',
                    ),
                    // History dihapus
                    _sidebarItem(FontAwesomeIcons.toolbox, 'Tools', 'tools'),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'SYAHID · BUILD 2026',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 9,
                    color: _C.muted2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, String page) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectFromDrawer(page),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: _C.muted, size: 16),
              const SizedBox(width: 14),
              Text(label, style: TextStyle(fontSize: 14, color: _C.text)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DASHED CIRCLE PAINTER
// ═════════════════════════════════════════════════════════════════════════════
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  _DashedCirclePainter({
    required this.color,
    this.dashWidth = 6,
    this.dashGap = 6,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final circumference = 2 * 3.14159265 * radius;
    final totalDash = dashWidth + dashGap;
    final dashCount = (circumference / totalDash).floor();
    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * totalDash / circumference) * 2 * 3.14159265;
      final sweepAngle = (dashWidth / circumference) * 2 * 3.14159265;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// SETTINGS PAGE
// ═════════════════════════════════════════════════════════════════════════════
class _SettingsPage extends StatefulWidget {
  final String username;
  final String sessionKey;
  final bool notif, sound, autoConnect, darkMode;
  final ValueChanged<bool> onToggleNotif,
      onToggleSound,
      onToggleAutoConnect,
      onToggleDarkMode;
  final VoidCallback onToggleMusic;
  final bool isMusicPlaying;

  const _SettingsPage({
    required this.username,
    required this.sessionKey,
    required this.notif,
    required this.sound,
    required this.autoConnect,
    required this.darkMode,
    required this.onToggleNotif,
    required this.onToggleSound,
    required this.onToggleAutoConnect,
    required this.onToggleDarkMode,
    required this.onToggleMusic,
    required this.isMusicPlaying,
  });

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  late bool _n, _s, _a, _d, _m;

  @override
  void initState() {
    super.initState();
    _n = widget.notif;
    _s = widget.sound;
    _a = widget.autoConnect;
    _d = widget.darkMode;
    _m = widget.isMusicPlaying;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg2,
        elevation: 0,
        title: Text(
          'SETTINGS',
          style: TextStyle(
            fontFamily: 'MADEEvolveSansEVO',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _C.text,
          ),
        ),
        iconTheme: IconThemeData(color: _C.text),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sl('GENERAL'),
            const SizedBox(height: 8),
            _tt('Notifications', _n, (v) {
              setState(() => _n = v);
              widget.onToggleNotif(v);
            }, Icons.notifications),
            _tt('Sound Effects', _s, (v) {
              setState(() => _s = v);
              widget.onToggleSound(v);
            }, Icons.volume_up),
            _tt('Auto Connect', _a, (v) {
              setState(() => _a = v);
              widget.onToggleAutoConnect(v);
            }, Icons.sync),
            _tt('Dark Mode', _d, (v) {
              setState(() => _d = v);
              widget.onToggleDarkMode(v);
            }, Icons.dark_mode),
            const SizedBox(height: 16),
            _sl('AUDIO'),
            const SizedBox(height: 8),
            _tt('Background Music', _m, (_) {
              setState(() => _m = !_m);
              widget.onToggleMusic();
            }, Icons.music_note),
            const SizedBox(height: 16),
            _sl('ACCOUNT'),
            const SizedBox(height: 8),
            _at(
              'Change Password',
              Icons.lock,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangePasswordPage(
                    username: widget.username,
                    sessionKey: widget.sessionKey,
                  ),
                ),
              ),
            ),
            _at('Logout', Icons.logout, () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted)
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (r) => false,
                );
            }),
          ],
        ),
      ),
    );
  }

  Widget _sl(String l) => Text(
    l,
    style: TextStyle(
      fontFamily: 'ShareTechMono',
      fontSize: 11,
      color: _C.muted,
      letterSpacing: 2,
    ),
  );

  Widget _tt(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: _C.muted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 14, color: _C.text)),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: value ? _C.accent : _C.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: value ? _C.accent : _C.muted2,
                    shape: BoxShape.circle,
                    boxShadow: value
                        ? [
                            BoxShadow(
                              color: _C.accent.withOpacity(0.4),
                              blurRadius: 6,
                            ),
                          ]
                        : [],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: value ? Colors.white : _C.muted2,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _at(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: _C.muted, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: _C.text),
              ),
            ),
            Icon(Icons.chevron_right, color: _C.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

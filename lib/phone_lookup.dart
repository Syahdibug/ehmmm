import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
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
  static const blueG1  = Color(0xFF229ED9);
  static const blueG2  = Color(0xFF0072aa);
  static const purpleG1= Color(0xFF9C27B0);
  static const orangeG1= Color(0xFFFF8C00);
}

// ── PHONE LOOKUP PAGE ────────────────────────────────────────────────────────
class PhoneLookupPage extends StatefulWidget {
  final String sessionKey;

  const PhoneLookupPage({super.key, required this.sessionKey});

  @override
  State<PhoneLookupPage> createState() => _PhoneLookupPageState();
}

class _PhoneLookupPageState extends State<PhoneLookupPage> {
  final TextEditingController _phoneController = TextEditingController();
  Map<String, String>? _phoneData;
  bool _isLoading = false;

  final List<String> _userAgents = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"
  ];

  String _getRandomUA() {
    return _userAgents[Random().nextInt(_userAgents.length)];
  }

  // ── API Logic ──────────────────────────────────────────────────────────────
  Future<void> _lookupPhone() async {
    if (_phoneController.text.isEmpty) {
      _showSnackBar('Nomor telepon wajib diisi', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _phoneData = null;
    });

    try {
      final phoneNumber = _phoneController.text.trim();
      final url = Uri.parse('https://free-lookup.net/$phoneNumber');

      final response = await http.get(
        url,
        headers: {
          "User-Agent": _getRandomUA(),
          "Accept-Language": "en-US,en;q=0.9"
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final items = document.querySelectorAll('.report-summary__list div');

        Map<String, String> info = {};
        for (int i = 0; i < items.length; i += 2) {
          if (i + 1 < items.length) {
            final key = items[i].text.trim();
            final value = items[i + 1].text.trim();
            info[key] = value.isNotEmpty ? value : 'Not found';
          }
        }

        setState(() => _phoneData = info);
      } else {
        _showSnackBar('Gagal terhubung ke layanan lookup', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? _C.danger : _C.greenG1, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(color: _C.text, fontSize: 13))),
          ],
        ),
        backgroundColor: _C.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isError ? _C.danger.withOpacity(0.4) : _C.accent.withOpacity(0.4), width: 1),
        ),
        duration: const Duration(seconds: 3),
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
                color: _C.blueG1.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.blueG1.withOpacity(0.25)),
              ),
              child: Icon(FontAwesomeIcons.phone, color: _C.blueG1, size: 15),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PHONE LOOKUP', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.bold, color: _C.text)),
                Text('Phone number intelligence', style: TextStyle(fontSize: 10, color: _C.muted)),
              ],
            ),
          ],
        ),
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
                      color: _C.blueG1.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.blueG1.withOpacity(0.25)),
                    ),
                    child: Icon(FontAwesomeIcons.phoneVolume, color: _C.blueG1, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NUMBER INTELLIGENCE', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text('Masukkan nomor telepon beserta kode negara untuk melacak informasi.', style: TextStyle(fontSize: 12, color: _C.muted)),
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
                  width: 4, height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_C.blueG1, _C.blueG2]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('INPUT NUMBER', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 14),

            // ── Search Card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _C.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('PHONE NUMBER', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: _C.muted, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border2),
                    ),
                    child: TextField(
                      controller: _phoneController,
                      style: TextStyle(color: _C.text, fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'ShareTechMono', letterSpacing: 1),
                      cursorColor: _C.accent,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '628xxxxxxx',
                        hintStyle: TextStyle(color: _C.muted2, fontSize: 14, letterSpacing: 1),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(FontAwesomeIcons.magnifyingGlass, color: _C.muted, size: 16),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _lookupPhone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _C.surface,
                        disabledForegroundColor: _C.muted2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: _C.accent))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(FontAwesomeIcons.magnifyingGlass, size: 15),
                                const SizedBox(width: 10),
                                Text('LOOKUP PHONE', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Results ──
            if (_isLoading) _buildLoadingState()
            else if (_phoneData != null) _buildResults(),
          ],
        ),
      ),
    );
  }

  // ── Loading State ──────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(strokeWidth: 2.5, color: _C.blueG1),
          const SizedBox(height: 16),
          Text('FETCHING INFORMATION...', style: TextStyle(color: _C.muted, fontFamily: 'MADEEvolveSansEVO', fontSize: 11, letterSpacing: 1)),
        ],
      ),
    );
  }

  // ── Results ────────────────────────────────────────────────────────────────
  Widget _buildResults() {
    final filteredData = _phoneData!.entries.where((e) => e.value != 'Not found').toList();

    if (filteredData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          children: [
            Icon(FontAwesomeIcons.phoneSlash, color: _C.muted2, size: 40),
            const SizedBox(height: 14),
            Text('NO INFORMATION FOUND', style: TextStyle(color: _C.muted, fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text('Tidak dapat menemukan data untuk nomor ini.', style: TextStyle(color: _C.muted2, fontSize: 12)),
          ],
        ),
      );
    }

    // Assign icons per field keyword
    final fieldIcons = {
      'phone': FontAwesomeIcons.phone,
      'number': FontAwesomeIcons.hashtag,
      'carrier': FontAwesomeIcons.towerBroadcast,
      'line': FontAwesomeIcons.signal,
      'type': FontAwesomeIcons.tags,
      'country': FontAwesomeIcons.globe,
      'region': FontAwesomeIcons.map,
      'city': FontAwesomeIcons.city,
      'area': FontAwesomeIcons.locationDot,
      'zip': FontAwesomeIcons.envelope,
      'postal': FontAwesomeIcons.envelope,
      'timezone': FontAwesomeIcons.clock,
      'time': FontAwesomeIcons.clock,
      'valid': FontAwesomeIcons.circleCheck,
      'status': FontAwesomeIcons.circleInfo,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
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
            Text('RESULT DATA', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _C.blueG1.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _C.blueG1.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: _C.blueG1, size: 11),
                  const SizedBox(width: 4),
                  Text('${filteredData.length} FIELDS', style: TextStyle(color: _C.blueG1, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'MADEEvolveSansEVO', letterSpacing: 0.5)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Result card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            children: [
              // Card header
              Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: _C.blueG1.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Icon(FontAwesomeIcons.squarePhone, color: _C.blueG1, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Text('PHONE INFORMATION', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 11, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: _C.border2),
              const SizedBox(height: 14),
              // Rows
              ...filteredData.map((entry) {
                final keyLower = entry.key.toLowerCase();
                IconData icon = FontAwesomeIcons.circleInfo;
                Color iconColor = _C.blueG1;

                for (final mapEntry in fieldIcons.entries) {
                  if (keyLower.contains(mapEntry.key)) {
                    icon = mapEntry.value;
                    break;
                  }
                }

                // Color variety
                if (keyLower.contains('carrier') || keyLower.contains('line') || keyLower.contains('type')) {
                  iconColor = _C.orangeG1;
                } else if (keyLower.contains('country') || keyLower.contains('region') || keyLower.contains('city') || keyLower.contains('area')) {
                  iconColor = _C.greenG1;
                } else if (keyLower.contains('time') || keyLower.contains('zone')) {
                  iconColor = _C.purpleG1;
                } else if (keyLower.contains('valid') || keyLower.contains('status')) {
                  iconColor = _C.gold;
                }

                return _infoRow(entry.key, entry.value, icon, iconColor);
              }),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Footer
        _buildFooter(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _infoRow(String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(child: Icon(icon, color: iconColor, size: 12)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: _C.muted, fontSize: 12, fontFamily: 'ShareTechMono')),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(value, style: TextStyle(color: _C.text, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
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
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: _C.greenG1,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _C.greenG1, blurRadius: 4)],
              ),
            ),
            const SizedBox(width: 8),
            Text('SECURE CONNECTION', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 9, color: _C.muted2, letterSpacing: 1)),
            const SizedBox(width: 12),
            Icon(Icons.fingerprint, color: _C.muted2, size: 12),
          ],
        ),
        const SizedBox(height: 4),
        Text('SYAHID • ENCRYPTED', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: _C.muted2, letterSpacing: 1.5)),
      ],
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
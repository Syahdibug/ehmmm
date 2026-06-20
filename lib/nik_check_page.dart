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
  static const blueG1 = Color(0xFF229ED9);
  static const purpleG1 = Color(0xFF9C27B0);
  static const orangeG1 = Color(0xFFFF8C00);
}

// ── NIK CHECK PAGE ──────────────────────────────────────────────────────────
class NIKCheckPage extends StatefulWidget {
  final String sessionKey;

  const NIKCheckPage({super.key, required this.sessionKey});

  @override
  State<NIKCheckPage> createState() => _NIKCheckPageState();
}

class _NIKCheckPageState extends State<NIKCheckPage> {
  final TextEditingController _nikController = TextEditingController();
  Map<String, dynamic>? _nikData;
  bool _isLoading = false;

  Future<void> _checkNIK() async {
    if (_nikController.text.isEmpty) {
      _showSnackBar('NIK wajib diisi', isError: true);
      return;
    }
    if (_nikController.text.length != 16) {
      _showSnackBar('NIK harus 16 digit', isError: true);
      return;
    }
    setState(() {
      _isLoading = true;
      _nikData = null;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'http://104.207.64.203:2001/api/tools/nik-check?key=${widget.sessionKey}&nik=${_nikController.text}',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() => _nikData = data);
        } else {
          _showSnackBar('NIK tidak valid atau server error', isError: true);
        }
      } else {
        _showSnackBar('Gagal terhubung ke layanan NIK', isError: true);
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
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? _C.danger : _C.greenG1,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: _C.text, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: _C.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError
                ? _C.danger.withOpacity(0.4)
                : _C.accent.withOpacity(0.4),
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

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
                color: _C.blueG1.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.blueG1.withOpacity(0.25)),
              ),
              child: Icon(FontAwesomeIcons.idCard, color: _C.blueG1, size: 16),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NIK CHECK',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _C.text,
                  ),
                ),
                Text(
                  'KTP Data Lookup',
                  style: TextStyle(fontSize: 10, color: _C.muted),
                ),
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _C.blueG1.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.blueG1.withOpacity(0.25)),
                    ),
                    child: Icon(
                      FontAwesomeIcons.idCard,
                      color: _C.blueG1,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IDENTITY LOOKUP',
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
                          'Masukkan 16 digit NIK untuk melihat data KTP.',
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
                    gradient: LinearGradient(colors: [_C.blueG1, _C.purpleG1]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'INPUT NIK',
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

            // ── Input Card ──
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
                  // NIK Label
                  Text(
                    'NIK NUMBER',
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 10,
                      color: _C.muted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // NIK Field
                  Container(
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border2),
                    ),
                    child: TextField(
                      controller: _nikController,
                      style: TextStyle(
                        color: _C.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'ShareTechMono',
                        letterSpacing: 2,
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 16,
                      cursorColor: _C.accent,
                      decoration: InputDecoration(
                        hintText: '3174XXXXXXXXXXXX',
                        hintStyle: TextStyle(
                          color: _C.muted2,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            FontAwesomeIcons.fingerprint,
                            color: _C.muted,
                            size: 18,
                          ),
                        ),
                        suffixIcon: _nikController.text.length == 16
                            ? Padding(
                                padding: const EdgeInsets.all(14),
                                child: Icon(
                                  Icons.check_circle,
                                  color: _C.greenG1,
                                  size: 18,
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                  // Character counter
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${_nikController.text.length}/16',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'ShareTechMono',
                            color: _nikController.text.length == 16
                                ? _C.greenG1
                                : _C.muted2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Check Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _checkNIK,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _C.accent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _C.surface,
                        disabledForegroundColor: _C.muted2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: _C.accent,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  FontAwesomeIcons.magnifyingGlass,
                                  size: 15,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'CHECK NIK',
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
            const SizedBox(height: 24),

            // ── Result ──
            if (_nikData != null) ...[
              _buildNIKResult(),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  // ── NIK Result ────────────────────────────────────────────────────────────
  Widget _buildNIKResult() {
    final data = _nikData!['data'] as Map<String, dynamic>;
    final nikData = data['data'] as Map<String, dynamic>;
    final metadata = data['metadata'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Label
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_C.greenG1, _C.blueG1]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'RESULT DATA',
              style: TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _C.text,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
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
                  Icon(Icons.check_circle, color: _C.greenG1, size: 11),
                  const SizedBox(width: 4),
                  Text(
                    'FOUND',
                    style: TextStyle(
                      color: _C.greenG1,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MADEEvolveSansEVO',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Personal Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _C.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      FontAwesomeIcons.user,
                      color: _C.accent,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'PERSONAL DATA',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _C.text,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: _C.border2),
              const SizedBox(height: 14),
              _infoRow(
                'NIK',
                nikData['nik'] ?? 'N/A',
                FontAwesomeIcons.idCard,
                _C.blueG1,
              ),
              _infoRow(
                'Nama',
                nikData['nama'] ?? 'N/A',
                FontAwesomeIcons.user,
                _C.accent,
              ),
              _infoRow(
                'Jenis Kelamin',
                nikData['kelamin'] ?? 'N/A',
                FontAwesomeIcons.venusMars,
                _C.accent3,
              ),
              _infoRow(
                'Tempat Lahir',
                nikData['tempat_lahir'] ?? 'N/A',
                FontAwesomeIcons.locationDot,
                _C.orangeG1,
              ),
              _infoRow(
                'Usia',
                nikData['usia'] ?? 'N/A',
                FontAwesomeIcons.cakeCandles,
                _C.gold,
              ),
              _infoRow(
                'Zodiak',
                nikData['zodiak'] ?? 'N/A',
                FontAwesomeIcons.star,
                _C.purpleG1,
              ),
              _infoRow(
                'Pasaran',
                nikData['pasaran'] ?? 'N/A',
                FontAwesomeIcons.moon,
                _C.blueG1,
              ),
              _infoRow(
                'Ultah Mendatang',
                nikData['ultah_mendatang'] ?? 'N/A',
                FontAwesomeIcons.calendarCheck,
                _C.greenG1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Address Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _C.orangeG1.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      FontAwesomeIcons.mapLocationDot,
                      color: _C.orangeG1,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ADDRESS',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _C.text,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: _C.border2),
              const SizedBox(height: 14),
              _infoRow(
                'Provinsi',
                nikData['provinsi'] ?? 'N/A',
                FontAwesomeIcons.map,
                _C.orangeG1,
              ),
              _infoRow(
                'Kabupaten',
                nikData['kabupaten'] ?? 'N/A',
                FontAwesomeIcons.city,
                _C.orangeG1,
              ),
              _infoRow(
                'Kecamatan',
                nikData['kecamatan'] ?? 'N/A',
                FontAwesomeIcons.streetView,
                _C.orangeG1,
              ),
              _infoRow(
                'Kelurahan',
                nikData['kelurahan'] ?? 'N/A',
                FontAwesomeIcons.house,
                _C.orangeG1,
              ),
              _infoRow(
                'Alamat',
                nikData['alamat'] ?? 'N/A',
                FontAwesomeIcons.locationCrosshairs,
                _C.orangeG1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Metadata Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _C.purpleG1.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      FontAwesomeIcons.microchip,
                      color: _C.purpleG1,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'METADATA',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _C.text,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: _C.border2),
              const SizedBox(height: 14),
              _infoRow(
                'Metode Pencarian',
                metadata['metode_pencarian'] ?? 'N/A',
                FontAwesomeIcons.search,
                _C.purpleG1,
              ),
              _infoRow(
                'Kode Wilayah',
                metadata['kode_wilayah'] ?? 'N/A',
                FontAwesomeIcons.hashtag,
                _C.purpleG1,
              ),
              _infoRow(
                'Nomor Urut',
                metadata['nomor_urut'] ?? 'N/A',
                FontAwesomeIcons.listOl,
                _C.purpleG1,
              ),
              _infoRow(
                'Kategori Usia',
                metadata['kategori_usia'] ?? 'N/A',
                FontAwesomeIcons.userClock,
                _C.purpleG1,
              ),
              _infoRow(
                'Jenis Wilayah',
                metadata['jenis_wilayah'] ?? 'N/A',
                FontAwesomeIcons.layerGroup,
                _C.purpleG1,
              ),
            ],
          ),
        ),
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
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(child: Icon(icon, color: iconColor, size: 12)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: _C.muted,
                fontSize: 12,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: _C.text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nikController.dispose();
    super.dispose();
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
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
  static const purpleG2 = Color(0xFF6a1a80);
  static const orangeG1 = Color(0xFFFF8C00);
  static const orangeG2 = Color(0xFFcc6a00);
}

// ── SUBDOMAIN FINDER PAGE ───────────────────────────────────────────────────
class SubdomainFinderPage extends StatefulWidget {
  final String sessionKey;

  const SubdomainFinderPage({super.key, required this.sessionKey});

  @override
  State<SubdomainFinderPage> createState() => _SubdomainFinderPageState();
}

class _SubdomainFinderPageState extends State<SubdomainFinderPage> {
  final TextEditingController _domainController = TextEditingController();
  List<String> _subdomains = [];
  bool _isLoading = false;

  // ── API Logic ──────────────────────────────────────────────────────────────
  Future<void> _findSubdomains() async {
    if (_domainController.text.isEmpty) {
      _showSnackBar('Domain wajib diisi', isError: true);
      return;
    }
    setState(() {
      _isLoading = true;
      _subdomains = [];
    });
    try {
      final response = await http.get(
        Uri.parse(
          'http://104.207.64.203:2001/api/tools/subdomain-finder?key=${widget.sessionKey}&domain=${_domainController.text}',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            final allSubdomains = <String>{};
            for (var item in data['data']) {
              final subdomainList = item.toString().split('\n');
              for (var subdomain in subdomainList) {
                if (subdomain.isNotEmpty) {
                  allSubdomains.add(subdomain.trim());
                }
              }
            }
            _subdomains = allSubdomains.toList();
            _subdomains.sort();
          });
        } else {
          _showSnackBar('Gagal menemukan subdomain', isError: true);
        }
      } else {
        _showSnackBar('Gagal terhubung ke layanan subdomain', isError: true);
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
                color: _C.orangeG1.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.orangeG1.withOpacity(0.25)),
              ),
              child: Icon(FontAwesomeIcons.globe, color: _C.orangeG1, size: 15),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SUBDOMAIN FINDER',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _C.text,
                  ),
                ),
                Text(
                  'Discover hidden subdomains',
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
                      color: _C.orangeG1.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.orangeG1.withOpacity(0.25)),
                    ),
                    child: Icon(
                      FontAwesomeIcons.magnifyingGlassChart,
                      color: _C.orangeG1,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOMAIN RECON',
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
                          'Masukkan domain untuk menemukan subdomain tersembunyi.',
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
                      colors: [_C.orangeG1, _C.orangeG2],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'TARGET DOMAIN',
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
                  Text(
                    'DOMAIN NAME',
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 10,
                      color: _C.muted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border2),
                    ),
                    child: TextField(
                      controller: _domainController,
                      style: TextStyle(
                        color: _C.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'ShareTechMono',
                      ),
                      cursorColor: _C.accent,
                      decoration: InputDecoration(
                        hintText: 'example.com',
                        hintStyle: TextStyle(
                          color: _C.muted2,
                          fontSize: 14,
                          fontFamily: 'ShareTechMono',
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(
                            FontAwesomeIcons.globe,
                            color: _C.muted,
                            size: 16,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _findSubdomains,
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
                                  'FIND SUBDOMAINS',
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

            // ── Results ──
            _buildResults(),
            const SizedBox(height: 30),

            // ── Footer ──
            _buildFooter(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Results ────────────────────────────────────────────────────────────────
  Widget _buildResults() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          children: [
            CircularProgressIndicator(strokeWidth: 2.5, color: _C.orangeG1),
            const SizedBox(height: 16),
            Text(
              'SCANNING SUBDOMAINS...',
              style: TextStyle(
                color: _C.muted,
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }

    if (_subdomains.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_C.orangeG1, _C.purpleG1]),
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
                color: _C.orangeG1.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _C.orangeG1.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.dns, color: _C.orangeG1, size: 11),
                  const SizedBox(width: 4),
                  Text(
                    '${_subdomains.length} FOUND',
                    style: TextStyle(
                      color: _C.orangeG1,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'MADEEvolveSansEVO',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _subdomains.join('\n')));
                _showSnackBar('Semua subdomain disalin ke clipboard!');
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _C.border2),
                ),
                child: Icon(Icons.copy_all, color: _C.muted, size: 15),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Results card
        Container(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.list, color: _C.orangeG1, size: 14),
                    const SizedBox(width: 10),
                    Text(
                      'SUBDOMAIN LIST',
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
              ),
              // List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _subdomains.length,
                itemBuilder: (context, index) {
                  final subdomain = _subdomains[index];
                  return _subdomainRow(subdomain, index);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _subdomainRow(String subdomain, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Index number
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _C.orangeG1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: _C.orangeG1,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Link icon
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _C.orangeG1.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(Icons.link, color: _C.orangeG1, size: 12),
              ),
            ),
            const SizedBox(width: 10),
            // Subdomain text
            Expanded(
              child: Text(
                subdomain,
                style: TextStyle(
                  color: _C.text,
                  fontSize: 12,
                  fontFamily: 'ShareTechMono',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Copy button
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: subdomain));
                _showSnackBar('Disalin: $subdomain');
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _C.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(Icons.copy, color: _C.muted, size: 13),
              ),
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

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }
}

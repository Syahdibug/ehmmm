import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
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
  static const purpleG1= Color(0xFF9C27B0);
  static const purpleG2= Color(0xFF6a1a80);
  static const orangeG1= Color(0xFFFF8C00);
  static const orangeG2= Color(0xFFcc6a00);
}

// ── SUBDOMAIN PAGE ───────────────────────────────────────────────────────────
class SubdomainPage extends StatefulWidget {
  const SubdomainPage({super.key});

  @override
  State<SubdomainPage> createState() => _SubdomainPageState();
}

class _SubdomainPageState extends State<SubdomainPage> {
  final TextEditingController _controller = TextEditingController(text: "google.com");

  bool isLoading = false;
  List<Map<String, dynamic>> subdomains = [];

  // ── API Logic ──────────────────────────────────────────────────────────────
  Future<void> fetchSubdomains() async {
    final domain = _controller.text.trim();
    if (domain.isEmpty) return;

    setState(() {
      isLoading = true;
      subdomains.clear();
    });

    try {
      final uri = Uri.parse("https://api.siputzx.my.id/api/tools/subdomains?domain=$domain");
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data["data"] is List) {
          final List subs = data["data"];

          setState(() {
            subdomains = subs.map((s) => {
              "sub": s,
              "status": "⏳ Checking...",
              "statusColor": _C.orangeG1,
              "title": "Loading...",
              "loading": true,
            }).toList();
          });

          for (int i = 0; i < subs.length; i++) {
            checkSubdomain(subs[i], i);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetch: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> checkSubdomain(String sub, int index) async {
    String status = "❌ Inactive";
    Color statusColor = _C.danger;
    String title = "N/A";

    for (var scheme in ["https://", "http://"]) {
      final url = "$scheme$sub";
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
        status = "✅ Active (${res.statusCode})";
        statusColor = _C.greenG1;
        final regex = RegExp(r"<title>(.*?)</title>", caseSensitive: false, dotAll: true);
        final match = regex.firstMatch(res.body);
        if (match != null) {
          title = match.group(1)!.trim();
        }
        break;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        subdomains[index]["status"] = status;
        subdomains[index]["statusColor"] = statusColor;
        subdomains[index]["title"] = title;
        subdomains[index]["loading"] = false;
      });
    }
  }

  void _copySub(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: _C.greenG1, size: 20),
            const SizedBox(width: 10),
            Text('Disalin: $text', style: TextStyle(color: _C.text, fontSize: 13)),
          ],
        ),
        backgroundColor: _C.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _C.greenG1.withOpacity(0.4), width: 1),
        ),
        duration: const Duration(seconds: 2),
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
                color: _C.purpleG1.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.purpleG1.withOpacity(0.25)),
              ),
              child: Icon(FontAwesomeIcons.globe, color: _C.purpleG1, size: 15),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SUBDOMAIN SCANNER', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.bold, color: _C.text)),
                Text('Live status check', style: TextStyle(fontSize: 10, color: _C.muted)),
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
      body: Column(
        children: [
          // ── Search Section ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TARGET DOMAIN', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: _C.muted, letterSpacing: 1)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _C.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.border2),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: _C.text, fontSize: 14, fontFamily: 'ShareTechMono'),
                          cursorColor: _C.accent,
                          decoration: InputDecoration(
                            hintText: 'example.com',
                            hintStyle: TextStyle(color: _C.muted2, fontSize: 13),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Icon(FontAwesomeIcons.globe, color: _C.muted, size: 16),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : fetchSubdomains,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.purpleG1,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _C.surface,
                          disabledForegroundColor: _C.muted2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : Icon(FontAwesomeIcons.magnifyingGlass, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Stats bar ──
          if (subdomains.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _miniStat('TOTAL', '${subdomains.length}', _C.text, FontAwesomeIcons.list),
                  const SizedBox(width: 8),
                  _miniStat('ACTIVE', '${subdomains.where((s) => !s["loading"]).where((s) => s["status"].toString().startsWith("✅")).length}', _C.greenG1, FontAwesomeIcons.circleCheck),
                  const SizedBox(width: 8),
                  _miniStat('INACTIVE', '${subdomains.where((s) => !s["loading"]).where((s) => s["status"].toString().startsWith("❌")).length}', _C.danger, FontAwesomeIcons.circleXmark),
                  const SizedBox(width: 8),
                  _miniStat('PENDING', '${subdomains.where((s) => s["loading"]).length}', _C.orangeG1, FontAwesomeIcons.spinner),
                ],
              ),
            ),

          // ── List ──
          Expanded(
            child: isLoading && subdomains.isEmpty
                ? Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: _C.purpleG1))
                : subdomains.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                color: _C.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _C.border2),
                              ),
                              child: Icon(FontAwesomeIcons.globe, color: _C.muted2, size: 28),
                            ),
                            const SizedBox(height: 14),
                            Text('NO SUBDOMAINS FOUND', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.muted, letterSpacing: 1)),
                            const SizedBox(height: 6),
                            Text('Masukkan domain lalu tekan scan.', style: TextStyle(color: _C.muted2, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: subdomains.length,
                        itemBuilder: (context, index) {
                          final sub = subdomains[index];
                          return _subdomainCard(sub, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ── Mini Stat ──────────────────────────────────────────────────────────────
  Widget _miniStat(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono')),
                Text(label, style: TextStyle(color: _C.muted2, fontSize: 8, letterSpacing: 0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Subdomain Card ─────────────────────────────────────────────────────────
  Widget _subdomainCard(Map<String, dynamic> sub, int index) {
    final isLoading = sub["loading"] == true;
    final isActive = sub["status"].toString().startsWith("✅");
    final statusColor = sub["statusColor"] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? _C.greenG1.withOpacity(0.2) : _C.border2),
        ),
        child: Column(
          children: [
            // Main row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
              child: Row(
                children: [
                  // Status dot
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: isLoading ? _C.orangeG1 : statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isLoading ? _C.orangeG1 : statusColor,
                          blurRadius: isLoading ? 0 : 4,
                          spreadRadius: isLoading ? 0 : 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Subdomain name
                  Expanded(
                    child: Text(
                      sub["sub"],
                      style: TextStyle(color: _C.text, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'ShareTechMono'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Copy button
                  GestureDetector(
                    onTap: () => _copySub(sub["sub"]),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(7)),
                      child: Icon(Icons.copy, color: _C.muted, size: 13),
                    ),
                  ),
                ],
              ),
            ),
            // Detail row
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  // Status
                  isLoading
                      ? Row(
                          children: [
                            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _C.orangeG1)),
                            const SizedBox(width: 8),
                            Text('Checking...', style: TextStyle(color: _C.orangeG1, fontSize: 11, fontFamily: 'ShareTechMono')),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withOpacity(0.2), width: 0.5),
                          ),
                          child: Text(
                            sub["status"],
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'ShareTechMono'),
                          ),
                        ),
                  const Spacer(),
                  // Title preview
                  if (!isLoading)
                    Expanded(
                      child: Text(
                        sub["title"],
                        style: TextStyle(color: _C.muted, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
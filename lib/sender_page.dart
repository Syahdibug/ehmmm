// sender_page.dart — WhatsApp Sender Manager (Enhanced UI)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import 'dart:math' as math;

// ── COLOR SCHEME ──────────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF0c0d15);
  static const bg2 = Color(0xFF10111d);
  static const surface = Color(0xFF161823);
  static const card = Color(0xFF181a27);
  static const cardHigh = Color(0xFF1c1e2e);
  static const accent = Color(0xFFe8184a);
  static const accent2 = Color(0xFFff4466);
  static const accent3 = Color(0xFFff8099);
  static const gold = Color(0xFFFFD447);
  static const goldDim = Color(0xFFc9a72e);
  static const danger = Color(0xFFFF4D6D);
  static const text = Color(0xFFE2EAE5);
  static const textSub = Color(0xFFa0aab0);
  static const muted = Color(0x73E2EAE5);
  static const muted2 = Color(0x38E2EAE5);
  static const border = Color(0x1AE8184A);
  static const border2 = Color(0x0FFFFFFF);
  static const borderSub = Color(0x14FFFFFF);
  static const green = Color(0xFF25D366);
  static const greenDim = Color(0xFF18a84c);
  static const purpleG1 = Color(0xFF9C27B0);
}

class SenderPage extends StatefulWidget {
  final String sessionKey;
  const SenderPage({super.key, required this.sessionKey});

  @override
  State<SenderPage> createState() => _SenderPageState();
}

class _SenderPageState extends State<SenderPage> with TickerProviderStateMixin {
  static const String _baseUrl = "http://104.207.64.203:2001";

  Map<String, dynamic> _connections = {"private": [], "global": []};
  bool _isLoading = false;
  String _currentFilter = "all";

  late AnimationController _pulseController;
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
    _fetchSenders();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  // ── API ───────────────────────────────────────────────────────────────────

  Future<void> _fetchSenders() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final res = await http
          .get(
            Uri.parse(
              "$_baseUrl/api/whatsapp/mySender?key=${widget.sessionKey}",
            ),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          setState(() {
            _connections = data["connections"] ?? {"private": [], "global": []};
          });
        }
      }
    } catch (e) {
      _showSnackBar('Gagal memuat sender', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _addSender(String number) async {
    setState(() => _isLoading = true);
    try {
      final res = await http
          .get(
            Uri.parse(
              "$_baseUrl/api/whatsapp/getPairing?key=${widget.sessionKey}&number=$number",
            ),
          )
          .timeout(const Duration(seconds: 45));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          _showPairingDialog(number, data['pairingCode']);
          _fetchSenders();
        } else {
          _showSnackBar(
            data['message'] ?? 'Gagal mendapat kode',
            isError: true,
          );
        }
      }
    } catch (e) {
      _showSnackBar('Gagal. Coba lagi.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<dynamic> _getFilteredSenders() {
    switch (_currentFilter) {
      case "private":
        return _connections["private"] ?? [];
      case "global":
        return _connections["global"] ?? [];
      default:
        return [
          ...(_connections["private"] ?? []),
          ...(_connections["global"] ?? []),
        ];
    }
  }

  int get _privateCount => (_connections["private"] as List?)?.length ?? 0;
  int get _globalCount => (_connections["global"] as List?)?.length ?? 0;
  int get _totalCount => _privateCount + _globalCount;
  int get _onlineCount {
    final all = [
      ...(_connections["private"] ?? []),
      ...(_connections["global"] ?? []),
    ];
    return all.where((s) => s['isActive'] == true).length;
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'ShareTechMono',
            fontSize: 12,
          ),
        ),
        backgroundColor: isError
            ? _C.danger.withOpacity(0.92)
            : _C.green.withOpacity(0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showAddSenderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _StyledDialog(
        icon: FontAwesomeIcons.whatsapp,
        iconColor: _C.green,
        title: "ADD SENDER",
        child: StatefulBuilder(
          builder: (ctx, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField(
                controller: controller,
                hint: "62xxxxxxxxxx",
                icon: FontAwesomeIcons.whatsapp,
                iconColor: _C.green,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              _infoBox("Nomor akan otomatis tersimpan ke Private & Global"),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _dialogBtn(
                      label: 'BATAL',
                      onTap: () => Navigator.pop(context),
                      ghost: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dialogBtn(
                      label: 'TAMBAH',
                      color: _C.green,
                      onTap: () {
                        final number = controller.text.trim();
                        Navigator.pop(context);
                        if (number.isEmpty) {
                          _showSnackBar(
                            'Nomor tidak boleh kosong',
                            isError: true,
                          );
                          return;
                        }
                        _addSender(number);
                      },
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

  void _showPairingDialog(String number, String code) {
    showDialog(
      context: context,
      builder: (_) => _StyledDialog(
        icon: FontAwesomeIcons.link,
        iconColor: _C.accent,
        title: "PAIRING CODE",
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.whatsapp,
                  color: _C.green.withOpacity(0.6),
                  size: 13,
                ),
                const SizedBox(width: 7),
                Text(
                  number,
                  style: TextStyle(
                    color: _C.green.withOpacity(0.85),
                    fontSize: 13,
                    fontFamily: 'ShareTechMono',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Code box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _C.accent.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(color: _C.accent.withOpacity(0.08), blurRadius: 20),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'KODE PAIRING',
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 8,
                      letterSpacing: 2,
                      color: _C.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    code,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      fontFamily: 'MADEEvolveSansEVO',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _infoBox("WhatsApp › Perangkat Tertaut › Tautkan Perangkat"),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _dialogBtn(
                    label: 'SALIN',
                    icon: Icons.copy_rounded,
                    ghost: true,
                    accentColor: _C.accent,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      Navigator.pop(context);
                      _showSnackBar('Kode pairing disalin!');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dialogBtn(
                    label: 'TUTUP',
                    color: _C.accent,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialog Widgets ────────────────────────────────────────────────────────

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _C.borderSub),
      ),
      padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
      child: Row(
        children: [
          Icon(icon, color: iconColor.withOpacity(0.5), size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                color: _C.text,
                fontFamily: 'ShareTechMono',
                fontSize: 13,
              ),
              cursorColor: _C.accent,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                hintText: hint,
                hintStyle: TextStyle(
                  color: _C.muted2,
                  fontSize: 11,
                  fontFamily: 'ShareTechMono',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.borderSub),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _C.muted2, size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _C.muted,
                fontSize: 10,
                fontFamily: 'ShareTechMono',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogBtn({
    required String label,
    required VoidCallback onTap,
    bool ghost = false,
    Color color = _C.accent,
    Color? accentColor,
    IconData? icon,
  }) {
    final c = accentColor ?? color;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: ghost ? Colors.transparent : c,
          borderRadius: BorderRadius.circular(12),
          border: ghost ? Border.all(color: c.withOpacity(0.25)) : null,
          boxShadow: ghost
              ? null
              : [BoxShadow(color: c.withOpacity(0.28), blurRadius: 14)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: ghost ? c : Colors.white, size: 13),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: ghost ? c.withOpacity(0.8) : Colors.white,
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // BG gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0f1020), _C.bg, Color(0xFF0a0b12)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Subtle dot grid
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _DotGridPainter()),
            ),
          ),
          // Top accent orb
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_C.green.withOpacity(0.05), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStatsBar(),
                _buildFilterChips(),
                Expanded(
                  child: _isLoading && _totalCount == 0
                      ? _buildLoading()
                      : _totalCount == 0
                      ? _buildEmptyState()
                      : _buildSenderList(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xF00c0d17),
        border: Border(
          bottom: BorderSide(color: _C.green.withOpacity(0.08), width: 1),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                // Back button
                _headerBtn(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 10),
                // WA icon with green glow
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _C.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.green.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: _C.green.withOpacity(0.08),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    FontAwesomeIcons.whatsapp,
                    color: _C.green,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "SENDER",
                            style: TextStyle(
                              color: _C.text,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: "MADEEvolveSansEVO",
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _C.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: _C.green.withOpacity(0.2),
                              ),
                            ),
                            child: const Text(
                              "MGR",
                              style: TextStyle(
                                color: _C.green,
                                fontSize: 8,
                                fontFamily: "MADEEvolveSansEVO",
                                letterSpacing: 1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _dotController,
                            builder: (_, __) => Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: _C.green.withOpacity(
                                  0.6 + _dotController.value * 0.4,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _C.green.withOpacity(
                                      0.4 * _dotController.value,
                                    ),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "$_onlineCount online · $_totalCount total",
                            style: const TextStyle(
                              color: _C.textSub,
                              fontSize: 10,
                              fontFamily: "ShareTechMono",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _headerBtn(
                  icon: Icons.refresh_rounded,
                  onTap: _isLoading ? null : _fetchSenders,
                  loading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerBtn({
    required IconData icon,
    VoidCallback? onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _C.borderSub),
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: _C.muted,
                  ),
                ),
              )
            : Icon(icon, color: _C.textSub, size: 15),
      ),
    );
  }

  // ── Stats Bar ─────────────────────────────────────────────────────────────

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.borderSub),
      ),
      child: Row(
        children: [
          _statItem(label: "TOTAL", value: "$_totalCount", color: _C.text),
          _statDivider(),
          _statItem(label: "ONLINE", value: "$_onlineCount", color: _C.green),
          _statDivider(),
          _statItem(
            label: "PRIVATE",
            value: "$_privateCount",
            color: _C.accent3,
          ),
          _statDivider(),
          _statItem(label: "GLOBAL", value: "$_globalCount", color: _C.gold),
        ],
      ),
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'MADEEvolveSansEVO',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: _C.textSub,
              fontSize: 8,
              fontFamily: 'ShareTechMono',
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withOpacity(0.05),
    );
  }

  // ── Filter Chips ──────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'SEMUA', 'value': 'all', 'icon': Icons.apps_rounded},
      {'label': 'PRIVATE', 'value': 'private', 'icon': Icons.person_rounded},
      {'label': 'GLOBAL', 'value': 'global', 'icon': Icons.public_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: filters.map((f) {
          final isSelected = _currentFilter == f['value'];
          final count = f['value'] == 'all'
              ? _totalCount
              : (f['value'] == 'private' ? _privateCount : _globalCount);
          final chipColor = f['value'] == 'global' ? _C.gold : _C.accent;

          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _currentFilter = f['value'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? chipColor.withOpacity(0.1) : _C.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? chipColor.withOpacity(0.4)
                        : Colors.white.withOpacity(0.05),
                    width: isSelected ? 1 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          f['icon'] as IconData,
                          color: isSelected ? chipColor : _C.muted2,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${f['label']}",
                          style: TextStyle(
                            color: isSelected ? chipColor : _C.muted,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 8.5,
                            fontFamily: 'MADEEvolveSansEVO',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // count pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? chipColor.withOpacity(0.15)
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected ? chipColor : _C.muted2,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Sender List ───────────────────────────────────────────────────────────

  Widget _buildSenderList() {
    final filtered = _getFilteredSenders();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off_rounded, color: _C.muted2, size: 32),
            const SizedBox(height: 12),
            Text(
              "Tidak ada sender di ${_currentFilter.toUpperCase()}",
              style: const TextStyle(
                color: _C.textSub,
                fontSize: 12,
                fontFamily: 'ShareTechMono',
              ),
            ),
          ],
        ),
      );
    }

    // If "all" mode → show grouped with section headers
    if (_currentFilter == 'all') {
      final privateList = _connections["private"] as List? ?? [];
      final globalList = _connections["global"] as List? ?? [];

      return RefreshIndicator(
        onRefresh: _fetchSenders,
        color: _C.accent,
        backgroundColor: _C.surface,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
          children: [
            if (privateList.isNotEmpty) ...[
              _sectionHeader("PRIVATE", privateList.length, _C.accent3),
              const SizedBox(height: 6),
              ...privateList.map((s) => _buildSenderCard(s)),
              const SizedBox(height: 4),
            ],
            if (globalList.isNotEmpty) ...[
              _sectionHeader("GLOBAL", globalList.length, _C.gold),
              const SizedBox(height: 6),
              ...globalList.map((s) => _buildSenderCard(s)),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSenders,
      color: _C.accent,
      backgroundColor: _C.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
        children: filtered.map((s) => _buildSenderCard(s)).toList(),
      ),
    );
  }

  Widget _sectionHeader(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontFamily: 'MADEEvolveSansEVO',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontFamily: 'ShareTechMono',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderCard(dynamic sender) {
    final isGlobal = sender['owner'] == "global";
    final isActive = sender['isActive'] == true;
    final stripeColor = isGlobal ? _C.gold : _C.green;
    final name = (sender['sessionName'] ?? 'Unknown') as String;
    final type = (sender['type'] ?? 'N/A') as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? stripeColor.withOpacity(0.18)
              : Colors.white.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? stripeColor.withOpacity(0.05)
                : Colors.transparent,
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left color stripe
          Positioned(
            left: 0,
            top: 10,
            bottom: 10,
            width: 3,
            child: Container(
              decoration: BoxDecoration(
                color: isActive ? stripeColor : Colors.white.withOpacity(0.06),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(3),
                  bottomRight: Radius.circular(3),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: stripeColor.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: stripeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: stripeColor.withOpacity(0.18)),
                  ),
                  child: Icon(
                    FontAwesomeIcons.whatsapp,
                    color: stripeColor.withOpacity(isActive ? 1 : 0.4),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                // Main info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: _C.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _badge(
                            type,
                            type == 'Business' ? _C.green : _C.muted2,
                          ),
                          const SizedBox(width: 5),
                          _badge(
                            isGlobal ? 'GLOBAL' : 'PRIVATE',
                            isGlobal ? _C.gold : _C.accent,
                            icon: isGlobal ? Icons.star_rounded : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Online/offline pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? _C.green.withOpacity(0.1)
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? _C.green.withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          isActive
                              ? AnimatedBuilder(
                                  animation: _dotController,
                                  builder: (_, __) => Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: _C.green.withOpacity(
                                        0.7 + _dotController.value * 0.3,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _C.green.withOpacity(
                                            0.5 * _dotController.value,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF445055),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                          const SizedBox(width: 5),
                          Text(
                            isActive ? 'ONLINE' : 'OFFLINE',
                            style: TextStyle(
                              color: isActive
                                  ? _C.green
                                  : const Color(0xFF445055),
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'MADEEvolveSansEVO',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 7),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              fontFamily: 'ShareTechMono',
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _C.green.withOpacity(
                          0.06 + 0.06 * _pulseController.value,
                        ),
                        width: 1,
                      ),
                    ),
                  ),
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _C.green.withOpacity(
                        0.05 + 0.04 * _pulseController.value,
                      ),
                      border: Border.all(
                        color: _C.green.withOpacity(
                          0.12 + 0.08 * _pulseController.value,
                        ),
                      ),
                    ),
                    child: Icon(
                      FontAwesomeIcons.whatsapp,
                      color: _C.green.withOpacity(
                        0.4 + 0.25 * _pulseController.value,
                      ),
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'BELUM ADA SENDER',
              style: TextStyle(
                color: _C.text,
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan nomor WhatsApp untuk mulai mengirim pesan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _C.textSub,
                fontFamily: 'ShareTechMono',
                fontSize: 11,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _showAddSenderDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: _C.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.green.withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: _C.green.withOpacity(0.06),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: _C.green, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'TAMBAH SENDER',
                      style: TextStyle(
                        color: _C.green,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'MADEEvolveSansEVO',
                        fontSize: 11,
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
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: _C.green.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Memuat sender...',
            style: TextStyle(
              color: _C.textSub,
              fontFamily: 'ShareTechMono',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return GestureDetector(
      onTap: _isLoading ? null : _showAddSenderDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_C.green, _C.greenDim]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _C.green.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            const Text(
              'TAMBAH',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Styled Dialog ────────────────────────────────────────────────

class _StyledDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _StyledDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF181a27),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Top accent line
              Positioned(
                top: 0,
                left: 30,
                right: 30,
                height: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        iconColor.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: iconColor.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(icon, color: iconColor, size: 15),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            color: _C.text,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'MADEEvolveSansEVO',
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    child,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dot Grid Painter ──────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

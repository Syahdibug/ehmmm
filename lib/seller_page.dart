import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  static const purpleG1 = Color(0xFF9C27B0);
  static const orangeG1 = Color(0xFFFF8C00);
}

// ── SELLER PAGE ─────────────────────────────────────────────────────────────
class SellerPage extends StatefulWidget {
  final String keyToken;

  const SellerPage({super.key, required this.keyToken});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  final _newUser = TextEditingController();
  final _newPass = TextEditingController();
  final _days = TextEditingController();
  final _editUser = TextEditingController();
  final _editDays = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
  }

  // ── API Logic ──────────────────────────────────────────────────────────────
  Future<void> _create() async {
    final u = _newUser.text.trim(),
        p = _newPass.text.trim(),
        d = _days.text.trim();
    if (u.isEmpty || p.isEmpty || d.isEmpty)
      return _showNotification("Semua field wajib diisi", isError: true);
    setState(() => loading = true);
    try {
      final res = await http.get(
        Uri.parse(
          "http://104.207.64.203:2001/api/user/createAccount?key=${widget.keyToken}&newUser=$u&pass=$p&day=$d",
        ),
      );
      final data = jsonDecode(res.body);
      if (data['created'] == true) {
        _showNotification("Akun berhasil dibuat!");
        _newUser.clear();
        _newPass.clear();
        _days.clear();
        Navigator.pop(context);
      } else {
        _showNotification(
          data['message'] ?? 'Gagal membuat akun.',
          isError: true,
        );
      }
    } catch (e) {
      _showNotification("Terjadi kesalahan: ${e.toString()}", isError: true);
    }
    setState(() => loading = false);
  }

  Future<void> _edit() async {
    final u = _editUser.text.trim(), d = _editDays.text.trim();
    if (u.isEmpty || d.isEmpty)
      return _showNotification(
        "Username dan durasi wajib diisi",
        isError: true,
      );
    setState(() => loading = true);
    try {
      final res = await http.get(
        Uri.parse(
          "http://104.207.64.203:2001/api/user/editUser?key=${widget.keyToken}&username=$u&addDays=$d",
        ),
      );
      final data = jsonDecode(res.body);
      if (data['edited'] == true) {
        _showNotification("Durasi berhasil diperbarui.");
        _editUser.clear();
        _editDays.clear();
        Navigator.pop(context);
      } else {
        _showNotification(
          data['message'] ?? 'Gagal mengubah durasi.',
          isError: true,
        );
      }
    } catch (e) {
      _showNotification("Terjadi kesalahan: ${e.toString()}", isError: true);
    }
    setState(() => loading = false);
  }

  void _showNotification(String message, {bool isError = false}) {
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
                color: _C.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.gold.withOpacity(0.25)),
              ),
              child: Icon(FontAwesomeIcons.store, color: _C.gold, size: 16),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELLER PANEL',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _C.text,
                  ),
                ),
                Text(
                  'Account Management',
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
      body: loading
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
                  // Info card
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
                            color: _C.gold.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _C.gold.withOpacity(0.25),
                            ),
                          ),
                          child: Icon(
                            FontAwesomeIcons.store,
                            color: _C.gold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SELLER PORTAL',
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
                                'Buat akun baru atau perpanjang durasi akun yang sudah ada.',
                                style: TextStyle(fontSize: 12, color: _C.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section label
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_C.gold, _C.orangeG1],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ACTIONS',
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

                  // Action cards
                  _sellerCard(
                    title: 'CREATE NEW ACCOUNT',
                    subtitle: 'Tambah user baru ke sistem',
                    icon: FontAwesomeIcons.userPlus,
                    g1: _C.greenG1,
                    g2: _C.greenG2,
                    onTap: _showCreateAccountDialog,
                  ),
                  const SizedBox(height: 12),
                  _sellerCard(
                    title: 'EXTEND DURATION',
                    subtitle: 'Tambah hari ke akun yang sudah ada',
                    icon: FontAwesomeIcons.calendarPlus,
                    g1: _C.blueG1,
                    g2: const Color(0xFF0072aa),
                    onTap: _showEditDurationDialog,
                  ),
                  const SizedBox(height: 30),

                  // Footer
                  _buildFooter(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ── Seller Card ───────────────────────────────────────────────────────────
  Widget _sellerCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color g1,
    required Color g2,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: g1.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: g1.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: g1.withOpacity(0.25)),
                  ),
                  child: Icon(icon, color: g1, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _C.text,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: _C.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.border2),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: _C.muted,
                    size: 13,
                  ),
                ),
              ],
            ),
          ),
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
                boxShadow: [
                  BoxShadow(color: _C.greenG1.withOpacity(0.5), blurRadius: 4),
                ],
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
          'SYAHID SELLER PORTAL • ENCRYPTED',
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

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showCreateAccountDialog() {
    _newUser.clear();
    _newPass.clear();
    _days.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildDialog(
        title: 'CREATE ACCOUNT',
        icon: FontAwesomeIcons.userPlus,
        iconColor: _C.greenG1,
        borderColor: _C.greenG1,
        fields: [
          _dialogField('Username', _newUser, Icons.person),
          const SizedBox(height: 14),
          _dialogField('Password', _newPass, Icons.lock, isPassword: true),
          const SizedBox(height: 14),
          _dialogField(
            'Duration (days)',
            _days,
            Icons.calendar_today,
            keyboardType: TextInputType.number,
          ),
        ],
        onConfirm: _create,
        confirmLabel: 'CREATE',
        confirmColor: _C.greenG1,
      ),
    );
  }

  void _showEditDurationDialog() {
    _editUser.clear();
    _editDays.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildDialog(
        title: 'EXTEND DURATION',
        icon: FontAwesomeIcons.calendarPlus,
        iconColor: _C.blueG1,
        borderColor: _C.blueG1,
        fields: [
          _dialogField('Username', _editUser, Icons.person),
          const SizedBox(height: 14),
          _dialogField(
            'Add Days',
            _editDays,
            Icons.add_circle,
            keyboardType: TextInputType.number,
          ),
        ],
        onConfirm: _edit,
        confirmLabel: 'CONFIRM',
        confirmColor: _C.blueG1,
      ),
    );
  }

  Widget _buildDialog({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color borderColor,
    required List<Widget> fields,
    required VoidCallback onConfirm,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return Dialog(
      backgroundColor: _C.surface.withOpacity(0.98),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor.withOpacity(0.3), width: 1),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    color: _C.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'MADEEvolveSansEVO',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Fields
            ...fields,
            const SizedBox(height: 24),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: loading ? null : () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _C.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border2),
                    ),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        fontFamily: 'MADEEvolveSansEVO',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _C.muted,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: loading ? null : onConfirm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: confirmColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: loading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            confirmLabel,
                            style: TextStyle(
                              fontFamily: 'MADEEvolveSansEVO',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border2),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: TextStyle(color: _C.text, fontSize: 14),
        cursorColor: _C.accent,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _C.muted, fontSize: 12),
          prefixIcon: Icon(icon, color: _C.muted, size: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newUser.dispose();
    _newPass.dispose();
    _days.dispose();
    _editUser.dispose();
    _editDays.dispose();
    super.dispose();
  }
}

// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const String baseUrl = "http://104.207.64.203:2001/api/user";

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
}

// ── CHANGE PASSWORD PAGE ────────────────────────────────────────────────────
class ChangePasswordPage extends StatefulWidget {
  final String username;
  final String sessionKey;

  const ChangePasswordPage({
    super.key,
    required this.username,
    required this.sessionKey,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final oldPassCtrl = TextEditingController();
  final newPassCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  bool isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // ── API Call ──────────────────────────────────────────────────────────────
  Future<void> _changePassword() async {
    final oldPass = oldPassCtrl.text.trim();
    final newPass = newPassCtrl.text.trim();
    final confirmPass = confirmPassCtrl.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showMessage("Semua field wajib diisi");
      return;
    }

    if (newPass != confirmPass) {
      _showMessage("Password baru tidak cocok dengan konfirmasi");
      return;
    }

    if (newPass.length < 6) {
      _showMessage("Password baru minimal 6 karakter");
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/changepass"),
        body: {
          "username": widget.username,
          "oldPass": oldPass,
          "newPass": newPass,
          "key": widget.sessionKey,
        },
      );

      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        _showMessage("Password berhasil diubah", isSuccess: true);
        oldPassCtrl.clear();
        newPassCtrl.clear();
        confirmPassCtrl.clear();
      } else {
        _showMessage(data['message'] ?? "Gagal mengubah password");
      }
    } catch (e) {
      _showMessage("Server error: $e");
    }

    setState(() => isLoading = false);
  }

  // ── Dialog ────────────────────────────────────────────────────────────────
  void _showMessage(String msg, {bool isSuccess = false}) {
    final color = isSuccess ? _C.accent : _C.danger;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.surface.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.5), width: 1),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSuccess ? Icons.check_circle : Icons.warning_amber_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isSuccess ? 'SUCCESS' : 'ERROR',
              style: TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        content: Text(msg, style: TextStyle(fontSize: 14, color: _C.text)),
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
                'CLOSE',
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

  // ── Input Field ───────────────────────────────────────────────────────────
  Widget _inputField(
    String label,
    String hint,
    TextEditingController controller,
    bool obscure,
    VoidCallback onToggle,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'ShareTechMono',
            fontSize: 10,
            color: _C.muted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.border2),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(color: _C.text, fontSize: 14),
            cursorColor: _C.accent,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _C.muted2, fontSize: 13),
              prefixIcon: Icon(icon, color: _C.muted, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: _C.muted,
                  size: 18,
                ),
                onPressed: onToggle,
              ),
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
        ),
      ],
    );
  }

  // ── Password Strength Indicator ───────────────────────────────────────────
  Widget _buildStrengthIndicator() {
    final pass = newPassCtrl.text;
    if (pass.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    if (pass.length >= 6) strength++;
    if (pass.length >= 10) strength++;
    if (RegExp(r'[A-Z]').hasMatch(pass)) strength++;
    if (RegExp(r'[0-9]').hasMatch(pass)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass)) strength++;

    String label;
    Color color;
    if (strength <= 1) {
      label = 'WEAK';
      color = _C.danger;
    } else if (strength <= 2) {
      label = 'FAIR';
      color = _C.gold;
    } else if (strength <= 3) {
      label = 'GOOD';
      color = const Color(0xFF229ED9);
    } else {
      label = 'STRONG';
      color = _C.greenG1;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: strength / 5,
                backgroundColor: _C.surface,
                color: color,
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'MADEEvolveSansEVO',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1,
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
        title: Text(
          'CHANGE PASSWORD',
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
                      color: _C.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.accent.withOpacity(0.25)),
                    ),
                    child: Icon(
                      FontAwesomeIcons.shieldHalved,
                      color: _C.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SECURITY SETTINGS',
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
                          'Ubah password akun kamu',
                          style: TextStyle(fontSize: 12, color: _C.muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(FontAwesomeIcons.shieldAlt, color: _C.muted2, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Section Label ──
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_C.accent, _C.accent2]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'CREDENTIAL UPDATE',
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

            // ── Form Card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _C.border),
              ),
              child: Column(
                children: [
                  _inputField(
                    'CURRENT PASSWORD',
                    'Masukkan password lama',
                    oldPassCtrl,
                    _obscureOld,
                    () => setState(() => _obscureOld = !_obscureOld),
                    Icons.lock_outline,
                  ),
                  const SizedBox(height: 18),
                  _inputField(
                    'NEW PASSWORD',
                    'Masukkan password baru',
                    newPassCtrl,
                    _obscureNew,
                    () => setState(() => _obscureNew = !_obscureNew),
                    Icons.lock_open,
                  ),
                  // Password strength indicator
                  _buildStrengthIndicator(),
                  const SizedBox(height: 18),
                  _inputField(
                    'CONFIRM PASSWORD',
                    'Konfirmasi password baru',
                    confirmPassCtrl,
                    _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
                    Icons.check_circle_outline,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Change Button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _changePassword,
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
                child: isLoading
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
                          Icon(FontAwesomeIcons.key, size: 16),
                          const SizedBox(width: 10),
                          Text(
                            'CHANGE PASSWORD',
                            style: TextStyle(
                              fontFamily: 'MADEEvolveSansEVO',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),

            // ── Security Footer ──
            Column(
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
                          BoxShadow(
                            color: _C.greenG1.withOpacity(0.5),
                            blurRadius: 4,
                          ),
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
                  'SYAHID • ENCRYPTED',
                  style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 9,
                    color: _C.muted2,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    oldPassCtrl.dispose();
    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }
}

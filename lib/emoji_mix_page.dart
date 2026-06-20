import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  static const purpleG1= Color(0xFF9C27B0);
  static const orangeG1= Color(0xFFFF8C00);
  // Emoji mix colors
  static const emojiG1 = Color(0xFFFBBF24);
  static const emojiG2 = Color(0xFFF59E0B);
}

// ── EMOJI MIX PAGE ────────────────────────────────────────────────────────
class EmojiMixPage extends StatefulWidget {
  final String sessionKey;

  const EmojiMixPage({super.key, required this.sessionKey});

  @override
  State<EmojiMixPage> createState() => _EmojiMixPageState();
}

class _EmojiMixPageState extends State<EmojiMixPage> {
  final TextEditingController _emoji1Controller = TextEditingController();
  final TextEditingController _emoji2Controller = TextEditingController();
  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _isSaving = false;

  // Quick-pick emojis
  final List<String> _quickEmojis = [
    '😀', '😂', '🤣', '😍', '🥰', '😘', '😎', '🤩',
    '😏', '😒', '😤', '😡', '🥺', '😭', '😱', '🤯',
    '🥶', '🥵', '😈', '👻', '💀', '🤖', '👽', '💩',
    '🔥', '⭐', '💎', '❤️', '💜', '💚', '💙', '🧡',
    '👁️', '🫦', '🤤', '🤪', '🥴', '😴', '🤮', '🤧',
    '🐱', '🐶', '🦊', '🐻', '🐼', '🦁', '🐸', '🐵',
  ];

  Future<void> _mixEmoji() async {
    if (_emoji1Controller.text.isEmpty || _emoji2Controller.text.isEmpty) {
      _showSnackBar('Dua emoji wajib diisi', isError: true);
      return;
    }
    setState(() {
      _isLoading = true;
      _imageBytes = null;
    });
    try {
      final e1 = Uri.encodeComponent(_emoji1Controller.text.trim());
      final e2 = Uri.encodeComponent(_emoji2Controller.text.trim());
      final response = await http.get(Uri.parse(
          'https://api.zenzxz.my.id/tools/emojimix?emoji1=$e1&emoji2=$e2'));
      if (response.statusCode == 200 &&
          response.bodyBytes.isNotEmpty &&
          response.headers['content-type']?.contains('image') == true) {
        setState(() => _imageBytes = response.bodyBytes);
      } else {
        _showSnackBar('Gagal membuat emoji mix, coba emoji lain', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveImage() async {
    if (_imageBytes == null) return;
    setState(() => _isSaving = true);
    try {
      final directory = await getTemporaryDirectory();
      final e1 = _emoji1Controller.text.trim();
      final e2 = _emoji2Controller.text.trim();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/emojimix_${e1}_${e2}_${timestamp}.png');
      await file.writeAsBytes(_imageBytes!);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Emoji Mix: $e1 + $e2',
      );
      _showSnackBar('Gambar berhasil disimpan!', isError: false);
    } catch (e) {
      _showSnackBar('Gagal menyimpan: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isSaving = false);
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
          side: BorderSide(
              color: isError ? _C.danger.withOpacity(0.4) : _C.accent.withOpacity(0.4), width: 1),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _insertEmoji(String emoji, int field) {
    final controller = field == 1 ? _emoji1Controller : _emoji2Controller;
    // Replace entire text with single emoji
    controller.text = emoji;
    controller.selection = TextSelection.fromPosition(TextPosition(offset: emoji.length));
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
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _C.emojiG1.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.emojiG1.withOpacity(0.25)),
              ),
              child: Icon(Icons.emoji_emotions_rounded, color: _C.emojiG1, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EMOJI MIX', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.bold, color: _C.text)),
                Text('Mix Two Emojis', style: TextStyle(fontSize: 10, color: _C.muted)),
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
                      color: _C.emojiG1.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.emojiG1.withOpacity(0.25)),
                    ),
                    child: Icon(Icons.emoji_emotions_rounded, color: _C.emojiG1, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EMOJI COMBINER', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text('Pilih 2 emoji untuk digabungkan menjadi satu emoji baru.', style: TextStyle(fontSize: 12, color: _C.muted)),
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
                    gradient: LinearGradient(colors: [_C.emojiG1, _C.accent]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('INPUT EMOJI', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
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
                children: [
                  // Emoji inputs row
                  Row(
                    children: [
                      // Emoji 1
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EMOJI 1', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: _C.muted, letterSpacing: 1)),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: _C.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _C.border2),
                              ),
                              child: TextField(
                                controller: _emoji1Controller,
                                style: TextStyle(color: _C.text, fontSize: 28, letterSpacing: 0),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.text,
                                maxLines: 1,
                                maxLength: 2,
                                cursorColor: _C.accent,
                                inputFormatters: [LengthLimitingTextInputFormatter(2)],
                                decoration: InputDecoration(
                                  hintText: '🤤',
                                  hintStyle: TextStyle(color: _C.muted2, fontSize: 28),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  counterText: '',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Plus icon
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _C.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.accent.withOpacity(0.2)),
                        ),
                        child: Icon(Icons.add_rounded, color: _C.accent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      // Emoji 2
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EMOJI 2', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: _C.muted, letterSpacing: 1)),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: _C.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _C.border2),
                              ),
                              child: TextField(
                                controller: _emoji2Controller,
                                style: TextStyle(color: _C.text, fontSize: 28, letterSpacing: 0),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.text,
                                maxLines: 1,
                                maxLength: 2,
                                cursorColor: _C.accent,
                                inputFormatters: [LengthLimitingTextInputFormatter(2)],
                                decoration: InputDecoration(
                                  hintText: '😆',
                                  hintStyle: TextStyle(color: _C.muted2, fontSize: 28),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  counterText: '',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Mix Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _mixEmoji,
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
                                Icon(Icons.auto_awesome_rounded, size: 16),
                                const SizedBox(width: 10),
                                Text('MIX EMOJI', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Quick Pick Section ──
            Row(
              children: [
                Container(
                  width: 4, height: 18,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_C.purpleG1, _C.blueG1]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('QUICK PICK', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
                const Spacer(),
                Text('Tap emoji lalu tap field', style: TextStyle(fontSize: 9, color: _C.muted2)),
              ],
            ),
            const SizedBox(height: 10),

            // Field selector (which field gets the emoji)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Pilih target: ', style: TextStyle(fontSize: 10, color: _C.muted, fontFamily: 'ShareTechMono')),
                  GestureDetector(
                    onTap: () => setState(() => _activeField = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _activeField == 1 ? _C.emojiG1.withOpacity(0.15) : _C.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _activeField == 1 ? _C.emojiG1.withOpacity(0.4) : _C.border2),
                      ),
                      child: Text('Emoji 1', style: TextStyle(fontSize: 10, color: _activeField == 1 ? _C.emojiG1 : _C.muted2, fontWeight: _activeField == 1 ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _activeField = 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _activeField == 2 ? _C.emojiG1.withOpacity(0.15) : _C.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _activeField == 2 ? _C.emojiG1.withOpacity(0.4) : _C.border2),
                      ),
                      child: Text('Emoji 2', style: TextStyle(fontSize: 10, color: _activeField == 2 ? _C.emojiG1 : _C.muted2, fontWeight: _activeField == 2 ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                ],
              ),
            ),

            // Emoji grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _C.border),
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _quickEmojis.map((emoji) {
                  return GestureDetector(
                    onTap: () => _insertEmoji(emoji, _activeField),
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Result Image ──
            if (_imageBytes != null) ...[
              _buildResultImage(),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  int _activeField = 1;

  Widget _buildResultImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Label
        Row(
          children: [
            Container(
              width: 4, height: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_C.greenG1, _C.emojiG1]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text('RESULT', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
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
                  Text('MIXED', style: TextStyle(color: _C.greenG1, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'MADEEvolveSansEVO', letterSpacing: 1)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Image display card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            children: [
              // Emoji formula
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_emoji1Controller.text.trim(), style: TextStyle(fontSize: 40)),
                  const SizedBox(width: 8),
                  Icon(Icons.add_rounded, color: _C.accent, size: 28),
                  const SizedBox(width: 8),
                  Text(_emoji2Controller.text.trim(), style: TextStyle(fontSize: 40)),
                  const SizedBox(width: 12),
                  Icon(Icons.arrow_forward_rounded, color: _C.muted2, size: 24),
                  const SizedBox(width: 12),
                  Icon(Icons.auto_awesome_rounded, color: _C.emojiG1, size: 28),
                ],
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: _C.border2),
              const SizedBox(height: 20),

              // The mixed image
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _C.border2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.memory(
                    _imageBytes!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded, color: _C.muted, size: 40),
                          const SizedBox(height: 8),
                          Text('Gagal load', style: TextStyle(color: _C.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Download button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.greenG1,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _C.surface,
                    disabledForegroundColor: _C.muted2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: _C.greenG1))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download_rounded, size: 16),
                            const SizedBox(width: 10),
                            Text('DOWNLOAD GAMBAR', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emoji1Controller.dispose();
    _emoji2Controller.dispose();
    super.dispose();
  }
}

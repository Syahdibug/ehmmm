import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  // Instagram Pink
  static const igG1     = Color(0xFFE1306C);
  static const igG2     = Color(0xFFF77737);
}

// ── INSTAGRAM DOWNLOADER PAGE ────────────────────────────────────────────────
class InstagramDownloaderPage extends StatefulWidget {
  final String sessionKey;

  const InstagramDownloaderPage({super.key, required this.sessionKey});

  @override
  State<InstagramDownloaderPage> createState() => _InstagramDownloaderPageState();
}

class _InstagramDownloaderPageState extends State<InstagramDownloaderPage> {
  final TextEditingController _urlController = TextEditingController();
  Map<String, dynamic>? _resultData;
  List<Map<String, dynamic>> _downloadUrls = [];
  Map<String, dynamic>? _meta;
  bool _isLoading = false;

  Future<void> _fetchInstagram() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showSnackBar('URL Instagram wajib diisi', isError: true);
      return;
    }
    final igPattern = RegExp(r'(instagram\.com|instagr\.am)');
    if (!igPattern.hasMatch(url)) {
      _showSnackBar('Masukkan URL Instagram yang valid', isError: true);
      return;
    }
    setState(() {
      _isLoading = true;
      _resultData = null;
      _downloadUrls = [];
      _meta = null;
    });
    try {
      final encoded = Uri.encodeComponent(url);
      final response = await http.get(Uri.parse(
          'https://api.siputzx.my.id/api/d/igram?url=$encoded'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final result = data['data'] as Map<String, dynamic>;
          setState(() {
            _resultData = result;
            _downloadUrls = (result['url'] as List<dynamic>? ?? [])
                .map((u) => Map<String, dynamic>.from(u))
                .toList();
            _meta = result['meta'] as Map<String, dynamic>?;
          });
        } else {
          _showSnackBar('Gagal mengambil data Instagram', isError: true);
        }
      } else {
        _showSnackBar('Gagal terhubung ke layanan (${response.statusCode})', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isDownloading = false;

  Future<void> _openInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _downloadAndShare(String downloadUrl, String name, String ext) async {
    if (downloadUrl.isEmpty) {
      _showSnackBar('URL download tidak tersedia', isError: true);
      return;
    }
    setState(() => _isDownloading = true);
    try {
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final safeExt = ext.replaceAll('.', '').toLowerCase().isEmpty ? 'mp4' : ext.replaceAll('.', '').toLowerCase();
        final file = File('${directory.path}/ig_${name.replaceAll(' ', '_')}_${timestamp}.$safeExt');
        await file.writeAsBytes(response.bodyBytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Instagram $safeExt');
        _showSnackBar('File berhasil disimpan!', isError: false);
      } else {
        _showSnackBar('Gagal mengunduh file', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error download: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isDownloading = false);
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

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return '$number';
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
                gradient: LinearGradient(
                  colors: [_C.igG1, _C.igG2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IG DOWNLOADER', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.bold, color: _C.text)),
                Text('Instagram Saver', style: TextStyle(fontSize: 10, color: _C.muted)),
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
                      gradient: LinearGradient(
                        colors: [_C.igG1, _C.igG2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('INSTAGRAM DOWNLOADER', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text('Paste URL Instagram untuk download foto, reel, atau story.', style: TextStyle(fontSize: 12, color: _C.muted)),
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
                    gradient: LinearGradient(colors: [_C.igG1, _C.igG2]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('INPUT URL', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
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
                  Text('INSTAGRAM URL', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: _C.muted, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border2),
                    ),
                    child: TextField(
                      controller: _urlController,
                      style: TextStyle(color: _C.text, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'ShareTechMono', letterSpacing: 0.5),
                      keyboardType: TextInputType.url,
                      cursorColor: _C.accent,
                      onSubmitted: (_) => _fetchInstagram(),
                      decoration: InputDecoration(
                        hintText: 'https://instagram.com/reel/xxxxx',
                        hintStyle: TextStyle(color: _C.muted2, fontSize: 13),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(Icons.link_rounded, color: _C.muted, size: 18),
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
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_C.igG1, _C.igG2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _fetchInstagram,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.transparent,
                          disabledForegroundColor: _C.muted2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.download_rounded, size: 16),
                                  const SizedBox(width: 10),
                                  Text('DOWNLOAD INSTAGRAM', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Result ──
            if (_isLoading) ...[
              _buildLoadingIndicator(),
            ] else if (_resultData != null) ...[
              _buildMediaInfo(),
              const SizedBox(height: 16),
              _buildDownloadList(),
              const SizedBox(height: 16),
              _buildCommentsSection(),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: 40, height: 40,
            child: CircularProgressIndicator(strokeWidth: 3, color: _C.igG1),
          ),
        ),
        const SizedBox(height: 14),
        Text('Mengambil data Instagram...', style: TextStyle(color: _C.muted, fontSize: 13)),
      ],
    );
  }

  Widget _buildMediaInfo() {
    final result = _resultData!;
    final thumb = result['thumb'] as String? ?? '';
    final meta = _meta;
    final title = meta?['title'] as String? ?? 'No title';
    final username = meta?['username'] as String? ?? '';
    final source = meta?['source'] as String? ?? '';
    final shortcode = meta?['shortcode'] as String? ?? '';
    final likeCount = meta?['like_count'] as int? ?? 0;
    final commentCount = meta?['comment_count'] as int? ?? 0;
    final takenAt = meta?['taken_at'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          if (thumb.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: thumb,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 220,
                  color: _C.surface,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: _C.igG1),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 220,
                  color: _C.surface,
                  child: Center(
                    child: Icon(Icons.camera_alt_rounded, color: _C.igG1, size: 48),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),

          // Title
          Text(
            title,
            style: TextStyle(color: _C.text, fontSize: 15, fontWeight: FontWeight.bold),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Stats row
          Row(
            children: [
              // Likes
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.igG1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _C.igG1.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_rounded, color: _C.igG1, size: 12),
                    const SizedBox(width: 4),
                    Text(_formatNumber(likeCount), style: TextStyle(color: _C.igG1, fontSize: 10, fontFamily: 'ShareTechMono', fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Comments
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.blueG1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _C.blueG1.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: _C.blueG1, size: 12),
                    const SizedBox(width: 4),
                    Text(_formatNumber(commentCount), style: TextStyle(color: _C.blueG1, fontSize: 10, fontFamily: 'ShareTechMono', fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Spacer(),
              // Instagram badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _C.igG1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('INSTAGRAM', style: TextStyle(color: _C.igG1, fontSize: 9, fontFamily: 'ShareTechMono', fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Author & date row
          Row(
            children: [
              // Author
              if (username.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.igG1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _C.igG1.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_outline_rounded, color: _C.igG1, size: 12),
                      const SizedBox(width: 4),
                      Text('@$username', style: TextStyle(color: _C.igG1, fontSize: 10, fontFamily: 'ShareTechMono'), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Date
              if (takenAt > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.muted2.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, color: _C.muted, size: 10),
                      const SizedBox(width: 4),
                      Text(_formatDate(takenAt), style: TextStyle(color: _C.muted, fontSize: 10, fontFamily: 'ShareTechMono')),
                    ],
                  ),
                ),
            ],
          ),
          // Open on Instagram button
          if (source.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                onPressed: () => _openInBrowser(source),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _C.igG1,
                  side: BorderSide(color: _C.igG1.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 14),
                    const SizedBox(width: 6),
                    Text('BUKA DI INSTAGRAM', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDownloadList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Label
        Row(
          children: [
            Container(
              width: 4, height: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_C.greenG1, _C.igG1]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text('DOWNLOAD LINKS', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _C.greenG1.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _C.greenG1.withOpacity(0.25)),
              ),
              child: Text('${_downloadUrls.length} available', style: TextStyle(color: _C.greenG1, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono')),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Download cards
        ..._downloadUrls.map((item) => _buildDownloadCard(item)),
      ],
    );
  }

  Widget _buildDownloadCard(Map<String, dynamic> item) {
    final downloadUrl = item['url'] as String? ?? '';
    final name = item['name'] as String? ?? 'Unknown';
    final type = item['type'] as String? ?? '';
    final ext = item['ext'] as String? ?? '';
    final quality = item['quality'] as dynamic;
    final subname = item['subname'] as String? ?? '';

    final qualityStr = quality != null ? '${quality}p' : subname;
    final color = _C.igG1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.25), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Icon(
                type == 'mp4' ? Icons.videocam_rounded : Icons.image_rounded,
                color: Colors.white, size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name.toUpperCase(),
                        style: TextStyle(color: _C.text, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      if (qualityStr.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _C.igG1.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            qualityStr.toUpperCase(),
                            style: TextStyle(color: _C.igG1, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ext.toUpperCase(),
                    style: TextStyle(color: _C.muted, fontSize: 11, fontFamily: 'ShareTechMono'),
                  ),
                ],
              ),
            ),
            // Download button
            GestureDetector(
              onTap: _isDownloading ? null : (downloadUrl.isNotEmpty ? () => _downloadAndShare(downloadUrl, name, ext) : null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: _isDownloading
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(ext.toUpperCase(), style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'MADEEvolveSansEVO', letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    final meta = _meta;
    if (meta == null) return const SizedBox.shrink();

    final comments = (meta['comments'] as List<dynamic>? ?? [])
        .map((c) => Map<String, dynamic>.from(c))
        .toList();

    if (comments.isEmpty) return const SizedBox.shrink();

    final commentCount = meta['comment_count'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Label
        Row(
          children: [
            Container(
              width: 4, height: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_C.igG1, _C.igG2]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text('COMMENTS', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _C.igG1.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _C.igG1.withOpacity(0.25)),
              ),
              child: Text('${_formatNumber(commentCount)} total', style: TextStyle(color: _C.igG1, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono')),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Comments card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            children: [
              // Show max 5 comments
              ...comments.take(5).map((comment) => _buildCommentItem(comment)),
              if (comments.length > 5) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '+ ${comments.length - 5} more comments',
                      style: TextStyle(color: _C.muted, fontSize: 11, fontFamily: 'ShareTechMono'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final username = comment['username'] as String? ?? 'anonymous';
    final text = comment['text'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar placeholder
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.igG1, _C.igG2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.person_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@$username',
                  style: TextStyle(color: _C.igG1, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono'),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(color: _C.text, fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}

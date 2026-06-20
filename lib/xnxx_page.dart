// xnxx_page.dart — XNXX Search, Download & Watch
// REWRITTEN: Video player fetches API data, quality selector, loadHtmlString with baseUrl for Referer
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ── COLOR SCHEME ──────────────────────────────────────────────────────────────
class _XC {
  static const bg       = Color(0xFF0a0a12);
  static const bg2      = Color(0xFF0f0f1a);
  static const surface  = Color(0xFF141422);
  static const card     = Color(0xFF1a1a2e);
  static const accent   = Color(0xFFE5253B);
  static const accent2  = Color(0xFFB71C1C);
  static const accent3  = Color(0xFFFF5252);
  static const gold     = Color(0xFFFFD447);
  static const success  = Color(0xFF00E676);
  static const danger   = Color(0xFFFF4D6D);
  static const text     = Color(0xFFE8E8EE);
  static const muted    = Color(0x73E8E8EE);
  static const muted2   = Color(0x38E8E8EE);
  static const border   = Color(0x1AE5253B);
  static const border2  = Color(0x0FFFFFFF);
}

// ── XNXX API ──────────────────────────────────────────────────────────────────
class _XnxxApi {
  static const String _baseUrl = 'https://api.deline.web.id';

  static Future<Map<String, dynamic>?> search(String query) async {
    try {
      final uri = Uri.parse('$_baseUrl/search/xnxx').replace(queryParameters: {'q': query});
      debugPrint('[XNXX API] Search: $uri');
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data is Map<String, dynamic> ? data : null;
      }
      return null;
    } catch (e) {
      debugPrint('[XNXX API] Search Error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> download(String url) async {
    try {
      final uri = Uri.parse('$_baseUrl/downloader/xnxx').replace(queryParameters: {'url': url});
      debugPrint('[XNXX API] Download: $uri');
      final res = await http.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data is Map<String, dynamic> ? data : null;
      }
      return null;
    } catch (e) {
      debugPrint('[XNXX API] Download Error: $e');
      return null;
    }
  }

  static Map<String, String> parseInfo(String info) {
    final lines = info.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    String views = '', rating = '', duration = '', quality = '';
    for (final line in lines) {
      if (views.isEmpty) {
        final parts = line.split(RegExp(r'\s+'));
        for (final p in parts) {
          if (p.contains('%')) { rating = p; }
          else if (p.isNotEmpty && p != '-') { views = views.isEmpty ? p : '$views $p'; }
        }
        if (views.endsWith(' ')) views = views.trim();
      }
      if (line.contains(RegExp(r'(min|sec|hour)', caseSensitive: false))) { duration = line; }
      if (RegExp(r'^\d{3,4}p$').hasMatch(line)) { quality = line; }
    }
    return {'views': views, 'rating': rating, 'duration': duration, 'quality': quality};
  }

  static Map<String, String> extractLinks(Map<String, dynamic> data) {
    final links = <String, String>{};
    final dynamic result = data['result'] ?? data['data'];
    if (result is Map) {
      dynamic videosMap = result['videos'];
      if (videosMap is Map) { videosMap = videosMap['videos']; }
      if (videosMap is Map) {
        for (final entry in videosMap.entries) {
          final key = entry.key.toString().toUpperCase();
          if (entry.value is String && entry.value.toString().startsWith('http')) {
            links[key] = entry.value.toString();
          }
        }
      }
      if (result['videos'] is List) {
        for (final v in (result['videos'] as List)) {
          if (v is Map) {
            final label = (v['quality'] ?? v['label'] ?? v['res'] ?? 'Video').toString();
            final url = v['url'] ?? v['link'] ?? v['download'] ?? '';
            if (url is String && url.startsWith('http')) { links[label.toUpperCase()] = url; }
          }
        }
      }
      if (links.isEmpty) {
        for (final k in ['url', 'link', 'download', 'download_url', 'video_url', 'dl', 'video', 'high', 'low', 'HLS']) {
          final v = result[k];
          if (v is String && v.isNotEmpty && v.startsWith('http')) { links[k.toUpperCase()] = v; }
        }
      }
    } else if (result is String && result.startsWith('http')) {
      links['DOWNLOAD'] = result;
    } else if (result is List && result.isNotEmpty) {
      final first = result[0];
      if (first is Map) {
        for (final k in ['url', 'link', 'download', 'download_url', 'video_url', 'dl', 'video']) {
          final v = first[k];
          if (v is String && v.isNotEmpty && v.startsWith('http')) {
            final label = (first['quality'] ?? first['label'] ?? first['res'] ?? k).toString().toUpperCase();
            links[label] = v;
          }
        }
      } else if (first is String && first.startsWith('http')) {
        links['DOWNLOAD'] = first;
      }
    }
    return links;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// XNXX PAGE
// ═══════════════════════════════════════════════════════════════════════════════
class XnxxPage extends StatefulWidget {
  const XnxxPage({super.key});
  @override
  State<XnxxPage> createState() => _XnxxPageState();
}

class _XnxxPageState extends State<XnxxPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _errorMessage;
  String _lastQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _glowController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..repeat(reverse: true);
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _glowController.dispose(); _fadeController.dispose();
    _searchController.dispose(); _focusNode.dispose();
    super.dispose();
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isSearching = true; _hasSearched = true; _errorMessage = null; _results.clear(); _lastQuery = query; });
    final data = await _XnxxApi.search(query);
    if (!mounted) return;
    if (data == null) { setState(() { _isSearching = false; _errorMessage = 'Gagal terhubung ke API. Cek koneksi internet kamu.'; }); return; }
    if (data['status'] == false) { setState(() { _isSearching = false; _errorMessage = data['message']?.toString() ?? 'API error'; }); return; }
    final List<dynamic> raw = data['result'] ?? [];
    final videos = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final title = (item['title'] ?? '').toString();
      final link = (item['link'] ?? '').toString();
      final info = (item['info'] ?? '').toString();
      if (title.isEmpty && link.isEmpty) continue;
      final parsed = _XnxxApi.parseInfo(info);
      videos.add({'title': title, 'link': link, 'info': info, 'views': parsed['views'] ?? '', 'rating': parsed['rating'] ?? '', 'duration': parsed['duration'] ?? '', 'quality': parsed['quality'] ?? ''});
    }
    setState(() { _results = videos; _isSearching = false; });
  }

  void _showVideoOptions(Map<String, dynamic> video) {
    final title = video['title'] ?? '';
    final link = video['link'] ?? '';
    final duration = video['duration'] ?? '';
    final quality = video['quality'] ?? '';
    final views = video['views'] ?? '';
    final rating = video['rating'] ?? '';
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => Container(margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(color: _XC.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _XC.border, width: 1), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 12))]),
        child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 3, decoration: BoxDecoration(color: _XC.accent, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          Text(title, style: const TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 14, fontWeight: FontWeight.w700, color: _XC.text, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _XC.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              if (duration.isNotEmpty) ...[const Icon(Icons.schedule_rounded, color: _XC.muted, size: 12), const SizedBox(width: 4), Text(duration, style: const TextStyle(color: _XC.muted, fontSize: 11, fontFamily: 'ShareTechMono')), const SizedBox(width: 12)],
              if (quality.isNotEmpty) ...[Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _XC.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text(quality.toUpperCase(), style: const TextStyle(color: _XC.accent, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono'))), const SizedBox(width: 12)],
              if (views.isNotEmpty) ...[const Icon(Icons.visibility_rounded, color: _XC.muted, size: 12), const SizedBox(width: 4), Text(views, style: const TextStyle(color: _XC.muted, fontSize: 11, fontFamily: 'ShareTechMono')), const SizedBox(width: 12)],
              if (rating.isNotEmpty) Text(rating, style: const TextStyle(color: _XC.gold, fontSize: 11, fontFamily: 'ShareTechMono')),
            ])),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: GestureDetector(onTap: () { Navigator.pop(context); _watchVideo(link, title); },
              child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(gradient: LinearGradient(colors: [_XC.accent, _XC.accent2]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: _XC.accent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Text('WATCH', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.5))])))),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(onTap: () { Navigator.pop(context); _handleDownload(link, title); },
              child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: _XC.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _XC.border)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.download_rounded, color: _XC.success, size: 18), SizedBox(width: 8), Text('DOWNLOAD', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.w700, color: _XC.text, letterSpacing: 1.5))])))),
          ]),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: GestureDetector(onTap: () { Navigator.pop(context); _openInBrowser(link); },
            child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _XC.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _XC.border2)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.open_in_new_rounded, color: _XC.muted, size: 16), SizedBox(width: 8), Text('OPEN IN BROWSER', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: _XC.muted, letterSpacing: 1))])))),
          const SizedBox(height: 8),
        ]))));
  }

  Future<void> _watchVideo(String videoUrl, String title) async {
    if (videoUrl.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => _XnxxVideoPlayerPage(videoPageUrl: videoUrl, title: title)));
  }

  void _showActionError(String msg) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => Container(margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(color: _XC.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _XC.border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24)]),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 3, decoration: BoxDecoration(color: _XC.danger, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18), const Icon(Icons.warning_amber_rounded, color: _XC.danger, size: 40), const SizedBox(height: 14),
          const Text('ERROR', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 14, fontWeight: FontWeight.w700, color: _XC.danger)), const SizedBox(height: 8),
          Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _XC.surface, borderRadius: BorderRadius.circular(12)),
            child: Text(msg, style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: _XC.muted, height: 1.5), textAlign: TextAlign.center)), const SizedBox(height: 16),
          GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12), decoration: BoxDecoration(color: _XC.accent, borderRadius: BorderRadius.circular(12)),
            child: const Text('OK', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)))),
        ]))));
  }

  void _openInBrowser(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) { await launchUrl(uri, mode: LaunchMode.externalApplication); }
  }

  Future<void> _handleDownload(String videoUrl, String title) async {
    if (videoUrl.isEmpty) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const _FetchLoadingDialog(label: 'FETCHING DOWNLOAD...'));
    final data = await _XnxxApi.download(videoUrl);
    if (!mounted) return;
    Navigator.pop(context);
    if (data == null) { _showActionError('Gagal terhubung ke server. Coba lagi nanti.'); return; }
    if (data['status'] == false) { _showActionError(data['error'] ?? data['message'] ?? 'Download gagal.'); return; }
    final links = _XnxxApi.extractLinks(data);
    if (links.isEmpty) { _showActionError('Tidak ditemukan link download. Coba buka di browser.'); return; }
    _showDownloadResult(links, title);
  }

  void _showDownloadResult(Map<String, String> links, String title) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => Container(margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(color: _XC.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _XC.border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24)]),
        child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 3, decoration: BoxDecoration(color: _XC.success, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18), const Icon(Icons.check_circle_rounded, color: _XC.success, size: 40), const SizedBox(height: 10),
          const Text('DOWNLOAD READY', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 14, fontWeight: FontWeight.w700, color: _XC.success, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _XC.surface, borderRadius: BorderRadius.circular(12)),
            child: Text(title, style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: _XC.muted, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis)),
          const SizedBox(height: 16),
          ...links.entries.map((entry) {
            final isHLS = entry.key.toUpperCase().contains('HLS');
            return Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity, child: GestureDetector(
              onTap: () { Navigator.pop(context); _openInBrowser(entry.value); },
              child: Container(padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16), decoration: BoxDecoration(color: _XC.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _XC.border)),
                child: Row(children: [const Icon(Icons.download_rounded, color: _XC.success, size: 18), const SizedBox(width: 10),
                  Expanded(child: Text(entry.key, style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, fontWeight: FontWeight.bold, color: _XC.success, letterSpacing: 1))),
                  const Icon(Icons.arrow_forward_rounded, color: _XC.muted2, size: 16)])))));
          }), const SizedBox(height: 8),
        ]))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _XC.bg, body: SafeArea(child: Column(children: [_buildHeader(), const SizedBox(height: 8), _buildSearchBar(), const SizedBox(height: 8), Expanded(child: _buildBody())])));
  }

  Widget _buildHeader() {
    return ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), child: Container(
      height: 58, padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: const Color(0xEB0A0A12), border: Border(bottom: BorderSide(color: _XC.border))),
      child: Row(children: [
        GestureDetector(onTap: () => Navigator.pop(context), child: Container(width: 38, height: 38, decoration: BoxDecoration(color: _XC.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _XC.border2)), child: const Icon(Icons.arrow_back_rounded, color: _XC.muted, size: 15))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          ShaderMask(shaderCallback: (b) => const LinearGradient(colors: [_XC.accent, _XC.accent3]).createShader(b), child: const Text('XNXX EXPLORER', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2))),
          const Text('SEARCH \u2022 DOWNLOAD \u2022 STREAM', style: TextStyle(fontSize: 9, color: _XC.muted, letterSpacing: 1, fontFamily: 'ShareTechMono')),
        ])),
        AnimatedBuilder(animation: _glowController, builder: (_, __) => Container(width: 38, height: 38, decoration: BoxDecoration(color: _XC.accent.withOpacity(0.08 + _glowController.value * 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: _XC.accent.withOpacity(0.2 + _glowController.value * 0.2))), child: Icon(Icons.hd_rounded, color: _XC.accent.withOpacity(0.6 + _glowController.value * 0.4), size: 15))),
      ]))));
  }

  Widget _buildSearchBar() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: AnimatedContainer(duration: const Duration(milliseconds: 200), height: 46,
      decoration: BoxDecoration(color: _XC.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _focusNode.hasFocus ? _XC.accent.withOpacity(0.5) : _XC.border2), boxShadow: _focusNode.hasFocus ? [BoxShadow(color: _XC.accent.withOpacity(0.1), blurRadius: 10)] : []),
      child: Row(children: [
        const SizedBox(width: 14), Icon(Icons.search_rounded, color: _focusNode.hasFocus ? _XC.accent : _XC.muted2, size: 16), const SizedBox(width: 10),
        Expanded(child: TextField(controller: _searchController, focusNode: _focusNode, style: const TextStyle(color: _XC.text, fontSize: 13, fontFamily: 'ShareTechMono'), cursorColor: _XC.accent, textInputAction: TextInputAction.search, onSubmitted: (v) => _doSearch(v),
          decoration: InputDecoration(hintText: 'Cari video XNXX...', hintStyle: const TextStyle(color: _XC.muted2, fontSize: 13), border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 12)))),
        if (_isSearching) const Padding(padding: EdgeInsets.only(right: 12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(_XC.accent))))
        else if (_searchController.text.isNotEmpty) GestureDetector(onTap: () { _searchController.clear(); setState(() { _results.clear(); _hasSearched = false; _errorMessage = null; }); _focusNode.unfocus(); }, child: const Padding(padding: EdgeInsets.only(right: 10), child: Icon(Icons.close_rounded, color: _XC.muted, size: 16))),
        const SizedBox(width: 4),
        GestureDetector(onTap: () { if (_searchController.text.trim().isNotEmpty) { _doSearch(_searchController.text.trim()); _focusNode.unfocus(); } },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_XC.accent, _XC.accent2]), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: _XC.accent.withOpacity(0.3), blurRadius: 8)]), child: const Icon(Icons.search_rounded, color: Colors.white, size: 16))),
        const SizedBox(width: 12),
      ])));
  }

  Widget _buildBody() {
    if (_isSearching) return _buildShimmerList();
    if (_errorMessage != null) return _buildErrorView();
    if (!_hasSearched) return _buildWelcomeView();
    if (_results.isEmpty) return _buildEmptyView();
    return FadeTransition(opacity: _fadeController, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildResultHeader(), Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), itemCount: _results.length, itemBuilder: (_, i) => _buildVideoCard(_results[i], i)))]));
  }

  Widget _buildResultHeader() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Row(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _XC.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: _XC.accent.withOpacity(0.2))), child: Text('${_results.length} VIDEO', style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: _XC.accent, fontWeight: FontWeight.bold, letterSpacing: 1))),
      const Spacer(), Text('"$_lastQuery"', style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: _XC.muted2)),
    ]));
  }

  Widget _buildVideoCard(Map<String, dynamic> video, int index) {
    final title = video['title'] ?? '';
    final duration = video['duration'] ?? '';
    final quality = video['quality'] ?? '';
    final views = video['views'] ?? '';
    final rating = video['rating'] ?? '';
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: GestureDetector(onTap: () => _showVideoOptions(video),
      child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _XC.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _XC.border)),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: [_XC.accent, _XC.accent2]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.w600, color: _XC.text, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6), Row(children: [
              if (duration.isNotEmpty) ...[const Icon(Icons.schedule_rounded, color: _XC.muted, size: 11), const SizedBox(width: 3), Text(duration, style: const TextStyle(color: _XC.muted, fontSize: 10, fontFamily: 'ShareTechMono')), const SizedBox(width: 10)],
              if (quality.isNotEmpty) ...[Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: _XC.accent.withOpacity(0.2), borderRadius: BorderRadius.circular(3)), child: Text(quality.toUpperCase(), style: const TextStyle(color: _XC.accent, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono'))), const SizedBox(width: 10)],
              if (views.isNotEmpty) ...[const Icon(Icons.visibility_rounded, color: _XC.muted, size: 11), const SizedBox(width: 3), Text(views, style: const TextStyle(color: _XC.muted, fontSize: 10, fontFamily: 'ShareTechMono'))],
            ]),
          ])), const Icon(Icons.more_vert_rounded, color: _XC.muted2, size: 18),
        ]))));
  }

  Widget _buildShimmerList() {
    return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4), itemCount: 6, itemBuilder: (_, __) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Shimmer.fromColors(baseColor: _XC.surface, highlightColor: _XC.card, child: Container(height: 76, decoration: BoxDecoration(color: _XC.surface, borderRadius: BorderRadius.circular(14))))));
  }

  Widget _buildWelcomeView() {
    return Center(child: SingleChildScrollView(padding: const EdgeInsets.all(30), child: Column(children: [
      AnimatedBuilder(animation: _glowController, builder: (_, __) => Container(width: 110, height: 110, decoration: BoxDecoration(color: _XC.accent.withOpacity(0.06 + _glowController.value * 0.08), shape: BoxShape.circle, border: Border.all(color: _XC.accent.withOpacity(0.15 + _glowController.value * 0.15), width: 2)), child: Icon(Icons.play_circle_filled_rounded, color: _XC.accent.withOpacity(0.5 + _glowController.value * 0.5), size: 44))),
      const SizedBox(height: 24),
      ShaderMask(shaderCallback: (b) => const LinearGradient(colors: [_XC.accent, _XC.accent3]).createShader(b), child: const Text('XNXX', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4))),
      const SizedBox(height: 8), const Text('Search, Download & Watch', style: TextStyle(color: _XC.muted, fontSize: 13, fontFamily: 'ShareTechMono')),
      const SizedBox(height: 4), Text('api.deline.web.id', style: TextStyle(color: _XC.accent.withOpacity(0.6), fontSize: 11, fontFamily: 'ShareTechMono')),
      const SizedBox(height: 28),
      _buildFeatureCard(Icons.search_rounded, 'SEARCH', 'Cari video berdasarkan keyword'), const SizedBox(height: 10),
      _buildFeatureCard(Icons.download_rounded, 'DOWNLOAD', 'Download video langsung dari server'), const SizedBox(height: 10),
      _buildFeatureCard(Icons.play_circle_filled_rounded, 'STREAM', 'Tonton langsung di dalam app'), const SizedBox(height: 28),
      const Align(alignment: Alignment.centerLeft, child: Text('QUICK SEARCH', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 11, fontWeight: FontWeight.w700, color: _XC.muted, letterSpacing: 2))),
      const SizedBox(height: 10),
      _buildQuickSearch('Japanese'), _buildQuickSearch('Korean'), _buildQuickSearch('Indo'), _buildQuickSearch('Thai'),
    ])));
  }

  Widget _buildFeatureCard(IconData icon, String title, String desc) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _XC.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _XC.border)),
      child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: _XC.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _XC.accent.withOpacity(0.2))), child: Icon(icon, color: _XC.accent, size: 18)),
        const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.w700, color: _XC.text, letterSpacing: 1.5)), const SizedBox(height: 3), Text(desc, style: const TextStyle(color: _XC.muted, fontSize: 11, fontFamily: 'ShareTechMono'))]))]));
  }

  Widget _buildQuickSearch(String query) {
    return GestureDetector(onTap: () { _searchController.text = query; _doSearch(query); },
      child: Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: _XC.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _XC.border)),
        child: Row(children: [const Icon(Icons.search_rounded, color: _XC.accent, size: 13), const SizedBox(width: 12), Text(query, style: const TextStyle(color: _XC.text, fontSize: 13)), const Spacer(), const Icon(Icons.chevron_right_rounded, color: _XC.muted2, size: 18)])));
  }

  Widget _buildErrorView() {
    return Center(child: SingleChildScrollView(padding: const EdgeInsets.all(30), child: Column(children: [
      const Icon(Icons.warning_amber_rounded, color: _XC.danger, size: 44), const SizedBox(height: 16),
      const Text('Oops!', style: TextStyle(color: _XC.text, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _XC.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: _XC.border)),
        child: Text(_errorMessage ?? 'Terjadi kesalahan', style: const TextStyle(color: _XC.muted, fontSize: 12, height: 1.5, fontFamily: 'ShareTechMono'), textAlign: TextAlign.center)),
      const SizedBox(height: 20), GestureDetector(onTap: () => _doSearch(_lastQuery), child: Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12), decoration: BoxDecoration(color: _XC.accent, borderRadius: BorderRadius.circular(12)),
        child: const Text('RETRY', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)))),
    ])));
  }

  Widget _buildEmptyView() {
    return Center(child: SingleChildScrollView(padding: const EdgeInsets.all(30), child: Column(children: [
      const Icon(Icons.search_off_rounded, color: _XC.muted2, size: 48), const SizedBox(height: 16),
      const Text('Tidak ditemukan', style: TextStyle(color: _XC.text, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      const Text('Coba keyword lain ya...', style: TextStyle(color: _XC.muted, fontSize: 13)),
    ])));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOADING DIALOG
// ═══════════════════════════════════════════════════════════════════════════════
class _FetchLoadingDialog extends StatefulWidget {
  final String label;
  const _FetchLoadingDialog({required this.label});
  @override
  State<_FetchLoadingDialog> createState() => _FetchLoadingDialogState();
}

class _FetchLoadingDialogState extends State<_FetchLoadingDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Dialog(backgroundColor: Colors.transparent, child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: _XC.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _XC.border)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(animation: _controller, builder: (_, __) => Container(width: 48, height: 48, decoration: BoxDecoration(color: _XC.accent.withOpacity(0.1 + _controller.value * 0.15), shape: BoxShape.circle, border: Border.all(color: _XC.accent.withOpacity(0.2 + _controller.value * 0.3))),
          child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(_XC.accent)))))),
        const SizedBox(height: 16), Text(widget.label, style: const TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.w700, color: _XC.text, letterSpacing: 1.5)),
      ])));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VIDEO PLAYER PAGE — Fetches API data, quality selector, HTML player + HLS.js
// Uses loadHtmlString with baseUrl for Referer header on CDN requests
// ═══════════════════════════════════════════════════════════════════════════════
class _XnxxVideoPlayerPage extends StatefulWidget {
  final String videoPageUrl;
  final String title;
  const _XnxxVideoPlayerPage({required this.videoPageUrl, this.title = ''});
  @override
  State<_XnxxVideoPlayerPage> createState() => _XnxxVideoPlayerPageState();
}

class _XnxxVideoPlayerPageState extends State<_XnxxVideoPlayerPage> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;
  bool _isWebViewLoading = true;
  bool _isFullScreen = false;

  // Quality
  List<Map<String, String>> _qualities = []; // [{title, url}]
  int _selectedQualityIndex = 0;
  bool _showQualitySelector = true;

  String? _streamUrl;
  late WebViewController _webViewController;

  // Ad domains
  static const List<String> _adDomains = [
    'doubleclick.net', 'googlesyndication.com', 'googleadservices.com', 'google-analytics.com',
    'adnxs.com', 'adsrvr.org', 'taboola.com', 'outbrain.com', 'popads.net', 'popcash.net',
    'propellerads.com', 'juicyads.com', 'exoclick.com', 'trafficjunky.com', 'adsterra.com',
    'hilltopads.net', 'clickadu.com', 'richpush.com', 'adform.net', 'criteo.com',
    'amazon-adsystem.com', 'moatads.com', 'scorecardresearch.com', 'quantserve.com',
    'rubiconproject.com', 'openx.net', 'casalemedia.com', 'indexexchange.com', 'pubmatic.com',
    'smartadserver.com', 'advertising.com', 'adsymptotic.com', 'bidswitch.com', 'lijit.com',
    'media.net', 'mookie1.com', 'nativex.com', 'serving-sys.com', 'sharethis.com', 'simpli.fi',
    'sitescout.com', 'sonobi.com', 'spotxchange.com', 'tapad.com', 'tidaltv.com', 'towerdata.com',
    'turn.com', 'yldbt.com', 'zergnet.com', 'mgid.com', 'revcontent.com', 'contentabc.com',
    'bidvertiser.com', 'yllix.com', 'evadav.com', 'monetag.com', 'profitablecpmrate.com',
    'popunder.net', 'clicksor.com', 'infolinks.com', 'chitika.com', 'buysellads.com',
  ];

  bool _isAdUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    for (final adDomain in _adDomains) {
      if (host.contains(adDomain)) return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchVideoData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      final isNowFullScreen = size.width > size.height;
      if (isNowFullScreen != _isFullScreen) {
        setState(() { _isFullScreen = isNowFullScreen; });
        if (_isFullScreen) {
          SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        } else {
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        }
      }
    });
  }

  Future<void> _fetchVideoData() async {
    try {
      final data = await _XnxxApi.download(widget.videoPageUrl);
      if (!mounted) return;
      if (data == null) {
        setState(() { _isLoading = false; _isError = true; _errorMessage = 'Gagal terhubung ke server. Coba lagi nanti.'; });
        return;
      }
      if (data['status'] == false) {
        setState(() { _isLoading = false; _isError = true; _errorMessage = data['error'] ?? data['message'] ?? 'Gagal mengambil video.'; });
        return;
      }
      final links = _XnxxApi.extractLinks(data);
      if (links.isEmpty) {
        setState(() { _isLoading = false; _isError = true; _errorMessage = 'Tidak ditemukan link video. Coba buka di browser.'; });
        return;
      }
      // Convert to quality list
      setState(() {
        _qualities = links.entries.map((e) => {'title': e.key, 'url': e.value}).toList();
        // Default: prefer HIGH > LOW > HLS > first
        _selectedQualityIndex = 0;
        for (int i = 0; i < _qualities.length; i++) {
          if (_qualities[i]['title']!.toUpperCase().contains('HIGH')) {
            _selectedQualityIndex = i;
            break;
          }
        }
        _streamUrl = _qualities[_selectedQualityIndex]['url'];
        _isLoading = false;
      });
      _initializeWebView();
    } catch (e) {
      debugPrint('Error fetching video data: $e');
      if (mounted) setState(() { _isLoading = false; _isError = true; _errorMessage = 'Terjadi kesalahan. Coba lagi.'; });
    }
  }

  void _changeQuality(int index) {
    if (index < 0 || index >= _qualities.length) return;
    setState(() {
      _selectedQualityIndex = index;
      _streamUrl = _qualities[index]['url'];
      _isWebViewLoading = true;
      _showQualitySelector = false;
    });
    _initializeWebView();
  }

  void _initializeWebView() {
    if (_streamUrl == null) return;
    final html = _generatePlayerHtml(_streamUrl!);
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel('FullScreen', onMessageReceived: (JavaScriptMessage message) {
        if (message.message == 'enter') {
          _enterFullScreen();
        } else if (message.message == 'exit') {
          _exitFullScreen();
        }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (int progress) {
          if (progress == 100) {
            setState(() { _isWebViewLoading = false; });
            _injectAdBlocker();
          }
        },
        onPageStarted: (_) => setState(() { _isWebViewLoading = true; }),
        onPageFinished: (_) {
          setState(() { _isWebViewLoading = false; });
          _injectAdBlocker();
        },
        onWebResourceError: (_) => setState(() { _isWebViewLoading = false; }),
        onNavigationRequest: (NavigationRequest request) {
          if (_isAdUrl(request.url)) return NavigationDecision.prevent;
          if (!request.url.startsWith('http://') && !request.url.startsWith('https://')) return NavigationDecision.prevent;
          return NavigationDecision.navigate;
        },
      ))
      // KEY FIX: Use loadHtmlString with baseUrl to set Referer header
      ..loadHtmlString(html, baseUrl: 'https://www.xnxx.com/');
  }

  void _injectAdBlocker() {
    _webViewController.runJavaScript('''
      (function() {
        try {
          var style = document.createElement('style');
          style.textContent = 'iframe, [id*="ad"], [class*="ad"], [class*="popup"], div[id^="ads"], div[id^="pop"] { display: none !important; }';
          document.head.appendChild(style);
        } catch(e) {}
      })();
    ''');
  }

  void _enterFullScreen() {
    if (_isFullScreen) return;
    setState(() { _isFullScreen = true; });
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullScreen() {
    if (!_isFullScreen) return;
    setState(() { _isFullScreen = false; });
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _toggleFullScreen() {
    if (_isFullScreen) {
      _exitFullScreen();
    } else {
      _enterFullScreen();
    }
  }

  void _refreshPlayer() {
    setState(() { _isWebViewLoading = true; });
    _initializeWebView();
  }

  void _openInExternalBrowser() async {
    if (widget.videoPageUrl.isNotEmpty) {
      final uri = Uri.parse(widget.videoPageUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  static String _generatePlayerHtml(String videoUrl) {
    final isHls = videoUrl.toLowerCase().contains('.m3u8');
    if (isHls) {
      return '''<!DOCTYPE html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<script src="https://cdn.jsdelivr.net/npm/hls.js@1.5.7/dist/hls.min.js"></script>
<style>*{margin:0;padding:0;box-sizing:border-box}body{background:#000;display:flex;align-items:center;justify-content:center;min-height:100vh;overflow:hidden}
video{width:100%;height:100vh;object-fit:contain;background:#000}</style></head><body>
<video id="v" controls autoplay playsinline></video>
<script>
var video=document.getElementById('v');
if(Hls.isSupported()){var hls=new Hls({xhrSetup:function(xhr,url){xhr.setRequestHeader('Referer','https://www.xnxx.com/');}});hls.loadSource('$videoUrl');hls.attachMedia(video);
hls.on(Hls.Events.MANIFEST_PARSED,function(){video.play().catch(function(){});});
hls.on(Hls.Events.ERROR,function(e,d){if(d.fatal){console.error('HLS Error',d);document.body.innerHTML='<div style="color:#ff4d6d;text-align:center;padding:40px;font-family:sans-serif"><h3>Error Loading Video</h3><p>Stream failed to load</p></div>';}});}
else if(video.canPlayType('application/vnd.apple.mpegurl')){video.src='$videoUrl';video.addEventListener('loadedmetadata',function(){video.play().catch(function(){});});}
video.addEventListener('error',function(){document.body.innerHTML='<div style="color:#ff4d6d;text-align:center;padding:40px;font-family:sans-serif"><h3>Error Loading Video</h3><p>Could not load video from server</p><p style="font-size:12px;color:#888;margin-top:10px">The video URL may have expired. Try again.</p></div>';});
</script></body></html>''';
    } else {
      return '''<!DOCTYPE html>
<html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>*{margin:0;padding:0;box-sizing:border-box}body{background:#000;display:flex;align-items:center;justify-content:center;min-height:100vh;overflow:hidden}
video{width:100%;height:100vh;object-fit:contain;background:#000}</style></head><body>
<video id="v" src="$videoUrl" controls autoplay playsinline></video>
<script>
document.getElementById('v').addEventListener('error',function(){document.body.innerHTML='<div style="color:#ff4d6d;text-align:center;padding:40px;font-family:sans-serif"><h3>Error Loading Video</h3><p>Could not load video from server</p><p style="font-size:12px;color:#888;margin-top:10px">The video URL may have expired. Try again.</p></div>';});
</script></body></html>''';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          _buildWebView(),
          // Exit fullscreen button (top left)
          Positioned(
            top: 12,
            left: 12,
            child: GestureDetector(
              onTap: _exitFullScreen,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
          // Loading overlay
          if (_isWebViewLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: const Center(
                  child: CircularProgressIndicator(color: _XC.accent, strokeWidth: 2.5),
                ),
              ),
            ),
        ]),
      );
    }

    return Scaffold(
      backgroundColor: _XC.bg,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _XC.bg2,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _XC.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _XC.border2)),
          child: const Icon(Icons.arrow_back_rounded, color: _XC.muted, size: 18),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NOW PLAYING', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 11, fontWeight: FontWeight.w700, color: _XC.accent, letterSpacing: 1.5)),
          if (widget.title.isNotEmpty)
            Text(widget.title, style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: _XC.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
      actions: [
        if (!_isLoading && !_isError && _qualities.length > 1)
          GestureDetector(
            onTap: _refreshPlayer,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _XC.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _XC.border2)),
              child: const Icon(Icons.refresh_rounded, color: _XC.muted, size: 18),
            ),
          ),
        GestureDetector(
          onTap: _openInExternalBrowser,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: _XC.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: _XC.border2)),
            child: Row(children: [
              const Icon(Icons.open_in_new_rounded, color: _XC.muted, size: 14),
              const SizedBox(width: 4),
              const Text('BROWSER', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: _XC.muted, letterSpacing: 1)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(
            width: 64, height: 64,
            child: CircularProgressIndicator(strokeWidth: 3, valueColor: const AlwaysStoppedAnimation(_XC.accent)),
          ),
          const SizedBox(height: 20),
          const Text('LOADING VIDEO DATA...', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.w700, color: _XC.text, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          const Text('Fetching stream links from server', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: _XC.muted)),
        ]),
      );
    }

    if (_isError) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(children: [
            const Icon(Icons.warning_amber_rounded, color: _XC.danger, size: 48),
            const SizedBox(height: 18),
            const Text('ERROR', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 16, fontWeight: FontWeight.w700, color: _XC.danger)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _XC.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _XC.border)),
              child: Text(_errorMessage ?? 'Unknown error', style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 12, color: _XC.muted, height: 1.5), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: _fetchVideoData,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [_XC.accent, _XC.accent2]), borderRadius: BorderRadius.circular(14)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('RETRY', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.5)),
                  ]),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: _openInExternalBrowser,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: _XC.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _XC.border)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.open_in_new_rounded, color: _XC.muted, size: 18),
                    SizedBox(width: 8),
                    Text('BROWSER', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.w700, color: _XC.text, letterSpacing: 1.5)),
                  ]),
                ),
              )),
            ]),
          ]),
        ),
      );
    }

    return Column(children: [
      // Video container
      _buildVideoContainer(),
      // Quality selector panel
      if (_showQualitySelector && _qualities.length > 1)
        _buildQualityPanel(),
      // Video info
      if (!_isFullScreen && _showQualitySelector && _qualities.length > 1)
        _buildVideoInfo(),
    ]);
  }

  Widget _buildVideoContainer() {
    return Container(
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(children: [
          _buildWebView(),
          // Loading overlay
          if (_isWebViewLoading)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(_XC.accent))),
                  SizedBox(height: 12),
                  Text('Loading stream...', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 11, color: Colors.white54)),
                ]),
              ),
            ),
          // Quality settings button (top right)
          if (_qualities.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => setState(() { _showQualitySelector = !_showQualitySelector; }),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    const Icon(Icons.settings_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _qualities[_selectedQualityIndex]['title'] ?? '',
                      style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ]),
                ),
              ),
            ),
          // Fullscreen toggle (bottom right)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _toggleFullScreen,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildWebView() {
    return WebViewWidget(controller: _webViewController);
  }

  Widget _buildQualityPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: _XC.bg2,
        border: Border(top: BorderSide(color: _XC.border, width: 1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            const Icon(Icons.high_quality_rounded, color: _XC.accent, size: 18),
            const SizedBox(width: 8),
            const Text('QUALITY SETTINGS', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.w700, color: _XC.accent, letterSpacing: 1.5)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _showQualitySelector = false),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: _XC.surface, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.close_rounded, color: _XC.muted, size: 14),
              ),
            ),
          ]),
        ),
        const Divider(height: 1, color: _XC.border),
        // Quality options
        ...List.generate(_qualities.length, (index) {
          final quality = _qualities[index];
          final isSelected = index == _selectedQualityIndex;
          final isHls = quality['title']!.toUpperCase().contains('HLS');
          return GestureDetector(
            onTap: () => _changeQuality(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? _XC.accent.withOpacity(0.1) : Colors.transparent,
                border: Border(bottom: BorderSide(color: _XC.border2.withOpacity(0.3), width: 0.5)),
              ),
              child: Row(children: [
                // Radio indicator
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? _XC.accent : Colors.transparent,
                    border: Border.all(color: isSelected ? _XC.accent : _XC.muted2, width: 2),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 14),
                // Quality icon
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isHls ? _XC.gold.withOpacity(0.1) : _XC.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isHls ? _XC.gold.withOpacity(0.2) : _XC.border),
                  ),
                  child: Icon(
                    isHls ? Icons.stream_rounded : Icons.play_circle_filled_rounded,
                    color: isHls ? _XC.gold : _XC.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                // Quality label
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(quality['title'] ?? 'Unknown', style: TextStyle(
                    fontFamily: 'ShareTechMono',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? _XC.accent : _XC.text,
                    letterSpacing: 1,
                  )),
                  const SizedBox(height: 2),
                  Text(
                    isHls ? 'HLS Adaptive Stream' : 'Direct MP4 Download',
                    style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: _XC.muted),
                  ),
                ])),
                // Selected badge
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _XC.accent, borderRadius: BorderRadius.circular(4)),
                    child: const Text('ACTIVE', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: _XC.muted2, size: 16),
              ]),
            ),
          );
        }),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildVideoInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (widget.title.isNotEmpty)
          Text(widget.title, style: const TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.w600, color: _XC.text, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: _XC.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: _XC.accent.withOpacity(0.2))),
            child: Text('${_qualities.length} QUALITIES', style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: _XC.accent, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: _XC.success.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: _XC.success.withOpacity(0.2))),
            child: Text(_qualities[_selectedQualityIndex]['title'] ?? '', style: const TextStyle(fontFamily: 'ShareTechMono', fontSize: 9, color: _XC.success, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.hd_rounded, color: _XC.muted2, size: 12),
        ]),
      ]),
    );
  }
}

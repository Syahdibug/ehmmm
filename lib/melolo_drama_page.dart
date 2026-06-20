// melolo_drama_page.dart — Drama China via Melolo Short Drama API
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ── COLOR SCHEME ──────────────────────────────────────────────────────────────
class _DC {
  static const bg       = Color(0xFF0c0d15);
  static const bg2      = Color(0xFF11121c);
  static const surface  = Color(0xFF161823);
  static const card     = Color(0xFF1a1c29);
  static const accent   = Color(0xFFe8184a);
  static const accent2  = Color(0xFFff4466);
  static const accent3  = Color(0xFFff8099);
  static const gold     = Color(0xFFFFD447);
  static const danger   = Color(0xFFFF4D6D);
  static const text     = Color(0xFFE2EAE5);
  static const muted    = Color(0x73E2EAE5);
  static const muted2   = Color(0x38E2EAE5);
  static const border   = Color(0x1AE8184A);
  static const border2  = Color(0x0FFFFFFF);
  static const dramaG1  = Color(0xFFE91E63);
  static const dramaG2  = Color(0xFFAD1457);
}

// ── MELOLO API ───────────────────────────────────────────────────────────────
class _MeloloApi {
  static const String _base   = 'https://anabot.my.id/api/search/drama/melolo';
  static const String _apikey = 'SQUADCIT';

  static Future<Map<String, dynamic>?> _get(String url) async {
    try {
      debugPrint('[MeloloAPI] GET $url');
      final res = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      debugPrint('[MeloloAPI] ${res.statusCode} len=${res.body.length}');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data is Map<String, dynamic> ? data : null;
      }
      return null;
    } catch (e) {
      debugPrint('[MeloloAPI] Error: $e');
      return null;
    }
  }

  /// Fetch trending/recommended dramas
  static Future<List<Map<String, dynamic>>> fetchRecommend() async {
    final data = await _get('$_base/recommend?apikey=${Uri.encodeComponent(_apikey)}');
    if (data == null || data['success'] != true) return [];
    try {
      final result = data['data']?['result'];
      if (result == null) return [];

      final List<Map<String, dynamic>> items = [];
      final searchInfos = result['search_infos'] as List? ?? [];
      final scrollWords = (result['scroll_words'] as List? ?? []).cast<String>();

      for (int i = 0; i < scrollWords.length; i++) {
        final title = scrollWords[i];
        if (i < searchInfos.length) {
          final info = searchInfos[i];
          items.add({
            'title': title,
            'book_id': info['search_source_book_id'] ?? '',
            'recommend_reason': info['recommend_reason'] ?? '',
          });
        } else {
          items.add({'title': title, 'book_id': '', 'recommend_reason': ''});
        }
      }
      return items;
    } catch (e) {
      debugPrint('[MeloloAPI] fetchRecommend parse error: $e');
      return [];
    }
  }

  /// Search dramas
  static Future<List<Map<String, dynamic>>> search(String query) async {
    final data = await _get(
        '$_base/search?query=${Uri.encodeComponent(query)}&apikey=${Uri.encodeComponent(_apikey)}');
    if (data == null || data['success'] != true) return [];
    try {
      final result = data['data']?['result'];
      if (result == null) return [];

      final searchSections = result['search_data'] as List? ?? [];
      final List<Map<String, dynamic>> items = [];

      for (final section in searchSections) {
        final books = section['books'] as List? ?? [];
        for (final b in books) {
          if (b is! Map) continue;
          items.add({
            'title': b['book_name'] ?? '',
            'book_id': b['book_id']?.toString() ?? '',
            'abstract': b['abstract'] ?? '',
            'thumb_url': b['thumb_url'] ?? '',
            'author': b['author'] ?? '',
            'serial_count': b['serial_count'] ?? 0,
            'is_dubbed': b['is_dubbed'] ?? false,
            'is_hot': b['is_hot'] ?? false,
            'is_new_book': b['is_new_book'] ?? false,
            'category_info': b['category_info'] ?? [],
          });
        }
      }
      return items;
    } catch (e) {
      debugPrint('[MeloloAPI] search parse error: $e');
      return [];
    }
  }

  // Helper methods
  static String getTitle(Map<String, dynamic> item) =>
      (item['title'] ?? item['book_name'] ?? '').toString();

  static String getThumb(Map<String, dynamic> item) =>
      (item['thumb_url'] ?? item['thumbnail'] ?? item['poster'] ?? '').toString();

  static String getBookId(Map<String, dynamic> item) =>
      (item['book_id'] ?? item['id'] ?? '').toString();

  static String getAbstract(Map<String, dynamic> item) =>
      (item['abstract'] ?? item['description'] ?? '').toString();

  static int getEpisodeCount(Map<String, dynamic> item) {
    final v = item['serial_count'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// Build Melolo deep link or web URL for a drama
  static String getMeloloUrl(String bookId) {
    // Melolo is a short drama app; open in browser as fallback
    return 'https://www.google.com/search?q=melolo+drama+${Uri.encodeComponent(bookId)}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. HOME PAGE — Browse & Search
// ═══════════════════════════════════════════════════════════════════════════════
class MeloloDramaPage extends StatefulWidget {
  const MeloloDramaPage({super.key});

  @override
  State<MeloloDramaPage> createState() => _MeloloDramaPageState();
}

class _MeloloDramaPageState extends State<MeloloDramaPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _trendingItems = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearchLoading = false;
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _glowController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    )..forward();
    _focusNode.addListener(() => setState(() {}));
    _loadTrending();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTrending() async {
    setState(() => _isLoading = true);
    final items = await _MeloloApi.fetchRecommend();
    if (mounted) setState(() { _trendingItems = items; _isLoading = false; });
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _isSearching = false; _searchResults.clear(); });
      return;
    }
    setState(() { _isSearching = true; _isSearchLoading = true; _searchResults.clear(); });
    final results = await _MeloloApi.search(query);
    if (mounted) setState(() { _searchResults = results; _isSearchLoading = false; });
  }

  /// Tap a trending item → search that title to get full info
  void _openTrendingItem(Map<String, dynamic> item) {
    final title = _MeloloApi.getTitle(item);
    if (title.isNotEmpty) {
      _searchController.text = title;
      _doSearch(title);
      _focusNode.unfocus();
    }
  }

  /// Tap a search result → open detail/watch page
  void _openDramaDetail(Map<String, dynamic> item) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MeloloDramaDetailPage(item: item),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DC.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildSearchBar(),
            const SizedBox(height: 12),
            Expanded(
              child: _isSearching
                  ? _buildSearchView()
                  : _buildHomeView(),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xEB0C0D15),
            border: Border(bottom: BorderSide(color: _DC.border)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _DC.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _DC.border2),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: _DC.muted, size: 15),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [_DC.accent, _DC.accent2],
                      ).createShader(b),
                      child: const Text('DRAMA CHINA',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          )),
                    ),
                    const Text('MELOLO SHORT DRAMA',
                        style: TextStyle(
                          fontSize: 9,
                          color: _DC.muted,
                          letterSpacing: 1,
                        )),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _glowController,
                builder: (_, __) => Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _DC.dramaG1.withOpacity(
                        0.08 + _glowController.value * 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _DC.dramaG1.withOpacity(
                          0.2 + _glowController.value * 0.15),
                    ),
                  ),
                  child: Icon(FontAwesomeIcons.clapperboard,
                      color: _DC.dramaG1.withOpacity(
                          0.6 + _glowController.value * 0.4),
                      size: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── SEARCH BAR ───────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        decoration: BoxDecoration(
          color: _DC.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focusNode.hasFocus
                ? _DC.accent.withOpacity(0.4)
                : _DC.border2,
          ),
          boxShadow: _focusNode.hasFocus
              ? [BoxShadow(color: _DC.accent.withOpacity(0.08), blurRadius: 8)]
              : [],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(FontAwesomeIcons.magnifyingGlass,
                color: _focusNode.hasFocus ? _DC.accent : _DC.muted2,
                size: 14),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(color: _DC.text, fontSize: 13),
                cursorColor: _DC.accent,
                decoration: const InputDecoration(
                  hintText: 'Cari drama China...',
                  hintStyle: TextStyle(color: _DC.muted2, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) {
                  if (v.isNotEmpty) _doSearch(v);
                  else setState(() { _isSearching = false; _searchResults.clear(); });
                },
              ),
            ),
            if (_isSearching && _isSearchLoading)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_DC.accent)),
                ),
              )
            else if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() { _isSearching = false; _searchResults.clear(); });
                  _focusNode.unfocus();
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.close, color: _DC.muted, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── HOME VIEW ─────────────────────────────────────────────────────────────
  Widget _buildHomeView() {
    if (_isLoading) {
      return _buildShimmerGrid();
    }

    if (_trendingItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.triangleExclamation,
                color: _DC.muted2, size: 40),
            const SizedBox(height: 14),
            const Text('Gagal memuat konten',
                style: TextStyle(color: _DC.muted, fontSize: 13)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _loadTrending,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_DC.accent, _DC.accent2]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('COBA LAGI',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              ),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('TRENDING DRAMA', FontAwesomeIcons.fire),
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              itemCount: _trendingItems.length,
              itemBuilder: (_, i) => _buildTrendingCard(
                _trendingItems[i], i,
                onTap: () => _openTrendingItem(_trendingItems[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SEARCH VIEW ───────────────────────────────────────────────────────────
  Widget _buildSearchView() {
    if (_isSearchLoading) return _buildShimmerGrid();

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FontAwesomeIcons.magnifyingGlass,
                color: _DC.muted2, size: 40),
            const SizedBox(height: 14),
            Text('Tidak ada hasil untuk "${_searchController.text}"',
                style: const TextStyle(color: _DC.muted, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text('Coba kata kunci lain',
                style: TextStyle(color: _DC.muted2, fontSize: 11)),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSectionHeader(
            '${_searchResults.length} HASIL', FontAwesomeIcons.list),
        Expanded(
          child: ListView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: _searchResults.length,
            itemBuilder: (_, i) => _buildDramaCard(
              _searchResults[i],
              onTap: () => _openDramaDetail(_searchResults[i]),
            ),
          ),
        ),
      ],
    );
  }

  // ── TRENDING CARD (simple, tap to search) ─────────────────────────────────
  Widget _buildTrendingCard(Map<String, dynamic> item, int index,
      {required VoidCallback onTap}) {
    final title = _MeloloApi.getTitle(item);
    final reason = item['recommend_reason'] ?? '';
    final reasonColor = reason == 'Populer'
        ? _DC.accent
        : reason == 'Sedang Tren'
            ? _DC.gold
            : _DC.accent2;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _DC.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _DC.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_DC.accent, _DC.accent2]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _DC.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (reason.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: reasonColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(reason,
                      style: TextStyle(
                        color: reasonColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: _DC.muted2, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ── DRAMA CARD (search result with full info) ────────────────────────────
  Widget _buildDramaCard(Map<String, dynamic> item,
      {required VoidCallback onTap}) {
    final title = _MeloloApi.getTitle(item);
    final thumb = _MeloloApi.getThumb(item);
    final abstract = _MeloloApi.getAbstract(item);
    final epCount = _MeloloApi.getEpisodeCount(item);
    final isDubbed = item['is_dubbed'] == true;
    final isHot = item['is_hot'] == true;

    if (title.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _DC.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _DC.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: thumb.isNotEmpty
                        ? Image.network(
                            thumb,
                            width: 90, height: 130,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _thumbPlaceholder(),
                          )
                        : _thumbPlaceholder(),
                  ),
                  Positioned(
                    top: 4, left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('$epCount EP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                  ),
                  Positioned(
                    bottom: 6, right: 6,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [_DC.accent, _DC.accent2]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: _DC.accent.withOpacity(0.3),
                              blurRadius: 8)
                        ],
                      ),
                      child: const Icon(FontAwesomeIcons.play,
                          color: Colors.white, size: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isHot)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('HOT',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                          ),
                        if (isDubbed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: _DC.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('DUB',
                                style: TextStyle(
                                  color: _DC.gold,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _DC.text,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    if (abstract.isNotEmpty)
                      Text(abstract,
                          style: const TextStyle(
                              color: _DC.muted,
                              fontSize: 11,
                              height: 1.4),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_DC.accent, _DC.accent2]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('TONTON',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                )),
                            SizedBox(width: 5),
                            Icon(Icons.arrow_forward_ios,
                                color: Colors.white, size: 9),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 90, height: 130,
      decoration: BoxDecoration(
        color: _DC.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(FontAwesomeIcons.image,
          color: _DC.muted2, size: 24),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _DC.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _DC.accent, size: 12),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _DC.accent,
                letterSpacing: 1.5,
              )),
          const SizedBox(width: 10),
          Expanded(
              child: Container(height: 1, color: _DC.border)),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: 8,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: _DC.card,
        highlightColor: _DC.surface,
        child: Container(
          height: 60,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _DC.card,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. DETAIL PAGE — with WebView Watch
// ═══════════════════════════════════════════════════════════════════════════════
class MeloloDramaDetailPage extends StatefulWidget {
  final Map<String, dynamic> item;

  const MeloloDramaDetailPage({
    super.key,
    required this.item,
  });

  @override
  State<MeloloDramaDetailPage> createState() => _MeloloDramaDetailPageState();
}

class _MeloloDramaDetailPageState extends State<MeloloDramaDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  bool _isWebViewLoading = false;
  bool _showWebView = false;

  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _watchInWebView() {
    final bookId = _MeloloApi.getBookId(widget.item);
    final title = _MeloloApi.getTitle(widget.item);

    // Melolo short dramas — search in Melolo app or web
    // Use a Google search as bridge since Melolo doesn't have a public web URL per drama
    final searchQuery = 'melolo drama ${title.isNotEmpty ? title : bookId}';
    final url = 'https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}';

    setState(() { _showWebView = true; _isWebViewLoading = true; });

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _isWebViewLoading = false);
        },
        onWebResourceError: (_) {
          if (mounted) setState(() => _isWebViewLoading = false);
        },
      ))
      ..loadRequest(Uri.parse(url));
  }

  Future<void> _openInBrowser() async {
    final bookId = _MeloloApi.getBookId(widget.item);
    final title = _MeloloApi.getTitle(widget.item);
    final searchQuery = 'melolo drama ${title.isNotEmpty ? title : bookId}';
    final url = 'https://www.google.com/search?q=${Uri.encodeComponent(searchQuery)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DC.bg,
      body: _showWebView
          ? _buildWebViewPage()
          : _buildDetailPage(),
    );
  }

  Widget _buildWebViewPage() {
    return WillPopScope(
      onWillPop: () async {
        // Back button: close WebView, go back to detail
        if (_showWebView) {
          setState(() => _showWebView = false);
          return false;
        }
        return true;
      },
      child: Column(
        children: [
          // WebView header
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _DC.bg2.withOpacity(0.95),
              border: Border(bottom: BorderSide(color: _DC.border)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showWebView = false),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _DC.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _DC.border2),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: _DC.muted, size: 14),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('WATCH DRAMA',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _DC.accent,
                        letterSpacing: 2,
                      )),
                ),
                GestureDetector(
                  onTap: _openInBrowser,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _DC.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _DC.border2),
                    ),
                    child: const Icon(FontAwesomeIcons.upRightFromSquare,
                        color: _DC.accent, size: 13),
                  ),
                ),
              ],
            ),
          ),
          // WebView content
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (_isWebViewLoading)
                  const Center(
                    child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(_DC.accent)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPage() {
    final title = _MeloloApi.getTitle(widget.item);
    final thumb = _MeloloApi.getThumb(widget.item);
    final abstract = _MeloloApi.getAbstract(widget.item);
    final epCount = _MeloloApi.getEpisodeCount(widget.item);
    final author = widget.item['author'] ?? '';
    final isDubbed = widget.item['is_dubbed'] == true;
    final isHot = widget.item['is_hot'] == true;
    final categories = widget.item['category_info'] as List? ?? [];

    return Scaffold(
      backgroundColor: _DC.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _DC.bg2.withOpacity(0.95),
            pinned: true,
            elevation: 0,
            iconTheme: const IconThemeData(color: _DC.accent),
            title: const Text('DETAIL DRAMA',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _DC.accent,
                  letterSpacing: 2,
                )),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: _DC.border))),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeController,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    _buildInfoCard(
                        title, thumb, epCount, author, isDubbed, isHot),
                    const SizedBox(height: 16),
                    // Genre Tags
                    if (categories.isNotEmpty) ..._buildGenreTags(categories),
                    if (categories.isNotEmpty) const SizedBox(height: 16),
                    // Synopsis
                    if (abstract.isNotEmpty) ...[
                      _sectionTitle('SINOPSIS',
                          FontAwesomeIcons.alignLeft),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _DC.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _DC.border),
                        ),
                        child: Text(abstract,
                            style: const TextStyle(
                              color: _DC.text,
                              fontSize: 13,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.justify),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Action Buttons
                    _buildActionButtons(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String thumb, int epCount,
      String author, bool isDubbed, bool isHot) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _DC.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _DC.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: thumb.isNotEmpty
                ? Image.network(
                    thumb,
                    width: 130, height: 190,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _bigPlaceholder(),
                  )
                : _bigPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _DC.text,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                _infoRow(FontAwesomeIcons.film, 'Episode',
                    '$epCount EP', _DC.accent),
                if (author.isNotEmpty)
                  _infoRow(FontAwesomeIcons.penFancy, 'Author',
                      author, _DC.accent2),
                if (isDubbed)
                  _infoRow(FontAwesomeIcons.microphone, 'Dubbing',
                      'Tersedia', _DC.gold),
                if (isHot)
                  _infoRow(FontAwesomeIcons.fire, 'Status',
                      'Sedang Populer', Colors.redAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigPlaceholder() {
    return Container(
      width: 130, height: 190,
      decoration: BoxDecoration(
        color: _DC.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(FontAwesomeIcons.image,
          color: _DC.muted2, size: 32),
    );
  }

  List<Widget> _buildGenreTags(List categories) {
    final List<String> genreNames = [];
    for (final cat in categories) {
      if (cat is Map) {
        final name = cat['Name']?.toString() ?? '';
        if (name.isNotEmpty && name.length < 30) {
          genreNames.add(name);
        }
      }
    }

    if (genreNames.isEmpty) return [];
    return [
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: genreNames.take(5).map((g) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_DC.accent, _DC.accent2]),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(g,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
        )).toList(),
      ),
    ];
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary: Watch in WebView
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _watchInWebView,
            icon: const Icon(FontAwesomeIcons.play,
                color: Colors.white, size: 16),
            label: const Text('TONTON SEKARANG',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                )),
            style: ElevatedButton.styleFrom(
              backgroundColor: _DC.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Secondary: Open in browser
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _openInBrowser,
            icon: const Icon(FontAwesomeIcons.upRightFromSquare,
                color: _DC.accent, size: 14),
            label: const Text('BUKA DI BROWSER',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _DC.accent,
                  letterSpacing: 1,
                )),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _DC.accent.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(color: _DC.muted, fontSize: 11)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                  color: _DC.text,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _DC.accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _DC.accent, size: 13),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _DC.accent,
              letterSpacing: 1.5,
            )),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: _DC.border)),
      ],
    );
  }
}

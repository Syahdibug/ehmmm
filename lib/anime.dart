import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════
// ANIME COLORS
// ═══════════════════════════════════════════════════════════════════════
class AC {
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
  static const blueG2  = Color(0xFF0072aa);
  static const purpleG1= Color(0xFF9C27B0);
  static const purpleG2= Color(0xFF6a1a80);
  static const orangeG1= Color(0xFFFF8C00);
  static const orangeG2= Color(0xFFcc6a00);
}

// ═══════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════
Widget _buildGlassHeader({required String title, VoidCallback? onProfileTap}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: AC.bg2.withOpacity(0.85),
      border: Border(bottom: BorderSide(color: AC.border, width: 1)),
    ),
    child: Row(children: [
      ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(colors: [AC.accent, AC.accent2]).createShader(bounds),
        child: const Text('TEMPAT WIBU', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
      ),
      const Spacer(),
      if (onProfileTap != null)
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AC.border)),
            child: const Icon(FontAwesomeIcons.circleUser, color: AC.accent, size: 22),
          ),
        ),
    ]),
  );
}

Widget _buildSectionTitle(String title, {IconData? icon}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      if (icon != null) ...[
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AC.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AC.accent, size: 16),
        ),
        const SizedBox(width: 10),
      ],
      Text(title.toUpperCase(), style: const TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.w700, color: AC.accent, letterSpacing: 2)),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1, color: AC.border)),
    ]),
  );
}

Widget _buildQuickAccessCard(String title, IconData icon, VoidCallback onTap, {required LinearGradient gradient}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: gradient.colors.first.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Stack(children: [
        Positioned(top: -15, right: -15,
          child: Opacity(opacity: 0.15, child: Icon(icon, color: Colors.white, size: 80))),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title.toUpperCase(), style: const TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
        ])),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════
// 1. HOME ANIME PAGE
// ═══════════════════════════════════════════════════════════════════════
class HomeAnimePage extends StatefulWidget {
  const HomeAnimePage({super.key});
  @override
  State<HomeAnimePage> createState() => _HomeAnimePageState();
}

class _HomeAnimePageState extends State<HomeAnimePage> {
  Map<String, dynamic>? animeData;
  bool isLoading = true;
  bool isSearching = false;
  List<dynamic> searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _watchHistory = [];
  bool _isHistoryLoading = true;

  @override
  void initState() { super.initState(); fetchAnimeData(); _loadWatchHistory(); }

  void refreshHistory() { _loadWatchHistory(); }

  Future<void> _loadWatchHistory() async {
    setState(() { _isHistoryLoading = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('watch_history') ?? [];
      setState(() {
        _watchHistory = historyJson.map((item) => Map<String, dynamic>.from(json.decode(item))).toList();
        _isHistoryLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading watch history: $e');
      setState(() { _isHistoryLoading = false; });
    }
  }

  Future<void> fetchAnimeData() async {
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/home'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() { animeData = jsonData['data']; isLoading = false; });
      } else { throw Exception('Gagal memuat data anime'); }
    } catch (e) { debugPrint('Error: $e'); setState(() => isLoading = false); }
  }

  Future<void> searchAnime(String query) async {
    if (query.isEmpty) { setState(() { isSearching = false; searchResults.clear(); }); return; }
    setState(() { isSearching = true; });
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/search/$query'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() { searchResults = jsonData['data']['animeList'] ?? []; });
      } else { setState(() { searchResults = []; }); }
    } catch (e) { debugPrint('Search Error: $e'); setState(() { searchResults = []; }); }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() { isSearching = false; searchResults.clear(); });
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() { _searchController.dispose(); _searchFocusNode.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(children: [
        _buildGlassHeader(title: 'TEMPAT WIBU', onProfileTap: () {}),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(color: AC.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AC.border)),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: AC.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: "SEARCH ANIME...",
                hintStyle: const TextStyle(color: AC.muted2, fontFamily: 'ShareTechMono', fontSize: 13),
                prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass, color: AC.accent, size: 18),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(FontAwesomeIcons.xmark, color: AC.accent, size: 16), onPressed: _clearSearch)
                    : null,
                filled: true, fillColor: AC.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AC.accent)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) { searchAnime(value); } else { setState(() { isSearching = false; searchResults.clear(); }); }
              },
              onSubmitted: (value) { if (value.isNotEmpty) searchAnime(value); },
            ),
          ),
        ),
        Expanded(
          child: isLoading ? _buildLoadingShimmer()
              : isSearching ? _buildSearchResults()
              : animeData == null ? _buildErrorWidget()
              : _buildHomeContent(),
        ),
      ]),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async { await Future.wait([fetchAnimeData(), _loadWatchHistory()]); },
      color: AC.accent, backgroundColor: AC.card,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSectionTitle('WATCH HISTORY', icon: FontAwesomeIcons.clockRotateLeft),
          if (_isHistoryLoading)
            SizedBox(height: 180, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: 5,
              itemBuilder: (context, index) => Container(width: 120, margin: const EdgeInsets.only(right: 12),
                child: Shimmer.fromColors(baseColor: AC.card, highlightColor: AC.surface,
                  child: Container(height: 160, decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(12)))))))
          else if (_watchHistory.isEmpty)
            Container(height: 120, alignment: Alignment.center,
              decoration: BoxDecoration(color: AC.card.withOpacity(0.5), borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.border)),
              child: const Text("No watch history yet.\nStart watching!", style: TextStyle(color: AC.muted, fontSize: 13, fontFamily: 'ShareTechMono'), textAlign: TextAlign.center))
          else
            SizedBox(height: 210, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _watchHistory.length,
              itemBuilder: (context, index) => _buildHistoryCard(_watchHistory[index]))),
          const SizedBox(height: 24),
          _buildSectionTitle('QUICK ACCESS', icon: FontAwesomeIcons.bolt),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: _buildQuickAccessCard('GENRE', FontAwesomeIcons.layerGroup,
              () { Navigator.push(context, MaterialPageRoute(builder: (context) => const AnimeGenreListPage())).then((_) => refreshHistory()); },
              gradient: const LinearGradient(colors: [AC.purpleG1, AC.purpleG2], begin: Alignment.topLeft, end: Alignment.bottomRight))),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickAccessCard('SCHEDULE', FontAwesomeIcons.calendarDays,
              () { Navigator.push(context, MaterialPageRoute(builder: (context) => const AnimeSchedulePage())).then((_) => refreshHistory()); },
              gradient: const LinearGradient(colors: [AC.blueG1, AC.blueG2], begin: Alignment.topLeft, end: Alignment.bottomRight))),
          ]),
          const SizedBox(height: 28),
          _buildSectionTitle('NOW AIRING', icon: FontAwesomeIcons.towerBroadcast),
          _buildAnimeGrid(animeData!['ongoing']['animeList'] ?? [], isAiring: true),
          const SizedBox(height: 28),
          _buildSectionTitle('COMPLETED', icon: FontAwesomeIcons.circleCheck),
          _buildAnimeGrid(animeData!['completed']['animeList'] ?? [], isAiring: false),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> anime) {
    return Container(
      width: 120, margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          if (anime['last_watched_episode_slug'] != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeEpisodePage(
              episodeSlug: anime['last_watched_episode_slug'], animeSlug: anime['slug'],
              animeTitle: anime['title'], animePoster: anime['poster'], onHistoryUpdate: refreshHistory,
            ))).then((_) => refreshHistory());
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeDetailPage(slug: anime['slug'], onHistoryUpdate: refreshHistory))).then((_) => refreshHistory());
          }
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12),
              child: Image.network(anime['poster'], height: 160, width: 120, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 160, width: 120, color: AC.card,
                  alignment: Alignment.center, child: const Icon(FontAwesomeIcons.image, color: AC.muted2, size: 24)))),
            Positioned(top: 8, right: 8, child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle, border: Border.all(color: AC.accent, width: 1)),
              child: const Icon(FontAwesomeIcons.play, color: AC.accent, size: 12))),
            Positioned(bottom: 0, left: 0, right: 0, child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])),
              child: Text(anime['last_watched_episode'] ?? '', style: const TextStyle(color: AC.accent3, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono'),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis))),
          ]),
          const SizedBox(height: 8),
          Text(anime['title'], style: const TextStyle(color: AC.text, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(FontAwesomeIcons.magnifyingGlass, color: AC.muted2, size: 48),
        const SizedBox(height: 16),
        const Text("No results found", style: TextStyle(color: AC.muted, fontSize: 16, fontFamily: 'ShareTechMono')),
        const SizedBox(height: 8),
        const Text("Try different keywords", style: TextStyle(color: AC.muted2, fontSize: 13)),
      ]));
    }
    return ListView.builder(padding: const EdgeInsets.all(16.0), itemCount: searchResults.length,
      itemBuilder: (context, index) => _buildSearchResultCard(searchResults[index]));
  }

  Widget _buildSearchResultCard(Map<String, dynamic> anime) {
    final String title = anime['title'];
    final String poster = anime['poster'];
    final String? status = anime['status'];
    final String? score = anime['score'];
    final String slug = anime['animeId'];
    final List<dynamic> genres = anime['genreList'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.border)),
      child: InkWell(
        onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeDetailPage(slug: slug, onHistoryUpdate: refreshHistory))).then((_) => refreshHistory()); },
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(10),
            child: Image.network(poster, width: 80, height: 120, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 80, height: 120, color: AC.surface,
                alignment: Alignment.center, child: const Icon(FontAwesomeIcons.image, color: AC.muted2, size: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AC.text), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(children: [
              if (score != null && score.isNotEmpty) ...[
                const Icon(FontAwesomeIcons.star, color: AC.gold, size: 12), const SizedBox(width: 4),
                Text(score, style: const TextStyle(color: AC.gold, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono')),
                const SizedBox(width: 12),
              ],
              if (status != null) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: status.toLowerCase() == 'ongoing' ? AC.greenG1 : AC.accent, borderRadius: BorderRadius.circular(6)),
                child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono'))),
            ]),
            const SizedBox(height: 8),
            if (genres.isNotEmpty)
              Wrap(spacing: 6, runSpacing: 4,
                children: genres.take(3).map<Widget>((genre) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AC.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: AC.border)),
                  child: Text(genre['title'], style: const TextStyle(color: AC.accent3, fontSize: 10)))).toList()),
          ])),
        ])),
      ),
    );
  }

  Widget _buildAnimeGrid(List<dynamic> list, {bool isAiring = true}) {
    return GridView.builder(
      itemCount: list.length, physics: const NeverScrollableScrollPhysics(), shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 270, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemBuilder: (context, index) {
        final anime = list[index];
        final String title = anime['title'];
        final String poster = anime['poster'];
        final String? episode = anime['episodes']?.toString();
        final String? date = anime['latestReleaseDate'] ?? anime['lastReleaseDate'];
        final String slug = anime['animeId'];

        return GestureDetector(
          onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeDetailPage(slug: slug, onHistoryUpdate: refreshHistory))).then((_) => refreshHistory()); },
          child: Container(
            decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AC.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Stack(children: [
                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Image.network(poster, height: 170, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 170, color: AC.surface, alignment: Alignment.center,
                      child: const Icon(FontAwesomeIcons.image, color: AC.muted2, size: 24)))),
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, AC.bg.withOpacity(0.9)])))),
                if (isAiring) Positioned(top: 8, left: 8, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: AC.accent, borderRadius: BorderRadius.circular(6)),
                  child: const Text('AIRING', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: 'MADEEvolveSansEVO')))),
              ])),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AC.text), maxLines: 2, overflow: TextOverflow.ellipsis)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(children: [
                  const Icon(FontAwesomeIcons.film, color: AC.muted2, size: 10), const SizedBox(width: 4),
                  Text(episode != null ? "$episode Eps" : "-", style: const TextStyle(fontSize: 11, color: AC.muted, fontFamily: 'ShareTechMono')),
                ])),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(date ?? '', style: const TextStyle(fontSize: 10, color: AC.muted2, fontFamily: 'ShareTechMono'))),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0), itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 270, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(baseColor: AC.card, highlightColor: AC.surface,
        child: Container(decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(14)))));
  }

  Widget _buildErrorWidget() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(FontAwesomeIcons.triangleExclamation, color: AC.accent, size: 48),
      const SizedBox(height: 16),
      const Text("Failed to load data", style: TextStyle(color: AC.muted, fontSize: 16)),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () async { await Future.wait([fetchAnimeData(), _loadWatchHistory()]); },
        style: ElevatedButton.styleFrom(backgroundColor: AC.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text("RETRY", style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, letterSpacing: 1))),
    ]));
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 2. ANIME DETAIL PAGE
// ═══════════════════════════════════════════════════════════════════════
class AnimeDetailPage extends StatefulWidget {
  final String slug;
  final Function()? onHistoryUpdate;
  const AnimeDetailPage({super.key, required this.slug, this.onHistoryUpdate});
  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  Map<String, dynamic>? animeDetail;
  bool isLoading = true;
  bool isError = false;

  @override
  void initState() { super.initState(); fetchAnimeDetail(); }

  Future<void> fetchAnimeDetail() async {
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/anime/${widget.slug}'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() { animeDetail = jsonData['data']; isLoading = false; });
      } else { setState(() { isLoading = false; isError = true; }); }
    } catch (e) { debugPrint('Error: $e'); setState(() { isLoading = false; isError = true; }); }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) { await launchUrl(uri, mode: LaunchMode.externalApplication); }
    else { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open URL'))); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: isLoading ? _buildLoadingShimmer()
          : isError || animeDetail == null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(FontAwesomeIcons.triangleExclamation, color: AC.accent, size: 48),
                  const SizedBox(height: 16),
                  const Text("Failed to load anime details", style: TextStyle(color: AC.muted)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: fetchAnimeDetail,
                    style: ElevatedButton.styleFrom(backgroundColor: AC.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("RETRY", style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, letterSpacing: 1))),
                ]))
              : _buildAnimeDetail(),
    );
  }

  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Shimmer.fromColors(baseColor: AC.card, highlightColor: AC.surface,
        child: Container(height: 220, width: double.infinity, decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(16)))),
      const SizedBox(height: 16),
      Shimmer.fromColors(baseColor: AC.card, highlightColor: AC.surface,
        child: Container(height: 24, width: 200, decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(8)))),
    ]));
  }

  Widget _buildAnimeDetail() {
    final anime = animeDetail!;
    final List<dynamic> episodes = anime['episodeList'] ?? [];
    final List<dynamic> recommendations = anime['recommendedAnimeList'] ?? [];
    final List<dynamic> genres = anime['genreList'] ?? [];

    return CustomScrollView(slivers: [
      SliverAppBar(
        backgroundColor: AC.bg2.withOpacity(0.9),
        pinned: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AC.accent),
        // FIX: title wajib ada di SliverAppBar
        title: const Text("ANIME DETAILS", style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.bold, color: AC.accent, letterSpacing: 2)),
        flexibleSpace: Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AC.border)))),
        actions: [IconButton(icon: const Icon(FontAwesomeIcons.shareNodes, color: AC.accent, size: 18), onPressed: () {})],
      ),
      SliverToBoxAdapter(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AC.border)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(borderRadius: BorderRadius.circular(12),
                child: Image.network(anime['poster'], height: 220, width: 150, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 220, width: 150, color: AC.surface,
                    alignment: Alignment.center, child: const Icon(FontAwesomeIcons.image, color: AC.muted2, size: 32)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(anime['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AC.text, fontFamily: 'MADEEvolveSansEVO'), maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(anime['japanese'] ?? '-', style: const TextStyle(fontSize: 13, color: AC.muted, fontStyle: FontStyle.italic)),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(FontAwesomeIcons.star, color: AC.gold, size: 14), const SizedBox(width: 6),
                  Text(anime['score'] ?? '-', style: const TextStyle(color: AC.gold, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono')),
                ]),
                const SizedBox(height: 10),
                _buildInfoItem('TYPE', anime['type']),
                _buildInfoItem('STATUS', anime['status']),
                _buildInfoItem('EPISODES', anime['episodes']?.toString()),
                _buildInfoItem('DURATION', anime['duration']),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          if (genres.isNotEmpty) ...[
            _buildSectionTitle('GENRES'),
            Wrap(spacing: 8, runSpacing: 8, children: genres.map<Widget>((genre) {
              return GestureDetector(
                onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeGenrePage(genreSlug: genre['genreId'], genreName: genre['title']))); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [AC.accent, AC.accent2]), borderRadius: BorderRadius.circular(16)),
                  child: Text(genre['title'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              );
            }).toList()),
            const SizedBox(height: 20),
          ],
          if (anime['synopsis'] != null && anime['synopsis']['paragraphs'].isNotEmpty) ...[
            _buildSectionTitle('SYNOPSIS'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AC.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.border)),
              child: Text(anime['synopsis']['paragraphs'].join('\n\n'), style: const TextStyle(color: AC.text, height: 1.6, fontSize: 13), textAlign: TextAlign.justify)),
            const SizedBox(height: 20),
          ],
          if (episodes.isNotEmpty) ...[
            _buildSectionTitle('EPISODES', icon: FontAwesomeIcons.listOl),
            ListView.builder(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, itemCount: episodes.length,
              itemBuilder: (context, index) {
                final episode = episodes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AC.border)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Container(width: 40, height: 40,
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AC.accent, AC.accent2]), borderRadius: BorderRadius.circular(8)),
                      child: Center(child: Text(episode['eps'].toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono')))),
                    title: Text(episode['title'], style: const TextStyle(color: AC.text, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeEpisodePage(
                        episodeSlug: episode['episodeId'], animeSlug: widget.slug, animeTitle: anime['title'],
                        animePoster: anime['poster'], episodes: episodes, recommendations: recommendations, onHistoryUpdate: widget.onHistoryUpdate,
                      ))).then((_) { if (widget.onHistoryUpdate != null) widget.onHistoryUpdate!(); });
                    },
                    trailing: const Icon(FontAwesomeIcons.circlePlay, color: AC.accent, size: 22),
                  ),
                );
              }),
            const SizedBox(height: 20),
          ],
          if (anime['batch'] != null) ...[
            Container(
              decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.border)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AC.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(FontAwesomeIcons.download, color: AC.accent, size: 20)),
                title: const Text("BATCH DOWNLOAD", style: TextStyle(color: AC.text, fontWeight: FontWeight.bold, fontFamily: 'MADEEvolveSansEVO', fontSize: 12, letterSpacing: 1)),
                subtitle: Text(anime['batch']['title'], style: const TextStyle(color: AC.muted)),
                onTap: () => _launchURL(anime['batch']['otakudesuUrl']),
                trailing: const Icon(FontAwesomeIcons.arrowUpRightFromSquare, color: AC.accent, size: 16)),
            ),
            const SizedBox(height: 20),
          ],
          if (recommendations.isNotEmpty) ...[
            _buildSectionTitle('RECOMMENDATIONS', icon: FontAwesomeIcons.thumbsUp),
            SizedBox(height: 210, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final rec = recommendations[index];
                return GestureDetector(
                  onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeDetailPage(slug: rec['animeId'], onHistoryUpdate: widget.onHistoryUpdate))).then((_) { if (widget.onHistoryUpdate != null) widget.onHistoryUpdate!(); }); },
                  child: Container(width: 120, margin: const EdgeInsets.only(right: 12), child: Column(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(12),
                      child: Image.network(rec['poster'], height: 160, width: 120, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 160, width: 120, color: AC.card,
                          alignment: Alignment.center, child: const Icon(FontAwesomeIcons.image, color: AC.muted2, size: 20)))),
                    const SizedBox(height: 6),
                    Text(rec['title'], style: const TextStyle(color: AC.text, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                  ])),
                );
              })),
          ],
          const SizedBox(height: 24),
        ]),
      )),
    ]);
  }

  Widget _buildInfoItem(String label, String? value) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
      Text('$label: ', style: const TextStyle(color: AC.muted, fontSize: 11, fontFamily: 'ShareTechMono', letterSpacing: 1)),
      Text(value ?? '-', style: const TextStyle(color: AC.text, fontSize: 12, fontWeight: FontWeight.bold)),
    ]));
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 3. ANIME GENRE PAGE
// ═══════════════════════════════════════════════════════════════════════
class AnimeGenrePage extends StatefulWidget {
  final String genreSlug;
  final String genreName;
  const AnimeGenrePage({super.key, required this.genreSlug, required this.genreName});
  @override
  State<AnimeGenrePage> createState() => _AnimeGenrePageState();
}

class _AnimeGenrePageState extends State<AnimeGenrePage> {
  List<dynamic> animeList = [];
  Map<String, dynamic>? pagination;
  bool isLoading = true;
  bool isError = false;
  int currentPage = 1;

  Future<void> fetchGenreAnime({int page = 1}) async {
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/genre/${widget.genreSlug}?page=$page'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() { animeList = jsonData['data']['animeList']; pagination = jsonData['pagination']; isLoading = false; currentPage = page; });
      } else { setState(() { isLoading = false; isError = true; }); }
    } catch (e) { debugPrint('Error: $e'); setState(() { isLoading = false; isError = true; }); }
  }

  @override
  void initState() { super.initState(); fetchGenreAnime(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      // FIX: hapus 'pinned: true' dari AppBar biasa
      appBar: AppBar(
        backgroundColor: AC.bg2.withOpacity(0.9),
        iconTheme: const IconThemeData(color: AC.accent),
        title: Text(widget.genreName.toUpperCase(), style: const TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.bold, color: AC.accent, letterSpacing: 2)),
        flexibleSpace: Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AC.border)))),
      ),
      body: isLoading ? _buildLoadingShimmer()
          : isError ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(FontAwesomeIcons.triangleExclamation, color: AC.accent, size: 48), const SizedBox(height: 16),
              const Text("Failed to load genre data", style: TextStyle(color: AC.muted)), const SizedBox(height: 16),
              ElevatedButton(onPressed: () => fetchGenreAnime(), style: ElevatedButton.styleFrom(backgroundColor: AC.accent, foregroundColor: Colors.white), child: const Text("RETRY")),
            ]))
          : _buildGenreContent(),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(padding: const EdgeInsets.all(16.0), itemCount: 10,
      itemBuilder: (context, index) => Shimmer.fromColors(baseColor: AC.card, highlightColor: AC.surface,
        child: Container(height: 150, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(16)))));
  }

  Widget _buildGenreContent() {
    return Column(children: [
      if (pagination != null) _buildPaginationInfo(),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(16.0), itemCount: animeList.length, itemBuilder: (context, index) => _buildAnimeCard(animeList[index]))),
      if (pagination != null) _buildPaginationControls(),
    ]);
  }

  Widget _buildPaginationInfo() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AC.border)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text("PAGE $currentPage / ${pagination!['totalPages']}", style: const TextStyle(color: AC.accent, fontSize: 12, fontFamily: 'ShareTechMono', letterSpacing: 1)),
        Text("${animeList.length} ANIME", style: const TextStyle(color: AC.muted, fontSize: 12, fontFamily: 'ShareTechMono', letterSpacing: 1)),
      ]));
  }

  Widget _buildPaginationControls() {
    final hasNext = pagination!['hasNextPage'] ?? false;
    final hasPrev = pagination!['hasPrevPage'] ?? false;
    return Container(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (hasPrev) ElevatedButton(onPressed: () => fetchGenreAnime(page: currentPage - 1),
        style: ElevatedButton.styleFrom(backgroundColor: AC.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(FontAwesomeIcons.arrowLeft, size: 14), SizedBox(width: 8), Text("PREV", style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 11))])),
      const SizedBox(width: 16),
      if (hasNext) ElevatedButton(onPressed: () => fetchGenreAnime(page: currentPage + 1),
        style: ElevatedButton.styleFrom(backgroundColor: AC.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [Text("NEXT", style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 11)), SizedBox(width: 8), Icon(FontAwesomeIcons.arrowRight, size: 14)])),
    ]));
  }

  Widget _buildAnimeCard(Map<String, dynamic> anime) {
    final String title = anime['title'];
    final String poster = anime['poster'];
    final String score = anime['score'] ?? '-';
    final String episodeCount = anime['episodes']?.toString() ?? '?';
    final String season = anime['season'] ?? '-';
    final String studio = anime['studios'] ?? '-';
    final String synopsis = anime['synopsis'] != null && anime['synopsis']['paragraphs'] != null ? anime['synopsis']['paragraphs'].join('\n\n') : '';
    final String slug = anime['animeId'];
    final List<dynamic> genres = anime['genreList'] ?? [];

    return Container(margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.border)),
      child: InkWell(onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeDetailPage(slug: slug))); },
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(borderRadius: BorderRadius.circular(12),
            child: Image.network(poster, width: 100, height: 140, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 100, height: 140, color: AC.surface,
                alignment: Alignment.center, child: const Icon(FontAwesomeIcons.image, color: AC.muted2, size: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AC.text), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(FontAwesomeIcons.star, color: AC.gold, size: 12), const SizedBox(width: 4),
              Text(score, style: const TextStyle(color: AC.gold, fontSize: 12, fontFamily: 'ShareTechMono')),
              const SizedBox(width: 12),
              const Icon(FontAwesomeIcons.film, color: AC.muted2, size: 10), const SizedBox(width: 4),
              Text("$episodeCount Eps", style: const TextStyle(color: AC.muted, fontSize: 11, fontFamily: 'ShareTechMono')),
            ]),
            const SizedBox(height: 4),
            Text("$season | $studio", style: const TextStyle(color: AC.muted2, fontSize: 11, fontFamily: 'ShareTechMono'), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            if (genres.isNotEmpty) Wrap(spacing: 6, runSpacing: 4,
              children: genres.take(3).map<Widget>((genre) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AC.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AC.border)),
                child: Text(genre['title'], style: const TextStyle(color: AC.accent3, fontSize: 10)))).toList()),
            if (synopsis.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8),
              child: Text(synopsis, style: const TextStyle(color: AC.muted, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
          ])),
        ]))));
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 4. ANIME SCHEDULE PAGE
// ═══════════════════════════════════════════════════════════════════════
class AnimeSchedulePage extends StatefulWidget {
  const AnimeSchedulePage({super.key});
  @override
  State<AnimeSchedulePage> createState() => _AnimeSchedulePageState();
}

class _AnimeSchedulePageState extends State<AnimeSchedulePage> {
  List<dynamic> scheduleData = [];
  bool isLoading = true;
  bool isError = false;

  Future<void> fetchSchedule() async {
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/schedule'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() { scheduleData = jsonData['data']; isLoading = false; });
      } else { setState(() { isLoading = false; isError = true; }); }
    } catch (e) { debugPrint('Error fetching schedule: $e'); setState(() { isLoading = false; isError = true; }); }
  }

  @override
  void initState() { super.initState(); fetchSchedule(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      // FIX: hapus 'pinned: true' dari AppBar biasa
      appBar: AppBar(
        backgroundColor: AC.bg2.withOpacity(0.9),
        iconTheme: const IconThemeData(color: AC.accent),
        title: const Text("RELEASE SCHEDULE", style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.bold, color: AC.accent, letterSpacing: 2)),
        flexibleSpace: Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AC.border)))),
      ),
      body: isLoading ? _buildLoadingShimmer() : isError ? _buildErrorWidget() : _buildScheduleContent(),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(padding: const EdgeInsets.all(16.0), itemCount: 7,
      itemBuilder: (context, index) => Shimmer.fromColors(baseColor: AC.card, highlightColor: AC.surface,
        child: Container(height: 200, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(16)))));
  }

  Widget _buildErrorWidget() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(FontAwesomeIcons.triangleExclamation, color: AC.accent, size: 48), const SizedBox(height: 16),
      const Text("Failed to load release schedule", style: TextStyle(color: AC.muted)), const SizedBox(height: 16),
      ElevatedButton(onPressed: fetchSchedule, style: ElevatedButton.styleFrom(backgroundColor: AC.accent, foregroundColor: Colors.white), child: const Text("RETRY")),
    ]));
  }

  Widget _buildScheduleContent() {
    return ListView.builder(padding: const EdgeInsets.all(16.0), itemCount: scheduleData.length,
      itemBuilder: (context, index) {
        final daySchedule = scheduleData[index];
        final String day = daySchedule['day'];
        final List<dynamic> animeList = daySchedule['anime_list'];
        return Container(margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.border)),
          child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AC.accent, AC.accent2]), borderRadius: BorderRadius.circular(10)),
                child: Text(day, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'MADEEvolveSansEVO', letterSpacing: 1))),
              const SizedBox(width: 10),
              Text("${animeList.length} Anime", style: const TextStyle(color: AC.muted, fontSize: 13, fontFamily: 'ShareTechMono')),
            ]),
            const SizedBox(height: 14),
            if (animeList.isNotEmpty) SizedBox(height: 190, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: animeList.length,
              itemBuilder: (context, animeIndex) {
                final anime = animeList[animeIndex];
                return Container(width: 120, margin: EdgeInsets.only(right: animeIndex == animeList.length - 1 ? 0 : 12),
                  child: GestureDetector(onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeDetailPage(slug: anime['slug']))); },
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ClipRRect(borderRadius: BorderRadius.circular(12),
                        child: Image.network(anime['poster'], width: 120, height: 160, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 120, height: 160, color: AC.surface,
                            alignment: Alignment.center, child: const Icon(FontAwesomeIcons.image, color: AC.muted2, size: 20)))),
                      const SizedBox(height: 6),
                      Expanded(child: Text(anime['title'], style: const TextStyle(color: AC.text, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ])));
              })),
          ])));
      });
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 5. ANIME GENRE LIST PAGE
// ═══════════════════════════════════════════════════════════════════════
class AnimeGenreListPage extends StatefulWidget {
  const AnimeGenreListPage({super.key});
  @override
  State<AnimeGenreListPage> createState() => _AnimeGenreListPageState();
}

class _AnimeGenreListPageState extends State<AnimeGenreListPage> {
  List<dynamic> genreList = [];
  bool isLoading = true;
  bool isError = false;

  Future<void> fetchGenreList() async {
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/genre/'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() { genreList = jsonData['data']['genreList']; isLoading = false; });
      } else { setState(() { isLoading = false; isError = true; }); }
    } catch (e) { debugPrint('Error fetching genre list: $e'); setState(() { isLoading = false; isError = true; }); }
  }

  @override
  void initState() { super.initState(); fetchGenreList(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      appBar: AppBar(
        backgroundColor: AC.bg2.withOpacity(0.9),
        iconTheme: const IconThemeData(color: AC.accent),
        title: const Text("ANIME GENRES", style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.bold, color: AC.accent, letterSpacing: 2)),
        flexibleSpace: Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AC.border)))),
      ),
      body: isLoading ? _buildLoadingShimmer() : isError ? _buildErrorWidget() : _buildGenreGrid(),
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(padding: const EdgeInsets.all(16.0), itemCount: 20,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 3.0),
      itemBuilder: (context, index) => Shimmer.fromColors(baseColor: AC.card, highlightColor: AC.surface,
        child: Container(decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(16)))));
  }

  Widget _buildErrorWidget() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(FontAwesomeIcons.triangleExclamation, color: AC.accent, size: 48), const SizedBox(height: 16),
      const Text("Failed to load genre list", style: TextStyle(color: AC.muted)), const SizedBox(height: 16),
      ElevatedButton(onPressed: fetchGenreList, style: ElevatedButton.styleFrom(backgroundColor: AC.accent, foregroundColor: Colors.white), child: const Text("RETRY")),
    ]));
  }

  Widget _buildGenreGrid() {
    return GridView.builder(padding: const EdgeInsets.all(16.0), itemCount: genreList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 3.0),
      itemBuilder: (context, index) {
        final genre = genreList[index];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AC.accent.withOpacity(0.12), AC.accent.withOpacity(0.04)]),
            borderRadius: BorderRadius.circular(16), border: Border.all(color: AC.border)),
          child: InkWell(onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeGenrePage(genreSlug: genre['genreId'], genreName: genre['title']))); },
            borderRadius: BorderRadius.circular(16),
            child: Center(child: Text(genre['title'], style: const TextStyle(color: AC.text, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
        );
      });
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 6. ANIME EPISODE PAGE
// ═══════════════════════════════════════════════════════════════════════
class AnimeEpisodePage extends StatefulWidget {
  final String episodeSlug;
  final String? animeSlug;
  final String? animeTitle;
  final String? animePoster;
  final List<dynamic>? episodes;
  final List<dynamic>? recommendations;
  final Function()? onHistoryUpdate;

  const AnimeEpisodePage({
    super.key,
    required this.episodeSlug,
    this.animeSlug,
    this.animeTitle,
    this.animePoster,
    this.episodes,
    this.recommendations,
    this.onHistoryUpdate,
  });

  @override
  State<AnimeEpisodePage> createState() => _AnimeEpisodePageState();
}

class _AnimeEpisodePageState extends State<AnimeEpisodePage> with WidgetsBindingObserver {
  Map<String, dynamic>? episodeData;
  bool isLoading = true;
  bool isError = false;
  int _currentTabIndex = 0;

  late WebViewController _webViewController;
  bool _isWebViewLoading = true;
  bool _isFullScreen = false;

  List<dynamic> _qualities = [];
  int _selectedQualityIndex = 0;
  int _selectedServerIndex = 0;
  bool _showQualitySelector = false;

  String? _streamUrl;
  int _currentEpisodeIndex = 0;

  // Ad domains list
  static const List<String> _adDomains = [
    'doubleclick.net','googlesyndication.com','googleadservices.com','google-analytics.com',
    'adnxs.com','adsrvr.org','taboola.com','outbrain.com','popads.net','popcash.net',
    'propellerads.com','juicyads.com','exoclick.com','trafficjunky.com','adsterra.com',
    'hilltopads.net','clickadu.com','richpush.com','adform.net','criteo.com',
    'amazon-adsystem.com','moatads.com','scorecardresearch.com','quantserve.com',
    'rubiconproject.com','openx.net','casalemedia.com','indexexchange.com','pubmatic.com',
    'smartadserver.com','advertising.com','adsymptotic.com','bidswitch.com','lijit.com',
    'media.net','mookie1.com','nativex.com','serving-sys.com','sharethis.com','simpli.fi',
    'sitescout.com','sonobi.com','spotxchange.com','tapad.com','tidaltv.com','towerdata.com',
    'turn.com','yldbt.com','zergnet.com','mgid.com','revcontent.com','contentabc.com',
    'bidvertiser.com','yllix.com','evadav.com','monetag.com','profitablecpmrate.com',
    'popunder.net','clicksor.com','infolinks.com','chitika.com','buysellads.com',
  ];

  bool _isAdUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    for (final adDomain in _adDomains) { if (host.contains(adDomain)) return true; }
    return false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchEpisodeData();
    _findCurrentEpisodeIndex();
  }

  void _findCurrentEpisodeIndex() {
    if (widget.episodes != null) {
      for (int i = 0; i < widget.episodes!.length; i++) {
        if (widget.episodes![i]['episodeId'] == widget.episodeSlug) {
          setState(() { _currentEpisodeIndex = i; });
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // FIX: didChangeMetrics — tidak pakai .window yang deprecated
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

  String _extractUrlFromIntent(String url) {
    if (!url.startsWith('intent://')) return url;
    try {
      final parts = url.split('#Intent;');
      if (parts.length < 2) return url;
      final intentPart = parts[0].replaceFirst('intent://', '');
      final intentParams = parts[1];
      String scheme = 'https';
      for (final param in intentParams.split(';')) {
        if (param.startsWith('scheme=')) { scheme = param.replaceFirst('scheme=', ''); break; }
      }
      return '$scheme://$intentPart';
    } catch (e) { debugPrint('Error parsing intent URL: $e'); return url; }
  }

  Future<void> fetchEpisodeData() async {
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/episode/${widget.episodeSlug}'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          episodeData = jsonData['data'];
          _qualities = episodeData?['server']?['qualities'] ?? [];
          if (_qualities.isNotEmpty) {
            for (int i = 0; i < _qualities.length; i++) {
              final serverList = _qualities[i]['serverList'] ?? [];
              if (serverList.isNotEmpty) { _selectedQualityIndex = i; _selectedServerIndex = 0; break; }
            }
          }
        });
        await _fetchStreamUrl();
        _initializeWebView();
        _addToWatchHistory();
        setState(() { isLoading = false; });
      } else { setState(() { isLoading = false; isError = true; }); }
    } catch (e) { debugPrint('Error: $e'); setState(() { isLoading = false; isError = true; }); }
  }

  Future<void> _fetchStreamUrl() async {
    if (_qualities.isEmpty) return;
    final selectedQuality = _qualities[_selectedQualityIndex];
    final serverList = selectedQuality['serverList'] ?? [];
    if (serverList.isEmpty) return;
    final serverId = serverList[_selectedServerIndex]['serverId'];
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/server/$serverId'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        String rawUrl = jsonData['data']['url'];
        String actualUrl = _extractUrlFromIntent(rawUrl);
        debugPrint('Stream URL: $actualUrl');
        setState(() { _streamUrl = actualUrl; });
      } else { debugPrint('Failed to fetch stream URL: ${response.statusCode}'); }
    } catch (e) { debugPrint('Error fetching stream URL: $e'); }
  }

  Future<void> _addToWatchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('watch_history') ?? [];
      List<Map<String, dynamic>> watchHistory = historyJson.map((item) => Map<String, dynamic>.from(json.decode(item))).toList();
      final historyItem = {
        'slug': widget.animeSlug, 'title': widget.animeTitle, 'poster': widget.animePoster,
        'last_watched_episode': episodeData?['title'], 'last_watched_episode_slug': widget.episodeSlug,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      watchHistory.removeWhere((item) => item['slug'] == widget.animeSlug);
      watchHistory.insert(0, historyItem);
      if (watchHistory.length > 20) watchHistory = watchHistory.sublist(0, 20);
      await prefs.setStringList('watch_history', watchHistory.map((item) => json.encode(item)).toList());
      if (widget.onHistoryUpdate != null) widget.onHistoryUpdate!();
    } catch (e) { debugPrint('Error saving to watch history: $e'); }
  }

  void _initializeWebView() {
    if (_streamUrl == null) return;
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel('FullScreen', onMessageReceived: (JavaScriptMessage message) {
        if (message.message == 'enter') { _enterFullScreen(); } else if (message.message == 'exit') { _exitFullScreen(); }
      })
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (int progress) {
          if (progress == 100) {
            setState(() { _isWebViewLoading = false; });
            _injectFullScreenDetection();
            _injectAdBlocker();
          }
        },
        onPageStarted: (_) => setState(() { _isWebViewLoading = true; }),
        onPageFinished: (_) {
          setState(() { _isWebViewLoading = false; });
          _injectFullScreenDetection();
          _injectAdBlocker();
        },
        onWebResourceError: (_) => setState(() { _isWebViewLoading = false; }),
        onNavigationRequest: (NavigationRequest request) {
          final url = request.url;
          if (url.startsWith('intent://')) {
            final actualUrl = _extractUrlFromIntent(url);
            _webViewController.loadRequest(Uri.parse(actualUrl), headers: _getChromeHeaders());
            return NavigationDecision.prevent;
          }
          if (_isAdUrl(url)) { debugPrint('AD BLOCKED: $url'); return NavigationDecision.prevent; }
          if (!url.startsWith('http://') && !url.startsWith('https://')) { debugPrint('Blocked unknown scheme: $url'); return NavigationDecision.prevent; }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(_streamUrl!), headers: _getChromeHeaders());
  }

  void _injectAdBlocker() {
    _webViewController.runJavaScript('''
      (function() {
        const s = document.createElement('style');
        s.textContent = \`
          [class*="ad-"],[class*="ads-"],[class*="advert"],[class*="banner-ad"],
          [class*="popup"],[class*="pop-up"],[class*="popunder"],[class*="overlay"],
          [class*="interstitial"],[class*="sticky-ad"],[class*="sponsor"],
          [id*="ad-"],[id*="ads-"],[id*="popup"],[id*="overlay"],[id*="banner"],
          ins[class*="adsbygoogle"],[data-ad],[data-ad-slot],
          div[class*="taboola"],div[class*="outbrain"],div[class*="mgid"],
          div[class*="Modal"]:not(:has(video)):not(:has(iframe)),
          div[class*="modal"]:not(:has(video)):not(:has(iframe)),
          div[style*="z-index: 99999"]:not(:has(video)):not(:has(iframe)),
          div[style*="z-index: 999999"]:not(:has(video)):not(:has(iframe)) {
            display:none!important;visibility:hidden!important;
            height:0!important;width:0!important;opacity:0!important;
          }
          video,iframe[src*="player"],iframe[src*="video"],iframe[src*="embed"],
          iframe[src*="stream"],.video-player,[class*="player"],[id*="player"] {
            display:block!important;visibility:visible!important;z-index:1!important;
          }
        \`;
        document.head.appendChild(s);
        const remove = ['ins','.adsbygoogle','[id^="google_ads"]','[id^="div-gpt-ad"]',
          'iframe[src*="ads"]','iframe[src*="banner"]','iframe[src*="popup"]',
          '.ad-banner','.ad-container','.sticky-ad','#sticky-ad',
          '.popup-overlay','.modal-overlay','.cookie-banner','.newsletter-popup'];
        remove.forEach(sel => {
          document.querySelectorAll(sel).forEach(el => {
            if (el.tagName === 'IFRAME') {
              const src = el.getAttribute('src') || '';
              if (src.includes('player')||src.includes('video')||src.includes('embed')||src.includes('stream')) return;
            }
            el.remove();
          });
        });
        if (!window._adBlock) {
          window._adBlock = setInterval(() => {
            document.querySelectorAll('div[style*="position: fixed"]').forEach(el => {
              const z = parseInt(window.getComputedStyle(el).zIndex)||0;
              if (z > 1000 && !el.querySelector('video') && !el.querySelector('iframe')) el.remove();
            });
          }, 2000);
        }
      })();
    ''');
  }

  void _injectFullScreenDetection() {
    _webViewController.runJavaScript('''
      function handleFS() {
        if (document.fullscreenElement||document.webkitFullscreenElement) FullScreen.postMessage('enter');
        else FullScreen.postMessage('exit');
      }
      ['fullscreenchange','webkitfullscreenchange','mozfullscreenchange','MSFullscreenChange'].forEach(e => document.addEventListener(e, handleFS));
      document.addEventListener('click', e => { if (e.target.tagName==='VIDEO'||e.target.closest?.('video')) setTimeout(handleFS,100); });
      document.addEventListener('touchend', e => { if (e.target.tagName==='VIDEO'||e.target.closest?.('video')) setTimeout(handleFS,100); });
    ''');
  }

  void _enterFullScreen() {
    if (!_isFullScreen) {
      setState(() { _isFullScreen = true; });
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _exitFullScreen() {
    if (_isFullScreen) {
      setState(() { _isFullScreen = false; });
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleFullScreen() { if (_isFullScreen) { _exitFullScreen(); } else { _enterFullScreen(); } }

  Map<String, String> _getChromeHeaders() {
    return {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
    };
  }

  void _refreshWebView() { setState(() { _isWebViewLoading = true; }); _webViewController.reload(); }
  void _openInExternalBrowser() { if (_streamUrl != null) _launchURL(_streamUrl!); }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) { await launchUrl(uri, mode: LaunchMode.externalApplication); }
  }

  void _showDownloadOptions() {
    showModalBottomSheet(
      context: context, backgroundColor: AC.card, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AC.border2, borderRadius: BorderRadius.circular(2)), margin: const EdgeInsets.only(bottom: 16))),
        const Text("DOWNLOAD OPTIONS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'MADEEvolveSansEVO', color: AC.accent, letterSpacing: 2)),
        const SizedBox(height: 16),
        const Text("Download options will be available soon.", style: TextStyle(color: AC.muted)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () { Navigator.pop(context); _openInExternalBrowser(); },
          style: ElevatedButton.styleFrom(backgroundColor: AC.accent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text("OPEN IN BROWSER", style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, letterSpacing: 1))),
      ]))),
    );
  }

  void _goToNextEpisode() {
    if (widget.episodes != null && _currentEpisodeIndex < widget.episodes!.length - 1) {
      final nextEpisode = widget.episodes![_currentEpisodeIndex + 1];
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AnimeEpisodePage(
        episodeSlug: nextEpisode['episodeId'], animeSlug: widget.animeSlug, animeTitle: widget.animeTitle,
        animePoster: widget.animePoster, episodes: widget.episodes, recommendations: widget.recommendations, onHistoryUpdate: widget.onHistoryUpdate,
      )));
    }
  }

  void _changeQuality(int qualityIndex, int serverIndex) async {
    setState(() { _selectedQualityIndex = qualityIndex; _selectedServerIndex = serverIndex; _isWebViewLoading = true; _streamUrl = null; });
    await _fetchStreamUrl();
    _initializeWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      appBar: _isFullScreen ? null : AppBar(
        backgroundColor: AC.bg2.withOpacity(0.9),
        iconTheme: const IconThemeData(color: AC.accent),
        flexibleSpace: Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AC.border)))),
        title: Text(episodeData?['title'] ?? "STREAMING",
          style: const TextStyle(fontWeight: FontWeight.bold, color: AC.accent, fontSize: 13, fontFamily: 'MADEEvolveSansEVO', letterSpacing: 1),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (episodeData != null) ...[
            IconButton(icon: const Icon(FontAwesomeIcons.arrowsRotate, color: AC.accent, size: 16), onPressed: _refreshWebView, tooltip: 'Refresh'),
            IconButton(icon: const Icon(FontAwesomeIcons.arrowUpRightFromSquare, color: AC.accent, size: 16), onPressed: _openInExternalBrowser, tooltip: 'Browser'),
            IconButton(icon: const Icon(FontAwesomeIcons.download, color: AC.accent, size: 16), onPressed: _showDownloadOptions, tooltip: 'Download'),
          ],
        ],
      ),
      body: isLoading ? _buildLoadingShimmer()
          : isError || episodeData == null
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(FontAwesomeIcons.triangleExclamation, color: AC.accent, size: 48), const SizedBox(height: 16),
                  const Text("Failed to load episode", style: TextStyle(color: AC.muted)), const SizedBox(height: 16),
                  ElevatedButton(onPressed: fetchEpisodeData,
                    style: ElevatedButton.styleFrom(backgroundColor: AC.accent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("RETRY")),
                ]))
              : _buildStreamingContent(),
    );
  }

  Widget _buildStreamingContent() {
    final List<dynamic> episodes = widget.episodes ?? [];
    final List<dynamic> recommendations = widget.recommendations ?? [];
    final List<dynamic> genres = episodeData?['genreList'] ?? [];

    return Column(children: [
      Container(
        height: _isFullScreen ? MediaQuery.of(context).size.height : MediaQuery.of(context).size.height * 0.35,
        width: double.infinity, color: Colors.black,
        child: Stack(children: [
          if (_streamUrl != null)
            WebViewWidget(controller: _webViewController)
          else
            const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(color: AC.accent),
              SizedBox(height: 16),
              Text("Loading stream URL...", style: TextStyle(color: AC.text)),
            ])),
          if (_isWebViewLoading)
            Container(color: Colors.black87, child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircularProgressIndicator(color: AC.accent, strokeWidth: 2),
              SizedBox(height: 12),
              Text("Loading video player...", style: TextStyle(color: AC.muted, fontSize: 12)),
            ]))),
          if (!_isFullScreen && _qualities.isNotEmpty)
            Positioned(top: 10, right: 10, child: Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
              child: IconButton(icon: const Icon(FontAwesomeIcons.gear, color: AC.accent, size: 18),
                onPressed: () { setState(() { _showQualitySelector = !_showQualitySelector; }); }))),
          Positioned(bottom: 12, right: 12, child: GestureDetector(
            onTap: _toggleFullScreen,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(10), border: Border.all(color: AC.border)),
              child: Icon(_isFullScreen ? FontAwesomeIcons.compress : FontAwesomeIcons.expand, color: AC.accent, size: 20)))),
          if (_isFullScreen)
            Positioned(top: 40, left: 16, child: GestureDetector(
              onTap: _exitFullScreen,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(10), border: Border.all(color: AC.border)),
                child: const Icon(FontAwesomeIcons.compress, color: AC.accent, size: 20)))),
        ]),
      ),
      if (_showQualitySelector && !_isFullScreen && _qualities.isNotEmpty)
        Container(padding: const EdgeInsets.all(16), color: AC.card, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("QUALITY SETTINGS", style: TextStyle(color: AC.accent, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'MADEEvolveSansEVO', letterSpacing: 1)),
            IconButton(icon: const Icon(FontAwesomeIcons.xmark, color: AC.accent, size: 16), onPressed: () { setState(() { _showQualitySelector = false; }); }),
          ]),
          const SizedBox(height: 12),
          ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _qualities.length,
            itemBuilder: (context, qualityIndex) {
              final quality = _qualities[qualityIndex];
              final qualityTitle = quality['title'] ?? '';
              final serverList = quality['serverList'] ?? [];
              if (serverList.isEmpty) return const SizedBox.shrink();
              return ExpansionTile(
                title: Text(qualityTitle, style: const TextStyle(color: AC.text, fontWeight: FontWeight.bold, fontFamily: 'ShareTechMono')),
                tilePadding: EdgeInsets.zero, childrenPadding: const EdgeInsets.only(left: 16),
                backgroundColor: AC.surface, collapsedBackgroundColor: AC.surface,
                iconColor: AC.accent, collapsedIconColor: AC.accent,
                children: serverList.map<Widget>((server) {
                  final serverTitle = server['title'] ?? '';
                  final serverIndex = serverList.indexOf(server);
                  final isSelected = _selectedQualityIndex == qualityIndex && _selectedServerIndex == serverIndex;
                  return ListTile(
                    title: Text(serverTitle, style: TextStyle(color: isSelected ? AC.accent : AC.text, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    trailing: isSelected ? const Icon(FontAwesomeIcons.circleCheck, color: AC.accent, size: 18) : null,
                    onTap: () { _changeQuality(qualityIndex, serverIndex); setState(() { _showQualitySelector = false; }); },
                  );
                }).toList(),
              );
            }),
        ])),
      if (!_isFullScreen && !_showQualitySelector) ...[
        Container(height: 50, color: AC.card, child: Row(children: [
          _buildTabButton(0, FontAwesomeIcons.listOl, 'EPISODES'),
          _buildTabButton(1, FontAwesomeIcons.thumbsUp, 'RECOMMEND'),
          _buildTabButton(2, FontAwesomeIcons.tags, 'GENRES'),
        ])),
        Expanded(child: IndexedStack(index: _currentTabIndex, children: [
          _buildEpisodeList(episodes),
          _buildRecommendations(recommendations),
          _buildGenresList(genres),
        ])),
      ],
    ]);
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;
    return Expanded(child: Material(
      color: isSelected ? AC.accent.withOpacity(0.15) : Colors.transparent,
      child: InkWell(onTap: () { setState(() { _currentTabIndex = index; }); },
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: isSelected ? AC.accent : AC.muted2, size: 16),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSelected ? AC.accent : AC.muted2, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontFamily: 'MADEEvolveSansEVO', letterSpacing: 0.5)),
        ])),
    ));
  }

  Widget _buildEpisodeList(List<dynamic> episodes) {
    if (episodes.isEmpty) {
      // FIX: FontAwesomeIcons.playlist → FontAwesomeIcons.listUl
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(FontAwesomeIcons.listUl, color: AC.muted2, size: 48),
        const SizedBox(height: 16),
        const Text("No episodes available", style: TextStyle(color: AC.muted)),
      ]));
    }
    return Column(children: [
      if (_currentEpisodeIndex < episodes.length - 1)
        Container(margin: const EdgeInsets.all(12), child: ElevatedButton.icon(
          onPressed: _goToNextEpisode,
          icon: const Icon(FontAwesomeIcons.forward, size: 14),
          label: const Text("NEXT EPISODE"),
          style: ElevatedButton.styleFrom(backgroundColor: AC.accent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      Expanded(child: ListView.builder(padding: const EdgeInsets.all(8), itemCount: episodes.length, itemBuilder: (context, index) {
        final episode = episodes[index];
        final isCurrentEpisode = episode['episodeId'] == widget.episodeSlug;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
          decoration: BoxDecoration(
            color: isCurrentEpisode ? AC.accent.withOpacity(0.15) : AC.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isCurrentEpisode ? AC.accent : AC.border)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            leading: Container(width: 38, height: 38,
              decoration: BoxDecoration(gradient: isCurrentEpisode ? const LinearGradient(colors: [AC.accent, AC.accent2]) : null, color: isCurrentEpisode ? null : AC.surface, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(episode['eps'].toString(), style: TextStyle(color: isCurrentEpisode ? Colors.white : AC.text, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'ShareTechMono')))),
            title: Text(episode['title'],
              style: TextStyle(color: isCurrentEpisode ? AC.accent : AC.text, fontSize: 13, fontWeight: isCurrentEpisode ? FontWeight.bold : FontWeight.normal),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () {
              if (!isCurrentEpisode) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AnimeEpisodePage(
                  episodeSlug: episode['episodeId'], animeSlug: widget.animeSlug, animeTitle: widget.animeTitle,
                  animePoster: widget.animePoster, episodes: widget.episodes, recommendations: widget.recommendations, onHistoryUpdate: widget.onHistoryUpdate,
                )));
              }
            },
            trailing: Icon(isCurrentEpisode ? FontAwesomeIcons.circlePlay : FontAwesomeIcons.play, color: isCurrentEpisode ? AC.accent : AC.muted2, size: 18),
          ),
        );
      })),
    ]);
  }

  Widget _buildRecommendations(List<dynamic> recommendations) {
    if (recommendations.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(FontAwesomeIcons.film, color: AC.muted2, size: 48), const SizedBox(height: 16),
        const Text("No recommendations available", style: TextStyle(color: AC.muted)),
      ]));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.7),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final rec = recommendations[index];
        return GestureDetector(
          onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeDetailPage(slug: rec['animeId'], onHistoryUpdate: widget.onHistoryUpdate))); },
          child: Container(
            decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AC.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Image.network(rec['poster'], width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: double.infinity, color: AC.surface,
                    alignment: Alignment.center, child: const Icon(FontAwesomeIcons.image, color: AC.muted2, size: 20))))),
              Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(rec['title'], style: const TextStyle(color: AC.text, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                if (rec['score'] != null && rec['score'].toString().isNotEmpty)
                  Row(children: [const Icon(FontAwesomeIcons.star, color: AC.gold, size: 10), const SizedBox(width: 4), Text(rec['score'], style: const TextStyle(color: AC.gold, fontSize: 10, fontFamily: 'ShareTechMono'))]),
              ])),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildGenresList(List<dynamic> genres) {
    if (genres.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(FontAwesomeIcons.tags, color: AC.muted2, size: 48), const SizedBox(height: 16),
        const Text("No genres available", style: TextStyle(color: AC.muted)),
      ]));
    }
    return Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("ANIME GENRES", style: TextStyle(color: AC.accent, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'MADEEvolveSansEVO', letterSpacing: 2)),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: genres.map<Widget>((genre) {
        return GestureDetector(
          onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeGenrePage(genreSlug: genre['genreId'], genreName: genre['title']))); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AC.accent, AC.accent2]), borderRadius: BorderRadius.circular(16)),
            child: Text(genre['title'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
        );
      }).toList()),
      const SizedBox(height: 20),
      if (widget.animeTitle != null) ...[
        const Text("ANIME INFO", style: TextStyle(color: AC.accent, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'MADEEvolveSansEVO', letterSpacing: 2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AC.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AC.border)),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(8),
              child: Image.network(widget.animePoster ?? '', height: 70, width: 50, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 70, width: 50, color: AC.surface,
                  alignment: Alignment.center, child: const Icon(FontAwesomeIcons.image, color: AC.muted2, size: 16)))),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.animeTitle ?? '', style: const TextStyle(color: AC.text, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
          ])),
      ],
    ]));
  }

  Widget _buildLoadingShimmer() {
    return ListView(children: [
      AspectRatio(aspectRatio: 16 / 9, child: Shimmer.fromColors(baseColor: AC.card, highlightColor: AC.surface, child: Container(color: AC.card))),
    ]);
  }
}
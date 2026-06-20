import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
  // Weather-specific
  static const skyG1   = Color(0xFF38BDF8);
  static const skyG2   = Color(0xFF0EA5E9);
  static const stormG1 = Color(0xFF6366F1);
  static const stormG2 = Color(0xFF4F46E5);
  static const sunG1    = Color(0xFFFBBF24);
  static const sunG2   = Color(0xFFF59E0B);
}

// ── WEATHER PAGE ────────────────────────────────────────────────────────────
class WeatherPage extends StatefulWidget {
  final String sessionKey;

  const WeatherPage({super.key, required this.sessionKey});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _cityController = TextEditingController();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;

  Future<void> _checkWeather() async {
    if (_cityController.text.trim().isEmpty) {
      _showSnackBar('Nama kota wajib diisi', isError: true);
      return;
    }
    setState(() {
      _isLoading = true;
      _weatherData = null;
    });
    try {
      final city = Uri.encodeComponent(_cityController.text.trim());
      final response = await http.get(Uri.parse(
          'https://api.zenzxz.my.id/tools/accuweather?city=$city'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['result'] != null) {
          setState(() => _weatherData = data);
        } else {
          _showSnackBar('Kota tidak ditemukan atau server error', isError: true);
        }
      } else {
        _showSnackBar('Gagal terhubung ke layanan cuaca', isError: true);
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

  IconData _getWeatherIcon(String? phrase) {
    if (phrase == null) return Icons.help_outline;
    final p = phrase.toLowerCase();
    if (p.contains('thunderstorm') || p.contains('t-storm')) return Icons.thunderstorm_rounded;
    if (p.contains('rain') || p.contains('shower')) return Icons.water_drop_rounded;
    if (p.contains('snow') || p.contains('ice') || p.contains('flurries')) return Icons.ac_unit_rounded;
    if (p.contains('cloudy') || p.contains('overcast') || p.contains('cloud')) return Icons.cloud_rounded;
    if (p.contains('sunny') || p.contains('clear')) return Icons.wb_sunny_rounded;
    if (p.contains('partly sunny') || p.contains('partly cloudy') || p.contains('intermittent')) return Icons.wb_cloudy_rounded;
    if (p.contains('hazy')) return Icons.filter_drama_rounded;
    if (p.contains('fog') || p.contains('mist')) return Icons.blur_on_rounded;
    if (p.contains('wind')) return Icons.air_rounded;
    return Icons.cloud_rounded;
  }

  Color _getWeatherColor(String? phrase) {
    if (phrase == null) return _C.muted;
    final p = phrase.toLowerCase();
    if (p.contains('thunderstorm') || p.contains('t-storm')) return _C.stormG1;
    if (p.contains('rain') || p.contains('shower')) return _C.blueG1;
    if (p.contains('snow') || p.contains('ice')) return _C.skyG1;
    if (p.contains('cloudy') || p.contains('overcast') || p.contains('cloud')) return _C.muted;
    if (p.contains('sunny') || p.contains('clear')) return _C.sunG1;
    if (p.contains('partly sunny') || p.contains('partly cloudy') || p.contains('intermittent')) return _C.orangeG1;
    if (p.contains('hazy')) return _C.sunG1;
    return _C.skyG1;
  }

  Color _getUvColor(String? uv) {
    if (uv == null) return _C.muted;
    final u = uv.toLowerCase();
    if (u.contains('extreme')) return _C.danger;
    if (u.contains('very high')) return _C.accent;
    if (u.contains('high')) return _C.orangeG1;
    if (u.contains('moderate')) return _C.sunG1;
    if (u.contains('low')) return _C.greenG1;
    return _C.muted;
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
                color: _C.skyG1.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.skyG1.withOpacity(0.25)),
              ),
              child: Icon(Icons.cloud_rounded, color: _C.skyG1, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CEK CUACA', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 13, fontWeight: FontWeight.bold, color: _C.text)),
                Text('AccuWeather Forecast', style: TextStyle(fontSize: 10, color: _C.muted)),
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
                      color: _C.skyG1.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.skyG1.withOpacity(0.25)),
                    ),
                    child: Icon(Icons.wb_sunny_rounded, color: _C.skyG1, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WEATHER FORECAST', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text('Masukkan nama kota untuk melihat prakiraan cuaca 10 hari dari AccuWeather.', style: TextStyle(fontSize: 12, color: _C.muted)),
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
                    gradient: LinearGradient(colors: [_C.skyG1, _C.stormG1]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('INPUT KOTA', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
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
                  Text('NAMA KOTA', style: TextStyle(fontFamily: 'ShareTechMono', fontSize: 10, color: _C.muted, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border2),
                    ),
                    child: TextField(
                      controller: _cityController,
                      style: TextStyle(color: _C.text, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'ShareTechMono', letterSpacing: 1),
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.words,
                      cursorColor: _C.accent,
                      onSubmitted: (_) => _checkWeather(),
                      decoration: InputDecoration(
                        hintText: 'Bandung, Jakarta, Surabaya...',
                        hintStyle: TextStyle(color: _C.muted2, fontSize: 14, letterSpacing: 0.5),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Icon(Icons.location_on_rounded, color: _C.muted, size: 18),
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
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _checkWeather,
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
                                Icon(Icons.search_rounded, size: 16),
                                const SizedBox(width: 10),
                                Text('CEK CUACA', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Result ──
            if (_weatherData != null) ...[
              _buildWeatherResult(),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  // ── Weather Result ────────────────────────────────────────────────────────
  Widget _buildWeatherResult() {
    final result = _weatherData!['result'] as Map<String, dynamic>;
    final location = result['location'] as Map<String, dynamic>;
    final forecast = result['forecast'] as Map<String, dynamic>;
    final headline = forecast['headline'] as String?;
    final effectiveDate = forecast['effectiveDate'] as String?;
    final dailyForecasts = forecast['dailyForecasts'] as List<dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Label
        Row(
          children: [
            Container(
              width: 4, height: 18,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_C.skyG1, _C.blueG1]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text('RESULT DATA', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 12, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
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
                  Text('${dailyForecasts.length} DAYS', style: TextStyle(color: _C.greenG1, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'MADEEvolveSansEVO', letterSpacing: 1)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Location Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: _C.skyG1.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.location_on_rounded, color: _C.skyG1, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text('LOCATION', style: TextStyle(fontFamily: 'MADEEvolveSansEVO', fontSize: 11, fontWeight: FontWeight.bold, color: _C.text, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: _C.border2),
              const SizedBox(height: 14),
              _infoRow('Kota', location['name'] ?? 'N/A', Icons.location_city_rounded, _C.skyG1),
              _infoRow('Negara', location['country'] ?? 'N/A', Icons.flag_rounded, _C.accent),
              if (headline != null) _infoRow('Headline', headline, Icons.notifications_rounded, _C.sunG1),
              if (effectiveDate != null) _infoRow('Tanggal Efektif', effectiveDate, Icons.calendar_today_rounded, _C.blueG1),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Daily Forecasts
        ...dailyForecasts.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value as Map<String, dynamic>;
          return _buildDayCard(day, index);
        }),
      ],
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day, int index) {
    final date = day['date'] as String? ?? 'N/A';
    final temp = day['temperature'] as Map<String, dynamic>? ?? {};
    final tempMin = temp['min'] as String? ?? 'N/A';
    final tempMax = temp['max'] as String? ?? 'N/A';
    final dayData = day['day'] as Map<String, dynamic>? ?? {};
    final nightData = day['night'] as Map<String, dynamic>? ?? {};
    final dayPhrase = dayData['phrase'] as String?;
    final nightPhrase = nightData['phrase'] as String?;
    final hasPrecip = dayData['hasPrecipitation'] as bool? ?? false;
    final precipType = dayData['precipitationType'] as String?;
    final precipProb = dayData['precipitationProbability'] as String? ?? '0%';
    final thunderstormProb = dayData['thunderstormProbability'] as String? ?? '0%';
    final dayWind = dayData['wind'] as Map<String, dynamic>? ?? {};
    final dayWindSpeed = dayWind['speed'] as String? ?? 'N/A';
    final dayWindDir = dayWind['direction'] as String? ?? 'N/A';
    final nightWind = nightData['wind'] as Map<String, dynamic>? ?? {};
    final nightWindSpeed = nightWind['speed'] as String? ?? 'N/A';
    final nightWindDir = nightWind['direction'] as String? ?? 'N/A';
    final hoursOfSun = day['hoursOfSun'] as double? ?? 0.0;
    final airQuality = day['airQuality'] as Map<String, dynamic>? ?? {};
    final link = day['link'] as String?;

    final dayIcon = _getWeatherIcon(dayPhrase);
    final nightIcon = _getWeatherIcon(nightPhrase);
    final dayColor = _getWeatherColor(dayPhrase);
    final nightColor = _getWeatherColor(nightPhrase);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: dayColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(dayIcon, color: dayColor, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HARI ${index + 1}',
                        style: TextStyle(
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _C.text,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(fontSize: 10, color: _C.muted, fontFamily: 'ShareTechMono'),
                      ),
                    ],
                  ),
                ),
                // Temperature badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _C.sunG1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.sunG1.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.thermostat_rounded, color: _C.sunG1, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$tempMin | $tempMax',
                        style: TextStyle(
                          color: _C.sunG1,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: _C.border2),
            const SizedBox(height: 14),

            // Day & Night section
            Row(
              children: [
                // Day
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: _C.sunG1.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(Icons.wb_sunny_rounded, color: _C.sunG1, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Siang', style: TextStyle(fontSize: 9, color: _C.muted2, fontFamily: 'ShareTechMono', letterSpacing: 1)),
                            Text(
                              dayPhrase ?? 'N/A',
                              style: TextStyle(color: _C.text, fontSize: 11, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: _C.border2),
                const SizedBox(width: 12),
                // Night
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: _C.stormG1.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(Icons.nightlight_rounded, color: _C.stormG1, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Malam', style: TextStyle(fontSize: 9, color: _C.muted2, fontFamily: 'ShareTechMono', letterSpacing: 1)),
                            Text(
                              nightPhrase ?? 'N/A',
                              style: TextStyle(color: _C.text, fontSize: 11, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: _C.border2),
            const SizedBox(height: 14),

            // Detail rows
            _infoRow('Curah Hujan', hasPrecip ? '$precipProb (${precipType ?? "Rain"})' : '$precipProb', hasPrecip ? Icons.water_drop_rounded : Icons.water_drop_outlined, hasPrecip ? _C.blueG1 : _C.muted),
            _infoRow('Petir', thunderstormProb, Icons.thunderstorm_rounded, int.parse(thunderstormProb.replaceAll('%', '')) > 20 ? _C.stormG1 : _C.muted),
            _infoRow('Angin Siang', '$dayWindSpeed $dayWindDir', Icons.air_rounded, _C.skyG1),
            _infoRow('Angin Malam', '$nightWindSpeed $nightWindDir', Icons.air_rounded, _C.stormG1),
            _infoRow('Jam Matahari', '${hoursOfSun.toStringAsFixed(1)}h', Icons.wb_sunny_rounded, _C.sunG1),

            const SizedBox(height: 10),

            // Air Quality badges row
            if (airQuality.isNotEmpty) ...[
              Container(height: 1, color: _C.border2),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: _C.greenG1.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(Icons.eco_rounded, color: _C.greenG1, size: 12),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _airBadge('AQ: ${airQuality['AirQuality'] ?? 'N/A'}', _getUvColor(airQuality['AirQuality'])),
                        _airBadge('UV: ${airQuality['UVIndex'] ?? 'N/A'}', _getUvColor(airQuality['UVIndex'])),
                        _airBadge('Grass: ${airQuality['Grass'] ?? 'N/A'}', _C.greenG1),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 38),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _airBadge('Mold: ${airQuality['Mold'] ?? 'N/A'}', _C.purpleG1),
                    _airBadge('Ragweed: ${airQuality['Ragweed'] ?? 'N/A'}', _C.orangeG1),
                    _airBadge('Tree: ${airQuality['Tree'] ?? 'N/A'}', _C.greenG1),
                  ],
                ),
              ),
            ],

            // Link to full forecast
            if (link != null) ...[
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(link);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _C.skyG1.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.open_in_browser_rounded, color: _C.skyG1, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'LIHAT DETAIL DI ACCUWEATHER',
                        style: TextStyle(
                          color: _C.skyG1,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'MADEEvolveSansEVO',
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _airBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontFamily: 'ShareTechMono',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(child: Icon(icon, color: iconColor, size: 12)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: _C.muted, fontSize: 12, fontFamily: 'ShareTechMono')),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: _C.text, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }
}

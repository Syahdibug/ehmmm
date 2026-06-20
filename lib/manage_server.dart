import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  static const blueG1 = Color(0xFF229ED9);
  static const purpleG1 = Color(0xFF9C27B0);
  static const orangeG1 = Color(0xFFFF8C00);
}

// ── MANAGE SERVER PAGE ──────────────────────────────────────────────────────
class ManageServerPage extends StatefulWidget {
  final String sessionKey;

  const ManageServerPage({super.key, required this.sessionKey});

  @override
  State<ManageServerPage> createState() => _ManageServerPageState();
}

class _ManageServerPageState extends State<ManageServerPage> {
  static const String baseUrl = "http://104.207.64.203:2001/api/vps";

  bool _isLoading = true;
  List<Map<String, dynamic>> _servers = [];

  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchServers();
  }

  // ── API Logic ──────────────────────────────────────────────────────────────
  Future<void> _fetchServers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/myServer?key=${widget.sessionKey}"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['servers'] != null) {
          setState(
            () => _servers = List<Map<String, dynamic>>.from(data['servers']),
          );
        }
      } else {
        _showMessage("Gagal memuat server.", isError: true);
      }
    } catch (e) {
      _showMessage("Error fetching servers: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addServer() async {
    final host = _hostController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (host.isEmpty || username.isEmpty || password.isEmpty) {
      _showMessage("Semua field wajib diisi.", isError: true);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/addServer"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "key": widget.sessionKey,
          "host": host,
          "username": username,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showMessage("Server berhasil ditambahkan!");
        _hostController.clear();
        _usernameController.clear();
        _passwordController.clear();
        Navigator.pop(context);
        _fetchServers();
      } else {
        _showMessage(
          data['error'] ?? "Gagal menambahkan server.",
          isError: true,
        );
      }
    } catch (e) {
      _showMessage("Error adding server: $e", isError: true);
    }
  }

  Future<void> _deleteServer(String host) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/delServer"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"key": widget.sessionKey, "host": host}),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        _showMessage("Server berhasil dihapus!");
        _fetchServers();
      } else {
        _showMessage(data['error'] ?? "Gagal menghapus server.", isError: true);
      }
    } catch (e) {
      _showMessage("Error deleting server: $e", isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
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
                color: _C.purpleG1.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.purpleG1.withOpacity(0.25)),
              ),
              child: Icon(
                FontAwesomeIcons.server,
                color: _C.purpleG1,
                size: 15,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MANAGE SERVERS',
                  style: TextStyle(
                    fontFamily: 'MADEEvolveSansEVO',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _C.text,
                  ),
                ),
                Text(
                  'VPS Management',
                  style: TextStyle(fontSize: 10, color: _C.muted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _fetchServers,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.border2),
                ),
                child: Icon(Icons.refresh, color: _C.muted, size: 16),
              ),
            ),
          ),
        ],
        iconTheme: IconThemeData(color: _C.text),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _C.border),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _C.accent,
              ),
            )
          : _servers.isEmpty
          ? _buildEmptyState()
          : _buildServerList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddServerDialog,
        backgroundColor: _C.accent,
        elevation: 0,
        child: Icon(Icons.add, color: Colors.white, size: 22),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _C.border2),
            ),
            child: Icon(FontAwesomeIcons.server, color: _C.muted2, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'NO SERVERS FOUND',
            style: TextStyle(
              fontFamily: 'MADEEvolveSansEVO',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _C.muted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tambahkan VPS pertamamu untuk memulai.',
            style: TextStyle(color: _C.muted2, fontSize: 12),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showAddServerDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _C.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.accent.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: _C.accent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'ADD SERVER',
                    style: TextStyle(
                      fontFamily: 'MADEEvolveSansEVO',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _C.accent,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Server List ───────────────────────────────────────────────────────────
  Widget _buildServerList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      itemCount: _servers.length,
      itemBuilder: (context, index) {
        final server = _servers[index];
        return _serverCard(server);
      },
    );
  }

  Widget _serverCard(Map<String, dynamic> server) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.border),
          ),
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                height: 76,
                decoration: const BoxDecoration(
                  color: _C.purpleG1,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),
              // Icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _C.purpleG1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FontAwesomeIcons.server,
                    color: _C.purpleG1,
                    size: 18,
                  ),
                ),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        server['host'] ?? 'Unknown Host',
                        style: TextStyle(
                          color: _C.text,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'ShareTechMono',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.user,
                            color: _C.muted2,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            server['username'] ?? 'N/A',
                            style: TextStyle(
                              color: _C.muted,
                              fontSize: 11,
                              fontFamily: 'ShareTechMono',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Delete button
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _showDeleteConfirmation(server['host']),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _C.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: _C.danger.withOpacity(0.7),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showAddServerDialog() {
    _hostController.clear();
    _usernameController.clear();
    _passwordController.clear();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _C.surface.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _C.purpleG1.withOpacity(0.3), width: 1),
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
                      color: _C.purpleG1.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FontAwesomeIcons.server,
                      color: _C.purpleG1,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'ADD SERVER',
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
              _dialogField(
                'Host IP',
                _hostController,
                FontAwesomeIcons.globe,
                hint: '192.168.1.1',
              ),
              const SizedBox(height: 14),
              _dialogField(
                'SSH Username',
                _usernameController,
                FontAwesomeIcons.user,
                hint: 'root',
              ),
              const SizedBox(height: 14),
              _dialogField(
                'SSH Password',
                _passwordController,
                FontAwesomeIcons.lock,
                hint: '••••••••',
                isPassword: true,
              ),
              const SizedBox(height: 24),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                    onTap: _addServer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _C.purpleG1,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'ADD',
                            style: TextStyle(
                              fontFamily: 'MADEEvolveSansEVO',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String? host) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.surface.withOpacity(0.98),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _C.danger.withOpacity(0.4), width: 1),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _C.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: _C.danger,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Confirm Delete',
              style: TextStyle(
                color: _C.text,
                fontFamily: 'MADEEvolveSansEVO',
                fontSize: 14,
              ),
            ),
          ],
        ),
        content: Text(
          'Hapus server "$host" secara permanen?',
          style: TextStyle(color: _C.muted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _C.muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteServer(host!);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: _C.danger, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    String label,
    TextEditingController controller,
    IconData icon, {
    String hint = '',
    bool isPassword = false,
  }) {
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
            color: _C.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _C.border2),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: TextStyle(color: _C.text, fontSize: 14),
            cursorColor: _C.accent,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _C.muted2, fontSize: 13),
              prefixIcon: Icon(icon, color: _C.muted, size: 16),
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

  @override
  void dispose() {
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

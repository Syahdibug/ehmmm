import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ── COLOR SCHEME ──────────────────────────────────────────────────────────────
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
}

class ChatPage extends StatefulWidget {
  final String username;
  const ChatPage({super.key, required this.username});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final String baseUrl = 'http://104.207.64.203:2001';

  final TextEditingController _msgController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addContactController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _chatUsers = [];
  String? _selectedUser;
  List<Map<String, dynamic>> _messages = [];
  Timer? _refreshTimer;
  bool _isSending = false;
  bool _isSearching = false;
  bool _isTyping = false;
  List<Map<String, dynamic>> _searchResults = [];

  // Add contact state
  bool _isCheckingUser = false;
  bool? _userValid;
  String _checkedUsername = '';

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _msgController.addListener(() {
      final typing = _msgController.text.isNotEmpty;
      if (typing != _isTyping) setState(() => _isTyping = typing);
    });

    _addContactController.addListener(() {
      // Reset valid state tiap kali user ngetik ulang
      if (_addContactController.text != _checkedUsername) {
        setState(() {
          _userValid = null;
          _checkedUsername = '';
        });
      }
    });

    _loadChatUsers();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_selectedUser != null) {
        _fetchMessages(_selectedUser!);
      } else {
        _loadChatUsers();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _msgController.dispose();
    _searchController.dispose();
    _addContactController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── API ───────────────────────────────────────────────────────────────────

  Future<void> _loadChatUsers() async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/get-private-chat-users?username=${widget.username}',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['users'] != null && mounted) {
          setState(() {
            _chatUsers = List<Map<String, dynamic>>.from(
              (data['users'] as List).map((e) => Map<String, dynamic>.from(e)),
            );
          });
        }
      }
    } catch (e) {
      debugPrint('[PrivateChat] Error loadUsers: $e');
    }
  }

  Future<void> _fetchMessages(String otherUser) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/get-private-chat?user1=${widget.username}&user2=$otherUser',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['messages'] != null) {
          final newMsgs = List<Map<String, dynamic>>.from(
            (data['messages'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
          final shouldScroll = newMsgs.length > _messages.length;
          if (mounted) {
            setState(() => _messages = newMsgs);
            if (shouldScroll) _scrollToBottom();
          }
        }
      }
    } catch (e) {
      debugPrint('[PrivateChat] Error fetchMessages: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _selectedUser == null) return;

    _msgController.clear();
    setState(() => _isSending = true);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/send-private-chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'from': widget.username,
          'to': _selectedUser,
          'message': text,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          await _fetchMessages(_selectedUser!);
          _scrollToBottom();
        } else {
          _showSnackBar(data['message'] ?? 'Gagal mengirim', isError: true);
        }
      }
    } catch (_) {
      _showSnackBar('Gagal mengirim pesan', isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteChat(String otherUser) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/delete-private-chat?user1=${widget.username}&user2=$otherUser',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          _showSnackBar('Chat dihapus');
          _loadChatUsers();
          if (_selectedUser == otherUser) {
            setState(() {
              _selectedUser = null;
              _messages.clear();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[PrivateChat] Error deleteChat: $e');
    }
  }

  Future<void> _searchUser(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/get-private-chat-users?username=$query'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['users'] != null) {
          final results = <Map<String, dynamic>>[];
          for (var u in data['users']) {
            final name = u['username'].toString().toLowerCase();
            if (name.contains(query.toLowerCase()) &&
                name != widget.username.toLowerCase()) {
              results.add(Map<String, dynamic>.from(u));
            }
          }
          if (results.isEmpty &&
              query.trim().toLowerCase() != widget.username.toLowerCase()) {
            results.add({
              'username': query.trim(),
              'lastMessage': '',
              'lastTime': '',
              'totalMessages': 0,
              'isNewUser': true,
            });
          }
          setState(() => _searchResults = results);
        }
      }
    } catch (_) {
      if (query.trim().toLowerCase() != widget.username.toLowerCase()) {
        setState(() {
          _searchResults = [
            {
              'username': query.trim(),
              'lastMessage': '',
              'lastTime': '',
              'totalMessages': 0,
              'isNewUser': true,
            },
          ];
        });
      }
    }
  }

  // Validasi username ke server sebelum tambah kontak
  Future<void> _checkUsername(String username) async {
    if (username.trim().isEmpty) return;
    if (username.trim().toLowerCase() == widget.username.toLowerCase()) {
      _showSnackBar('Tidak bisa tambah diri sendiri', isError: true);
      return;
    }

    setState(() => _isCheckingUser = true);

    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/get-private-chat-users?username=${username.trim()}',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Anggap valid kalau server respond 200 dan success true
        setState(() {
          _userValid = data['success'] == true;
          _checkedUsername = username.trim();
        });
      } else {
        setState(() {
          _userValid = false;
          _checkedUsername = username.trim();
        });
      }
    } catch (_) {
      setState(() {
        _userValid = false;
        _checkedUsername = username.trim();
      });
    } finally {
      if (mounted) setState(() => _isCheckingUser = false);
    }
  }

  void _startChatWith(String otherUser) {
    setState(() {
      _selectedUser = otherUser;
      _messages.clear();
      _isSearching = false;
      _searchController.clear();
      _searchResults = [];
    });
    _fetchMessages(otherUser);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError
            ? _C.danger.withOpacity(0.9)
            : _C.accent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── MODAL TAMBAH KONTAK ───────────────────────────────────────────────────

  void _showAddContactModal() {
    _addContactController.clear();
    setState(() {
      _userValid = null;
      _checkedUsername = '';
      _isCheckingUser = false;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: _C.bg2,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(color: _C.border),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _C.muted2,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _C.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _C.border),
                        ),
                        child: const Icon(
                          FontAwesomeIcons.userPlus,
                          color: _C.accent,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TAMBAH KONTAK',
                            style: TextStyle(
                              fontFamily: 'MADEEvolveSansEVO',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _C.text,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Cari dan validasi username',
                            style: TextStyle(fontSize: 10, color: _C.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info box cara penggunaan
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _C.border2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info_outline, color: _C.gold, size: 13),
                            SizedBox(width: 6),
                            Text(
                              'CARA MENAMBAH KONTAK',
                              style: TextStyle(
                                fontFamily: 'MADEEvolveSansEVO',
                                fontSize: 9,
                                color: _C.gold,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _infoStep('1', 'Ketik username yang ingin ditambahkan'),
                        const SizedBox(height: 6),
                        _infoStep(
                          '2',
                          'Tekan tombol CEK untuk memvalidasi username',
                        ),
                        const SizedBox(height: 6),
                        _infoStep('3', 'Jika valid ✓, tekan MULAI CHAT'),
                        const SizedBox(height: 6),
                        _infoStep('4', 'Username harus terdaftar di sistem'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input username
                  Container(
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _userValid == true
                            ? Colors.green.withOpacity(0.5)
                            : _userValid == false
                            ? _C.danger.withOpacity(0.5)
                            : _C.border2,
                      ),
                      boxShadow: _userValid == true
                          ? [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ]
                          : _userValid == false
                          ? [
                              BoxShadow(
                                color: _C.danger.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(
                          FontAwesomeIcons.at,
                          color: _C.muted,
                          size: 14,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _addContactController,
                            style: const TextStyle(
                              color: _C.text,
                              fontSize: 13,
                            ),
                            cursorColor: _C.accent,
                            onChanged: (_) => setModalState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Masukkan username...',
                              hintStyle: TextStyle(
                                color: _C.muted2,
                                fontSize: 12,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        // Status icon
                        if (_isCheckingUser)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _C.accent,
                              ),
                            ),
                          )
                        else if (_userValid == true)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            ),
                          )
                        else if (_userValid == false)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.cancel,
                              color: _C.danger,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Feedback text
                  if (_userValid == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 11,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '@$_checkedUsername ditemukan, siap di-chat!',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_userValid == false)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.cancel, color: _C.danger, size: 11),
                          const SizedBox(width: 5),
                          Text(
                            '@$_checkedUsername tidak ditemukan di sistem',
                            style: const TextStyle(
                              color: _C.danger,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    children: [
                      // Cek button
                      Expanded(
                        child: GestureDetector(
                          onTap: _isCheckingUser
                              ? null
                              : () async {
                                  await _checkUsername(
                                    _addContactController.text,
                                  );
                                  setModalState(() {});
                                },
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: _C.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _C.border),
                            ),
                            child: Center(
                              child: _isCheckingUser
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _C.accent,
                                      ),
                                    )
                                  : const Text(
                                      'CEK',
                                      style: TextStyle(
                                        fontFamily: 'MADEEvolveSansEVO',
                                        fontSize: 11,
                                        color: _C.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Mulai chat button
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _userValid == true
                              ? () {
                                  Navigator.of(ctx).pop();
                                  _startChatWith(_checkedUsername);
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: _userValid == true
                                  ? const LinearGradient(
                                      colors: [_C.accent, _C.accent2],
                                    )
                                  : null,
                              color: _userValid == true ? null : _C.muted2,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _userValid == true
                                  ? [
                                      BoxShadow(
                                        color: _C.accent.withOpacity(0.3),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.paperPlane,
                                    size: 12,
                                    color: _userValid == true
                                        ? Colors.white
                                        : _C.muted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'MULAI CHAT',
                                    style: TextStyle(
                                      fontFamily: 'MADEEvolveSansEVO',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _userValid == true
                                          ? Colors.white
                                          : _C.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: _C.accent.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: _C.accent,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _C.muted, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _selectedUser == null
                  ? _buildUserList()
                  : _buildChatScreen(),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xEB0C0D15),
            border: Border(bottom: BorderSide(color: _C.border)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (_selectedUser != null) {
                    setState(() {
                      _selectedUser = null;
                      _messages.clear();
                    });
                    _loadChatUsers();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.border2),
                  ),
                  child: const Icon(Icons.arrow_back, color: _C.text, size: 16),
                ),
              ),
              const SizedBox(width: 10),

              // Live dot
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(
                          0.3 + _pulseController.value * 0.4,
                        ),
                        blurRadius: 5 + _pulseController.value * 5,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedUser != null
                          ? '@$_selectedUser'
                          : 'PRIVATE CHAT',
                      style: const TextStyle(
                        color: _C.text,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'MADEEvolveSansEVO',
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _selectedUser != null
                          ? '${_messages.length} pesan'
                          : '${_chatUsers.length} kontak',
                      style: const TextStyle(
                        color: _C.muted,
                        fontSize: 10,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ],
                ),
              ),

              // Tombol tambah kontak (hanya di user list)
              if (_selectedUser == null)
                GestureDetector(
                  onTap: _showAddContactModal,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _C.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.border),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1,
                      color: _C.accent,
                      size: 16,
                    ),
                  ),
                ),

              // Tombol delete (hanya di chat screen)
              if (_selectedUser != null) ...[
                GestureDetector(
                  onTap: () => _deleteChat(_selectedUser!),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _C.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.danger.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: _C.danger,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── USER LIST ─────────────────────────────────────────────────────────────

  Widget _buildUserList() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Container(
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.search, color: _C.muted2, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                      color: _C.text,
                      fontFamily: 'ShareTechMono',
                      fontSize: 13,
                    ),
                    cursorColor: _C.accent,
                    onChanged: (val) {
                      setState(() => _isSearching = val.isNotEmpty);
                      _searchUser(val);
                    },
                    decoration: const InputDecoration(
                      hintText: 'Cari username...',
                      hintStyle: TextStyle(color: _C.muted2, fontSize: 12),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_isSearching)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _isSearching = false;
                        _searchResults = [];
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.close, color: _C.muted, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Search results
        if (_isSearching && _searchResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                final isNew = user['isNewUser'] == true;
                return _buildUserTile(
                  user['username'],
                  isNew ? 'Mulai chat baru' : user['lastMessage'] ?? '',
                  isNew ? '' : user['lastTime'] ?? '',
                  isNew: isNew,
                );
              },
            ),
          )
        else if (_isSearching && _searchResults.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, color: _C.muted2, size: 36),
                  const SizedBox(height: 12),
                  const Text(
                    'User tidak ditemukan',
                    style: TextStyle(color: _C.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _showAddContactModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _C.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _C.accent.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_alt_1,
                            color: _C.accent,
                            size: 13,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Tambah Kontak',
                            style: TextStyle(
                              color: _C.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _chatUsers.isEmpty
              ? Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: _C.accent.withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _C.accent.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.lock_outline,
                            color: _C.accent.withOpacity(0.4),
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada chat private',
                          style: TextStyle(
                            color: _C.muted,
                            fontFamily: 'ShareTechMono',
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tekan + di atas untuk tambah kontak',
                          style: TextStyle(
                            color: _C.muted2,
                            fontFamily: 'ShareTechMono',
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _showAddContactModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_C.accent, _C.accent2],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.accent.withOpacity(0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_add_alt_1,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'TAMBAH KONTAK',
                                  style: TextStyle(
                                    fontFamily: 'MADEEvolveSansEVO',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    itemCount: _chatUsers.length,
                    itemBuilder: (context, index) {
                      final user = _chatUsers[index];
                      return _buildUserTile(
                        user['username'],
                        user['lastMessage'] ?? '',
                        user['lastTime'] ?? '',
                        totalMsgs: user['totalMessages'] ?? 0,
                      );
                    },
                  ),
                ),
      ],
    );
  }

  Widget _buildUserTile(
    String username,
    String preview,
    String time, {
    bool isNew = false,
    int totalMsgs = 0,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _startChatWith(username),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_C.accent, _C.accent2],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '@$username',
                            style: const TextStyle(
                              color: _C.text,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (isNew) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'MADEEvolveSansEVO',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        preview.isEmpty ? 'Belum ada pesan' : preview,
                        style: const TextStyle(color: _C.muted, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (time.isNotEmpty)
                      Text(
                        time,
                        style: const TextStyle(
                          color: _C.muted2,
                          fontSize: 10,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                    if (totalMsgs > 0 && !isNew)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _C.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$totalMsgs',
                          style: const TextStyle(
                            color: _C.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── CHAT SCREEN ───────────────────────────────────────────────────────────

  Widget _buildChatScreen() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, color: _C.muted2, size: 40),
                      const SizedBox(height: 14),
                      Text(
                        'Chat private dengan @$_selectedUser',
                        style: const TextStyle(
                          color: _C.muted,
                          fontFamily: 'ShareTechMono',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pesan terenkripsi end-to-end',
                        style: TextStyle(
                          color: _C.muted2,
                          fontFamily: 'ShareTechMono',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg['from'] == widget.username;
                    final prev = index > 0 ? _messages[index - 1] : null;
                    final isFirst = prev == null || prev['from'] != msg['from'];
                    return _buildChatBubble(msg, isMe, isFirst);
                  },
                ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, bool isMe, bool isFirst) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4, top: isFirst ? 10 : 2),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe && isFirst)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    '@${msg['from']}',
                    style: const TextStyle(
                      color: _C.accent3,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(colors: [_C.accent, _C.accent2])
                      : null,
                  color: isMe ? null : _C.card,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 5),
                    bottomRight: Radius.circular(isMe ? 5 : 18),
                  ),
                  border: isMe ? null : Border.all(color: _C.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg['message'] ?? '',
                      style: TextStyle(
                        color: isMe ? Colors.white : _C.text,
                        fontSize: 13,
                        fontFamily: 'ShareTechMono',
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        msg['time'] ?? '',
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withOpacity(0.6)
                              : _C.muted2,
                          fontSize: 9,
                          fontFamily: 'ShareTechMono',
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

  // ── INPUT AREA ────────────────────────────────────────────────────────────

  Widget _buildInputArea() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0xE60C0D15),
            border: Border(top: BorderSide(color: _C.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isTyping
                            ? _C.accent.withOpacity(0.4)
                            : _C.border,
                      ),
                      boxShadow: _isTyping
                          ? [
                              BoxShadow(
                                color: _C.accent.withOpacity(0.08),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: const TextStyle(
                        color: _C.text,
                        fontFamily: 'ShareTechMono',
                        fontSize: 13,
                      ),
                      cursorColor: _C.accent,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Ketik pesan...',
                        hintStyle: TextStyle(color: _C.muted2, fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: _isTyping && !_isSending
                          ? const LinearGradient(
                              colors: [_C.accent, _C.accent2],
                            )
                          : null,
                      color: _isTyping && !_isSending ? null : _C.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isTyping ? _C.accent : _C.border2,
                      ),
                      boxShadow: _isTyping && !_isSending
                          ? [
                              BoxShadow(
                                color: _C.accent.withOpacity(0.3),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      _isSending
                          ? Icons.hourglass_top
                          : FontAwesomeIcons.paperPlane,
                      color: _isTyping ? Colors.white : _C.muted,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

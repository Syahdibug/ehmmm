// chat_ai_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ── COLOR SCHEME (same as dashboard) ──────────────────────────────────────
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

class ChatAIPage extends StatefulWidget {
  final String sessionKey;

  const ChatAIPage({super.key, required this.sessionKey});

  @override
  State<ChatAIPage> createState() => _ChatAIPageState();
}

class _ChatAIPageState extends State<ChatAIPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _currentSessionId;
  List<ChatSession> _chatSessions = [];
  bool _showSessionList = false;

  // Animation Controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadChatSessions();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseController.repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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

  // ── Session Management ──────────────────────────────────────────────────

  Future<void> _loadChatSessions() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://104.207.64.203:2001/api/tools/chat/list?key=${widget.sessionKey}',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _chatSessions = (data['chatHistoryList'] as List)
                .map((session) => ChatSession.fromJson(session))
                .toList();
          });
        }
      }
    } catch (e) {
      _showSnackBar('Gagal memuat sesi chat', isError: true);
    }
  }

  Future<void> _createNewSession() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://104.207.64.203:2001/api/tools/chat/new-session?key=${widget.sessionKey}',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _currentSessionId = data['sessionId'];
            _messages.clear();
            _showSessionList = false;
          });
          _loadChatSessions();
          _showSnackBar('Sesi baru berhasil dibuat');
        }
      }
    } catch (e) {
      _showSnackBar('Gagal membuat sesi baru', isError: true);
    }
  }

  Future<void> _loadChatSession(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://104.207.64.203:2001/api/tools/chat/history?key=${widget.sessionKey}&session=$sessionId',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _currentSessionId = sessionId;
            _messages.clear();
            final chatHistory = data['chatHistory'] as List;
            for (var message in chatHistory) {
              _messages.add(
                ChatMessage(
                  text: message['message'],
                  isAI: message['isAI'] == true,
                  timestamp: DateTime.parse(message['timestamp']),
                ),
              );
            }
            _showSessionList = false;
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      _showSnackBar('Gagal memuat sesi chat', isError: true);
    }
  }

  Future<void> _deleteChatSession(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://104.207.64.203:2001/api/tools/chat/delete?key=${widget.sessionKey}&session=$sessionId',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          _showSnackBar('Sesi chat dihapus');
          _loadChatSessions();
          if (_currentSessionId == sessionId) {
            setState(() {
              _currentSessionId = null;
              _messages.clear();
            });
          }
        }
      }
    } catch (e) {
      _showSnackBar('Gagal menghapus sesi', isError: true);
    }
  }

  // ── Send Message ────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentSessionId == null) {
      if (_currentSessionId == null) {
        _showSnackBar('Buat sesi baru terlebih dahulu', isError: true);
      }
      return;
    }

    final userMessage = text;

    // Tambah pesan user ke UI SEBELUM API call
    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isAI: false, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final uri = Uri.parse(
        'http://104.207.64.203:2001/api/tools/chat/send?key=${widget.sessionKey}&session=$_currentSessionId&message=${Uri.encodeComponent(userMessage)}',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle berbagai format response dari server
        String? aiMessage;

        if (data['status'] == true) {
          // Format lama: { status: true, data: { message: "..." } }
          aiMessage = data['data']?['message'];
        }

        // Jika format lama gagal, coba format lain
        if (aiMessage == null || aiMessage.isEmpty) {
          // Format alternatif: { status: true, data: { response: "..." } }
          aiMessage = data['data']?['response'];
        }
        if (aiMessage == null || aiMessage.isEmpty) {
          // Format lain: { result: "..." }
          aiMessage = data['result'];
        }
        if (aiMessage == null || aiMessage.isEmpty) {
          // Format lain: { data: "..." }
          if (data['data'] is String) {
            aiMessage = data['data'];
          }
        }

        if (aiMessage != null && aiMessage.isNotEmpty) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: aiMessage!,
                isAI: true,
                timestamp: DateTime.now(),
              ),
            );
          });
          _scrollToBottom();
        } else {
          _showSnackBar('Tidak ada respons dari AI', isError: true);
        }
      } else {
        _showSnackBar(
          'Gagal terhubung ke server (${response.statusCode})',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'ShareTechMono',
          ),
        ),
        backgroundColor: isError
            ? _C.danger.withOpacity(0.9)
            : _C.accent.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build: Header ───────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xEB0c0d15),
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 62,
            padding: const EdgeInsets.only(left: 14, right: 14),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.border2),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: _C.text,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Title area
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _C.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _C.accent.withOpacity(0.25),
                          ),
                        ),
                        child: const Icon(
                          FontAwesomeIcons.robot,
                          color: _C.accent,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "AI ASSISTANT",
                              style: TextStyle(
                                color: _C.text,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: "MADEEvolveSansEVO",
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentSessionId != null
                                        ? Colors.green
                                        : _C.muted2,
                                    shape: BoxShape.circle,
                                    boxShadow: _currentSessionId != null
                                        ? [
                                            BoxShadow(
                                              color: Colors.green,
                                              blurRadius: 4,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _currentSessionId != null
                                      ? "Session Active"
                                      : "No Active Session",
                                  style: TextStyle(
                                    color: _currentSessionId != null
                                        ? Colors.green
                                        : _C.muted,
                                    fontSize: 10,
                                    fontFamily: "ShareTechMono",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // History toggle
                GestureDetector(
                  onTap: () =>
                      setState(() => _showSessionList = !_showSessionList),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _showSessionList
                          ? _C.accent.withOpacity(0.15)
                          : _C.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _showSessionList ? _C.accent : _C.border2,
                      ),
                    ),
                    child: Icon(
                      _showSessionList ? Icons.chat : Icons.history,
                      color: _showSessionList ? _C.accent : _C.muted,
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // New session
                GestureDetector(
                  onTap: _createNewSession,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _C.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _C.border2),
                    ),
                    child: const Icon(Icons.add, color: _C.accent, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build: Session List ────────────────────────────────────────────────

  Widget _buildSessionList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _C.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _C.accent.withOpacity(0.25)),
                ),
                child: const Icon(Icons.history, color: _C.accent, size: 13),
              ),
              const SizedBox(width: 10),
              const Text(
                "CHAT HISTORY",
                style: TextStyle(
                  color: _C.text,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: "MADEEvolveSansEVO",
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _createNewSession,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _C.border2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: _C.accent, size: 13),
                      const SizedBox(width: 4),
                      const Text(
                        "NEW",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _C.accent,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _chatSessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FontAwesomeIcons.comments,
                        color: _C.muted2,
                        size: 42,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Belum ada sesi chat",
                        style: TextStyle(
                          color: _C.muted,
                          fontFamily: 'ShareTechMono',
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _createNewSession,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _C.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _C.accent.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, color: _C.accent, size: 14),
                              const SizedBox(width: 6),
                              const Text(
                                "Buat Sesi Baru",
                                style: TextStyle(
                                  color: _C.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _chatSessions.length,
                  itemBuilder: (context, index) {
                    final session = _chatSessions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: _C.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _C.border),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _loadChatSession(session.sessionId),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _C.accent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble,
                                    color: _C.accent,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.sessionId.length > 28
                                            ? '${session.sessionId.substring(0, 28)}...'
                                            : session.sessionId,
                                        style: const TextStyle(
                                          color: _C.text,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'ShareTechMono',
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${session.messageCount} pesan',
                                        style: TextStyle(
                                          color: _C.muted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _deleteChatSession(session.sessionId),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: _C.danger.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: _C.danger,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Build: Chat Interface ──────────────────────────────────────────────

  Widget _buildChatInterface() {
    return Column(
      children: [
        Expanded(
          child: _currentSessionId == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _C.accent.withOpacity(
                                  0.2 * _pulseAnimation.value,
                                ),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              FontAwesomeIcons.robot,
                              size: 44,
                              color: _C.accent.withOpacity(
                                0.3 + 0.3 * _pulseAnimation.value,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Mulai percakapan baru',
                        style: TextStyle(
                          color: _C.accent.withOpacity(0.7),
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 15,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tekan tombol + untuk membuat sesi',
                        style: TextStyle(
                          color: _C.muted,
                          fontFamily: 'ShareTechMono',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                )
              : _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.forum_outlined, color: _C.muted2, size: 42),
                      const SizedBox(height: 16),
                      Text(
                        'Sesi kosong',
                        style: TextStyle(
                          color: _C.muted,
                          fontFamily: 'ShareTechMono',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kirim pesan untuk memulai',
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
                  padding: const EdgeInsets.all(14),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageBubble(_messages[index]),
                ),
        ),
        // Loading indicator
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _C.accent.withOpacity(0.8),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'AI sedang berpikir...',
                  style: TextStyle(
                    color: _C.muted,
                    fontFamily: 'ShareTechMono',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        _buildMessageInput(),
      ],
    );
  }

  // ── Build: Message Bubble ───────────────────────────────────────────────

  Widget _buildMessageBubble(ChatMessage message) {
    final isAI = message.isAI;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isAI
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _C.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.accent.withOpacity(0.25)),
              ),
              child: const Icon(
                FontAwesomeIcons.robot,
                color: _C.accent,
                size: 13,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: !isAI
                    ? LinearGradient(colors: [_C.accent, _C.accent2])
                    : null,
                color: isAI ? _C.card : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isAI
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                  bottomRight: isAI
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                ),
                border: isAI ? Border.all(color: _C.border, width: 1) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: !isAI ? Colors.white : _C.text,
                      fontWeight: !isAI ? FontWeight.w600 : FontWeight.normal,
                      fontFamily: 'ShareTechMono',
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: !isAI ? Colors.white.withOpacity(0.6) : _C.muted2,
                      fontSize: 9,
                      fontFamily: 'ShareTechMono',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isAI) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _C.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _C.accent.withOpacity(0.25)),
              ),
              child: const Icon(
                FontAwesomeIcons.user,
                color: _C.accent,
                size: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ── Build: Message Input ────────────────────────────────────────────────

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: _C.bg2,
        border: Border(top: BorderSide(color: _C.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _C.border),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(
                    color: _C.text,
                    fontFamily: 'ShareTechMono',
                    fontSize: 13,
                  ),
                  cursorColor: _C.accent,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: TextStyle(color: _C.muted2, fontSize: 12),
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_C.accent, _C.accent2]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: _C.accent.withOpacity(0.3), blurRadius: 8),
                  ],
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Subtle background pattern
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_C.bg, _C.bg2, _C.bg],
              ),
            ),
          ),
          SafeArea(
            top: true,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _showSessionList
                      ? _buildSessionList()
                      : _buildChatInterface(),
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
    _pulseController.dispose();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

// ── Data Models ──────────────────────────────────────────────────────────

class ChatMessage {
  final String text;
  final bool isAI;
  final DateTime timestamp;
  ChatMessage({
    required this.text,
    required this.isAI,
    required this.timestamp,
  });
}

class ChatSession {
  final String sessionId;
  final String username;
  final DateTime lastModified;
  final int messageCount;
  final String preview;

  ChatSession({
    required this.sessionId,
    required this.username,
    required this.lastModified,
    required this.messageCount,
    required this.preview,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['sessionId'],
      username: json['username'],
      lastModified: DateTime.parse(json['lastModified']),
      messageCount: json['messageCount'],
      preview: json['preview'],
    );
  }
}

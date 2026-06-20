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
  static const text = Color(0xFFE2EAE5);
  static const muted = Color(0x73E2EAE5);
  static const muted2 = Color(0x38E2EAE5);
  static const border = Color(0x1AE8184A);
  static const border2 = Color(0x0FFFFFFF);
  static const aiColor = Color(0xFF6C63FF);
}

class PublicChatPage extends StatefulWidget {
  final String username;
  final String sessionKey;

  const PublicChatPage({
    super.key,
    required this.username,
    required this.sessionKey,
  });

  @override
  State<PublicChatPage> createState() => _PublicChatPageState();
}

class _PublicChatPageState extends State<PublicChatPage>
    with TickerProviderStateMixin {
  final String baseUrl = "http://104.207.64.203:2001";

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<dynamic> _messages = [];
  Timer? _refreshTimer;
  bool _isSending = false;
  bool _isTyping = false;
  bool _aiThinking = false;
  String? _aiSessionId;

  late AnimationController _pulseController;

  static const String _aiBotName = '「AI」';

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

    _fetchMessages();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _fetchMessages(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── API ───────────────────────────────────────────────────────────────────

  Future<void> _fetchMessages() async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/get-public-chat'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final newMsgs = data['messages'] as List;
          final shouldScroll = newMsgs.length > _messages.length;
          if (mounted) {
            setState(() => _messages = newMsgs);
            if (shouldScroll) _scrollToBottom();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    _msgController.clear();
    setState(() => _isSending = true);

    try {
      await http.post(
        Uri.parse('$baseUrl/send-public-chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': widget.username, 'message': text}),
      );
      await _fetchMessages();
      _scrollToBottom();

      if (text.toLowerCase().contains('@ai')) {
        _triggerAiReply(text, widget.username);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Gagal mengirim pesan',
              style: TextStyle(color: _C.text),
            ),
            backgroundColor: _C.card,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── AI Integration ────────────────────────────────────────────────────────

  Future<void> _ensureAiSession() async {
    if (_aiSessionId != null) return;
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/api/tools/chat/new-session?key=${widget.sessionKey}',
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          _aiSessionId = data['sessionId'];
        } else {
          debugPrint('[AI] Gagal buat sesi: ${res.body}');
        }
      }
    } catch (e) {
      debugPrint('[AI] Error ensureAiSession: $e');
    }
  }

  Future<void> _triggerAiReply(String userMessage, String senderName) async {
    await _ensureAiSession();
    if (_aiSessionId == null) {
      debugPrint('[AI] Session null, batalkan');
      if (mounted) setState(() => _aiThinking = false);
      return;
    }

    final question = userMessage
        .replaceAll(RegExp(r'@ai\s*', caseSensitive: false), '')
        .trim();
    if (question.isEmpty) {
      if (mounted) setState(() => _aiThinking = false);
      return;
    }

    if (mounted) setState(() => _aiThinking = true);

    try {
      final prompt = '$senderName bertanya: $question';
      final uri = Uri.parse(
        '$baseUrl/api/tools/chat/send'
        '?key=${widget.sessionKey}'
        '&session=$_aiSessionId'
        '&message=${Uri.encodeComponent(prompt)}',
      );

      debugPrint('[AI] Kirim ke: $uri');

      final res = await http.get(uri).timeout(const Duration(seconds: 30));

      debugPrint('[AI] Response ${res.statusCode}: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        String? aiReply =
            data['data']?['message'] ??
            data['data']?['response'] ??
            data['result'] ??
            (data['data'] is String ? data['data'] : null);

        debugPrint('[AI] Reply parsed: $aiReply');

        if (aiReply != null && aiReply.isNotEmpty) {
          await http.post(
            Uri.parse('$baseUrl/send-public-chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': _aiBotName,
              'message': '@$senderName $aiReply',
            }),
          );
          await _fetchMessages();
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('[AI] Error: $e');
    } finally {
      if (mounted) setState(() => _aiThinking = false);
    }
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

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessageList()),
            if (_aiThinking) _buildAiTypingIndicator(),
            _buildInputArea(),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xEB0C0D15),
            border: Border(bottom: BorderSide(color: _C.border)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _C.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _C.border2),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: _C.muted,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _C.accent,
                    boxShadow: [
                      BoxShadow(
                        color: _C.accent.withOpacity(
                          0.3 + _pulseController.value * 0.4,
                        ),
                        blurRadius: 6 + _pulseController.value * 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PUBLIC LOUNGE',
                      style: TextStyle(
                        fontFamily: 'MADEEvolveSansEVO',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _C.text,
                        shadows: [Shadow(color: _C.accent, blurRadius: 6)],
                      ),
                    ),
                    Text(
                      'LIVE · ${_messages.length} messages',
                      style: const TextStyle(
                        fontSize: 10,
                        color: _C.muted,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _C.aiColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _C.aiColor.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(FontAwesomeIcons.robot, color: _C.aiColor, size: 10),
                    SizedBox(width: 5),
                    Text(
                      '@AI',
                      style: TextStyle(
                        fontFamily: 'MADEEvolveSansEVO',
                        fontSize: 8,
                        color: _C.aiColor,
                        fontWeight: FontWeight.bold,
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

  // ── MESSAGE LIST ──────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FontAwesomeIcons.commentSlash, color: _C.muted2, size: 36),
            const SizedBox(height: 14),
            const Text(
              'No messages yet',
              style: TextStyle(color: _C.muted, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ketik @ai untuk mengajak AI ngobrol!',
              style: TextStyle(color: _C.muted2, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = msg['username'] == widget.username;
        final prevMsg = index > 0 ? _messages[index - 1] : null;
        final isFirst =
            prevMsg == null || prevMsg['username'] != msg['username'];
        return _buildBubble(msg, isMe, isFirst);
      },
    );
  }

  Widget _buildBubble(dynamic msg, bool isMe, bool isFirst) {
    final isAiBot = msg['username'] == _aiBotName;

    return Padding(
      padding: EdgeInsets.only(bottom: 4, top: isFirst ? 10 : 2),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (isFirst)
              _buildAvatar(msg['username'])
            else
              const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe && isFirst)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAiBot)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(
                              FontAwesomeIcons.robot,
                              color: _C.aiColor,
                              size: 10,
                            ),
                          ),
                        Text(
                          msg['username'] ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: isAiBot ? _C.aiColor : _C.accent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (isAiBot)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _C.aiColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BOT',
                              style: TextStyle(
                                fontSize: 8,
                                color: _C.aiColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? _C.accent.withOpacity(0.15)
                        : isAiBot
                        ? _C.aiColor.withOpacity(0.08)
                        : _C.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isMe
                          ? _C.accent.withOpacity(0.3)
                          : isAiBot
                          ? _C.aiColor.withOpacity(0.25)
                          : _C.border2,
                    ),
                    boxShadow: isAiBot
                        ? [
                            BoxShadow(
                              color: _C.aiColor.withOpacity(0.06),
                              blurRadius: 8,
                            ),
                          ]
                        : isMe
                        ? [
                            BoxShadow(
                              color: _C.accent.withOpacity(0.08),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['message'] ?? '',
                        style: const TextStyle(
                          color: _C.text,
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          msg['time'] ?? '',
                          style: const TextStyle(
                            color: _C.muted,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildAvatar(String username) {
    final isAiBot = username == _aiBotName;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isAiBot
            ? _C.aiColor.withOpacity(0.15)
            : _C.accent.withOpacity(0.15),
        border: Border.all(
          color: isAiBot
              ? _C.aiColor.withOpacity(0.4)
              : _C.accent.withOpacity(0.3),
        ),
      ),
      child: Center(
        child: isAiBot
            ? const Icon(FontAwesomeIcons.robot, size: 14, color: _C.aiColor)
            : Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _C.accent,
                ),
              ),
      ),
    );
  }

  // ── AI TYPING INDICATOR ───────────────────────────────────────────────────

  Widget _buildAiTypingIndicator() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 6, 14, 6),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _C.aiColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(FontAwesomeIcons.robot, size: 11, color: _C.aiColor),
          const SizedBox(width: 6),
          const Text(
            '$_aiBotName sedang mengetik...',
            style: TextStyle(
              fontSize: 11,
              color: _C.aiColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── INPUT AREA ────────────────────────────────────────────────────────────

  Widget _buildInputArea() {
    final mentionsAi = _msgController.text.toLowerCase().contains('@ai');

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: const Color(0xE60C0D15),
            border: Border(top: BorderSide(color: _C.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isTyping && mentionsAi)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4),
                  child: Row(
                    children: const [
                      Icon(FontAwesomeIcons.robot, size: 10, color: _C.aiColor),
                      SizedBox(width: 6),
                      Text(
                        'AI akan membalas di chat publik',
                        style: TextStyle(
                          fontSize: 10,
                          color: _C.aiColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _isTyping && mentionsAi
                              ? _C.aiColor.withOpacity(0.5)
                              : _isTyping
                              ? _C.accent.withOpacity(0.4)
                              : _C.border2,
                        ),
                        boxShadow: _isTyping && mentionsAi
                            ? [
                                BoxShadow(
                                  color: _C.aiColor.withOpacity(0.1),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: TextField(
                        controller: _msgController,
                        focusNode: _focusNode,
                        style: const TextStyle(color: _C.text, fontSize: 13.5),
                        cursorColor: _C.accent,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Pesan... (ketik @ai untuk tanya AI)',
                          hintStyle: TextStyle(color: _C.muted2, fontSize: 12),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  GestureDetector(
                    onTap: _isSending ? null : _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isTyping
                            ? (mentionsAi ? _C.aiColor : _C.accent)
                            : _C.surface,
                        border: Border.all(
                          color: _isTyping
                              ? (mentionsAi ? _C.aiColor : _C.accent)
                              : _C.border2,
                        ),
                        boxShadow: _isTyping
                            ? [
                                BoxShadow(
                                  color: (mentionsAi ? _C.aiColor : _C.accent)
                                      .withOpacity(0.35),
                                  blurRadius: 12,
                                ),
                              ]
                            : [],
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(11),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              FontAwesomeIcons.paperPlane,
                              size: 15,
                              color: _isTyping ? Colors.white : _C.muted,
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
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/homework_entry.dart';
import '../../services/gemini_service.dart';
import '../../theme/kukie_accent.dart';

class HomeworkAiAssistantPage extends StatefulWidget {
  const HomeworkAiAssistantPage({super.key, required this.homework});

  final HomeworkEntry homework;
  static const routeName = '/student/homework-ai-assistant';

  @override
  State<HomeworkAiAssistantPage> createState() => _HomeworkAiAssistantPageState();
}

class _HomeworkAiAssistantPageState extends State<HomeworkAiAssistantPage>
    with TickerProviderStateMixin {
  final _geminiService = GeminiService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  late final AnimationController _dotAnimCtrl;
  late final AnimationController _entryAnimCtrl;

  // System context automatically constructed from the homework
  String get _systemContext => '''
You are a helpful, encouraging school study assistant inside the School Guardian app.
A student is working on the following homework assignment and needs your help.

Subject: ${widget.homework.subject}
Assignment Title: ${widget.homework.title}
Assignment Instructions: ${widget.homework.description}
Due Date: ${widget.homework.dueDate.toLocal().toString().split(' ')[0]}

Help the student understand the topic, solve problems step by step, and explain concepts clearly.
Use simple language appropriate for school students.
Be encouraging and supportive. Never just give direct answers — guide the student to think.
Keep responses concise (2-4 paragraphs max) unless detailed explanation is needed.
''';

  @override
  void initState() {
    super.initState();
    _dotAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
    _entryAnimCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _entryAnimCtrl.forward();

    // Add a welcome message from the AI
    _messages.add(_ChatMessage(
      role: 'model',
      text: '👋 Hi! I\'m your AI study assistant for this assignment.\n\n'
          '📚 **${widget.homework.subject}** — *${widget.homework.title}*\n\n'
          'Ask me anything about this homework — I\'ll guide you step by step without '
          'just giving away the answers. What would you like help with?',
    ));
  }

  @override
  void dispose() {
    _dotAnimCtrl.dispose();
    _entryAnimCtrl.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: text));
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Build history (exclude welcome message for context economy)
    final history = _messages
        .skip(1) // skip AI welcome
        .where((m) => m.role != 'typing')
        .take(_messages.length - 2) // exclude last user message just added
        .map((m) => GeminiMessage(role: m.role, text: m.text))
        .toList();

    final reply = await _geminiService.ask(
      text,
      systemContext: _systemContext,
      history: history,
    );

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(role: 'model', text: reply));
      });
      _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Homework context pill
          _buildHomeworkContextPill(),
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _TypingBubble(animCtrl: _dotAnimCtrl);
                }
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Study Assistant',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Powered by Gemini 3.6 Flash',
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
              SizedBox(width: 4),
              Text('Free', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHomeworkContextPill() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: KukieAccent.violetTint,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.homework.subject,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: KukieAccent.violet,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.homework.title,
              style: GoogleFonts.inter(
                color: const Color(0xFFCBD5E1),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.info_outline_rounded, color: Color(0xFF475569), size: 16),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF475569), width: 1.5),
              ),
              child: TextField(
                controller: _textController,
                cursorColor: const Color(0xFF8B5CF6),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Ask me about your homework…',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isTyping
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chat Message Model ───────────────────────────────────────────────────────

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text});
  final String role;
  final String text;
}

// ─── Message Bubble Widget ────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: _isUser ? 48 : 0,
          right: _isUser ? 0 : 48,
        ),
        child: Column(
          crossAxisAlignment: _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!_isUser)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 12),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI Assistant',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF8B5CF6),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isUser ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(_isUser ? 16 : 4),
                  bottomRight: Radius.circular(_isUser ? 4 : 16),
                ),
                border: _isUser
                    ? null
                    : Border.all(color: const Color(0xFF334155)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                  color: _isUser ? Colors.white : const Color(0xFFE2E8F0),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Typing Indicator Bubble ──────────────────────────────────────────────────

class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.animCtrl});
  final AnimationController animCtrl;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6), size: 14),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: animCtrl,
              builder: (_, __) {
                return Row(
                  children: List.generate(3, (i) {
                    final delay = i / 3;
                    final value = (animCtrl.value - delay).clamp(0.0, 1.0);
                    final opacity = (value < 0.5) ? value * 2 : (1.0 - value) * 2;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: opacity.clamp(0.2, 1.0)),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              'Thinking…',
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

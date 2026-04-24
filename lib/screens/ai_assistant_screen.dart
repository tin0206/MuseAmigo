import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = <_ChatMessage>[
    _ChatMessage(
      text:
          'Hello! I\'m Ogima, your personal guide to the Independence Palace. I can help you discover artifacts, navigate the museum, answer questions, and guide you to interesting exhibits. How can I assist you today?',
      time: '09:15 AM',
      isUser: false,
    ),
  ];

  bool _isAiTyping = false;

  static const _quickAccessQuestions = <String>[
    'What artifacts are nearby?',
    'Where is the nearest toilet?',
    'Show me highlights for 30 minutes',
    'How do I get to Tank T-54?',
    'Which exhibits are on Floor 2?',
    'Any kid-friendly exhibits?',
    'Where can I take a coffee break?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitMessage([String? preset]) async {
    final text = (preset ?? _messageController.text).trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          time: _formatTime(DateTime.now()),
          isUser: true,
        ),
      );
      _isAiTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) {
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          text: _buildAiReply(text),
          time: _formatTime(DateTime.now()),
          isUser: false,
        ),
      );
      _isAiTyping = false;
    });
    _scrollToBottom();
  }

  String _buildAiReply(String question) {
    final q = question.toLowerCase();
    if (q.contains('toilet') || q.contains('restroom')) {
      return 'The nearest restroom is near Hall C on Floor 1. I can guide you there if you want.';
    }
    if (q.contains('tank') || q.contains('t-54')) {
      return 'Tank T-54 is in Hall C, Floor 1. Follow the map route and I can navigate step-by-step for you.';
    }
    if (q.contains('floor 2')) {
      return 'On Floor 2, popular stops include Photography Gallery, Peace Memorial, Diplomatic Room, and Rooftop Cafe.';
    }
    if (q.contains('coffee') || q.contains('cafe')) {
      return 'You can take a break at Cafe Nile on Floor 1 or Rooftop Cafe on Floor 2.';
    }
    return 'Great question. I can help you explore artifacts, find facilities, and navigate to any room in the museum.';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  static String _formatTime(DateTime now) {
    final hour = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.home);
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up_outlined,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/model.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Ogima',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'online',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Your AI companion',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                itemCount: _messages.length + (_isAiTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isAiTyping && index == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _TypingBubble(),
                      ),
                    );
                  }
                  final msg = _messages[index];
                  final isOpeningMessage = index == 0 && !(msg.isUser ?? true);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: (msg.isUser ?? true)
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: _MessageBubble(message: msg),
                        ),
                        if (isOpeningMessage) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StarterActionChip(
                                icon: Icons.location_on_outlined,
                                text: 'Show Nearby',
                                onTap: () => _submitMessage(
                                  'Show nearby artifacts and highlights.',
                                ),
                              ),
                              _StarterActionChip(
                                icon: Icons.near_me_outlined,
                                text: 'View Map',
                                onTap: () => _submitMessage(
                                  'Open map and guide me from my current location.',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: const Text(
                'Quick access buttons:',
                style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: _quickAccessQuestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final q = _quickAccessQuestions[index];
                  return _QuickQuestionChip(
                    text: q,
                    onTap: () => _submitMessage(q),
                  );
                },
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(
                children: [
                  _roundIcon(Icons.mic_none),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF1F4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onSubmitted: (_) => _submitMessage(),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: const InputDecoration(
                          hintText: 'Ask me anything...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _submitMessage,
                    child: _roundIcon(Icons.near_me_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _roundIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFE5E7EB),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Color(0xFF4B5563)),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.time, this.isUser});

  final String text;
  final String time;
  final bool? isUser;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser ?? true;
    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: isUser
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: TextStyle(
              fontSize: 14,
              color: isUser ? Colors.white : const Color(0xFF111827),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message.time,
            style: TextStyle(
              fontSize: 11,
              color: isUser
                  ? Colors.white.withValues(alpha: 0.85)
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Ogima is typing...',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _QuickQuestionChip extends StatelessWidget {
  const _QuickQuestionChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _StarterActionChip extends StatelessWidget {
  const _StarterActionChip({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF111827)),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

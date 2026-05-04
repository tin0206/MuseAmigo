import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/screens/museum_3d_map_screen.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/session.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _quickAccessScrollController = ScrollController();

  final List<_ChatMessage> _messages = <_ChatMessage>[];

  bool _isAiTyping = false;

  @override
  void initState() {
    super.initState();
    _seedGreetingForCurrentMuseum();
    AppSession.currentMuseumName.addListener(_onMuseumContextChanged);
  }

  @override
  void dispose() {
    AppSession.currentMuseumName.removeListener(_onMuseumContextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _quickAccessScrollController.dispose();
    super.dispose();
  }

  void _onMuseumContextChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      final museumName = AppSession.currentMuseumName.value;
      final updatedMessage = _ChatMessage(
        text: _buildGreetingMessage(museumName),
        time: _formatTime(DateTime.now()),
        isUser: false,
      );

      if (_messages.isEmpty) {
        _messages.add(updatedMessage);
      } else if (!(_messages.first.isUser ?? true)) {
        _messages[0] = updatedMessage;
      } else {
        _messages.insert(0, updatedMessage);
      }
    });
  }

  void _seedGreetingForCurrentMuseum() {
    _messages.add(
      _ChatMessage(
        text: _buildGreetingMessage(AppSession.currentMuseumName.value),
        time: _formatTime(DateTime.now()),
        isUser: false,
      ),
    );
  }

  static String _buildGreetingMessage(String museumName) {
    return 'Hello! I\'m Ogima, your personal guide to $museumName. '
        'I can help you discover artifacts, navigate the museum, '
        'answer questions, and guide you to interesting exhibits. '
        'How can I assist you today?';
  }

  static List<String> _quickAccessQuestionsForMuseum(String museumName) {
    return <String>[
      'What are the operating hours of $museumName?',
      'How much is the ticket at $museumName?',
      'What exhibitions are available at $museumName?',
      'What routes are available at $museumName?',
      'Tell me about artifact code IP-002.',
      'Where is $museumName located?',
    ];
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

    String reply;
    try {
      reply = await _resolveReplyForInput(text);
    } catch (_) {
      // Keep local fallback so chat still works when backend is unreachable.
      reply = _buildAiReply(text);
    }
    if (!mounted) {
      return;
    }

    setState(() {
      final contextActions = _buildContextActions(text);
      _messages.add(
        _ChatMessage(
          text: reply,
          time: _formatTime(DateTime.now()),
          isUser: false,
          actions: contextActions,
          sourceQuestion: text,
        ),
      );
      _isAiTyping = false;
    });
    _scrollToBottom();
  }

  List<_ChatAction> _buildContextActions(String text) {
    final normalized = _normalizeForIntent(text);
    final actions = <_ChatAction>[];

    if (_isMapIntentQuestion(normalized)) {
      actions.add(
        const _ChatAction(
          type: _ChatActionType.map,
          label: 'View Map',
          icon: Icons.near_me_outlined,
        ),
      );
    }

    if (_isTicketIntentQuestion(normalized)) {
      actions.add(
        const _ChatAction(
          type: _ChatActionType.tickets,
          label: 'View Tickets',
          icon: Icons.confirmation_number_outlined,
        ),
      );
    }

    if (_isArtifactIntentQuestion(normalized)) {
      actions.add(
        const _ChatAction(
          type: _ChatActionType.artifact,
          label: 'View Artifact',
          icon: Icons.account_balance_outlined,
        ),
      );
    }

    return actions;
  }

  Future<void> _onActionTap(
    _ChatAction action,
    _ChatMessage sourceMessage,
  ) async {
    switch (action.type) {
      case _ChatActionType.map:
        if (!mounted) return;
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const Museum3DMapScreen()));
        break;
      case _ChatActionType.tickets:
        if (!mounted) return;
        await Navigator.of(context).pushNamed(AppRoutes.myTickets);
        break;
      case _ChatActionType.artifact:
        await _openArtifactFromText(
          sourceMessage.sourceQuestion ?? sourceMessage.text,
        );
        break;
    }
  }

  Future<void> _openArtifactFromText(String text) async {
    final artifactCode = _extractArtifactCode(text);

    if (artifactCode == null) {
      if (!mounted) return;
      await Navigator.of(context).pushNamed(
        AppRoutes.search,
        arguments: {'query': text, 'showResults': true},
      );
      return;
    }

    try {
      final artifact = await BackendApi.instance.fetchArtifact(artifactCode);
      if (!mounted) return;
      await Navigator.of(context).pushNamed(
        AppRoutes.artifactDetail,
        arguments: {
          'title': artifact.title,
          'location': AppSession.currentMuseumName.value,
          'year': artifact.year,
          'currentLocation': AppSession.currentMuseumName.value,
          'audioAsset': artifact.audioAsset,
        },
      );
    } catch (_) {
      if (!mounted) return;
      await Navigator.of(context).pushNamed(
        AppRoutes.search,
        arguments: {'query': artifactCode, 'showResults': true},
      );
    }
  }

  Future<String> _resolveReplyForInput(String text) async {
    final normalized = _normalizeForIntent(text);
    final isVietnamese = _isLikelyVietnameseQuestion(text, normalized);
    final museum = await _resolveMuseum(text);

    final artifactCode = _extractArtifactCode(text);
    if (artifactCode != null) {
      final artifact = await BackendApi.instance.fetchArtifact(artifactCode);
      return 'Artifact: ${artifact.title} (${artifact.artifactCode}). '
          'Year: ${artifact.year}. ${artifact.description}';
    }

    if (_isExhibitionQuestion(normalized) && museum != null) {
      final exhibitions = await BackendApi.instance.fetchExhibitions(museum.id);
      if (exhibitions.isEmpty) {
        return isVietnamese
            ? 'Hiện chưa có triển lãm nào được liệt kê cho ${museum.name}.'
            : 'There are currently no exhibitions listed for ${museum.name}.';
      }
      final lines = exhibitions
          .map((e) => '- ${e.name} (Location: ${e.location})')
          .join('\n');
      return isVietnamese
          ? 'Các triển lãm tại ${museum.name}:\n$lines'
          : 'Exhibitions at ${museum.name}:\n$lines';
    }

    if (_isRouteQuestion(normalized) && museum != null) {
      final routes = await BackendApi.instance.fetchRoutes(museum.id);
      if (routes.isEmpty) {
        return isVietnamese
            ? 'Hiện chưa có lộ trình tham quan nào cho ${museum.name}.'
            : 'There are currently no routes listed for ${museum.name}.';
      }
      final lines = routes
          .map((r) => '- ${r.name}: ${r.estimatedTime}, ${r.stopsCount} stops')
          .join('\n');
      return isVietnamese
          ? 'Các lộ trình tại ${museum.name}:\n$lines'
          : 'Available routes at ${museum.name}:\n$lines';
    }

    if (museum != null) {
      if (_isOperatingHoursQuestion(normalized)) {
        return isVietnamese
            ? 'Giờ mở cửa của ${museum.name}: ${museum.operatingHours}.'
            : 'Operating hours of ${museum.name}: ${museum.operatingHours}.';
      }
      if (_isTicketPriceQuestion(normalized)) {
        return isVietnamese
            ? 'Giá vé tại ${museum.name}: ${museum.baseTicketPrice} VND.'
            : 'Ticket price at ${museum.name}: ${museum.baseTicketPrice} VND.';
      }
      if (_isLocationQuestion(normalized)) {
        return isVietnamese
            ? 'Vị trí của ${museum.name}: ${museum.latitude}, ${museum.longitude}.'
            : 'Location of ${museum.name}: ${museum.latitude}, ${museum.longitude}.';
      }
      if (_isMuseumInfoQuestion(normalized)) {
        return isVietnamese
            ? '${museum.name}: mở cửa ${museum.operatingHours}, '
                  'giá vé ${museum.baseTicketPrice} VND.'
            : '${museum.name}: opens ${museum.operatingHours}, '
                  'ticket ${museum.baseTicketPrice} VND.';
      }
    }

    return BackendApi.instance.askAi(text);
  }

  String? _extractArtifactCode(String text) {
    final codeRegex = RegExp(r'\b[A-Za-z]{2,4}\s?-\s?\d{3}\b');
    final match = codeRegex.firstMatch(text);
    if (match == null) {
      return null;
    }
    return match.group(0)?.replaceAll(' ', '').toUpperCase();
  }

  Future<MuseumDto?> _resolveMuseum(String text) async {
    final museums = await BackendApi.instance.fetchMuseums();
    if (museums.isEmpty) {
      return null;
    }

    final normalized = _normalizeForIntent(text);

    for (final museum in museums) {
      final museumName = _normalizeForIntent(museum.name);
      if (normalized.contains(museumName)) {
        return museum;
      }
    }

    final currentMuseumId = AppSession.currentMuseumId.value;
    for (final museum in museums) {
      if (museum.id == currentMuseumId) {
        return museum;
      }
    }

    return museums.first;
  }

  static bool _isExhibitionQuestion(String text) {
    return _containsAny(text, <String>[
      'exhibition',
      'exhibitions',
      'exhibit',
      'exhibits',
      'trien lam',
      'trung bay',
      'show',
    ]);
  }

  static bool _isRouteQuestion(String text) {
    return _containsAny(text, <String>[
      'route',
      'routes',
      'navigation',
      'itinerary',
      'lo trinh',
      'duong di',
      'tuyen tham quan',
      'tham quan',
      'path',
    ]);
  }

  static bool _isOperatingHoursQuestion(String text) {
    return _containsAny(text, <String>[
      'operating hour',
      'opening hour',
      'open',
      'close',
      'gio mo cua',
      'gio dong cua',
      'dong cua',
      'mo cua',
    ]);
  }

  static bool _isTicketPriceQuestion(String text) {
    return _containsAny(text, <String>[
      'ticket',
      'price',
      'entry fee',
      'gia ve',
      've bao nhieu',
      've vao cong',
    ]);
  }

  static bool _isLocationQuestion(String text) {
    return _containsAny(text, <String>[
      'location',
      'where is',
      'dia chi',
      'o dau',
      'nam o dau',
    ]);
  }

  static bool _isMuseumInfoQuestion(String text) {
    return _isOperatingHoursQuestion(text) ||
        _isTicketPriceQuestion(text) ||
        _isLocationQuestion(text) ||
        _containsAny(text, <String>[
          'museum info',
          'information',
          'thong tin bao tang',
          'bao tang',
        ]);
  }

  static bool _isMapIntentQuestion(String text) {
    return _containsAny(text, <String>[
      'map',
      'route',
      'navigation',
      'duong di',
      'ban do',
      'chi duong',
    ]);
  }

  static bool _isTicketIntentQuestion(String text) {
    return _containsAny(text, <String>[
      'ticket',
      'tickets',
      've',
      'mua ve',
      'my ticket',
      'booking',
    ]);
  }

  static bool _isArtifactIntentQuestion(String text) {
    return _containsAny(text, <String>[
          'artifact',
          'artifacts',
          'hien vat',
          'qr',
          'artifact code',
        ]) ||
        RegExp(r'\b[a-z]{2,4}\s?-\s?\d{3}\b').hasMatch(text);
  }

  static bool _isLikelyVietnameseQuestion(String rawText, String normalized) {
    final hasVietnameseDiacritics = RegExp(
      r'[\u00C0-\u1EF9]',
      caseSensitive: false,
      unicode: true,
    ).hasMatch(rawText);

    if (hasVietnameseDiacritics) {
      return true;
    }

    return _containsAny(normalized, <String>[
      'bao tang',
      'trien lam',
      'lo trinh',
      'duong di',
      'gio mo cua',
      'gia ve',
      'dia chi',
      'o dau',
      'tham quan',
      'hien vat',
    ]);
  }

  static String _normalizeForIntent(String text) {
    var normalized = text.toLowerCase().trim();

    const replacements = <String, String>{
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };

    replacements.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    normalized = normalized
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return normalized;
  }

  static bool _containsAny(String text, List<String> candidates) {
    for (final keyword in candidates) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
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
    return ListenableBuilder(
      listenable: Listenable.merge([
        languageNotifier,
        AppSession.currentMuseumId,
        AppSession.currentMuseumName,
      ]),
      builder: (context, _) {
        final quickAccessQuestions = _quickAccessQuestionsForMuseum(
          AppSession.currentMuseumName.value,
        );
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
                                'online'.tr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your AI companion'.tr,
                            style: const TextStyle(
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
                    primary: false,
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
                      final isOpeningMessage =
                          index == 0 && !(msg.isUser ?? true);
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
                            if (!(msg.isUser ?? true) &&
                                (msg.actions?.isNotEmpty ?? false)) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final action
                                      in msg.actions ?? const <_ChatAction>[])
                                    _StarterActionChip(
                                      icon: action.icon,
                                      text: action.label.tr,
                                      onTap: () => _onActionTap(action, msg),
                                    ),
                                ],
                              ),
                            ],
                            if (isOpeningMessage) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _StarterActionChip(
                                    icon: Icons.near_me_outlined,
                                    text: 'View Map'.tr,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const Museum3DMapScreen(),
                                      ),
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
                  child: Text(
                    'Quick access buttons:'.tr,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ScrollConfiguration(
                    behavior: const MaterialScrollBehavior().copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                        PointerDeviceKind.stylus,
                        PointerDeviceKind.invertedStylus,
                      },
                    ),
                    child: ListView.separated(
                      controller: _quickAccessScrollController,
                      primary: false,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: quickAccessQuestions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, index) => _QuickQuestionChip(
                        text: quickAccessQuestions[index].tr,
                        onTap: () =>
                            _submitMessage(quickAccessQuestions[index]),
                      ),
                    ),
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
                            decoration: InputDecoration(
                              hintText: 'Ask me anything...'.tr,
                              hintStyle: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9CA3AF),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
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
      },
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
      child: Icon(icon, color: const Color(0xFF4B5563)),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.time,
    this.isUser,
    this.actions,
    this.sourceQuestion,
  });

  final String text;
  final String time;
  final bool? isUser;
  final List<_ChatAction>? actions;
  final String? sourceQuestion;
}

enum _ChatActionType { map, tickets, artifact }

class _ChatAction {
  const _ChatAction({
    required this.type,
    required this.label,
    required this.icon,
  });

  final _ChatActionType type;
  final String label;
  final IconData icon;
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
            message.text.tr,
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
      child: Text(
        'Ogima is typing...'.tr,
        style: const TextStyle(
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Text(
            text.tr,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w500,
            ),
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
              text.tr,
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

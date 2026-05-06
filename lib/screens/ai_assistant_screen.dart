import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/font_size_notifier.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/screens/museum_3d_map_screen.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/session.dart';
import 'package:museamigo/theme_notifier.dart';

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
  bool _isTranslating = false;
  _PendingRouteRequest? _pendingRouteRequest;

  bool get _useVietnameseReplies =>
      languageNotifier.currentLanguage == 'Vietnamese';

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
      _pendingRouteRequest = null;
      final museumName = AppSession.currentMuseumName.value;
      final updatedMessage = _ChatMessage(
        text: _buildGreetingMessage(museumName, _useVietnameseReplies),
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
        text: _buildGreetingMessage(
          AppSession.currentMuseumName.value,
          _useVietnameseReplies,
        ),
        time: _formatTime(DateTime.now()),
        isUser: false,
      ),
    );
  }

  static String _buildGreetingMessage(String museumName, bool isVietnamese) {
    if (isVietnamese) {
      return 'Xin chào! Mình là Ogima, hướng dẫn viên cá nhân của bạn tại $museumName. '
          'Mình có thể giúp bạn khám phá hiện vật, chỉ đường trong museum, '
          'trả lời câu hỏi và gợi ý các trưng bày thú vị. '
          'ôm nay mình có thể hỗ trợ bạn điều gì?';
    }

    return 'Hello! I\'m Ogima, your personal guide to $museumName. '
        'I can help you discover artifacts, navigate the museum, '
        'answer questions, and guide you to interesting exhibits. '
        'How can I assist you today?';
  }

  List<String> _quickAccessQuestionsForMuseum(String museumName) {
    if (_useVietnameseReplies) {
      return <String>[
        'Giờ mở cửa của $museumName là gì?',
        'Giá vé tại $museumName là bao nhiêu?',
        'ại $museumName có những triển lãm nào?',
        'ại $museumName có những lộ trình tham quan nào?',
        'ãy cho tôi biết về hiện vật mã IP-002.',
        '$museumName nằm ở đâu?',
      ];
    }

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

    _ResolvedReply resolved;
    try {
      resolved = await _resolveReplyForInput(text);
    } catch (_) {
      // Keep local fallback so chat still works when backend is unreachable.
      resolved = _ResolvedReply(text: _buildAiReply(text));
    }
    if (!mounted) {
      return;
    }

    setState(() {
      final contextActions = resolved.actions.isNotEmpty
          ? resolved.actions
          : _buildContextActions(text);
      _messages.add(
        _ChatMessage(
          text: resolved.text,
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
        await _openMapFromAction(action);
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
      case _ChatActionType.themeOption:
        final color = action.color;
        if (color != null) {
          themeNotifier.setPrimaryColor(color);
          _applySettingsToBackend(
            theme: (action.value ?? '').replaceFirst('#', ''),
            language: null,
          );
        }
        if (!mounted) return;
        _addBotMessage(
          _useVietnameseReplies
              ? 'Đã chuyển sang theme ${action.label} (${action.value})!'
              : 'Switched to ${action.label} theme (${action.value})!',
        );
        break;
      case _ChatActionType.languageOption:
        final lang = action.value ?? 'English';
        languageNotifier.setLanguage(lang);
        _applySettingsToBackend(
          theme: null,
          language: lang == 'Vietnamese' ? 'vi' : 'en',
        );
        break;
      case _ChatActionType.fontSizeOption:
        final levelName = action.value ?? 'medium';
        final level = FontSizeLevel.values.firstWhere(
          (l) => l.name == levelName,
          orElse: () => FontSizeLevel.medium,
        );
        fontSizeNotifier.setLevel(level);
        if (!mounted) return;
        _addBotMessage(
          _useVietnameseReplies
              ? 'Đã chuyển cỡ chữ sang ${action.label}!'
              : 'Font size changed to ${action.label}!',
        );
        break;
    }
  }

  Future<void> _openMapFromAction(_ChatAction action) async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      _SlidePageRoute<void>(
        builder: (_) => Museum3DMapScreen(
          initialFromLocationName: action.fromLocationName,
          initialToLocationName: action.toLocationName,
        ),
      ),
    );
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

  Future<_ResolvedReply> _resolveReplyForInput(String text) async {
    final normalized = _normalizeForIntent(text);
    final isVietnamese = _useVietnameseReplies;

    // Handle settings intents before any network-dependent logic.
    if (_isThemeChangeIntent(normalized)) {
      return _buildThemeReply(normalized, isVietnamese);
    }

    if (_isLanguageChangeIntent(normalized)) {
      return _buildLanguageReply(normalized, isVietnamese);
    }

    if (_isFontSizeChangeIntent(normalized)) {
      return _buildFontSizeReply(normalized, isVietnamese);
    }

    final museum = await _resolveMuseum(text);

    // If the user is clearly asking a new question, reset any stale pending state.
    if (_pendingRouteRequest != null) {
      if (_isNewTopicQuestion(normalized, text, museum)) {
        _pendingRouteRequest = null;
        // fall through to normal handling below
      } else {
        return _resolvePendingRouteRequest(
          text: text,
          isVietnamese: _useVietnameseReplies,
          museum: museum,
          request: _pendingRouteRequest!,
        );
      }
    }

    if (museum != null &&
        (_isAmbiguousMultiFloorQuery(normalized) ||
            _isLocationQuestion(normalized) ||
            _isDirectionsToPlaceQuestion(normalized))) {
      // Ambiguous restroom/stairs (no floor specified) → resolve destination after user gives floor
      if (_isAmbiguousMultiFloorQuery(normalized)) {
        final spotType = _extractAmbiguousSpotType(normalized);
        _pendingRouteRequest = _PendingRouteRequest(
          isVietnamese: isVietnamese,
          ambiguousSpotType: spotType,
        );
        return _ResolvedReply(
          text: isVietnamese
              ? 'Bạn đang ở tầng nào vậy? Bạn có thể trả lời là tầng 1 hoặc tầng 2!'
              : 'Which floor are you on? You can just say Floor 1 or Floor 2 😊',
        );
      }

      // Known in-museum spot → ask floor first
      final destination = _extractNavigationSpot(text, museum.id);
      if (destination != null) {
        _pendingRouteRequest = _PendingRouteRequest(
          destination: destination,
          isVietnamese: isVietnamese,
        );
        return _ResolvedReply(
          text: isVietnamese
              ? 'Bạn đang ở tầng nào vậy? Bạn có thể trả lời là tầng 1 hoặc tầng 2!'
              : 'Which floor are you on? You can just say Floor 1 or Floor 2 😊',
        );
      }

      // 2. Location question about the museum itself → return real-world address
      if (_isLocationQuestion(normalized) &&
          _isAskingAboutMuseumSelf(normalized, museum.name)) {
        final locationInfo = _museumLocationInfo(museum.name);
        if (locationInfo != null) {
          return _ResolvedReply(
            text: isVietnamese
                ? 'Theo Google Maps, ${museum.name} nằm tại ${locationInfo.addressVi}.'
                : 'According to Google Maps, ${museum.name} is located at ${locationInfo.addressEn}.',
          );
        }
        return _ResolvedReply(
          text: isVietnamese
              ? 'Vị trí của ${museum.name}: ${museum.latitude}, ${museum.longitude}.'
              : 'Location of ${museum.name}: ${museum.latitude}, ${museum.longitude}.',
        );
      }

      // 3. Place not found in museum
      return _ResolvedReply(
        text: isVietnamese
            ? 'Địa điểm đó không có trong bản đồ của ${museum.name}.'
            : 'That place is not found on the map of ${museum.name}.',
      );
    }

    final artifactCode = _extractArtifactCode(text);
    if (artifactCode != null) {
      final artifact = await BackendApi.instance.fetchArtifact(artifactCode);
      return _ResolvedReply(
        text:
            'Artifact: ${artifact.title} (${artifact.artifactCode}). '
            'Year: ${artifact.year}. ${artifact.description}',
      );
    }

    if (_isExhibitionQuestion(normalized) && museum != null) {
      final exhibitions = await BackendApi.instance.fetchExhibitions(museum.id);
      if (exhibitions.isEmpty) {
        return _ResolvedReply(
          text: isVietnamese
              ? 'Hiện chưa có triển lãm nào được liệt kê cho ${museum.name}.'
              : 'There are currently no exhibitions listed for ${museum.name}.',
        );
      }
      final lines = exhibitions
          .map((e) => '- ${e.name} (Location: ${e.location})')
          .join('\n');
      return _ResolvedReply(
        text: isVietnamese
            ? 'Các triển lãm tại ${museum.name}:\n$lines'
            : 'Exhibitions at ${museum.name}:\n$lines',
      );
    }

    if (_isRouteQuestion(normalized) && museum != null) {
      final routes = await BackendApi.instance.fetchRoutes(museum.id);
      if (routes.isEmpty) {
        return _ResolvedReply(
          text: isVietnamese
              ? 'Hiện chưa có lộ trình tham quan nào cho ${museum.name}.'
              : 'There are currently no routes listed for ${museum.name}.',
        );
      }
      final lines = routes
          .map((r) => '- ${r.name}: ${r.estimatedTime}, ${r.stopsCount} stops')
          .join('\n');
      return _ResolvedReply(
        text: isVietnamese
            ? 'Các lộ trình tại ${museum.name}:\n$lines'
            : 'Available routes at ${museum.name}:\n$lines',
      );
    }

    if (museum != null) {
      if (_isOperatingHoursQuestion(normalized)) {
        return _ResolvedReply(
          text: isVietnamese
              ? 'Giờ mở cửa của ${museum.name}: ${museum.operatingHours}.'
              : 'Operating hours of ${museum.name}: ${museum.operatingHours}.',
        );
      }
      if (_isTicketPriceQuestion(normalized)) {
        return _ResolvedReply(
          text: isVietnamese
              ? 'Giá vé tại ${museum.name}: ${museum.baseTicketPrice} VND.'
              : 'Ticket price at ${museum.name}: ${museum.baseTicketPrice} VND.',
        );
      }
      if (_isMuseumInfoQuestion(normalized)) {
        return _ResolvedReply(
          text: isVietnamese
              ? '${museum.name}: mở cửa ${museum.operatingHours}, '
                    'giá vé ${museum.baseTicketPrice} VND.'
              : '${museum.name}: opens ${museum.operatingHours}, '
                    'ticket ${museum.baseTicketPrice} VND.',
        );
      }
    }

    return _ResolvedReply(text: await BackendApi.instance.askAi(text));
  }

  _ResolvedReply _resolvePendingRouteRequest({
    required String text,
    required bool isVietnamese,
    required MuseumDto? museum,
    required _PendingRouteRequest request,
  }) {
    final currentMuseumId = museum?.id ?? AppSession.currentMuseumId.value;

    // ── Case 1: Ambiguous spot (restroom/stairs), waiting for floor ────────────
    // destination is null; resolve to same-floor spot once user gives their floor.
    if (request.destination == null) {
      final floor = _extractFloorLabel(text);
      if (floor == null) {
        return _ResolvedReply(
          text: isVietnamese
              ? 'Bạn đang ở tầng nào vậy? Bạn có thể trả lời là tầng 1 hoặc tầng 2!'
              : 'Which floor are you on? You can just say Floor 1 or Floor 2 😊',
        );
      }

      final spotLabel = request.ambiguousSpotType == 'restroom'
          ? 'Restroom'
          : 'Stairs';
      final destination = _findNavigationSpotByName(
        currentMuseumId,
        '$spotLabel - $floor',
      );

      if (destination == null) {
        _pendingRouteRequest = null;
        final viLabel = request.ambiguousSpotType == 'restroom'
            ? 'nhà vệ sinh'
            : 'cầu thang';
        return _ResolvedReply(
          text: isVietnamese
              ? 'Không tìm thấy $viLabel trên $floor.'
              : 'Could not find ${request.ambiguousSpotType} on $floor.',
        );
      }

      // Restroom/Stairs are always on the same floor as the user → ask current position
      _pendingRouteRequest = _PendingRouteRequest(
        destination: destination,
        isVietnamese: isVietnamese,
        currentFloor: floor,
      );
      return _ResolvedReply(
        text: isVietnamese
            ? 'Bạn đang ở $floor. Bạn đang đứng ở điểm nào trên $floor? Ví dụ: Main Entrance, Stairs - $floor.'
            : 'You are on $floor. Which spot are you currently at on $floor? For example: Main Entrance, Stairs - $floor.',
      );
    }

    // From here destination is always non-null.
    final destination = request.destination!;

    // ── Case 2: Destination known, waiting for user's floor ───────────────────
    if (request.currentFloor == null) {
      final currentFloor = _extractFloorLabel(text);
      if (currentFloor == null) {
        return _ResolvedReply(
          text: isVietnamese
              ? 'Bạn đang ở tầng nào vậy? Bạn có thể trả lời là tầng 1 hoặc tầng 2!'
              : 'Which floor are you on? You can just say Floor 1 or Floor 2 😊',
        );
      }

      if (currentFloor != destination.floor) {
        // Different floor → give cross-floor instructions + View Map (Stairs → dest)
        _pendingRouteRequest = null;
        final floorInstruction = _buildCrossFloorInstruction(
          fromFloor: currentFloor,
          toFloor: destination.floor,
          isVietnamese: isVietnamese,
        );
        final destFloorStairs = _findNavigationSpotByName(
          currentMuseumId,
          'Stairs - ${destination.floor}',
        );
        final routeFrom = destFloorStairs ?? destination;
        final mapAction = _ChatAction(
          type: _ChatActionType.map,
          label: 'View Map',
          icon: Icons.near_me_outlined,
          fromLocationName: routeFrom.name,
          toLocationName: destination.name,
        );
        return _ResolvedReply(
          text: isVietnamese
              ? '$floorInstruction ${destination.name} nằm ở ${destination.floor}. Bạn sẽ đi từ cầu thang đến ${destination.name}. Nhấn View Map bên dưới để xem đường đi!'
              : '$floorInstruction ${destination.name} is on ${destination.floor}. You\'ll head from the stairs to ${destination.name}. Tap View Map below to see the route!',
          actions: <_ChatAction>[mapAction],
          mapAction: mapAction,
        );
      }

      // Same floor → ask current position
      _pendingRouteRequest = request.copyWith(currentFloor: currentFloor);
      return _ResolvedReply(
        text: isVietnamese
            ? 'Bạn đang ở $currentFloor. Bạn đang đứng ở điểm nào trên $currentFloor? Ví dụ: Main Entrance, Restroom - $currentFloor hoặc Stairs - $currentFloor.'
            : 'You are on $currentFloor. Which spot are you currently at on $currentFloor? For example: Main Entrance, Restroom - $currentFloor, or Stairs - $currentFloor.',
      );
    }

    // ── Case 3: Floor known, waiting for current spot ─────────────────────────
    // If user says an ambiguous spot type (stairs/restroom) without a floor,
    // resolve it to the floor we already know they're on.
    final normalized3 = _normalizeForIntent(text);
    final _NavigationSpot? floorQualifiedSpot = () {
      for (final label in ['Restroom', 'Stairs']) {
        final aliases = label == 'Stairs'
            ? <String>['stairs', 'staircase', 'stair', 'cầu thang', 'thang bộ']
            : <String>['restroom', 'toilet', 'wc', 'nhà vệ sinh', 'wc'];
        final matched = aliases.any((a) => normalized3.contains(a));
        if (matched && !normalized3.contains('floor')) {
          return _findNavigationSpotByName(
            currentMuseumId,
            '$label - ${request.currentFloor}',
          );
        }
      }
      return null;
    }();
    final fromSpot =
        floorQualifiedSpot ?? _extractNavigationSpot(text, currentMuseumId);

    if (fromSpot == null) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'Mình chưa xác định được vị trí của bạn. Hãy nói tên điểm trên map, ví dụ Main Entrance hoặc Restroom - Floor 1 nhé!'
            : 'I could not find that spot. Please say an exact place name from the map, e.g. Main Entrance or Restroom - Floor 1.',
      );
    }

    if (fromSpot.floor != request.currentFloor) {
      return _ResolvedReply(
        text: isVietnamese
            ? '${fromSpot.name} ở ${fromSpot.floor}, nhưng bạn nói bạn đang ở ${request.currentFloor}. Hãy chọn một điểm trên ${request.currentFloor} nhé!'
            : '${fromSpot.name} is on ${fromSpot.floor}, but you said you\'re on ${request.currentFloor}. Please pick a spot on ${request.currentFloor}.',
      );
    }

    _pendingRouteRequest = null;

    if (fromSpot.name == destination.name) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'Bạn đang ở ngay ${destination.name} rồi!'
            : 'You\'re already at ${destination.name}!',
      );
    }

    final mapAction = _ChatAction(
      type: _ChatActionType.map,
      label: 'View Map',
      icon: Icons.near_me_outlined,
      fromLocationName: fromSpot.name,
      toLocationName: destination.name,
    );
    return _ResolvedReply(
      text: isVietnamese
          ? '${destination.name} nằm trên ${destination.floor}. Mình đã chuẩn bị đường đi từ ${fromSpot.name} đến ${destination.name} trên bản đồ bên dưới!'
          : '${destination.name} is on ${destination.floor}. I\'ve prepared a route from ${fromSpot.name} to ${destination.name} on the map below!',
      actions: <_ChatAction>[mapAction],
      mapAction: mapAction,
    );
  }

  static String _buildCrossFloorInstruction({
    required String fromFloor,
    required String toFloor,
    required bool isVietnamese,
  }) {
    final fromLevel = _floorNumber(fromFloor);
    final toLevel = _floorNumber(toFloor);

    if (fromLevel != null && toLevel != null) {
      if (fromLevel < toLevel) {
        return isVietnamese
            ? 'Bạn hãy đi lên $toFloor bằng cầu thang.'
            : 'Please go up to $toFloor using the stairs.';
      }
      if (fromLevel > toLevel) {
        return isVietnamese
            ? 'Bạn hãy đi xuống $toFloor bằng cầu thang.'
            : 'Please go down to $toFloor using the stairs.';
      }
    }

    return isVietnamese
        ? 'Bạn hãy di chuyển giữa các tầng bằng cầu thang.'
        : 'Please move between floors using the stairs.';
  }

  static int? _floorNumber(String floorLabel) {
    final match = RegExp(r'(\d+)').firstMatch(floorLabel);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static String? _extractFloorLabel(String text) {
    final normalized = _normalizeForIntent(text);
    if (_containsAny(normalized, <String>[
      'floor 1',
      'tang 1',
      'level 1',
      '1st floor',
    ])) {
      return 'Floor 1';
    }
    if (_containsAny(normalized, <String>[
      'floor 2',
      'tang 2',
      'level 2',
      '2nd floor',
    ])) {
      return 'Floor 2';
    }
    return null;
  }

  static bool _isDirectionsToPlaceQuestion(String text) {
    return _containsAny(text, <String>[
      'how can i get to',
      'how do i get to',
      'how can i go to',
      'how do i go to',
      'how to get to',
      'how to reach',
      'how do i reach',
      'directions to',
      'where can i find',
      'help me find',
      'show me',
      'lead me to',
      'take me to',
      'navigate to',
      'way to',
      'go to',
      'get to',
      'chi duong',
      'huong dan den',
      'chi toi den',
      'cho toi den',
      'di den',
      'duong den',
      'duong di den',
      'lam sao de toi',
      'lam sao den',
      'toi muon den',
      'dan toi den',
      'dan toi',
      'den',
    ]);
  }

  _NavigationSpot? _extractNavigationSpot(String text, int museumId) {
    final normalized = _normalizeForIntent(text);
    final spots = _museumNavigationSpots[museumId] ?? const <_NavigationSpot>[];

    _NavigationSpot? bestMatch;
    var bestScore = 0;

    for (final spot in spots) {
      for (final alias in spot.aliases) {
        if (!normalized.contains(alias)) {
          continue;
        }
        if (alias.length > bestScore) {
          bestScore = alias.length;
          bestMatch = spot;
        }
      }
    }

    return bestMatch;
  }

  _NavigationSpot? _findNavigationSpotByName(int museumId, String name) {
    final normalizedName = _normalizeForIntent(name);
    final spots = _museumNavigationSpots[museumId] ?? const <_NavigationSpot>[];

    for (final spot in spots) {
      if (_normalizeForIntent(spot.name) == normalizedName) {
        return spot;
      }
    }

    return null;
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

  static bool _isAmbiguousMultiFloorQuery(String normalized) {
    final hasFloor = _containsAny(normalized, <String>[
      'floor 1',
      'floor 2',
      'tang 1',
      'tang 2',
      'level 1',
      'level 2',
    ]);
    if (hasFloor) return false;
    return _containsAny(normalized, <String>[
      'restroom',
      'toilet',
      'wc',
      'nha ve sinh',
      'stairs',
      'stair',
      'cau thang',
    ]);
  }

  static String _extractAmbiguousSpotType(String normalized) {
    if (_containsAny(normalized, <String>[
      'restroom',
      'toilet',
      'wc',
      'nha ve sinh',
    ])) {
      return 'restroom';
    }
    return 'stairs';
  }

  /// Returns true when the user's message is clearly a new question/topic
  /// unrelated to any pending navigation state (e.g. asking about a different
  /// spot, museum info, exhibitions, tickets, or an artifact code).
  bool _isNewTopicQuestion(
    String normalized,
    String rawText,
    MuseumDto? museum,
  ) {
    // If we're waiting for the user's current position (Case 3), any spot name
    // they give is their answer — not a new navigation intent.
    if (_pendingRouteRequest?.currentFloor != null) {
      // Only treat as new topic for clearly unrelated questions (museum info, artifacts, etc.)
      if (_isExhibitionQuestion(normalized) ||
          _isRouteQuestion(normalized) ||
          _isOperatingHoursQuestion(normalized) ||
          _isTicketPriceQuestion(normalized) ||
          _extractArtifactCode(rawText) != null) {
        return true;
      }
      return false;
    }

    // Asking about a named spot in the museum → new navigation intent
    if (museum != null) {
      final spot = _extractNavigationSpot(rawText, museum.id);
      if (spot != null) {
        // Only treat as new if the spot differs from the current pending destination
        final pendingDest = _pendingRouteRequest?.destination?.name;
        if (pendingDest == null || spot.name != pendingDest) return true;
      }
    }
    // Asking about museum-level info
    if (_isLocationQuestion(normalized) ||
        _isExhibitionQuestion(normalized) ||
        _isRouteQuestion(normalized) ||
        _isOperatingHoursQuestion(normalized) ||
        _isTicketPriceQuestion(normalized)) {
      return true;
    }
    // Contains an artifact code
    if (_extractArtifactCode(rawText) != null) return true;
    // Settings change requests
    if (_isThemeChangeIntent(normalized) ||
        _isLanguageChangeIntent(normalized) ||
        _isFontSizeChangeIntent(normalized)) {
      return true;
    }
    return false;
  }

  static bool _isLocationQuestion(String text) {
    return _containsAny(text, <String>[
      'location',
      'located',
      'where is',
      'where are',
      'where can i find',
      'find the',
      'dia chi',
      'vi tri',
      'o dau',
      'nam o dau',
      'nam o',
      'tim o dau',
      'co o dau',
      'o cho nao',
      'tai dau',
    ]);
  }

  static bool _isAskingAboutMuseumSelf(
    String normalizedText,
    String museumName,
  ) {
    final normalizedMuseumName = _normalizeForIntent(museumName);
    if (normalizedText.contains(normalizedMuseumName)) return true;
    return _containsAny(normalizedText, <String>[
      'this museum',
      'the museum',
      'museum located',
      'museum o dau',
      'bao tang o dau',
      'bao tang nay',
      'bao tang nay o dau',
      'dia chi bao tang',
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

  static bool _isThemeChangeIntent(String normalized) {
    return _containsAny(normalized, <String>[
      'change theme',
      'switch theme',
      'set theme',
      'theme settings',
      'change color',
      'switch color',
      'set color',
      'change colour',
      'switch colour',
      'set colour',
      'change app color',
      'switch app color',
      'app colour',
      'color of app',
      'colour of app',
      'color scheme',
      'theme color',
      'change ui color',
      'app color',
      'color theme',
      'theme',
      'doi theme',
      'chuyen theme',
      'thay doi theme',
      'set mau',
      'doi mau',
      'mau sac',
      'mau sac app',
      'mau sac giao dien',
      'doi mau app',
      'doi mau giao dien',
      'doi mau theme',
      'thay mau app',
      'thay doi mau',
      'doi mau sac',
      'thay doi mau sac',
      'chuyen mau',
      'chuyen mau sac',
      'giao dien mau',
      'mau giao dien',
      'doi giao dien',
      'theme app',
    ]);
  }

  static bool _isUnsupportedThemeRequest(String normalized) {
    return _containsAny(normalized, <String>[
      'dark mode',
      'dark theme',
      'night mode',
      'night theme',
      'light mode',
      'white theme',
      'black theme',
      'che do toi',
      'giao dien toi',
      'giao dien sang',
      'bright mode',
      'custom color',
    ]);
  }

  static _AppTheme? _detectSpecificTheme(String normalized) {
    final keywords = <String, _AppTheme>{
      'red': _appThemes[0],
      'do': _appThemes[0],
      'purple': _appThemes[1],
      'violet': _appThemes[1],
      'tim': _appThemes[1],
      'amber': _appThemes[2],
      'yellow': _appThemes[2],
      'vang': _appThemes[2],
      'brown': _appThemes[3],
      'nau': _appThemes[3],
      'green': _appThemes[4],
      'xanh la': _appThemes[4],
      'sky blue': _appThemes[6],
      'light blue': _appThemes[6],
      'xanh nhat': _appThemes[6],
      'blue': _appThemes[5],
      'xanh duong': _appThemes[5],
      'xanh': _appThemes[5],
    };

    final paddedNormalized = ' $normalized ';
    for (final entry in keywords.entries) {
      final needle = ' ${entry.key} ';
      if (paddedNormalized.contains(needle)) {
        return entry.value;
      }
    }
    return null;
  }

  static bool _isLanguageChangeIntent(String normalized) {
    return _containsAny(normalized, <String>[
      'change language',
      'switch language',
      'set language',
      'change app language',
      'language',
      'doi ngon ngu',
      'chuyen ngon ngu',
      'thay ngon ngu',
      'cai dat ngon ngu',
      'ngon ngu',
      'language setting',
      'doi tieng',
      'chuyen tieng',
      'thay tieng',
    ]);
  }

  static bool _isUnsupportedLanguageRequest(String normalized) {
    return _containsAny(normalized, <String>[
      'japanese',
      'korean',
      'french',
      'chinese',
      'mandarin',
      'spanish',
      'german',
      'italian',
      'portuguese',
      'russian',
      'arabic',
      'tieng nhat',
      'tieng han',
      'tieng phap',
      'tieng trung',
      'tieng duc',
    ]);
  }

  static String? _detectSpecificLanguage(String normalized) {
    if (_containsAny(normalized, <String>['english', 'tieng anh', ' anh'])) {
      return 'English';
    }
    if (_containsAny(normalized, <String>[
      'vietnamese',
      'tieng viet',
      'viet nam',
      'viet',
    ])) {
      return 'Vietnamese';
    }
    return null;
  }

  static bool _isFontSizeChangeIntent(String normalized) {
    return _containsAny(normalized, <String>[
      'font size',
      'change font size',
      'switch font size',
      'set font size',
      'text size',
      'change text size',
      'set text size',
      'font',
      'co chu',
      'kich co chu',
      'kich thuoc chu',
      'doi co chu',
      'chuyen co chu',
      'thay co chu',
      'size chu',
      'chu nho',
      'chu to',
    ]);
  }

  static bool _isUnsupportedFontSizeRequest(String normalized) {
    return _containsAny(normalized, <String>[
      'extra large',
      'extra small',
      'huge',
      'tiny',
      'giant',
      'very large',
      'very small',
      'rat to',
      'rat nho',
      'sieu to',
      'sieu nho',
    ]);
  }

  static FontSizeLevel? _detectSpecificFontSize(String normalized) {
    if (_containsAny(normalized, <String>['small', 'nho', ' be '])) {
      return FontSizeLevel.small;
    }
    if (_containsAny(normalized, <String>['large', 'big', ' to ', ' lon '])) {
      return FontSizeLevel.large;
    }
    if (_containsAny(normalized, <String>[
      'medium',
      'vua',
      'trung binh',
      'normal',
    ])) {
      return FontSizeLevel.medium;
    }
    return null;
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

  static _MuseumLocationInfo? _museumLocationInfo(String museumName) {
    const locations = <String, _MuseumLocationInfo>{
      'Independence Palace': _MuseumLocationInfo(
        addressEn:
            '135 Nam Ky Khoi Nghia Street, Ben Thanh Ward, Ho Chi Minh City, Vietnam',
        addressVi:
            '135 Nam Ky Khoi Nghia, phuong Ben Thanh, Thanh pho Ho Chi Minh, Viet Nam',
      ),
      'War Remnants Museum': _MuseumLocationInfo(
        addressEn:
            '28 Vo Van Tan Street, Xuan Hoa Ward, Ho Chi Minh City, Vietnam',
        addressVi:
            '28 Vo Van Tan, phuong Xuan Hoa, Thanh pho Ho Chi Minh, Viet Nam',
      ),
      'HCMC Museum of Fine Arts': _MuseumLocationInfo(
        addressEn:
            '97-97A Pho Duc Chinh Street, Ben Thanh Ward, District 1, Ho Chi Minh City, Vietnam',
        addressVi:
            '97-97A Pho Duc Chinh, phuong Ben Thanh, Quan 1, Thanh pho Ho Chi Minh, Viet Nam',
      ),
      'Ho Chi Minh City Museum': _MuseumLocationInfo(
        addressEn:
            'at the corner of Ly Tu Trong Street and Nam Ky Khoi Nghia Street, near Independence Palace, Ho Chi Minh City, Vietnam',
        addressVi:
            'tai goc duong Ly Tu Trong va Nam Ky Khoi Nghia, gan Independence Palace, Thanh pho Ho Chi Minh, Viet Nam',
      ),
    };

    return locations[museumName];
  }

  String _buildAiReply(String question) {
    final q = question.toLowerCase();
    final isVietnamese = _useVietnameseReplies;
    if (q.contains('toilet') || q.contains('restroom')) {
      return isVietnamese
          ? 'Nha ve sinh gan nhat nam gan Hall C o Floor 1. Neu ban muon, minh co the chi duong cho ban.'
          : 'The nearest restroom is near Hall C on Floor 1. I can guide you there if you want.';
    }
    if (q.contains('tank') || q.contains('t-54')) {
      return isVietnamese
          ? 'Tank T-54 nam o Hall C, Floor 1. Ban co the theo route tren ban do va minh se huong dan tung buoc cho ban.'
          : 'Tank T-54 is in Hall C, Floor 1. Follow the map route and I can navigate step-by-step for you.';
    }
    if (q.contains('floor 2')) {
      return isVietnamese
          ? 'O Floor 2, cac diem pho bien gom Photography Gallery, Peace Memorial, Diplomatic Room va Rooftop Cafe.'
          : 'On Floor 2, popular stops include Photography Gallery, Peace Memorial, Diplomatic Room, and Rooftop Cafe.';
    }
    if (q.contains('coffee') || q.contains('cafe')) {
      return isVietnamese
          ? 'Ban co the nghi chan tai Cafe Nile o Floor 1 hoac Rooftop Cafe o Floor 2.'
          : 'You can take a break at Cafe Nile on Floor 1 or Rooftop Cafe on Floor 2.';
    }
    return isVietnamese
        ? 'Cau hoi rat hay. Minh co the giup ban kham pha hien vat, tim tien ich va chi duong den bat ky khu vuc nao trong museum.'
        : 'Great question. I can help you explore artifacts, find facilities, and navigate to any room in the museum.';
  }

  void _addBotMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          time: _formatTime(DateTime.now()),
          isUser: false,
        ),
      );
    });
    _scrollToBottom();
  }

  void _applySettingsToBackend({String? theme, String? language}) {
    final userId = AppSession.userId.value;
    if (userId == null) return;
    () async {
      try {
        await BackendApi.instance.updateUserSettings(
          userId,
          theme: theme ?? _currentThemeHex(),
          language: language ?? _currentLanguageCode(),
        );
      } catch (_) {}
    }();
  }

  String _currentThemeHex() {
    final value = themeNotifier.primaryColor.value;
    return (value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  String _currentLanguageCode() {
    return languageNotifier.currentLanguage == 'Vietnamese' ? 'vi' : 'en';
  }

  List<_ChatAction> _buildThemeActions() {
    return _appThemes
        .map(
          (t) => _ChatAction(
            type: _ChatActionType.themeOption,
            label: t.name,
            icon: Icons.circle,
            color: t.color,
            value: t.hex,
          ),
        )
        .toList();
  }

  List<_ChatAction> _buildLanguageActions() {
    final isVietnamese = _useVietnameseReplies;
    return [
      _ChatAction(
        type: _ChatActionType.languageOption,
        label: isVietnamese ? '🇬🇧 Tiếng Anh' : '🇬🇧 English',
        icon: Icons.language,
        value: 'English',
      ),
      _ChatAction(
        type: _ChatActionType.languageOption,
        label: isVietnamese ? '🇻🇳 Tiếng Việt' : '🇻🇳 Vietnamese',
        icon: Icons.language,
        value: 'Vietnamese',
      ),
    ];
  }

  List<_ChatAction> _buildFontSizeActions() {
    return const [
      _ChatAction(
        type: _ChatActionType.fontSizeOption,
        label: 'Small',
        icon: Icons.text_fields,
        value: 'small',
      ),
      _ChatAction(
        type: _ChatActionType.fontSizeOption,
        label: 'Medium',
        icon: Icons.text_fields,
        value: 'medium',
      ),
      _ChatAction(
        type: _ChatActionType.fontSizeOption,
        label: 'Large',
        icon: Icons.text_fields,
        value: 'large',
      ),
    ];
  }

  _ResolvedReply _buildThemeReply(String normalized, bool isVietnamese) {
    if (_isUnsupportedThemeRequest(normalized)) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'App không hỗ trợ theme đó. Dưới đây là các theme màu có sẵn trong app — nhấn để áp dụng:'
            : 'The app doesn\'t support that theme. Here are the available color themes — tap to apply:',
        actions: _buildThemeActions(),
      );
    }
    final specific = _detectSpecificTheme(normalized);
    if (specific != null) {
      themeNotifier.setPrimaryColor(specific.color);
      _applySettingsToBackend(
        theme: specific.hex.replaceFirst('#', ''),
        language: null,
      );
      return _ResolvedReply(
        text: isVietnamese
            ? 'Đã chuyển sang theme ${specific.nameVi} (${specific.hex})!'
            : 'Switched to ${specific.name} theme (${specific.hex})!',
      );
    }
    return _ResolvedReply(
      text: isVietnamese
          ? 'Dưới đây là các theme màu sắc có sẵn trong app. Nhấn vào màu bạn muốn để áp dụng ngay!'
          : 'Here are the available color themes in the app. Tap one to apply it instantly!',
      actions: _buildThemeActions(),
    );
  }

  _ResolvedReply _buildLanguageReply(String normalized, bool isVietnamese) {
    if (_isUnsupportedLanguageRequest(normalized)) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'App hiện chưa hỗ trợ ngôn ngữ đó. Bạn có thể chọn một trong các ngôn ngữ sau:'
            : 'The app doesn\'t support that language yet. You can choose from the following:',
        actions: _buildLanguageActions(),
      );
    }
    final specific = _detectSpecificLanguage(normalized);
    if (specific != null) {
      languageNotifier.setLanguage(specific);
      _applySettingsToBackend(
        theme: null,
        language: specific == 'Vietnamese' ? 'vi' : 'en',
      );
      return _ResolvedReply(
        text: specific == 'Vietnamese'
            ? 'Đã chuyển sang Tiếng Việt!'
            : 'Switched to English!',
      );
    }
    return _ResolvedReply(
      text: isVietnamese
          ? 'App hỗ trợ các ngôn ngữ sau. Nhấn để thay đổi:'
          : 'The app supports the following languages. Tap to switch:',
      actions: _buildLanguageActions(),
    );
  }

  _ResolvedReply _buildFontSizeReply(String normalized, bool isVietnamese) {
    if (_isUnsupportedFontSizeRequest(normalized)) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'App không hỗ trợ cỡ chữ đó. Các cỡ chữ có sẵn:'
            : 'The app doesn\'t support that font size. Available sizes:',
        actions: _buildFontSizeActions(),
      );
    }
    final specific = _detectSpecificFontSize(normalized);
    if (specific != null) {
      fontSizeNotifier.setLevel(specific);
      final levelLabel = specific == FontSizeLevel.small
          ? (isVietnamese ? 'Nhỏ' : 'Small')
          : specific == FontSizeLevel.large
          ? (isVietnamese ? 'Lớn' : 'Large')
          : (isVietnamese ? 'Vừa' : 'Medium');
      return _ResolvedReply(
        text: isVietnamese
            ? 'Đã chuyển cỡ chữ sang $levelLabel!'
            : 'Font size changed to $levelLabel!',
      );
    }
    return _ResolvedReply(
      text: isVietnamese
          ? 'Các cỡ chữ có sẵn trong app. Nhấn để thay đổi:'
          : 'Available font sizes in the app. Tap to change:',
      actions: _buildFontSizeActions(),
    );
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
                  child: Stack(
                    children: [
                      ListView.builder(
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
                                          in msg.actions ??
                                              const <_ChatAction>[])
                                        action.type ==
                                                _ChatActionType.themeOption
                                            ? _ThemeOptionChip(
                                                action: action,
                                                onTap: () =>
                                                    _onActionTap(action, msg),
                                              )
                                            : _StarterActionChip(
                                                icon: action.icon,
                                                text: action.label.tr,
                                                onTap: () =>
                                                    _onActionTap(action, msg),
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
                                          _SlidePageRoute<void>(
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
                      if (_isTranslating)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.88),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    color: themeNotifier.primaryColor,
                                    strokeWidth: 3,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _useVietnameseReplies
                                        ? 'Đang dịch tin nhắn...'
                                        : 'Translating messages...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeNotifier.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
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

enum _ChatActionType {
  map,
  tickets,
  artifact,
  themeOption,
  languageOption,
  fontSizeOption,
}

class _ChatAction {
  const _ChatAction({
    required this.type,
    required this.label,
    required this.icon,
    this.fromLocationName,
    this.toLocationName,
    this.color,
    this.value,
  });

  final _ChatActionType type;
  final String label;
  final IconData icon;
  final String? fromLocationName;
  final String? toLocationName;
  final Color? color;
  final String? value;
}

class _ResolvedReply {
  const _ResolvedReply({
    required this.text,
    this.actions = const <_ChatAction>[],
    this.mapAction,
  });

  final String text;
  final List<_ChatAction> actions;
  final _ChatAction? mapAction;
}

class _MuseumLocationInfo {
  const _MuseumLocationInfo({required this.addressEn, required this.addressVi});

  final String addressEn;
  final String addressVi;
}

class _PendingRouteRequest {
  const _PendingRouteRequest({
    this.destination,
    required this.isVietnamese,
    this.currentFloor,
    this.ambiguousSpotType,
  });

  /// null when ambiguousSpotType is set (destination resolved after user gives floor)
  final _NavigationSpot? destination;
  final bool isVietnamese;
  final String? currentFloor;

  /// 'restroom' or 'stairs' — destination resolved once user gives their floor
  final String? ambiguousSpotType;

  _PendingRouteRequest copyWith({
    _NavigationSpot? destination,
    bool? isVietnamese,
    String? currentFloor,
    String? ambiguousSpotType,
  }) {
    return _PendingRouteRequest(
      destination: destination ?? this.destination,
      isVietnamese: isVietnamese ?? this.isVietnamese,
      currentFloor: currentFloor ?? this.currentFloor,
      ambiguousSpotType: ambiguousSpotType ?? this.ambiguousSpotType,
    );
  }
}

class _NavigationSpot {
  const _NavigationSpot({
    required this.name,
    required this.floor,
    required this.aliases,
  });

  final String name;
  final String floor;
  final List<String> aliases;
}

final Map<int, List<_NavigationSpot>>
_museumNavigationSpots = <int, List<_NavigationSpot>>{
  1: <_NavigationSpot>[
    _spot('Main Entrance', 'Floor 1', <String>[
      'main entrance',
      'entrance',
      'cua chinh',
    ]),
    _spot('War History Gallery', 'Floor 1', <String>['war history gallery']),
    _spot('Presidential Throne', 'Floor 1', <String>[
      'presidential throne',
      'throne',
    ]),
    _spot('T-54 Tank', 'Floor 1', <String>['t-54 tank', 'tank t-54', 'tank']),
    _spot('Diplomatic Reception Hall', 'Floor 1', <String>[
      'diplomatic reception hall',
      'reception hall',
    ]),
    _spot('Restroom - Floor 1', 'Floor 1', <String>[
      'restroom floor 1',
      'toilet floor 1',
      'wc floor 1',
      'restroom',
      'toilet',
      'wc',
      'nha ve sinh',
    ]),
    _spot('Stairs - Floor 1', 'Floor 1', <String>[
      'stairs floor 1',
      'stair floor 1',
      'cau thang floor 1',
      'stairs',
      'stair',
      'cau thang',
    ]),
    _spot('Presidential Office Tour', 'Floor 2', <String>[
      'presidential office tour',
      'presidential office',
    ]),
    _spot('Historical Documents Room', 'Floor 2', <String>[
      'historical documents room',
      'documents room',
    ]),
    _spot('Independence Archive', 'Floor 2', <String>[
      'independence archive',
      'archive',
    ]),
    _spot('Command Communication Room', 'Floor 2', <String>[
      'command communication room',
      'communication room',
    ]),
    _spot('Souvenir Shop', 'Floor 2', <String>['souvenir shop', 'shop']),
    _spot('Rooftop Cafe', 'Floor 2', <String>[
      'rooftop cafe',
      'cafe',
      'coffee',
    ]),
    _spot('Restroom - Floor 2', 'Floor 2', <String>[
      'restroom floor 2',
      'toilet floor 2',
      'wc floor 2',
    ]),
    _spot('Stairs - Floor 2', 'Floor 2', <String>[
      'stairs floor 2',
      'stair floor 2',
      'cau thang floor 2',
    ]),
  ],
  2: <_NavigationSpot>[
    _spot('Main Entrance', 'Floor 1', <String>[
      'main entrance',
      'entrance',
      'cua chinh',
    ]),
    _spot('War Crimes Exhibition', 'Floor 1', <String>[
      'war crimes exhibition',
    ]),
    _spot('Guillotine', 'Floor 1', <String>['guillotine']),
    _spot('Tiger Cages', 'Floor 1', <String>['tiger cages']),
    _spot('Restroom - Floor 1', 'Floor 1', <String>[
      'restroom floor 1',
      'toilet floor 1',
      'wc floor 1',
      'restroom',
      'toilet',
      'wc',
      'nha ve sinh',
    ]),
    _spot('Stairs - Floor 1', 'Floor 1', <String>[
      'stairs floor 1',
      'stair floor 1',
      'cau thang floor 1',
      'stairs',
      'stair',
      'cau thang',
    ]),
    _spot('International Support Gallery', 'Floor 2', <String>[
      'international support gallery',
    ]),
    _spot('Peace and Reconciliation Display', 'Floor 2', <String>[
      'peace and reconciliation display',
      'reconciliation display',
    ]),
    _spot('Documentary Corner', 'Floor 2', <String>['documentary corner']),
    _spot('Souvenir Shop', 'Floor 2', <String>['souvenir shop', 'shop']),
    _spot('Cafe Break', 'Floor 2', <String>['cafe break', 'cafe', 'coffee']),
    _spot('Restroom - Floor 2', 'Floor 2', <String>[
      'restroom floor 2',
      'toilet floor 2',
      'wc floor 2',
    ]),
    _spot('Stairs - Floor 2', 'Floor 2', <String>[
      'stairs floor 2',
      'stair floor 2',
      'cau thang floor 2',
    ]),
  ],
  3: <_NavigationSpot>[
    _spot('Main Entrance', 'Floor 1', <String>[
      'main entrance',
      'entrance',
      'cua chinh',
    ]),
    _spot('Contemporary Vietnamese Art', 'Floor 1', <String>[
      'contemporary vietnamese art',
    ]),
    _spot('Lacquer Painting Rural Life', 'Floor 1', <String>[
      'lacquer painting rural life',
      'lacquer painting',
    ]),
    _spot('Restroom - Floor 1', 'Floor 1', <String>[
      'restroom floor 1',
      'toilet floor 1',
      'wc floor 1',
      'restroom',
      'toilet',
      'wc',
      'nha ve sinh',
    ]),
    _spot('Stairs - Floor 1', 'Floor 1', <String>[
      'stairs floor 1',
      'stair floor 1',
      'cau thang floor 1',
      'stairs',
      'stair',
      'cau thang',
    ]),
    _spot('Traditional Crafts Exhibition', 'Floor 2', <String>[
      'traditional crafts exhibition',
      'crafts exhibition',
    ]),
    _spot('Buddhist Statue', 'Floor 2', <String>['buddhist statue', 'statue']),
    _spot('International Art Collection', 'Floor 2', <String>[
      'international art collection',
    ]),
    _spot('Museum Cafe', 'Floor 2', <String>['museum cafe', 'cafe', 'coffee']),
    _spot('Restroom - Floor 2', 'Floor 2', <String>[
      'restroom floor 2',
      'toilet floor 2',
      'wc floor 2',
    ]),
    _spot('Stairs - Floor 2', 'Floor 2', <String>[
      'stairs floor 2',
      'stair floor 2',
      'cau thang floor 2',
    ]),
  ],
  4: <_NavigationSpot>[
    _spot('Main Entrance', 'Floor 1', <String>[
      'main entrance',
      'entrance',
      'cua chinh',
    ]),
    _spot('City History Journey Hall', 'Floor 1', <String>[
      'city history journey hall',
    ]),
    _spot('Traditional Ao Dai', 'Floor 1', <String>[
      'traditional ao dai',
      'ao dai',
    ]),
    _spot('Restroom - Floor 1', 'Floor 1', <String>[
      'restroom floor 1',
      'toilet floor 1',
      'wc floor 1',
      'restroom',
      'toilet',
      'wc',
      'nha ve sinh',
    ]),
    _spot('Stairs - Floor 1', 'Floor 1', <String>[
      'stairs floor 1',
      'stair floor 1',
      'cau thang floor 1',
      'stairs',
      'stair',
      'cau thang',
    ]),
    _spot('Cultural Heritage Trail Hall', 'Floor 2', <String>[
      'cultural heritage trail hall',
      'heritage trail hall',
    ]),
    _spot('Saigon Map 1930', 'Floor 2', <String>[
      'saigon map 1930',
      'saigon map',
    ]),
    _spot('Urban Planning Gallery', 'Floor 2', <String>[
      'urban planning gallery',
    ]),
    _spot('Museum Cafe', 'Floor 2', <String>['museum cafe', 'cafe', 'coffee']),
    _spot('Restroom - Floor 2', 'Floor 2', <String>[
      'restroom floor 2',
      'toilet floor 2',
      'wc floor 2',
    ]),
    _spot('Stairs - Floor 2', 'Floor 2', <String>[
      'stairs floor 2',
      'stair floor 2',
      'cau thang floor 2',
    ]),
  ],
};

_NavigationSpot _spot(String name, String floor, List<String> aliases) {
  return _NavigationSpot(
    name: name,
    floor: floor,
    aliases: <String>{
      _AIAssistantScreenState._normalizeForIntent(name),
      ...aliases.map(_AIAssistantScreenState._normalizeForIntent),
    }.toList(),
  );
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

/// Represents a supported app color theme.
class _AppTheme {
  const _AppTheme({
    required this.name,
    required this.nameVi,
    required this.color,
    required this.hex,
  });

  final String name;
  final String nameVi;
  final Color color;
  final String hex;
}

const List<_AppTheme> _appThemes = <_AppTheme>[
  _AppTheme(
    name: 'Red',
    nameVi: 'Đỏ',
    color: Color(0xFFCC353A),
    hex: '#CC353A',
  ),
  _AppTheme(
    name: 'Purple',
    nameVi: 'Tím',
    color: Color(0xFF6C4BE8),
    hex: '#6C4BE8',
  ),
  _AppTheme(
    name: 'Amber',
    nameVi: 'Vàng',
    color: Color(0xFFF59E0B),
    hex: '#F59E0B',
  ),
  _AppTheme(
    name: 'Brown',
    nameVi: 'Nâu',
    color: Color(0xFFB45309),
    hex: '#B45309',
  ),
  _AppTheme(
    name: 'Green',
    nameVi: 'Xanh lá',
    color: Color(0xFF10B981),
    hex: '#10B981',
  ),
  _AppTheme(
    name: 'Blue',
    nameVi: 'Xanh dương',
    color: Color(0xFF3B82F6),
    hex: '#3B82F6',
  ),
  _AppTheme(
    name: 'Sky Blue',
    nameVi: 'Xanh nhạt',
    color: Color(0xFF60A5FA),
    hex: '#60A5FA',
  ),
];

/// Chip widget for displaying a color theme option with a colored swatch + name + hex code.
class _ThemeOptionChip extends StatelessWidget {
  const _ThemeOptionChip({required this.action, required this.onTap});

  final _ChatAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chipColor = action.color ?? Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: chipColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: chipColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: chipColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: action.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  TextSpan(
                    text: '  ${action.value}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: chipColor,
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
}

/// Custom route: Cupertino slide animation (both screens move) without swipe-back gesture.
class _SlidePageRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
  _SlidePageRoute({required this.builder});

  final WidgetBuilder builder;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  bool get popGestureEnabled => false;

  @override
  bool get maintainState => true;

  @override
  String? get title => null;
}

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:museamigo/app_routes.dart';
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
  _PendingRouteRequest? _pendingRouteRequest;

  bool get _useVietnameseReplies =>
      languageNotifier.currentLanguage == 'Vietnamese';

  @override
  void initState() {
    super.initState();
    _seedGreetingForCurrentMuseum();
    AppSession.currentMuseumName.addListener(_onMuseumContextChanged);
    languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    AppSession.currentMuseumName.removeListener(_onMuseumContextChanged);
    languageNotifier.removeListener(_onLanguageChanged);
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

  void _onLanguageChanged() {
    if (!mounted || _messages.isEmpty) {
      return;
    }

    final firstMessage = _messages.first;
    if (firstMessage.isUser ?? true) {
      return;
    }

    setState(() {
      _messages[0] = _ChatMessage(
        text: _buildGreetingMessage(
          AppSession.currentMuseumName.value,
          _useVietnameseReplies,
        ),
        time: _formatTime(DateTime.now()),
        isUser: false,
      );
    });
  }

  static String _buildGreetingMessage(String museumName, bool isVietnamese) {
    if (isVietnamese) {
      return 'Xin chào! Mình là Ogima, hướng dẫn viên cá nhân của bạn tại $museumName. '
          'ình có thể giúp bạn khám phá hiện vật, chỉ đường trong museum, '
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
    }
  }

  Future<void> _openMapFromAction(_ChatAction action) async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
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
    final museum = await _resolveMuseum(text);

    final pendingRouteRequest = _pendingRouteRequest;
    if (pendingRouteRequest != null) {
      return _resolvePendingRouteRequest(
        text: text,
        isVietnamese: _useVietnameseReplies,
        museum: museum,
        request: pendingRouteRequest,
      );
    }

    if (museum != null && _isLocationQuestion(normalized)) {
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

    if (_isDirectionsToPlaceQuestion(normalized) && museum != null) {
      final destination = _extractNavigationSpot(text, museum.id);
      if (destination == null) {
        return _ResolvedReply(
          text: isVietnamese
              ? '${museum.name} hiện không có địa điểm đó trên bản đồ.'
              : '${museum.name} does not have that place on the current map.',
        );
      }
      _pendingRouteRequest = _PendingRouteRequest(
        destination: destination,
        isVietnamese: isVietnamese,
      );
      return _ResolvedReply(
        text: isVietnamese
            ? 'Mình tìm thấy ${destination.name} ở ${destination.floor}. Hiện tại bạn đang ở tầng nào?'
            : 'I found ${destination.name} on ${destination.floor}. Which floor are you on right now?',
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

    if (request.currentFloor == null) {
      final currentFloor = _extractFloorLabel(text);
      if (currentFloor == null) {
        return _ResolvedReply(
          text: isVietnamese
              ? 'Mình chưa xác định được bạn đang ở tầng nào. Bạn hãy trả lời như Floor 1, Floor 2, tầng 1 hoặc tầng 2.'
              : 'I could not identify your current floor. Reply with Floor 1, Floor 2, level 1, or level 2.',
        );
      }

      if (currentFloor != request.destination.floor) {
        _pendingRouteRequest = null;
        final floorInstruction = _buildCrossFloorInstruction(
          fromFloor: currentFloor,
          toFloor: request.destination.floor,
          isVietnamese: isVietnamese,
        );
        final destinationFloorStairs = _findNavigationSpotByName(
          currentMuseumId,
          'Stairs - ${request.destination.floor}',
        );
        final routeStartSpot = destinationFloorStairs ?? request.destination;
        final crossFloorMapAction = _ChatAction(
          type: _ChatActionType.map,
          label: 'View Map',
          icon: Icons.near_me_outlined,
          fromLocationName: routeStartSpot.name,
          toLocationName: request.destination.name,
        );

        return _ResolvedReply(
          text: isVietnamese
              ? '$floorInstruction Sau khi tới ${request.destination.floor}, bạn đi từ ${routeStartSpot.name} đến ${request.destination.name}. Mình đã chuẩn bị sẵn bản đồ 3D với route từ ${routeStartSpot.name} đến ${request.destination.name} ở nút bên dưới.'
              : '$floorInstruction After you reach ${request.destination.floor}, continue from ${routeStartSpot.name} to ${request.destination.name}. I prepared the 3D map with a route from ${routeStartSpot.name} to ${request.destination.name} in the button below.',
          actions: <_ChatAction>[crossFloorMapAction],
          mapAction: crossFloorMapAction,
        );
      }

      _pendingRouteRequest = request.copyWith(currentFloor: currentFloor);
      return _ResolvedReply(
        text: isVietnamese
            ? 'Bạn đang ở $currentFloor. Bạn đang đứng ở điểm nào trên $currentFloor? Ví dụ: Main Entrance, Restroom - $currentFloor hoặc Stairs - $currentFloor.'
            : 'You are on $currentFloor. Which point are you currently standing at on $currentFloor? For example: Main Entrance, Restroom - $currentFloor, or Stairs - $currentFloor.',
      );
    }

    final fromSpot = _extractNavigationSpot(text, currentMuseumId);

    if (fromSpot == null) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'Mình chưa xác định được vị trí hiện tại của bạn trong museum này. Bạn hãy trả lời bằng đúng tên điểm trên map, ví dụ Main Entrance hoặc Restroom - Floor 1.'
            : 'I could not identify your current location in this museum. Reply with an exact place name from the map, for example Main Entrance or Restroom - Floor 1.',
      );
    }

    if (fromSpot.floor != request.currentFloor) {
      return _ResolvedReply(
        text: isVietnamese
            ? '${fromSpot.name} nằm ở ${fromSpot.floor}, chưa khớp với tầng bạn vừa chọn là ${request.currentFloor}. Bạn hãy chọn lại một điểm nằm trên ${request.currentFloor}.'
            : '${fromSpot.name} is on ${fromSpot.floor}, which does not match your selected floor ${request.currentFloor}. Please choose a point on ${request.currentFloor}.',
      );
    }

    _pendingRouteRequest = null;

    if (fromSpot.name == request.destination.name) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'Bạn đang ở ngay ${request.destination.name} rồi.'
            : 'You are already at ${request.destination.name}.',
      );
    }

    final sameFloorMapAction = _ChatAction(
      type: _ChatActionType.map,
      label: 'View Map',
      icon: Icons.near_me_outlined,
      fromLocationName: fromSpot.name,
      toLocationName: request.destination.name,
    );

    if (fromSpot.floor == request.destination.floor) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'Bạn đang ở cùng tầng với ${request.destination.name}. Mình đã chuẩn bị bản đồ 3D với đường đi rõ ràng từ ${fromSpot.name} đến ${request.destination.name} ở nút bên dưới.'
            : 'You are on the same floor as ${request.destination.name}. I prepared the 3D map with a clear route from ${fromSpot.name} to ${request.destination.name} in the button below.',
        actions: <_ChatAction>[sameFloorMapAction],
        mapAction: sameFloorMapAction,
      );
    }

    final floorInstruction = _buildCrossFloorInstruction(
      fromFloor: fromSpot.floor,
      toFloor: request.destination.floor,
      isVietnamese: isVietnamese,
    );

    final destinationFloorStairs = _findNavigationSpotByName(
      currentMuseumId,
      'Stairs - ${request.destination.floor}',
    );
    final routeStartSpot = destinationFloorStairs ?? request.destination;
    final mapAction = _ChatAction(
      type: _ChatActionType.map,
      label: 'View Map',
      icon: Icons.near_me_outlined,
      fromLocationName: routeStartSpot.name,
      toLocationName: request.destination.name,
    );

    return _ResolvedReply(
      text: isVietnamese
          ? '$floorInstruction Sau khi tới ${request.destination.floor}, bạn đi từ ${routeStartSpot.name} đến ${request.destination.name}. Mình đã chuẩn bị sẵn bản đồ 3D với route từ ${routeStartSpot.name} đến ${request.destination.name} ở nút bên dưới.'
          : '$floorInstruction After you reach ${request.destination.floor}, continue from ${routeStartSpot.name} to ${request.destination.name}. I prepared the 3D map with a route from ${routeStartSpot.name} to ${request.destination.name} in the button below.',
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
      'where can i find',
      'way to',
      'navigate to',
      'take me to',
      'go to',
      'get to',
      'chi duong',
      'duong di den',
      'lam sao de toi',
      'lam sao den',
      'toi muon den',
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
        themeNotifier,
      ]),
      builder: (context, _) {
        final quickAccessQuestions = _quickAccessQuestionsForMuseum(
          AppSession.currentMuseumName.value,
        );
        return Scaffold(
          backgroundColor: themeNotifier.backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.home);
                        },
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: themeNotifier.surfaceColor,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: themeNotifier.surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.volume_up_outlined,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.fromLTRB(14, 12, 14, 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeNotifier.borderColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: themeNotifier.surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/model.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Ogima',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: themeNotifier.textPrimaryColor,
                                  ),
                              ),
                              SizedBox(width: 6),
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
                          SizedBox(height: 2),
                          Text(
                            'Your AI companion'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              color: themeNotifier.textSecondaryColor,
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
                    padding: EdgeInsets.fromLTRB(14, 4, 14, 8),
                    itemCount: _messages.length + (_isAiTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isAiTyping && index == _messages.length) {
                        return Padding(
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
                        padding: EdgeInsets.only(bottom: 8),
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
                              SizedBox(height: 8),
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
                              SizedBox(height: 8),
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
                  margin: EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Text(
                    'Quick access buttons:'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: themeNotifier.textSecondaryColor,
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
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      itemCount: quickAccessQuestions.length,
                      separatorBuilder: (_, _) => SizedBox(width: 8),
                      itemBuilder: (_, index) => _QuickQuestionChip(
                        text: quickAccessQuestions[index].tr,
                        onTap: () =>
                            _submitMessage(quickAccessQuestions[index]),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: themeNotifier.backgroundColor,
                    border: Border(top: BorderSide(color: themeNotifier.borderColor)),
                  ),
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Row(
                    children: [
                      _roundIcon(Icons.mic_none),
                      SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 48,
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: themeNotifier.surfaceColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: themeNotifier.borderColor),
                          ),
                          child: TextField(
                            controller: _messageController,
                            onSubmitted: (_) => _submitMessage(),
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: 'Ask me anything...'.tr,
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: themeNotifier.textSecondaryColor,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            textInputAction: TextInputAction.send,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
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
      decoration: BoxDecoration(
        color: themeNotifier.borderColor,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: themeNotifier.textSecondaryColor),
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
    this.fromLocationName,
    this.toLocationName,
  });

  final _ChatActionType type;
  final String label;
  final IconData icon;
  final String? fromLocationName;
  final String? toLocationName;
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
    required this.destination,
    required this.isVietnamese,
    this.currentFloor,
  });

  final _NavigationSpot destination;
  final bool isVietnamese;
  final String? currentFloor;

  _PendingRouteRequest copyWith({
    _NavigationSpot? destination,
    bool? isVietnamese,
    String? currentFloor,
  }) {
    return _PendingRouteRequest(
      destination: destination ?? this.destination,
      isVietnamese: isVietnamese ?? this.isVietnamese,
      currentFloor: currentFloor ?? this.currentFloor,
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
      padding: EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: isUser
            ? Theme.of(context).colorScheme.primary
            : themeNotifier.borderColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text.tr,
            style: TextStyle(
              fontSize: 14,
              color: isUser ? themeNotifier.surfaceColor : themeNotifier.textPrimaryColor,
              height: 1.35,
            ),
          ),
          SizedBox(height: 6),
          Text(
            message.time,
            style: TextStyle(
              fontSize: 11,
              color: isUser
                  ? themeNotifier.surfaceColor.withValues(alpha: 0.85)
                  : themeNotifier.textSecondaryColor,
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
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: themeNotifier.borderColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Ogima is typing...'.tr,
        style: TextStyle(
          fontSize: 12,
          color: themeNotifier.textSecondaryColor,
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
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: themeNotifier.backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: themeNotifier.borderColor),
          ),
          child: Text(
            text.tr,
            style: TextStyle(
              fontSize: 13,
              color: themeNotifier.textPrimaryColor,
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
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: themeNotifier.borderColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: themeNotifier.textPrimaryColor),
            SizedBox(width: 6),
            Text(
              text.tr,
              style: TextStyle(
                fontSize: 14,
                color: themeNotifier.textPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

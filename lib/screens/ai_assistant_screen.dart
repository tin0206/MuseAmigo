import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/font_size_notifier.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/screens/museum_3d_map_screen.dart';
import 'package:museamigo/l10n/artifact_localizer.dart';
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
          'Hôm nay mình có thể hỗ trợ bạn điều gì?';
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
        'Tại $museumName có những triển lãm nào?',
        'Tầng 1 có những hiện vật gì?',
        'Tầng 2 có những triển lãm gì?',
        'Hãy cho tôi biết về hiện vật mã IP-002.',
        'Xe tăng T-54 nằm ở đâu?',
        'Cho tôi thông tin về triển lãm Quyền lực & Quản trị hành pháp.',
        'Cho tôi thông tin về triển lãm Phòng Quân sự & Chiến tranh.',
        'Tại $museumName có những lộ trình tham quan nào?',
        '$museumName nằm ở đâu?',
      ];
    }

    return <String>[
      'What are the operating hours of $museumName?',
      'How much is the ticket at $museumName?',
      'What exhibitions are available at $museumName?',
      'What artifacts are on Floor 1?',
      'What exhibitions are on Floor 2?',
      'Tell me about artifact code IP-002.',
      'Where is Tank T-54?',
      'Tell me about the Presidential Power & Governance exhibition.',
      'Tell me about the Military Rooms & War Relics exhibition.',
      'What routes are available at $museumName?',
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
      final contextActions = resolved.suppressDefaultActions
          ? resolved.actions
          : (resolved.actions.isNotEmpty
                ? resolved.actions
                : _buildContextActions(text));
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

    if (_isAllArtifactsQuestion(normalized)) {
      return actions;
    }

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
          action.value ?? sourceMessage.sourceQuestion ?? sourceMessage.text,
        );
        break;
      case _ChatActionType.artifactRoute:
        await _submitMessage(
          _useVietnameseReplies
              ? 'Chỉ đường đến hiện vật ${action.value ?? sourceMessage.sourceQuestion ?? sourceMessage.text}'
              : 'Navigate to artifact ${action.value ?? sourceMessage.sourceQuestion ?? sourceMessage.text}',
        );
        break;
      case _ChatActionType.schemeOption:
        final color = action.color;
        if (color != null) {
          themeNotifier.setPrimaryColor(color);
          _applySettingsToBackend(
            scheme: (action.value ?? '').replaceFirst('#', ''),
          );
        }
        if (!mounted) return;
        _addBotMessage(
          _useVietnameseReplies
              ? 'Đã chuyển màu scheme sang ${action.label} (${action.value})!'
              : 'Switched scheme color to ${action.label} (${action.value})!',
        );
        break;
      case _ChatActionType.themeOption:
        final themeValue = action.value ?? 'light';
        themeNotifier.setThemeMode(
          themeValue == 'dark' ? ThemeMode.dark : ThemeMode.light,
        );
        _applySettingsToBackend(theme: themeValue);
        if (!mounted) return;
        _addBotMessage(
          _useVietnameseReplies
              ? (themeValue == 'dark'
                    ? 'Đã chuyển sang Dark Theme!'
                    : 'Đã chuyển sang Light Theme!')
              : (themeValue == 'dark'
                    ? 'Switched to Dark Theme!'
                    : 'Switched to Light Theme!'),
        );
        break;
      case _ChatActionType.languageOption:
        final lang = action.value ?? 'English';
        languageNotifier.setLanguage(lang);
        _applySettingsToBackend(language: lang == 'Vietnamese' ? 'vi' : 'en');
        break;
      case _ChatActionType.fontSizeOption:
        final levelName = action.value ?? 'medium';
        final level = FontSizeLevel.values.firstWhere(
          (l) => l.name == levelName,
          orElse: () => FontSizeLevel.medium,
        );
        fontSizeNotifier.setLevel(level);
        _applySettingsToBackend(fontSize: level.name);
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
          autoStartRouteFlow: action.autoStartRouteFlow,
        ),
      ),
    );
  }

  Future<void> _openArtifactFromText(String text) async {
    final artifactCode = _extractArtifactCode(text);

    ArtifactDto? artifact;

    if (artifactCode != null) {
      try {
        artifact = await BackendApi.instance.fetchArtifact(artifactCode);
      } catch (_) {}
    } else {
      final museum = await _resolveMuseum(text);
      if (museum != null) {
        artifact = await _findSpecificArtifactForDetail(
          _normalizeForIntent(text),
          museum.id,
        );
      }
    }

    if (artifact == null) {
      if (!mounted) return;
      await Navigator.of(context).pushNamed(
        AppRoutes.search,
        arguments: {'query': text, 'showResults': true},
      );
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).pushNamed(
      AppRoutes.artifactDetail,
      arguments: {'artifactCode': artifact.artifactCode},
    );
  }

  Future<_ResolvedReply> _resolveReplyForInput(String text) async {
    final normalized = _normalizeForIntent(text);
    final isVietnamese = _useVietnameseReplies;

    // Handle settings intents before any network-dependent logic.
    if (_isSchemeChangeIntent(normalized)) {
      return _buildSchemeReply(normalized, isVietnamese);
    }

    if (_isThemeChangeIntent(normalized)) {
      return _buildThemeReply(normalized, isVietnamese);
    }

    if (_isLanguageChangeIntent(normalized)) {
      return _buildLanguageReply(normalized, isVietnamese);
    }

    if (_isFontSizeChangeIntent(normalized)) {
      return _buildFontSizeReply(normalized, isVietnamese);
    }

    // Handle "view my tickets" intent early – before navigation block,
    // because some navigation keywords (e.g. "show me") can overlap.
    if (_isViewTicketIntent(normalized)) {
      const ticketsAction = _ChatAction(
        type: _ChatActionType.tickets,
        label: 'View My Tickets',
        icon: Icons.confirmation_number_outlined,
      );
      return _ResolvedReply(
        text: isVietnamese
            ? 'Đây là vé của bạn! Nhấn bên dưới để xem chi tiết.'
            : 'Here are your tickets! Tap below to view details.',
        actions: <_ChatAction>[ticketsAction],
      );
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

    // ── Artifact-list queries must be resolved BEFORE the navigation block
    // because "show me" is also a keyword in _isDirectionsToPlaceQuestion.
    if (museum != null && _isAllArtifactsQuestion(normalized)) {
      // Check if the user is asking for artifacts of a specific exhibition
      final exhibitions = await _fetchExhibitions(museum.id);
      final specificEx = _findSpecificExhibition(normalized, exhibitions);
      if (specificEx != null) {
        return await _buildSpecificExhibitionReply(
          exhibition: specificEx,
          museum: museum,
          isVietnamese: isVietnamese,
        );
      }
      final floorLabel = _extractFloorLabel(normalized);
      return await _buildAllArtifactsReply(
        museum: museum,
        isVietnamese: isVietnamese,
        floorLabel: floorLabel,
      );
    }

    if (_isExhibitionQuestion(normalized) && museum != null) {
      final exhibitions = await _fetchExhibitions(museum.id);
      if (exhibitions.isEmpty) {
        return _ResolvedReply(
          text: isVietnamese
              ? 'Hiện chưa có triển lãm nào được liệt kê cho ${museum.name}.'
              : 'There are currently no exhibitions listed for ${museum.name}.',
        );
      }

      // Directions to a specific exhibition should follow the same route flow
      // (ask floor, then current position) as other navigation intents.
      if (_isDirectionsToPlaceQuestion(normalized) &&
          !_isExhibitionListQuestion(normalized)) {
        final specificForRoute = _findSpecificExhibition(
          _extractDirectionTarget(text),
          exhibitions,
        );
        if (specificForRoute != null) {
          final exSpot = _findNavigationSpotByName(
            museum.id,
            specificForRoute.name,
          );
          if (exSpot != null) {
            _pendingRouteRequest = _PendingRouteRequest(
              destination: exSpot,
              isVietnamese: isVietnamese,
            );
            return _ResolvedReply(
              text: isVietnamese
                  ? '${specificForRoute.name} nằm tại ${specificForRoute.location}. Bạn đang ở tầng nào vậy? Bạn có thể trả lời là tầng 1 hoặc tầng 2!'
                  : '${specificForRoute.name} is at ${specificForRoute.location}. Which floor are you on? You can say Floor 1 or Floor 2!',
            );
          }
          return _ResolvedReply(
            text: isVietnamese
                ? '${specificForRoute.name} nằm tại ${specificForRoute.location}.'
                : '${specificForRoute.name} is located at ${specificForRoute.location}.',
          );
        }

        final exhibitionChoices = exhibitions
            .take(6)
            .map((e) => '• ${e.name}')
            .join('\n');
        return _ResolvedReply(
          text: isVietnamese
              ? 'Bạn muốn đến triển lãm nào? Ví dụ:\n$exhibitionChoices'
              : 'Which exhibition would you like to go to? For example:\n$exhibitionChoices',
          suppressDefaultActions: true,
        );
      }

      // Specific exhibition query
      final specific = _findSpecificExhibition(normalized, exhibitions);
      if (specific != null) {
        return await _buildSpecificExhibitionReply(
          exhibition: specific,
          museum: museum,
          isVietnamese: isVietnamese,
        );
      }

      final floorLabel = _extractFloorLabel(normalized);
      return _buildAllExhibitionsReply(
        museum: museum,
        isVietnamese: isVietnamese,
        floorLabel: floorLabel,
      );
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

      // 2b. Pure "where is X" (not a navigation/direction intent) → answer directly.
      if (_isLocationQuestion(normalized) &&
          !_isDirectionsToPlaceQuestion(normalized)) {
        final locTargetRaw = _extractDirectionTarget(text);
        final locTargetNorm = _normalizeForIntent(locTargetRaw);

        // Try artifact code first
        final locCode =
            _extractArtifactCode(locTargetRaw) ?? _extractArtifactCode(text);
        if (locCode != null) {
          ArtifactDto? locArtifact;
          try {
            locArtifact = await BackendApi.instance.fetchArtifact(locCode);
          } catch (_) {}
          if (locArtifact != null) {
            return await _buildArtifactLocationReply(
              locArtifact,
              museum,
              isVietnamese,
            );
          }
          // Fallback: use local exhibition mapping when API unavailable
          final exListForCode = await _fetchExhibitions(museum.id);
          final locExFromCode = _findExhibitionForArtifactCode(
            artifactCode: locCode,
            museumId: museum.id,
            exhibitions: exListForCode,
          );
          if (locExFromCode != null) {
            final exNum = locExFromCode.id - 100;
            final exSpot = _findNavigationSpotByName(
              museum.id,
              locExFromCode.name,
            );
            final floorStr = exSpot?.floor ?? locExFromCode.location;
            return _ResolvedReply(
              text: isVietnamese
                  ? '🏺 Hiện vật $locCode thuộc Triển lãm $exNum — ${locExFromCode.name} ($floorStr).'
                  : '🏺 Artifact $locCode is part of Exhibition $exNum — ${locExFromCode.name} ($floorStr).',
              actions: exSpot != null
                  ? <_ChatAction>[
                      _ChatAction(
                        type: _ChatActionType.map,
                        label: isVietnamese
                            ? 'Chỉ đường đến đây'
                            : 'Navigate there',
                        icon: Icons.near_me_outlined,
                        toLocationName: exSpot.name,
                      ),
                    ]
                  : const <_ChatAction>[],
              suppressDefaultActions: true,
            );
          }
        }

        // Try artifact by name (API-based)
        final locArtifactByName = await _findSpecificArtifactForDetail(
          locTargetNorm,
          museum.id,
        );
        if (locArtifactByName != null) {
          return await _buildArtifactLocationReply(
            locArtifactByName,
            museum,
            isVietnamese,
          );
        }

        // Try nav-spot alias match → resolve to artifact code (handles names like
        // "tank t-54", "xe tang t-54" that map to a known spot with an IP code alias)
        final aliasSpot =
            _extractNavigationSpot(locTargetRaw, museum.id) ??
            _extractNavigationSpot(text, museum.id);
        if (aliasSpot != null) {
          // Check if this spot has an artifact-code alias (e.g. 'ip-002')
          final codeAlias = aliasSpot.aliases
              .where((a) => RegExp(r'^[a-z]{2,4}-\d{3}$').hasMatch(a))
              .firstOrNull;
          if (codeAlias != null) {
            // Normalised alias like 'ip-002' → uppercase 'IP-002'
            final resolvedCode = codeAlias.toUpperCase();
            ArtifactDto? resolvedArtifact;
            try {
              resolvedArtifact = await BackendApi.instance.fetchArtifact(
                resolvedCode,
              );
            } catch (_) {}
            if (resolvedArtifact != null) {
              return await _buildArtifactLocationReply(
                resolvedArtifact,
                museum,
                isVietnamese,
              );
            }
            // API unavailable — use exhibition mapping
            final exListAlias = await _fetchExhibitions(museum.id);
            final exFromAlias = _findExhibitionForArtifactCode(
              artifactCode: resolvedCode,
              museumId: museum.id,
              exhibitions: exListAlias,
            );
            if (exFromAlias != null) {
              final exNum = exFromAlias.id - 100;
              final exSpotAlias = _findNavigationSpotByName(
                museum.id,
                exFromAlias.name,
              );
              final floorStr = exSpotAlias?.floor ?? exFromAlias.location;
              return _ResolvedReply(
                text: isVietnamese
                    ? '🏺 ${aliasSpot.name} ($resolvedCode) thuộc Triển lãm $exNum — ${exFromAlias.name} ($floorStr).'
                    : '🏺 ${aliasSpot.name} ($resolvedCode) is part of Exhibition $exNum — ${exFromAlias.name} ($floorStr).',
                actions: exSpotAlias != null
                    ? <_ChatAction>[
                        _ChatAction(
                          type: _ChatActionType.map,
                          label: isVietnamese
                              ? 'Chỉ đường đến đây'
                              : 'Navigate there',
                          icon: Icons.near_me_outlined,
                          toLocationName: exSpotAlias.name,
                        ),
                      ]
                    : const <_ChatAction>[],
                suppressDefaultActions: true,
              );
            }
          }
        }

        // Try exhibition
        final exListForLoc = await _fetchExhibitions(museum.id);
        final matchedExLoc = _findSpecificExhibition(
          locTargetNorm,
          exListForLoc,
        );
        if (matchedExLoc != null) {
          final exSpot = _findNavigationSpotByName(
            museum.id,
            matchedExLoc.name,
          );
          return _ResolvedReply(
            text: isVietnamese
                ? '🏛 ${matchedExLoc.name} nằm tại ${matchedExLoc.location}.'
                : '🏛 ${matchedExLoc.name} is located at ${matchedExLoc.location}.',
            actions: exSpot != null
                ? <_ChatAction>[
                    _ChatAction(
                      type: _ChatActionType.map,
                      label: isVietnamese
                          ? 'Chỉ đường đến đây'
                          : 'Navigate there',
                      icon: Icons.near_me_outlined,
                      toLocationName: exSpot.name,
                    ),
                  ]
                : const <_ChatAction>[],
            suppressDefaultActions: true,
          );
        }

        // Try navigation spot (stairs, restroom, etc.)
        final locSpot =
            _extractNavigationSpot(locTargetRaw, museum.id) ??
            _extractNavigationSpot(text, museum.id);
        if (locSpot != null) {
          return _ResolvedReply(
            text: isVietnamese
                ? '📍 ${locSpot.name} nằm trên ${locSpot.floor}.'
                : '📍 ${locSpot.name} is on ${locSpot.floor}.',
            actions: <_ChatAction>[
              _ChatAction(
                type: _ChatActionType.map,
                label: isVietnamese ? 'Chỉ đường đến đây' : 'Navigate there',
                icon: Icons.near_me_outlined,
                toLocationName: locSpot.name,
              ),
            ],
            suppressDefaultActions: true,
          );
        }

        // Not found in the museum
        return _ResolvedReply(
          text: isVietnamese
              ? 'Mình không tìm thấy "$locTargetRaw" trong ${museum.name}. Bạn hãy thử tên hiện vật, triển lãm hoặc mã hiện vật (ví dụ: IP-002).'
              : '"$locTargetRaw" was not found in ${museum.name}. Try an artifact name, exhibition name, or artifact code (e.g. IP-002).',
          suppressDefaultActions: true,
        );
      }

      // 3. Artifact route/location intent: mention exhibition, then ask user location.
      final directionTargetRaw = _extractDirectionTarget(text);
      final directionTargetNormalized = _normalizeForIntent(directionTargetRaw);
      final placeArtifactCode =
          _extractArtifactCode(directionTargetRaw) ??
          _extractArtifactCode(text);
      ArtifactDto? artifactForRoute;
      ExhibitionDto? exhibitionFromCode;
      _NavigationSpot? artifactSpotFromCode;
      if (placeArtifactCode != null) {
        final exForCode = await _fetchExhibitions(museum.id);
        exhibitionFromCode = _findExhibitionForArtifactCode(
          artifactCode: placeArtifactCode,
          museumId: museum.id,
          exhibitions: exForCode,
        );
        artifactSpotFromCode = _findNavigationSpotByArtifactCode(
          museum.id,
          placeArtifactCode,
        );
        try {
          artifactForRoute = await BackendApi.instance.fetchArtifact(
            placeArtifactCode,
          );
        } catch (_) {}
      } else if (_isDirectionsToPlaceQuestion(normalized)) {
        artifactForRoute = await _findSpecificArtifactForDetail(
          directionTargetNormalized,
          museum.id,
        );
      }

      // Route directly by specific exhibition phrase inside the direction target.
      if (_isDirectionsToPlaceQuestion(normalized)) {
        final exForTarget = await _fetchExhibitions(museum.id);
        final matchedExFromTarget = _findSpecificExhibition(
          directionTargetNormalized,
          exForTarget,
        );
        if (matchedExFromTarget != null) {
          final exSpot = _findNavigationSpotByName(
            museum.id,
            matchedExFromTarget.name,
          );
          if (exSpot != null) {
            _pendingRouteRequest = _PendingRouteRequest(
              destination: exSpot,
              isVietnamese: isVietnamese,
            );
            return _ResolvedReply(
              text: isVietnamese
                  ? '${matchedExFromTarget.name} nằm tại ${matchedExFromTarget.location}. Bạn đang ở tầng nào vậy? Bạn có thể trả lời là tầng 1 hoặc tầng 2!'
                  : '${matchedExFromTarget.name} is at ${matchedExFromTarget.location}. Which floor are you on? You can say Floor 1 or Floor 2!',
            );
          }
        }
      }

      if (artifactForRoute != null) {
        final exhibition = await _findExhibitionForArtifact(
          artifactForRoute,
          museum.id,
        );
        final artifactSpot = exhibition != null
            ? _findNavigationSpotByName(museum.id, exhibition.name)
            : _findArtifactNavigationSpot(artifactForRoute.title, museum.id);
        if (artifactSpot != null) {
          _pendingRouteRequest = _PendingRouteRequest(
            destination: artifactSpot,
            isVietnamese: isVietnamese,
          );
          final String exhibitionLine;
          if (exhibition != null) {
            final exNum = exhibition.id - 100; // 101→1, 102→2 …
            final exFloor = artifactSpot.floor;
            exhibitionLine = isVietnamese
                ? '🏺 ${artifactForRoute.title.tr} (${artifactForRoute.artifactCode}) thuộc Triển lãm $exNum — ${exhibition.name.tr} ($exFloor).\n'
                      'Mình sẽ hướng dẫn bạn đến triển lãm này. '
                : '🏺 ${artifactForRoute.title} (${artifactForRoute.artifactCode}) is part of Exhibition $exNum — ${exhibition.name} ($exFloor).\n'
                      'I will guide you to that exhibition. ';
          } else {
            exhibitionLine = isVietnamese
                ? '${artifactForRoute.title} (${artifactForRoute.artifactCode}) nằm tại ${artifactSpot.name} (${artifactSpot.floor}). '
                : '${artifactForRoute.title} (${artifactForRoute.artifactCode}) is at ${artifactSpot.name} (${artifactSpot.floor}). ';
          }
          return _ResolvedReply(
            text: isVietnamese
                ? '${exhibitionLine}Bạn đang ở tầng nào vậy? Bạn có thể trả lời là tầng 1 hoặc tầng 2!'
                : '${exhibitionLine}Which floor are you on? You can say Floor 1 or Floor 2!',
          );
        }
      }

      // Fallback for artifact code-based navigation even when artifact detail API lookup fails.
      if (placeArtifactCode != null && artifactSpotFromCode != null) {
        final codeDestination = exhibitionFromCode != null
            ? (_findNavigationSpotByName(museum.id, exhibitionFromCode.name) ??
                  artifactSpotFromCode)
            : artifactSpotFromCode;

        _pendingRouteRequest = _PendingRouteRequest(
          destination: codeDestination,
          isVietnamese: isVietnamese,
        );

        final String intro;
        if (exhibitionFromCode != null) {
          final exNum = exhibitionFromCode.id - 100;
          final exFloor = codeDestination.floor;
          intro = isVietnamese
              ? '🏺 Hiện vật $placeArtifactCode thuộc Triển lãm $exNum — ${exhibitionFromCode.name} ($exFloor).\n'
                    'Mình sẽ hướng dẫn bạn đến triển lãm này. '
              : '🏺 Artifact $placeArtifactCode is part of Exhibition $exNum — ${exhibitionFromCode.name} ($exFloor).\n'
                    'I will guide you to that exhibition. ';
        } else {
          intro = isVietnamese
              ? 'Hiện vật $placeArtifactCode nằm tại ${artifactSpotFromCode.name} (${artifactSpotFromCode.floor}). '
              : 'Artifact $placeArtifactCode is at ${artifactSpotFromCode.name} (${artifactSpotFromCode.floor}). ';
        }

        return _ResolvedReply(
          text: isVietnamese
              ? '${intro}Bạn đang ở tầng nào vậy? Bạn có thể trả lời là tầng 1 hoặc tầng 2!'
              : '${intro}Which floor are you on? You can say Floor 1 or Floor 2!',
        );
      }

      // 4. Known in-museum spot → ask floor first
      final destination =
          _extractNavigationSpot(directionTargetRaw, museum.id) ??
          _extractNavigationSpot(text, museum.id);
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

      // 5. Place not found – try exhibition name before giving up
      try {
        final exForNav = await _fetchExhibitions(museum.id);
        final matchedEx = _findSpecificExhibition(
          directionTargetNormalized,
          exForNav,
        );
        if (matchedEx != null) {
          final exSpot = _findNavigationSpotByName(museum.id, matchedEx.name);
          if (exSpot != null) {
            _pendingRouteRequest = _PendingRouteRequest(
              destination: exSpot,
              isVietnamese: isVietnamese,
            );
            return _ResolvedReply(
              text: isVietnamese
                  ? '${matchedEx.name} nằm tại ${matchedEx.location}. '
                        'Bạn đang ở tầng nào vậy? Bạn có thể trả lời là tầng 1 hoặc tầng 2!'
                  : '${matchedEx.name} is at ${matchedEx.location}. '
                        'Which floor are you on? You can say Floor 1 or Floor 2!',
            );
          }
          return _ResolvedReply(
            text: isVietnamese
                ? '${matchedEx.name} nằm tại ${matchedEx.location}.'
                : '${matchedEx.name} is located at ${matchedEx.location}.',
          );
        }
      } catch (_) {}

      if (_isDirectionsToPlaceQuestion(normalized)) {
        return _ResolvedReply(
          text: isVietnamese
              ? 'Mình chưa xác định được điểm đến. Bạn hãy thử theo mẫu: "Chỉ đường đến IP-002", "Chỉ đường đến Tank T-54" hoặc "Chỉ đường đến triển lãm Fall of Saigon".'
              : 'I could not identify the destination yet. Please try: "Navigate to IP-002", "Show me the way to Tank T-54", or "Navigate to the Fall of Saigon exhibition".',
          suppressDefaultActions: true,
        );
      }

      return _ResolvedReply(
        text: isVietnamese
            ? 'Địa điểm đó không có trong bản đồ của ${museum.name}.'
            : 'That place is not found on the map of ${museum.name}.',
      );
    }

    final artifactCode = _extractArtifactCode(text);

    // Directions to artifact by code → find its navigation spot and start route flow
    if (artifactCode != null &&
        _isDirectionsToPlaceQuestion(normalized) &&
        museum != null) {
      try {
        final artifact = await BackendApi.instance.fetchArtifact(artifactCode);
        final exhibition = await _findExhibitionForArtifact(
          artifact,
          museum.id,
        );
        final spot = exhibition != null
            ? _findNavigationSpotByName(museum.id, exhibition.name)
            : _findArtifactNavigationSpot(artifact.title, museum.id);
        if (spot != null) {
          _pendingRouteRequest = _PendingRouteRequest(
            destination: spot,
            isVietnamese: isVietnamese,
          );
          return _ResolvedReply(
            text: isVietnamese
                ? '${artifact.title.tr} (${artifact.artifactCode})${exhibition != null ? ' thuộc triển lãm ${exhibition.name.tr}.' : ' nằm tại ${spot.name} (${spot.floor}).'} '
                      'Bạn đang ở tầng nào vậy? Bạn có thể trả lời là tầng 1 hoặc tầng 2!'
                : '${artifact.title} (${artifact.artifactCode})${exhibition != null ? ' belongs to the exhibition ${exhibition.name}.' : ' is at ${spot.name} (${spot.floor}).'} '
                      'Which floor are you on? You can say Floor 1 or Floor 2!',
          );
        }
      } catch (_) {
        // fall through to regular artifact info
      }
    }

    ArtifactDto? artifactDetail;
    var triedNameLookup = false;
    if (artifactCode != null) {
      try {
        artifactDetail = await BackendApi.instance.fetchArtifact(artifactCode);
      } catch (_) {
        // Code not found or backend error — fall through to name lookup.
      }
      if (artifactDetail == null && museum != null) {
        triedNameLookup = true;
        artifactDetail = await _findSpecificArtifactForDetail(
          normalized,
          museum.id,
        );
      }
    } else if (museum != null) {
      triedNameLookup = true;
      artifactDetail = await _findSpecificArtifactForDetail(
        normalized,
        museum.id,
      );
    }

    if (artifactDetail != null) {
      return await _buildArtifactDetailReply(
        artifact: artifactDetail,
        museum: museum,
        isVietnamese: isVietnamese,
        showViewDetailButton:
            !_isLocationQuestion(normalized) &&
            !_isDirectionsToPlaceQuestion(normalized),
      );
    }

    // Floor-specific queries: "what exhibitions/artifacts are on Floor 1?"
    if (museum != null && _isFloorSpecificQuery(normalized)) {
      final floorLabel = _extractFloorLabel(normalized);
      if (floorLabel != null) {
        return _buildFloorQueryReply(
          floorLabel: floorLabel,
          museum: museum,
          isVietnamese: isVietnamese,
        );
      }
    }

    if (_isTourSuggestionQuestion(normalized) && museum != null) {
      return await _buildTourSuggestionReply(museum, isVietnamese);
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
          .map(
            (r) =>
                '- ${r.name.tr}: ${r.estimatedTime}, ${r.stopsCount} ${'stops'.tr}',
          )
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

    // Last-resort: check if user mentions a specific exhibition name
    if (museum != null) {
      try {
        final allExhibitions = await _fetchExhibitions(museum.id);
        final specificEx = _findSpecificExhibition(normalized, allExhibitions);
        if (specificEx != null) {
          return await _buildSpecificExhibitionReply(
            exhibition: specificEx,
            museum: museum,
            isVietnamese: isVietnamese,
          );
        }
      } catch (_) {}
    }

    // If we tried to find an artifact by name and found nothing, return a
    // friendly "not found" reply instead of calling the AI backend.
    if (triedNameLookup && museum != null) {
      return _ResolvedReply(
        text: isVietnamese
            ? '${museum.name} không có hiện vật nào khớp với tên đó. '
                  'Bạn có thể thử mã hiện vật (ví dụ: IP-001) hoặc tên khác nhé!'
            : '${museum.name} doesn\'t have an artifact matching that name. '
                  'Try an artifact code (e.g. IP-001) or a different name.',
        suppressDefaultActions: true,
      );
    }

    final aiResult = await BackendApi.instance.askAiWithAction(text);
    final aiActions = <_ChatAction>[];

    if (aiResult.action == 'NAVIGATE') {
      aiActions.add(
        _ChatAction(
          type: _ChatActionType.map,
          label: isVietnamese ? 'Mở bản đồ' : 'Open Map',
          icon: Icons.map_outlined,
        ),
      );
    } else if (aiResult.action == 'SETTINGS_UPDATE') {
      aiActions.addAll(_buildThemeActions());
      aiActions.addAll(_buildLanguageActions());
      aiActions.addAll(_buildFontSizeActions());
    }

    return _ResolvedReply(text: aiResult.reply, actions: aiActions);
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
      'floor a',
      'floor one',
      'first floor',
      '1st floor',
      'tang 1',
      'tang a',
      'tang mot',
      'level 1',
      'level a',
      'khu a',
      'block a',
      'tren tang 1',
      'o tang 1',
    ])) {
      return 'Floor 1';
    }
    if (_containsAny(normalized, <String>[
      'floor 2',
      'floor b',
      'floor two',
      'second floor',
      '2nd floor',
      'tang 2',
      'tang b',
      'tang hai',
      'level 2',
      'level b',
      'khu b',
      'block b',
      'tren tang 2',
      'o tang 2',
    ])) {
      return 'Floor 2';
    }
    return null;
  }

  /// True when user asks for a list of ALL artifacts (optionally filtered by floor).
  static bool _isAllArtifactsQuestion(String text) {
    final hasArtifact = _containsAny(text, <String>[
      'artifact',
      'artifacts',
      'hien vat',
      'cac hien vat',
      'nhung hien vat',
      'danh sach hien vat',
      'list artifact',
      'all artifact',
      'show artifact',
      'show me artifact',
      'liet ke hien vat',
      'hien vat o day',
    ]);
    if (!hasArtifact) return false;
    return _containsAny(text, <String>[
      'all',
      'list',
      'show',
      'danh sach',
      'liet ke',
      'nhung',
      'cac',
      'tat ca',
      'what',
      'which',
      'tell me',
      'give me',
      'show me',
      'museum',
      'bao tang',
      'floor',
      'tang',
      'level',
      'o day',
    ]);
  }

  /// Build a reply listing artifacts, optionally filtered to a specific floor.
  Future<_ResolvedReply> _buildAllArtifactsReply({
    required MuseumDto museum,
    required bool isVietnamese,
    String? floorLabel, // null → all floors
  }) async {
    List<ArtifactDto> artifacts = <ArtifactDto>[];
    try {
      artifacts = await BackendApi.instance.fetchArtifacts(museum.id);
    } catch (_) {}

    if (artifacts.isEmpty) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'Hiện chưa có dữ liệu hiện vật cho ${museum.name}.'
            : 'No artifact data available for ${museum.name}.',
      );
    }

    // If floor requested, filter by navigation spot floor
    List<ArtifactDto> filtered;
    if (floorLabel != null) {
      filtered = artifacts.where((a) {
        final spot = _findArtifactNavigationSpot(a.title, museum.id);
        return spot != null && spot.floor == floorLabel;
      }).toList();
      // Also match by artifact code if spot not found but spot aliases contain code
      if (filtered.isEmpty) {
        // fallback: use navigation spots that are on that floor and match code
        final spots = _museumNavigationSpots[museum.id] ?? <_NavigationSpot>[];
        final floorSpotAliases = spots
            .where((s) => s.floor == floorLabel)
            .expand((s) => s.aliases)
            .toSet();
        filtered = artifacts
            .where(
              (a) => floorSpotAliases.contains(a.artifactCode.toLowerCase()),
            )
            .toList();
      }
    } else {
      filtered = artifacts;
    }

    if (filtered.isEmpty) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'Không tìm thấy hiện vật nào trên ${floorLabel ?? 'tầng này'}.'
            : 'No artifacts found on ${floorLabel ?? 'this floor'}.',
      );
    }

    // Build a reverse map: artifactCode → exhibition name (for Museum 1)
    final Map<String, String> codeToExhibition = <String, String>{};
    if (museum.id == 1) {
      for (final entry in _museum1ExhibitionArtifacts.entries) {
        for (final code in entry.value) {
          codeToExhibition[code] = entry.key;
        }
      }
    }

    final lines = filtered
        .map((a) {
          final exName = codeToExhibition[a.artifactCode];
          final exSuffix = exName != null
              ? (isVietnamese ? ' — $exName' : ' — $exName')
              : '';
          return '• ${a.title} (${a.artifactCode})$exSuffix';
        })
        .join('\n');

    final header = floorLabel != null
        ? (isVietnamese
              ? '🏺 Hiện vật trên $floorLabel tại ${museum.name}:'
              : '🏺 Artifacts on $floorLabel at ${museum.name}:')
        : (isVietnamese
              ? '🏺 Danh sách hiện vật tại ${museum.name} (${filtered.length} hiện vật):'
              : '🏺 All artifacts at ${museum.name} (${filtered.length} artifacts):');
    return _ResolvedReply(
      text: '$header\n$lines',
      suppressDefaultActions: true,
    );
  }

  Future<ArtifactDto?> _findSpecificArtifactForDetail(
    String normalized,
    int museumId,
  ) async {
    // Strip intent words so only the artifact name is matched.
    final nameTarget = _extractInfoTarget(normalized);

    List<ArtifactDto> artifacts = <ArtifactDto>[];
    try {
      artifacts = await BackendApi.instance.fetchArtifacts(museumId);
    } catch (_) {
      return null;
    }

    if (artifacts.isEmpty) {
      return null;
    }

    // Find the artifact whose English or Vietnamese name matches the target.
    final matched = _findSpecificArtifact(nameTarget, artifacts);
    if (matched == null) return null;

    // Fetch the artifact by code for fresh, complete data.
    try {
      return await BackendApi.instance.fetchArtifact(matched.artifactCode);
    } catch (_) {
      return matched;
    }
  }

  static ArtifactDto? _findSpecificArtifact(
    String normalized,
    List<ArtifactDto> artifacts,
  ) {
    const stopwords = <String>{
      'artifact',
      'artifacts',
      'hien',
      'vat',
      'detail',
      'details',
      'about',
      'info',
      'information',
      'chi',
      'tiet',
      'thong',
      'tin',
      've',
      'cua',
      'show',
      'tell',
      'give',
      'xem',
      'cho',
      'toi',
    };

    ArtifactDto? bestMatch;
    var bestScore = 0;
    var bestLength = 0;

    int _scoreCandidate(String candidateTitle) {
      final normalizedCandidate = _normalizeForIntent(candidateTitle);

      if (normalized.contains(normalizedCandidate)) {
        return 1000 + normalizedCandidate.length;
      }

      if (normalizedCandidate.contains(normalized) && normalized.length >= 6) {
        return 900 + normalized.length;
      }

      final titleWords = normalizedCandidate
          .split(RegExp(r'[^a-z0-9]+'))
          .where((word) => word.length > 2 && !stopwords.contains(word))
          .toList();
      if (titleWords.isEmpty) return 0;

      final matchCount = titleWords.where(normalized.contains).length;
      final requiredMatches = titleWords.length == 1
          ? 1
          : (titleWords.length / 2).ceil();
      if (matchCount < requiredMatches) return 0;

      return matchCount * 10 + normalizedCandidate.length;
    }

    for (final artifact in artifacts) {
      // Score both the English title and its Vietnamese translation.
      // translateIn reads from translations.dart — the single source of truth
      // for English→Vietnamese artifact title mappings.
      final viTitle = artifact.title.translateIn('Vietnamese');
      final candidates = viTitle != artifact.title
          ? [artifact.title, viTitle]
          : [artifact.title];

      for (final candidate in candidates) {
        final score = _scoreCandidate(candidate);
        if (score > bestScore) {
          bestScore = score;
          bestLength = _normalizeForIntent(candidate).length;
          bestMatch = artifact;
        }
      }
    }

    return bestMatch;
  }

  Future<ExhibitionDto?> _findExhibitionForArtifact(
    ArtifactDto artifact,
    int museumId,
  ) async {
    final exhibitions = await _fetchExhibitions(museumId);

    if (museumId == 1) {
      for (final entry in _museum1ExhibitionArtifacts.entries) {
        if (!entry.value.contains(artifact.artifactCode)) {
          continue;
        }
        for (final exhibition in exhibitions) {
          if (exhibition.name == entry.key) {
            return exhibition;
          }
        }
      }
    }

    final artifactSpot = _findArtifactNavigationSpot(artifact.title, museumId);
    if (artifactSpot == null) {
      return null;
    }

    for (final exhibition in exhibitions) {
      final exhibitionSpot = _findNavigationSpotByName(
        museumId,
        exhibition.name,
      );
      if (exhibitionSpot != null &&
          exhibitionSpot.floor == artifactSpot.floor) {
        return exhibition;
      }
    }

    return null;
  }

  Future<_ResolvedReply> _buildArtifactLocationReply(
    ArtifactDto artifact,
    MuseumDto museum,
    bool isVietnamese,
  ) async {
    final exhibition = await _findExhibitionForArtifact(artifact, museum.id);
    final exSpot = exhibition != null
        ? _findNavigationSpotByName(museum.id, exhibition.name)
        : _findArtifactNavigationSpot(artifact.title, museum.id);

    final String locationText;
    if (exhibition != null && exSpot != null) {
      final exNum = exhibition.id - 100;
      locationText = isVietnamese
          ? '🏺 ${artifact.title.tr} (${artifact.artifactCode}) thuộc Triển lãm $exNum — ${exhibition.name.tr} (${exSpot.floor}).'
          : '🏺 ${artifact.title} (${artifact.artifactCode}) is part of Exhibition $exNum — ${exhibition.name} (${exSpot.floor}).';
    } else if (exSpot != null) {
      locationText = isVietnamese
          ? '🏺 ${artifact.title.tr} (${artifact.artifactCode}) nằm tại ${exSpot.name} (${exSpot.floor}).'
          : '🏺 ${artifact.title} (${artifact.artifactCode}) is at ${exSpot.name} (${exSpot.floor}).';
    } else {
      locationText = isVietnamese
          ? '🏺 ${artifact.title.tr} (${artifact.artifactCode}) thuộc ${museum.name.tr}.'
          : '🏺 ${artifact.title} (${artifact.artifactCode}) is at ${museum.name}.';
    }

    return _ResolvedReply(
      text: locationText,
      actions: <_ChatAction>[
        _ChatAction(
          type: _ChatActionType.artifactRoute,
          label: isVietnamese ? 'Chỉ đường đến đây' : 'Navigate there',
          icon: Icons.near_me_outlined,
          value: artifact.artifactCode,
        ),
      ],
      suppressDefaultActions: true,
    );
  }

  Future<_ResolvedReply> _buildArtifactDetailReply({
    required ArtifactDto artifact,
    required MuseumDto? museum,
    required bool isVietnamese,
    bool showViewDetailButton = true,
  }) async {
    final spot = museum != null
        ? _findArtifactNavigationSpot(artifact.title, museum.id)
        : null;
    final exhibition = museum != null
        ? await _findExhibitionForArtifact(artifact, museum.id)
        : null;
    final location = spot != null
        ? '${spot.name} (${spot.floor})'
        : (museum?.name ?? (isVietnamese ? 'Chưa rõ' : 'Unknown'));
    final routeTarget = exhibition != null && museum != null
        ? _findNavigationSpotByName(museum.id, exhibition.name)
        : spot;
    final actions = <_ChatAction>[
      if (showViewDetailButton)
        _ChatAction(
          type: _ChatActionType.artifact,
          label: isVietnamese ? 'Xem chi tiết' : 'View Detail',
          icon: Icons.account_balance_outlined,
          value: artifact.artifactCode,
        ),
      _ChatAction(
        type: _ChatActionType.artifactRoute,
        label: isVietnamese ? 'Chỉ đường đến hiện vật' : 'Navigate to Artifact',
        icon: Icons.near_me_outlined,
        value: artifact.artifactCode,
      ),
    ];

    return _ResolvedReply(
      text: isVietnamese
          ? 'Hiện vật: ${artifact.title.tr} (${artifact.artifactCode})\n'
                '${exhibition != null ? 'Triển lãm: ${exhibition.name.tr}\n' : ''}'
                'Năm: ${artifact.year}\n'
                'Vị trí: $location\n'
                'Mô tả: ${ArtifactLocalizer.description(artifact.artifactCode, 'Vietnamese', englishFallback: artifact.description)}'
          : 'Artifact: ${artifact.title} (${artifact.artifactCode})\n'
                '${exhibition != null ? 'Exhibition: ${exhibition.name}\n' : ''}'
                'Year: ${artifact.year}\n'
                'Location: $location\n'
                'Description: ${artifact.description}',
      actions: actions,
      suppressDefaultActions: true,
    );
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
    ]);
  }

  /// Strips common intent words from a query and returns just the subject name.
  /// E.g. "thong tin ve xe tang 390" → "xe tang 390"
  ///      "tell me about tank 390" → "tank 390"
  static String _extractInfoTarget(String normalized) {
    const prefixes = <String>[
      // Vietnamese – longer/more specific first
      'thong tin chi tiet ve ',
      'thong tin ve ',
      'thong tin cua ',
      'cho toi biet ve ',
      'cho toi xem thong tin ve ',
      'cho toi xem ',
      'gioi thieu ve ',
      'mo ta ve ',
      'the nao ve ',
      'noi ve ',
      // English
      'information about ',
      'details about ',
      'tell me about ',
      'info about ',
      'detail about ',
      'what is ',
      'what are ',
      'show me ',
      'about ',
    ];
    for (final prefix in prefixes) {
      final idx = normalized.indexOf(prefix);
      if (idx >= 0) {
        final target = normalized.substring(idx + prefix.length).trim();
        if (target.isNotEmpty) return target;
      }
    }
    return normalized;
  }

  static String _extractDirectionTarget(String text) {
    final normalized = _normalizeForIntent(text);
    final markers = <String>[
      'show me the way to ',
      'how can i get to ',
      'how do i get to ',
      'how can i go to ',
      'how do i go to ',
      'how to get to ',
      'how to reach ',
      'how do i reach ',
      'directions to ',
      'where can i find ',
      'help me find ',
      'lead me to ',
      'take me to ',
      'navigate to ',
      'way to ',
      'go to ',
      'get to ',
      'chi duong den ',
      'huong dan den ',
      'chi toi den ',
      'cho toi den ',
      'di den ',
      'duong den ',
      'duong di den ',
      'lam sao de toi ',
      'lam sao den ',
      'toi muon den ',
      'dan toi den ',
      'dan toi ',
    ];

    for (final marker in markers) {
      if (normalized.contains(marker)) {
        final idx = normalized.indexOf(marker);
        final target = normalized.substring(idx + marker.length).trim();
        if (target.isNotEmpty) {
          return target;
        }
      }
    }
    return normalized;
  }

  _NavigationSpot? _extractNavigationSpot(String text, int museumId) {
    final normalized = _normalizeForIntent(text);
    final spots = _museumNavigationSpots[museumId] ?? const <_NavigationSpot>[];

    _NavigationSpot? bestMatch;
    var bestScore = 0;

    // Pass 1: exact substring alias match.
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

    if (bestMatch != null) {
      return bestMatch;
    }

    // Pass 2: fuzzy word-overlap match for natural phrases like
    // "navigate to tank number 843" where no alias is a direct substring.
    final queryTokens = normalized
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length > 1)
        .toSet();

    for (final spot in spots) {
      final candidateText = [spot.name, ...spot.aliases].join(' ');
      final candidateTokens = _normalizeForIntent(
        candidateText,
      ).split(RegExp(r'[^a-z0-9]+')).where((t) => t.length > 1).toSet();

      final overlap = queryTokens.where(candidateTokens.contains).length;
      if (overlap < 2) {
        continue;
      }

      final score = overlap * 10 + spot.name.length;
      if (score > bestScore) {
        bestScore = score;
        bestMatch = spot;
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

  /// Find the navigation spot that matches an artifact title (for navigation purposes).
  _NavigationSpot? _findArtifactNavigationSpot(
    String artifactTitle,
    int museumId,
  ) {
    final spot = _findNavigationSpotByName(museumId, artifactTitle);
    if (spot != null) return spot;
    final normalizedTitle = _normalizeForIntent(artifactTitle);
    final spots = _museumNavigationSpots[museumId] ?? const <_NavigationSpot>[];
    for (final s in spots) {
      final ns = _normalizeForIntent(s.name);
      if (ns.contains(normalizedTitle) || normalizedTitle.contains(ns)) {
        return s;
      }
    }
    return null;
  }

  /// Returns local exhibitions for museums with hardcoded data, else fetches from API.
  Future<List<ExhibitionDto>> _fetchExhibitions(int museumId) async {
    if (_localExhibitionsMap.containsKey(museumId)) {
      return _localExhibitionsMap[museumId]!;
    }
    return BackendApi.instance.fetchExhibitions(museumId);
  }

  /// Find an exhibition whose name is mentioned in [normalized] query text.
  static ExhibitionDto? _findSpecificExhibition(
    String normalized,
    List<ExhibitionDto> exhibitions,
  ) {
    // Stopwords to ignore when scoring word overlap
    const stopwords = <String>{
      'the', 'a', 'an', 'of', 'in', 'at', 'on', 'and', 'or', 'to', 'for',
      'is', 'are', 'was', 'were', 'be', 'been', 'being', 'with', 'by',
      // Vietnamese stopwords (normalized / diacritic-stripped)
      'cua', 've', 'tai', 'cho', 'va', 'la', 'co', 'cac', 'nhung', 'tren',
      'trong', 'theo', 'thi', 'den', 'duoc', 'nay',
    };

    ExhibitionDto? bestMatch;
    var bestScore = 0;
    var bestLen = 0;

    int scorePhrase(String candidate) {
      if (candidate.isEmpty) {
        return 0;
      }

      if (normalized.contains(candidate)) {
        return 1000 + candidate.length;
      }

      final candidateWords = candidate
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 2 && !stopwords.contains(w))
          .toList();
      if (candidateWords.isEmpty) {
        return 0;
      }

      final matchCount = candidateWords.where(normalized.contains).length;
      final requiredMatches = candidateWords.length == 1
          ? 1
          : (candidateWords.length / 2).ceil();
      if (matchCount < requiredMatches) {
        return 0;
      }

      return matchCount * 10 + candidateWords.length;
    }

    for (final ex in exhibitions) {
      final normalizedName = _normalizeForIntent(ex.name);
      final viAliases = _exhibitionViAliases[ex.name] ?? const <String>[];

      final candidates = <String>[normalizedName, ...viAliases];
      for (final candidate in candidates) {
        final score = scorePhrase(candidate);
        if (score == 0) {
          continue;
        }

        if (score > bestScore) {
          bestScore = score;
          bestLen = candidate.length;
          bestMatch = ex;
        } else if (score == bestScore && candidate.length > bestLen) {
          bestLen = candidate.length;
          bestMatch = ex;
        }
      }
    }
    return bestMatch;
  }

  /// Build a rich reply for a specific exhibition query.
  Future<_ResolvedReply> _buildSpecificExhibitionReply({
    required ExhibitionDto exhibition,
    required MuseumDto museum,
    required bool isVietnamese,
  }) async {
    final spot = _findNavigationSpotByName(museum.id, exhibition.name);
    final actions = <_ChatAction>[];
    if (spot != null) {
      actions.add(
        _ChatAction(
          type: _ChatActionType.map,
          label: isVietnamese ? 'Đến triển lãm này' : 'Go to Exhibition',
          icon: Icons.near_me_outlined,
          toLocationName: spot.name,
        ),
      );
    }

    // Use per-exhibition artifact codes if available (Museum 1),
    // otherwise fall back to floor-based matching.
    final exhibitionCodes = museum.id == 1
        ? _museum1ExhibitionArtifacts[exhibition.name]
        : null;
    String artifactLine = '';
    if (exhibitionCodes != null && exhibitionCodes.isNotEmpty) {
      // Build artifact list from the known codes without an API call
      final codeList = exhibitionCodes.join(', ');
      artifactLine = isVietnamese
          ? '\n🏺 Hiện vật: $codeList'
          : '\n🏺 Artifacts: $codeList';
      // Try to enrich with titles from API
      try {
        final allArtifacts = await BackendApi.instance.fetchArtifacts(
          museum.id,
        );
        final matched = allArtifacts
            .where((a) => exhibitionCodes.contains(a.artifactCode))
            .toList();
        if (matched.isNotEmpty) {
          artifactLine = isVietnamese
              ? '\n🏺 Hiện vật:\n• ${matched.map((a) => '${a.title.tr} (${a.artifactCode})').join('\n• ')}'
              : '\n🏺 Artifacts:\n• ${matched.map((a) => '${a.title} (${a.artifactCode})').join('\n• ')}';
        }
      } catch (_) {}
    } else {
      // Fallback: find artifacts with a spot on the same floor
      try {
        final artifacts = await BackendApi.instance.fetchArtifacts(museum.id);
        final floorArtifacts = artifacts.where((a) {
          final aSpot = _findArtifactNavigationSpot(a.title, museum.id);
          return aSpot != null && spot != null && aSpot.floor == spot.floor;
        }).toList();
        if (floorArtifacts.isNotEmpty) {
          artifactLine = isVietnamese
              ? '\n🏺 Hiện vật:\n• ${floorArtifacts.map((a) => '${a.title.tr} (${a.artifactCode})').join('\n• ')}'
              : '\n🏺 Artifacts:\n• ${floorArtifacts.map((a) => '${a.title} (${a.artifactCode})').join('\n• ')}';
        }
      } catch (_) {}
    }

    final navHint = spot != null
        ? (isVietnamese
              ? '\n\nNhấn bên dưới nếu bạn muốn được hướng dẫn đến đây!'
              : '\n\nTap below if you want to navigate there!')
        : '';

    return _ResolvedReply(
      text: isVietnamese
          ? '🏛 ${exhibition.name.tr}\n📍 Vị trí: ${exhibition.location.tr}$artifactLine$navHint'
          : '🏛 ${exhibition.name}\n📍 Location: ${exhibition.location}$artifactLine$navHint',
      actions: actions,
      suppressDefaultActions: true,
    );
  }

  /// Build a reply listing exhibitions and artifacts on a specific floor.
  Future<_ResolvedReply> _buildFloorQueryReply({
    required String floorLabel,
    required MuseumDto museum,
    required bool isVietnamese,
  }) async {
    final spots =
        _museumNavigationSpots[museum.id] ?? const <_NavigationSpot>[];
    final floorSpots = spots.where((s) => s.floor == floorLabel).toList();

    List<ExhibitionDto> exhibitions = <ExhibitionDto>[];
    List<ArtifactDto> artifacts = <ArtifactDto>[];
    try {
      exhibitions = await _fetchExhibitions(museum.id);
      artifacts = await BackendApi.instance.fetchArtifacts(museum.id);
    } catch (_) {}

    final floorExhibitions = exhibitions
        .where(
          (e) => floorSpots.any(
            (s) => _normalizeForIntent(s.name) == _normalizeForIntent(e.name),
          ),
        )
        .toList();

    final floorArtifacts = artifacts.where((a) {
      final normalizedTitle = _normalizeForIntent(a.title);
      return floorSpots.any((s) {
        final ns = _normalizeForIntent(s.name);
        return ns == normalizedTitle ||
            ns.contains(normalizedTitle) ||
            normalizedTitle.contains(ns);
      });
    }).toList();

    final sb = StringBuffer();
    if (isVietnamese) {
      sb.writeln('$floorLabel tại ${museum.name}:');
      if (floorExhibitions.isNotEmpty) {
        sb.writeln('\n🏛 Triển lãm:');
        for (final e in floorExhibitions) {
          sb.writeln('• ${e.name.tr} (${e.location.tr})');
        }
      }
      if (floorArtifacts.isNotEmpty) {
        sb.writeln('\n🏺 Hiện vật:');
        for (final a in floorArtifacts) {
          sb.writeln('• ${a.title.tr} (${a.artifactCode})');
        }
      }
      if (floorExhibitions.isEmpty && floorArtifacts.isEmpty) {
        sb.writeln('Hiện chưa có thông tin cụ thể về tầng này.');
      }
    } else {
      sb.writeln('$floorLabel at ${museum.name}:');
      if (floorExhibitions.isNotEmpty) {
        sb.writeln('\n🏛 Exhibitions:');
        for (final e in floorExhibitions) {
          sb.writeln('• ${e.name} (${e.location})');
        }
      }
      if (floorArtifacts.isNotEmpty) {
        sb.writeln('\n🏺 Artifacts:');
        for (final a in floorArtifacts) {
          sb.writeln('• ${a.title} (${a.artifactCode})');
        }
      }
      if (floorExhibitions.isEmpty && floorArtifacts.isEmpty) {
        sb.writeln('No specific information available for this floor.');
      }
    }
    return _ResolvedReply(
      text: sb.toString().trim(),
      suppressDefaultActions: true,
    );
  }

  Future<_ResolvedReply> _buildTourSuggestionReply(
    MuseumDto museum,
    bool isVietnamese,
  ) async {
    final mapAction = _ChatAction(
      type: _ChatActionType.map,
      label: isVietnamese ? 'Mở bản đồ 3D' : 'Open 3D Map',
      icon: Icons.map_outlined,
      autoStartRouteFlow: true,
    );

    List<RouteDto> routes = <RouteDto>[];
    try {
      routes = await BackendApi.instance.fetchRoutes(museum.id);
    } catch (_) {
      routes = <RouteDto>[];
    }

    if (routes.isEmpty) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'Hiện chưa có lộ trình tham quan nào cho ${museum.name}. Nhấn bên dưới để mở bản đồ 3D và tự chọn điểm đến.'
            : 'There are currently no suggested routes for ${museum.name}. Tap below to open the 3D map and choose a destination manually.',
        actions: <_ChatAction>[mapAction],
        suppressDefaultActions: true,
      );
    }

    final lines = routes
        .map(
          (r) =>
              '• ${r.name.tr} — ${r.estimatedTime}, ${r.stopsCount} ${'stops'.tr}',
        )
        .join('\n');

    final text = isVietnamese
        ? '🗺 Các lộ trình gợi ý tại ${museum.name}:\n\n$lines\n\nNhấn bên dưới để mở bản đồ 3D và chọn lộ trình phù hợp!'
        : '🗺 Suggested routes at ${museum.name}:\n\n$lines\n\nTap below to open the 3D map and pick a route!';

    return _ResolvedReply(
      text: text,
      actions: <_ChatAction>[mapAction],
      suppressDefaultActions: true,
    );
  }

  Future<_ResolvedReply> _buildAllExhibitionsReply({
    required MuseumDto museum,
    required bool isVietnamese,
    String? floorLabel,
  }) async {
    List<ExhibitionDto> exhibitions = <ExhibitionDto>[];
    try {
      exhibitions = await _fetchExhibitions(museum.id);
    } catch (_) {}

    if (exhibitions.isEmpty) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'Hiện chưa có triển lãm nào được liệt kê cho ${museum.name}.'
            : 'There are currently no exhibitions listed for ${museum.name}.',
        suppressDefaultActions: true,
      );
    }

    final filtered = floorLabel == null
        ? exhibitions
        : exhibitions.where((exhibition) {
            if (_normalizeForIntent(
              exhibition.location,
            ).contains(_normalizeForIntent(floorLabel))) {
              return true;
            }
            final spot = _findNavigationSpotByName(museum.id, exhibition.name);
            return spot != null && spot.floor == floorLabel;
          }).toList();

    if (filtered.isEmpty) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'Không tìm thấy triển lãm nào trên $floorLabel tại ${museum.name}.'
            : 'No exhibitions found on $floorLabel at ${museum.name}.',
        suppressDefaultActions: true,
      );
    }

    final lines = isVietnamese
        ? filtered.map((e) => '• ${e.name.tr} (${e.location.tr})').join('\n')
        : filtered.map((e) => '• ${e.name} (${e.location})').join('\n');
    final header = floorLabel == null
        ? (isVietnamese
              ? '🏛 Các triển lãm tại ${museum.name} (${filtered.length} triển lãm):'
              : '🏛 Exhibitions at ${museum.name} (${filtered.length} exhibitions):')
        : (isVietnamese
              ? '🏛 Các triển lãm trên $floorLabel tại ${museum.name}:'
              : '🏛 Exhibitions on $floorLabel at ${museum.name}:');

    return _ResolvedReply(
      text: '$header\n$lines',
      suppressDefaultActions: true,
    );
  }

  String? _extractArtifactCode(String text) {
    // Dash is required to avoid matching e.g. "Tank 390" as "TANK-390".
    final codeRegex = RegExp(r'\b([A-Za-z]{2,4})\s?-\s?(\d{3})\b');
    final match = codeRegex.firstMatch(text);
    if (match == null) {
      return null;
    }
    final prefix = (match.group(1) ?? '').toUpperCase();
    final number = match.group(2) ?? '';
    if (prefix.isEmpty || number.isEmpty) {
      return null;
    }
    return '$prefix-$number';
  }

  _NavigationSpot? _findNavigationSpotByArtifactCode(
    int museumId,
    String code,
  ) {
    final normalizedCode = _normalizeForIntent(code);
    final compactCode = normalizedCode.replaceAll('-', '');
    final spots = _museumNavigationSpots[museumId] ?? const <_NavigationSpot>[];

    for (final spot in spots) {
      for (final alias in spot.aliases) {
        final normalizedAlias = _normalizeForIntent(alias);
        final compactAlias = normalizedAlias.replaceAll('-', '');
        if (normalizedAlias == normalizedCode || compactAlias == compactCode) {
          return spot;
        }
      }
    }
    return null;
  }

  ExhibitionDto? _findExhibitionForArtifactCode({
    required String artifactCode,
    required int museumId,
    required List<ExhibitionDto> exhibitions,
  }) {
    if (museumId == 1) {
      for (final entry in _museum1ExhibitionArtifacts.entries) {
        if (!entry.value.contains(artifactCode)) {
          continue;
        }
        for (final exhibition in exhibitions) {
          if (exhibition.name == entry.key) {
            return exhibition;
          }
        }
      }
    }

    final spot = _findNavigationSpotByArtifactCode(museumId, artifactCode);
    if (spot == null) {
      return null;
    }

    for (final exhibition in exhibitions) {
      final exSpot = _findNavigationSpotByName(museumId, exhibition.name);
      if (exSpot != null && exSpot.floor == spot.floor) {
        return exhibition;
      }
    }
    return null;
  }

  Future<MuseumDto?> _resolveMuseum(String text) async {
    List<MuseumDto> museums;
    try {
      museums = await BackendApi.instance.fetchMuseums();
    } catch (_) {
      // Backend unreachable — fall back to session context so intent
      // detection (artifact name lookup etc.) can still proceed locally.
      return MuseumDto(
        id: AppSession.currentMuseumId.value,
        name: AppSession.currentMuseumName.value,
        operatingHours: '',
        baseTicketPrice: 0,
        latitude: 0,
        longitude: 0,
      );
    }
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
      'all exhibitions',
      'all exhibits',
      'show all exhibitions',
      'show me all exhibitions',
      'list all exhibitions',
      'what exhibitions',
      'which exhibitions',
      'museum exhibitions',
      'all museums',
      'trien lam',
      'trung bay',
      'khu trung bay',
      'khu trien lam',
      'cac trien lam',
      'cac khu',
      'nhung trien lam',
      'tat ca trien lam',
      'tat ca trung bay',
      'liet ke trien lam',
      'liet ke trung bay',
      'trien lam trong bao tang',
      'tat ca bao tang',
      'danh sach trien lam',
      'list exhibition',
      'list of exhibition',
      'show exhibition',
      'show me exhibition',
      'all exhibition',
    ]);
  }

  static bool _isExhibitionListQuestion(String text) {
    return _containsAny(text, <String>[
      'all exhibitions',
      'all exhibits',
      'show all exhibitions',
      'show me all exhibitions',
      'list all exhibitions',
      'what exhibitions',
      'which exhibitions',
      'list exhibition',
      'list of exhibition',
      'tat ca trien lam',
      'tat ca trung bay',
      'danh sach trien lam',
      'liet ke trien lam',
      'cac trien lam',
      'nhung trien lam',
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

  static bool _isTourSuggestionQuestion(String text) {
    final hasTourKeyword = _containsAny(text, <String>[
      'tour',
      'tours',
      'suggested tour',
      'suggested tours',
      'recommend',
      'recommended',
      'suggestion',
      'suggest',
      'visit plan',
      'sightseeing',
      'quick explorer',
      'deep dive',
      'goi y',
      'de xuat',
      'chuyen tham quan',
      'ke hoach tham quan',
      'lich tham quan',
      'tham quan theo lo trinh',
      'lo trinh goi y',
      'lo trinh de xuat',
      'di tham quan',
      'kham pha nhanh',
      'kham pha sau',
    ]);
    if (hasTourKeyword) return true;
    // "what route should I take / what routes are available"
    return _containsAny(text, <String>[
      'what route',
      'which route',
      'available route',
      'lo trinh nao',
      'nen di theo lo trinh',
      'nen di tuyen nao',
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
      'ticket price',
      'ticket cost',
      'ticket fee',
      'how much',
      'entry fee',
      'admission fee',
      'admission cost',
      'price',
      'gia ve',
      've bao nhieu',
      've vao cong',
      'phi vao cua',
      'tien ve',
      'bao nhieu tien',
    ]);
  }

  static bool _isViewTicketIntent(String text) {
    return _containsAny(text, <String>[
      'my ticket',
      'my tickets',
      'view ticket',
      'view tickets',
      'show ticket',
      'show my ticket',
      'see ticket',
      'see my ticket',
      'check my ticket',
      'open ticket',
      'xem ve',
      'xem ve cua toi',
      've cua toi',
      'kiem tra ve',
      'danh sach ve',
    ]);
  }

  static bool _isFloorSpecificQuery(String normalized) {
    final hasFloor = _containsAny(normalized, <String>[
      'floor 1',
      'floor 2',
      'floor a',
      'floor b',
      'floor one',
      'floor two',
      'tang 1',
      'tang 2',
      'tang a',
      'tang b',
      'tang mot',
      'tang hai',
      'level 1',
      'level 2',
      'level a',
      'level b',
      '1st floor',
      '2nd floor',
      'first floor',
      'second floor',
      'tren tang 1',
      'tren tang 2',
      'o tang 1',
      'o tang 2',
    ]);
    if (!hasFloor) return false;
    return _containsAny(normalized, <String>[
      'exhibition',
      'exhibit',
      'artifact',
      'artifacts',
      'hien vat',
      'trien lam',
      'trung bay',
      'what',
      'which',
      'show',
      'list',
      'all',
      'tell',
      'give',
      'co gi',
      'nhung gi',
      'co nhung gi',
      'o day co',
      'co gi o',
      'danh sach',
      'liet ke',
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
        _isSchemeChangeIntent(normalized) ||
        _isLanguageChangeIntent(normalized) ||
        _isFontSizeChangeIntent(normalized)) {
      return true;
    }
    // View ticket intent
    if (_isViewTicketIntent(normalized)) return true;
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
      // additional Vietnamese
      'duong den',
      'o dau vay',
      'dang o dau',
      'dat o dau',
      'hien vat nay o dau',
      'tim thay o dau',
      'duoc dat o dau',
      'can tim o dau',
      'cho toi biet vi tri',
      'vi tri cua',
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
          'tell me about',
          'cho toi biet ve',
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
    final explicit = _containsAny(normalized, <String>[
      'change theme',
      'switch theme',
      'set theme',
      'update theme',
      'theme settings',
      'doi theme',
      'chuyen theme',
      'thay doi theme',
      'doi giao dien',
      'chuyen giao dien',
      'dark mode',
      'dark theme',
      'night mode',
      'night theme',
      'light mode',
      'light theme',
      'che do toi',
      'giao dien toi',
      'giao dien sang',
      'che do sang',
      'chuyen dark',
      'chuyen light',
      'doi dark',
      'doi light',
      'theme dark',
      'theme light',
      'theme app',
    ]);

    if (explicit) {
      return true;
    }

    final hasAction = _containsAny(normalized, <String>[
      'change',
      'switch',
      'set',
      'update',
      'doi',
      'chuyen',
      'thay doi',
      'muon doi',
      'muon chuyen',
      'want to',
    ]);
    final hasThemeTarget = _containsAny(normalized, <String>[
      'theme',
      'giao dien',
      'dark',
      'light',
      'che do toi',
      'che do sang',
    ]);
    return hasAction && hasThemeTarget;
  }

  static bool _isSchemeChangeIntent(String normalized) {
    final explicit = _containsAny(normalized, <String>[
      'change color',
      'switch color',
      'set color',
      'update color',
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
      'chuyen scheme',
      'doi scheme',
      'thay doi color',
      'thay doi colour',
      'thay doi scheme',
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
      'doi color',
      'doi colour',
      'scheme',
    ]);

    if (explicit) {
      return true;
    }

    final hasAction = _containsAny(normalized, <String>[
      'change',
      'switch',
      'set',
      'update',
      'doi',
      'chuyen',
      'thay doi',
      'muon doi',
      'muon chuyen',
      'want to',
    ]);
    final hasColorTarget = _containsAny(normalized, <String>[
      'color',
      'colour',
      'mau',
      'scheme',
    ]);
    return hasAction && hasColorTarget;
  }

  static bool _isUnsupportedThemeRequest(String normalized) {
    return _containsAny(normalized, <String>['bright mode', 'custom color']);
  }

  static _AppTheme? _detectSpecificScheme(String normalized) {
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

  static String? _detectSpecificThemeMode(String normalized) {
    if (_containsAny(normalized, <String>[
      'dark mode',
      'dark theme',
      'night mode',
      'night theme',
      'theme dark',
      'switch to dark',
      'set dark theme',
      'change to dark',
      'chuyen sang dark',
      'doi sang dark',
      'che do toi',
      'giao dien toi',
    ])) {
      return 'dark';
    }
    if (_containsAny(normalized, <String>[
      'light mode',
      'light theme',
      'theme light',
      'switch to light',
      'set light theme',
      'change to light',
      'chuyen sang light',
      'doi sang light',
      'che do sang',
      'giao dien sang',
    ])) {
      return 'light';
    }
    return null;
  }

  static bool _isLanguageChangeIntent(String normalized) {
    final explicit = _containsAny(normalized, <String>[
      'change language',
      'switch language',
      'set language',
      'update language',
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
      'chuyen sang tieng anh',
      'chuyen sang tieng viet',
      'doi sang tieng anh',
      'doi sang tieng viet',
      'switch to english',
      'switch to vietnamese',
      'set english',
      'set vietnamese',
    ]);

    if (explicit) {
      return true;
    }

    final hasAction = _containsAny(normalized, <String>[
      'change',
      'switch',
      'set',
      'update',
      'doi',
      'chuyen',
      'thay',
      'muon doi',
      'muon chuyen',
      'want to',
    ]);
    final hasLanguageTarget = _containsAny(normalized, <String>[
      'language',
      'ngon ngu',
      'tieng anh',
      'tieng viet',
      'english',
      'vietnamese',
    ]);
    return hasAction && hasLanguageTarget;
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
    if (_containsAny(normalized, <String>[
      'english',
      'tieng anh',
      'switch to english',
      'doi sang tieng anh',
      'chuyen sang tieng anh',
      'set english',
    ])) {
      return 'English';
    }
    if (_containsAny(normalized, <String>[
      'vietnamese',
      'tieng viet',
      'switch to vietnamese',
      'doi sang tieng viet',
      'chuyen sang tieng viet',
      'set vietnamese',
    ])) {
      return 'Vietnamese';
    }
    return null;
  }

  static bool _isFontSizeChangeIntent(String normalized) {
    return _containsAny(normalized, <String>[
      'font size',
      'change font size',
      'change font size text',
      'increase font size',
      'decrease font size',
      'make font bigger',
      'make font smaller',
      'bigger text',
      'smaller text',
      'switch font size',
      'set font size',
      'text size',
      'change text size',
      'set text size',
      'increase text size',
      'decrease text size',
      'font',
      'font size',
      'co chu',
      'kich co chu',
      'kich thuoc chu',
      'tang co chu',
      'giam co chu',
      'tang kich thuoc chu',
      'giam kich thuoc chu',
      'chu to hon',
      'chu nho hon',
      'doi co chu',
      'chuyen co chu',
      'thay co chu',
      'size chu',
      'chu nho',
      'chu to',
    ]);
  }

  static bool _isIncreaseFontSizeIntent(String normalized) {
    return _containsAny(normalized, <String>[
      'increase font size',
      'increase text size',
      'make font bigger',
      'bigger text',
      'text bigger',
      'tang co chu',
      'tang kich thuoc chu',
      'chu to hon',
      'phong to chu',
    ]);
  }

  static bool _isDecreaseFontSizeIntent(String normalized) {
    return _containsAny(normalized, <String>[
      'decrease font size',
      'decrease text size',
      'make font smaller',
      'smaller text',
      'text smaller',
      'giam co chu',
      'giam kich thuoc chu',
      'chu nho hon',
      'thu nho chu',
    ]);
  }

  static FontSizeLevel _nextFontSizeLevel(FontSizeLevel level) {
    switch (level) {
      case FontSizeLevel.small:
        return FontSizeLevel.medium;
      case FontSizeLevel.medium:
        return FontSizeLevel.large;
      case FontSizeLevel.large:
        return FontSizeLevel.large;
    }
  }

  static FontSizeLevel _previousFontSizeLevel(FontSizeLevel level) {
    switch (level) {
      case FontSizeLevel.small:
        return FontSizeLevel.small;
      case FontSizeLevel.medium:
        return FontSizeLevel.small;
      case FontSizeLevel.large:
        return FontSizeLevel.medium;
    }
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
    if (_containsAny(normalized, <String>['small', 'nho', 'chu nho'])) {
      return FontSizeLevel.small;
    }
    if (_containsAny(normalized, <String>['large', 'big', 'lon', 'chu to'])) {
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
            '135 Nam Kỳ Khởi Nghĩa, phường Bến Thành, Thành phố Hồ Chí Minh, Việt Nam',
      ),
      'War Remnants Museum': _MuseumLocationInfo(
        addressEn:
            '28 Vo Van Tan Street, Xuan Hoa Ward, Ho Chi Minh City, Vietnam',
        addressVi:
            '28 Võ Văn Tần, phường Xuân Hòa, Thành phố Hồ Chí Minh, Việt Nam',
      ),
      'HCMC Museum of Fine Arts': _MuseumLocationInfo(
        addressEn:
            '97-97A Pho Duc Chinh Street, Ben Thanh Ward, District 1, Ho Chi Minh City, Vietnam',
        addressVi:
            '97-97A Phố Đức Chính, phường Bến Thành, Quận 1, Thành phố Hồ Chí Minh, Việt Nam',
      ),
      'Ho Chi Minh City Museum': _MuseumLocationInfo(
        addressEn:
            'at the corner of Ly Tu Trong Street and Nam Ky Khoi Nghia Street, near Independence Palace, Ho Chi Minh City, Vietnam',
        addressVi:
            'tại góc đường Lý Tự Trọng và Nam Kỳ Khởi Nghĩa, gần Dinh Độc Lập, Thành phố Hồ Chí Minh, Việt Nam',
      ),
    };

    return locations[museumName];
  }

  String _buildAiReply(String question) {
    final q = question.toLowerCase();
    final isVietnamese = _useVietnameseReplies;
    if (q.contains('toilet') || q.contains('restroom')) {
      return isVietnamese
          ? 'Nhà vệ sinh gần nhất nằm gần Hall C ở Floor 1. Nếu bạn muốn, mình có thể chỉ đường cho bạn.'
          : 'The nearest restroom is near Hall C on Floor 1. I can guide you there if you want.';
    }
    if (q.contains('tank') || q.contains('t-54')) {
      return isVietnamese
          ? 'Tank T-54 nằm ở Hall C, Floor 1. Bạn có thể theo route trên bản đồ và mình sẽ hướng dẫn từng bước cho bạn.'
          : 'Tank T-54 is in Hall C, Floor 1. Follow the map route and I can navigate step-by-step for you.';
    }
    if (q.contains('floor 2')) {
      return isVietnamese
          ? 'Ở Floor 2, các điểm phổ biến gồm Photography Gallery, Peace Memorial, Diplomatic Room và Rooftop Cafe.'
          : 'On Floor 2, popular stops include Photography Gallery, Peace Memorial, Diplomatic Room, and Rooftop Cafe.';
    }
    if (q.contains('coffee') || q.contains('cafe')) {
      return isVietnamese
          ? 'Bạn có thể nghỉ chân tại Cafe Nile ở Floor 1 hoặc Rooftop Cafe ở Floor 2.'
          : 'You can take a break at Cafe Nile on Floor 1 or Rooftop Cafe on Floor 2.';
    }
    return isVietnamese
        ? 'Câu hỏi rất hay. Mình có thể giúp bạn khám phá hiện vật, tìm tiện ích và chỉ đường đến bất kỳ khu vực nào trong bảo tàng.'
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

  void _applySettingsToBackend({
    String? theme,
    String? language,
    String? fontSize,
    String? scheme,
  }) {
    final userId = AppSession.userId.value;
    final resolvedTheme = theme ?? _currentThemeCode();
    final resolvedLanguage = language ?? _currentLanguageCode();
    final resolvedFontSize = fontSize ?? _currentFontSizeCode();
    final resolvedScheme = scheme ?? _currentSchemeHex();

    if (userId == null) {
      return;
    }

    () async {
      try {
        await BackendApi.instance.updateUserSettings(
          userId,
          theme: resolvedTheme,
          language: resolvedLanguage,
          fontSize: resolvedFontSize,
          scheme: resolvedScheme,
        );
      } catch (e, st) {
        debugPrint('[AI_SETTINGS_SYNC] Failed userId=$userId error=$e');
        debugPrint(st.toString());
      }
    }();
  }

  String _currentSchemeHex() {
    final value = themeNotifier.primaryColor.value;
    final rgb = (value & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase();
    return '0xFF$rgb';
  }

  String _currentThemeCode() {
    return themeNotifier.isDarkMode ? 'dark' : 'light';
  }

  String _currentLanguageCode() {
    return languageNotifier.currentLanguage == 'Vietnamese' ? 'vi' : 'en';
  }

  String _currentFontSizeCode() {
    return fontSizeNotifier.level.name;
  }

  List<_ChatAction> _buildSchemeActions() {
    return _appThemes
        .map(
          (t) => _ChatAction(
            type: _ChatActionType.schemeOption,
            label: t.name,
            icon: Icons.circle,
            color: t.color,
            value: t.hex,
          ),
        )
        .toList();
  }

  List<_ChatAction> _buildThemeActions() {
    return [
      _ChatAction(
        type: _ChatActionType.themeOption,
        label: 'Light Theme',
        icon: Icons.light_mode_outlined,
        value: 'light',
      ),
      _ChatAction(
        type: _ChatActionType.themeOption,
        label: 'Dark Theme',
        icon: Icons.dark_mode_outlined,
        value: 'dark',
      ),
    ];
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

  _ResolvedReply _buildSchemeReply(String normalized, bool isVietnamese) {
    if (_isUnsupportedThemeRequest(normalized)) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'App không hỗ trợ theme đó. Dưới đây là các theme màu có sẵn trong app — nhấn để áp dụng:'
            : 'The app doesn\'t support that theme. Here are the available color themes — tap to apply:',
        actions: _buildSchemeActions(),
      );
    }
    final specific = _detectSpecificScheme(normalized);
    if (specific != null) {
      return _ResolvedReply(
        text: isVietnamese
            ? 'Bạn muốn đổi sang màu ${specific.nameVi} (${specific.hex}) đúng không? Chọn trong bảng màu bên dưới để áp dụng nhé!'
            : 'You want ${specific.name} (${specific.hex}), right? Please pick it from the scheme palette below to apply.',
        actions: _buildSchemeActions(),
      );
    }
    return _ResolvedReply(
      text: isVietnamese
          ? 'Dưới đây là các màu scheme có sẵn trong app. Nhấn vào màu bạn muốn để áp dụng ngay!'
          : 'Here are the available scheme colors in the app. Tap one to apply it instantly!',
      actions: _buildSchemeActions(),
    );
  }

  _ResolvedReply _buildThemeReply(String normalized, bool isVietnamese) {
    final specific = _detectSpecificThemeMode(normalized);
    if (specific != null) {
      themeNotifier.setThemeMode(
        specific == 'dark' ? ThemeMode.dark : ThemeMode.light,
      );
      _applySettingsToBackend(theme: specific);
      return _ResolvedReply(
        text: isVietnamese
            ? (specific == 'dark'
                  ? 'Đã chuyển sang Dark Theme!'
                  : 'Đã chuyển sang Light Theme!')
            : (specific == 'dark'
                  ? 'Switched to Dark Theme!'
                  : 'Switched to Light Theme!'),
      );
    }

    return _ResolvedReply(
      text: isVietnamese
          ? 'Theme của app gồm 2 lựa chọn: Light Theme và Dark Theme. Nhấn để đổi ngay:'
          : 'The app theme has 2 options: Light Theme and Dark Theme. Tap to switch:',
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

    if (_isIncreaseFontSizeIntent(normalized)) {
      final current = fontSizeNotifier.level;
      final next = _nextFontSizeLevel(current);
      fontSizeNotifier.setLevel(next);
      _applySettingsToBackend(fontSize: next.name);

      if (current == next) {
        return _ResolvedReply(
          text: isVietnamese
              ? 'Cỡ chữ hiện đã ở mức lớn nhất rồi.'
              : 'Font size is already at the largest level.',
        );
      }

      final label = next == FontSizeLevel.small
          ? (isVietnamese ? 'Nhỏ' : 'Small')
          : next == FontSizeLevel.large
          ? (isVietnamese ? 'Lớn' : 'Large')
          : (isVietnamese ? 'Vừa' : 'Medium');
      return _ResolvedReply(
        text: isVietnamese
            ? 'Đã tăng cỡ chữ lên $label!'
            : 'Increased font size to $label!',
      );
    }

    if (_isDecreaseFontSizeIntent(normalized)) {
      final current = fontSizeNotifier.level;
      final previous = _previousFontSizeLevel(current);
      fontSizeNotifier.setLevel(previous);
      _applySettingsToBackend(fontSize: previous.name);

      if (current == previous) {
        return _ResolvedReply(
          text: isVietnamese
              ? 'Cỡ chữ hiện đã ở mức nhỏ nhất rồi.'
              : 'Font size is already at the smallest level.',
        );
      }

      final label = previous == FontSizeLevel.small
          ? (isVietnamese ? 'Nhỏ' : 'Small')
          : previous == FontSizeLevel.large
          ? (isVietnamese ? 'Lớn' : 'Large')
          : (isVietnamese ? 'Vừa' : 'Medium');
      return _ResolvedReply(
        text: isVietnamese
            ? 'Đã giảm cỡ chữ xuống $label!'
            : 'Decreased font size to $label!',
      );
    }

    final specific = _detectSpecificFontSize(normalized);
    if (specific != null) {
      fontSizeNotifier.setLevel(specific);
      _applySettingsToBackend(fontSize: specific.name);
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
                                                _ChatActionType.schemeOption
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
                    border: Border(
                      top: BorderSide(color: themeNotifier.borderColor),
                    ),
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
                            border: Border.all(
                              color: themeNotifier.borderColor,
                            ),
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

enum _ChatActionType {
  map,
  tickets,
  artifact,
  artifactRoute,
  schemeOption,
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
    this.autoStartRouteFlow = false,
  });

  final _ChatActionType type;
  final String label;
  final IconData icon;
  final String? fromLocationName;
  final String? toLocationName;
  final Color? color;
  final String? value;
  final bool autoStartRouteFlow;
}

class _ResolvedReply {
  const _ResolvedReply({
    required this.text,
    this.actions = const <_ChatAction>[],
    this.mapAction,
    this.suppressDefaultActions = false,
  });

  final String text;
  final List<_ChatAction> actions;
  final _ChatAction? mapAction;
  final bool suppressDefaultActions;
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

// ── Local exhibition data (overrides API for specific museums) ────────────────
// Museum 1 — Independence Palace
const List<ExhibitionDto> _independencePalaceExhibitions = <ExhibitionDto>[
  // Floor 1 — Public & Ceremonial Spaces
  ExhibitionDto(
    id: 101,
    name: 'Fall of Saigon: April 30, 1975',
    location: 'Floor 1 — Public & Ceremonial Spaces',
    museumId: 1,
  ),
  ExhibitionDto(
    id: 102,
    name: 'Presidential Power & Governance',
    location: 'Floor 1 — Public & Ceremonial Spaces',
    museumId: 1,
  ),
  ExhibitionDto(
    id: 103,
    name: 'Diplomacy & State Ceremony',
    location: 'Floor 1 — Public & Ceremonial Spaces',
    museumId: 1,
  ),
  ExhibitionDto(
    id: 104,
    name: 'Presidential Lifestyle',
    location: 'Floor 1 — Public & Ceremonial Spaces',
    museumId: 1,
  ),
  // Floor 2 — War Operations & Secret Infrastructure
  ExhibitionDto(
    id: 105,
    name: 'War Command Bunker',
    location: 'Floor 2 — War Operations & Secret Infrastructure',
    museumId: 1,
  ),
  ExhibitionDto(
    id: 106,
    name: 'Air Warfare & Evacuation',
    location: 'Floor 2 — War Operations & Secret Infrastructure',
    museumId: 1,
  ),
];

/// Maps exhibition name → artifact codes for Museum 1.
const Map<String, List<String>> _museum1ExhibitionArtifacts =
    <String, List<String>>{
      'Fall of Saigon: April 30, 1975': <String>[
        'IP-001',
        'IP-002',
        'IP-007',
        'IP-006',
      ],
      'Presidential Power & Governance': <String>['IP-009', 'IP-015', 'IP-013'],
      'Diplomacy & State Ceremony': <String>['IP-008', 'IP-010'],
      'Presidential Lifestyle': <String>['IP-004', 'IP-012'],
      'War Command Bunker': <String>['IP-005', 'IP-011'],
      'Air Warfare & Evacuation': <String>['IP-003'],
    };

const Map<int, List<ExhibitionDto>> _localExhibitionsMap =
    <int, List<ExhibitionDto>>{1: _independencePalaceExhibitions};

/// Vietnamese keyword aliases for each exhibition (already diacritic-normalized).
/// Keys match exhibition names in [_independencePalaceExhibitions].
const Map<String, List<String>> _exhibitionViAliases = <String, List<String>>{
  'Fall of Saigon: April 30, 1975': <String>[
    'sup do sai gon',
    '30 thang 4',
    'giai phong sai gon',
    'ngay 30 thang 4',
    'tran danh sai gon',
    'sup do',
    'giai phong sai gon: 30 thang 4, 1975',
  ],
  'Presidential Power & Governance': <String>[
    'quyen luc hanh phap',
    'quyen luc & quan tri hanh phap',
    'quan tri hanh phap',
    'quyen hanh hanh phap',
    'phong hop noi cac',
    'noi cac',
    'quan tri quoc gia',
    'quyen luc tong thong',
    'quyen hanh tong thong',
  ],
  'Diplomacy & State Ceremony': <String>[
    'ngoai giao',
    'le nghi quoc gia',
    'le nghi nha nuoc',
    'phong nghi le',
    'le nghi chinh thuc',
    'nghi le quoc gia',
    'ngoai giao & nghi le quoc gia',
  ],
  'Presidential Lifestyle': <String>[
    'doi song sinh hoat tong thong',
    'khong gian sinh hoat tong thong',
    'sinh hoat tong thong',
    'cuoc song sinh hoat tong thong',
    'doi song sinh hoat',
    'noi o tong thong',
    'cuoc song tong thong',
    'doi song tong thong',
    'phong cach song tong thong',
    'noi that tong thong',
    'phong cach song & doi song tong thong',
    'phong cach song & doi song',
  ],
  'War Command Bunker': <String>[
    'ham chi huy',
    'ham ngam chi huy',
    'trung tam chi huy',
    'bo chi huy',
    'ham ngam',
    'bunker',
    'ham chi huy tac chien',
    'ham chi huy chien tranh',
  ],
  'Air Warfare & Evacuation': <String>[
    'khong chien',
    'di tan',
    'cuoc khong kich',
    'may bay truc thang',
    'truc thang',
    'san bay truc thang',
    'mai nha',
    'tac chien khong quan & cuoc di tan',
    'khong chien & di tan',
  ],
};

final Map<int, List<_NavigationSpot>>
_museumNavigationSpots = <int, List<_NavigationSpot>>{
  1: <_NavigationSpot>[
    _spot('Main Entrance', 'Floor 1', <String>[
      'main entrance',
      'entrance',
      'cua chinh',
      'loi vao chinh',
    ]),
    // ── Exhibition 1: Fall of Saigon: April 30, 1975 ──────────────────
    _spot('Fall of Saigon: April 30, 1975', 'Floor 1', <String>[
      'fall of saigon',
      'april 30',
      '30 thang 4',
      'giai phong',
    ]),
    _spot('Tank 390', 'Floor 1', <String>['tank 390', 'xe tang 390', 'ip-001']),
    _spot('Tank T-54 No. 843', 'Floor 1', <String>[
      'tank t-54',
      'xe tang t-54',
      'ip-002',
      't-54',
      '843',
    ]),
    _spot('Jeep M151A2', 'Floor 1', <String>[
      'jeep m151a2',
      'jeep',
      'm151',
      'ip-007',
    ]),
    _spot('F-5E Bombing Marks', 'Floor 1', <String>[
      'f-5e bombing marks',
      'f-5e',
      'bombing marks',
      'ip-006',
    ]),
    // ── Exhibition 2: Presidential Power & Governance ─────────────────
    _spot('Presidential Power & Governance', 'Floor 1', <String>[
      'presidential power',
      'governance',
      'quyen luc tong thong',
    ]),
    _spot('Cabinet Room Table', 'Floor 1', <String>[
      'cabinet room table',
      'cabinet room',
      'ban hop noi cac',
      'ip-009',
    ]),
    _spot('Vice President\'s Desk', 'Floor 1', <String>[
      "vice president's desk",
      'vice president desk',
      'ban pho tong thong',
      'ip-015',
    ]),
    _spot('National Security Council Maps', 'Floor 1', <String>[
      'national security council maps',
      'security council maps',
      'ban do hoi dong an ninh',
      'ip-013',
    ]),
    // ── Exhibition 3: Diplomacy & State Ceremony ──────────────────────
    _spot('Diplomacy & State Ceremony', 'Floor 1', <String>[
      'diplomacy',
      'state ceremony',
      'le nghi quoc gia',
      'ngoai giao',
    ]),
    _spot('Binh Ngo Dai Cao Lacquer Painting', 'Floor 1', <String>[
      'binh ngo dai cao',
      'binh ngo dai cao lacquer painting',
      'tranh son mai binh ngo dai cao',
      'ip-008',
    ]),
    _spot('The Golden Dragon Tapestry', 'Floor 1', <String>[
      'golden dragon tapestry',
      'the golden dragon tapestry',
      'tham rong vang',
      'ip-010',
    ]),
    // ── Exhibition 4: Presidential Lifestyle ─────────────────────────
    _spot('Presidential Lifestyle', 'Floor 1', <String>[
      'presidential lifestyle',
      'cuoc song tong thong',
    ]),
    _spot('Mercedes-Benz 200 W110', 'Floor 1', <String>[
      'mercedes-benz 200 w110',
      'mercedes benz',
      'mercedes',
      'xe mercedes',
      'ip-004',
    ]),
    _spot('The Presidential Bed', 'Floor 1', <String>[
      'presidential bed',
      'the presidential bed',
      'giuong tong thong',
      'ip-012',
    ]),
    // ── Shared Floor 1 facilities ─────────────────────────────────────
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
    // ── Exhibition 5: War Command Bunker ─────────────────────────────
    _spot('War Command Bunker', 'Floor 2', <String>[
      'war command bunker',
      'command bunker',
      'ham chi huy',
    ]),
    _spot('War Command Bunker Map', 'Floor 2', <String>[
      'war command bunker map',
      'command bunker map',
      'ban do ham chi huy',
      'ip-005',
    ]),
    _spot('Telecommunications Center', 'Floor 2', <String>[
      'telecommunications center',
      'telecommunications',
      'trung tam vien thong',
      'ip-011',
    ]),
    // ── Exhibition 6: Air Warfare & Evacuation ────────────────────────
    _spot('Air Warfare & Evacuation', 'Floor 2', <String>[
      'air warfare',
      'evacuation',
      'khong chien',
      'di tan',
    ]),
    _spot('UH-1 Helicopter', 'Floor 2', <String>[
      'uh-1 helicopter',
      'uh-1',
      'uh1',
      'helicopter',
      'truc thang',
      'ip-003',
    ]),
    // ── Shared Floor 2 facilities ─────────────────────────────────────
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
              color: isUser
                  ? themeNotifier.surfaceColor
                  : themeNotifier.textPrimaryColor,
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

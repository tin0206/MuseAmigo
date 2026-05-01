import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:museamigo/main.dart'; // To access globalNavigatorKey
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/session.dart';

// ============================================================================
// DATA MODEL
// ============================================================================

/// Represents a single achievement milestone (e.g. "Scan 1 artifact").
class AchievementMilestone {
  final int id;
  final String name;
  final String description;
  final int requiredScans;
  final int points;
  bool isUnlocked;

  AchievementMilestone({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredScans,
    required this.points,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'requiredScans': requiredScans,
        'points': points,
        'isUnlocked': isUnlocked,
      };

  factory AchievementMilestone.fromJson(Map<String, dynamic> json) =>
      AchievementMilestone(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        requiredScans: json['requiredScans'] ?? 0,
        points: json['points'] ?? 0,
        isUnlocked: json['isUnlocked'] ?? false,
      );
}

/// Holds all progress data for a single museum.
class MuseumProgress {
  final int museumId;
  String museumName;
  Set<int> scannedArtifactIds;
  int totalArtifactCount;
  List<AchievementMilestone> milestones;

  MuseumProgress({
    required this.museumId,
    required this.museumName,
    Set<int>? scannedArtifactIds,
    this.totalArtifactCount = 15,
    List<AchievementMilestone>? milestones,
  })  : scannedArtifactIds = scannedArtifactIds ?? {},
        milestones = milestones ?? _defaultMilestones();

  /// The single source of truth: number of scanned artifacts.
  int get scannedCount => scannedArtifactIds.length;

  /// Total points earned from unlocked milestones.
  int get totalPoints =>
      milestones.where((m) => m.isUnlocked).fold(0, (sum, m) => sum + m.points);

  /// Number of unlocked milestones.
  int get unlockedMilestoneCount =>
      milestones.where((m) => m.isUnlocked).length;

  /// Check and unlock milestones based on current scannedCount.
  List<AchievementMilestone> evaluateMilestones() {
    final newlyUnlocked = <AchievementMilestone>[];
    for (final m in milestones) {
      if (!m.isUnlocked && scannedCount >= m.requiredScans) {
        m.isUnlocked = true;
        newlyUnlocked.add(m);
      }
    }
    return newlyUnlocked;
  }

  static List<AchievementMilestone> _defaultMilestones() => [
        AchievementMilestone(
          id: 1,
          name: 'First Steps',
          description: 'Scan your first artifact',
          requiredScans: 1,
          points: 10,
        ),
        AchievementMilestone(
          id: 2,
          name: 'Explorer',
          description: 'Scan 2 artifacts',
          requiredScans: 2,
          points: 20,
        ),
        AchievementMilestone(
          id: 3,
          name: 'AR Pioneer',
          description: 'Scan 3 artifacts',
          requiredScans: 3,
          points: 30,
        ),
        AchievementMilestone(
          id: 4,
          name: 'Curious Mind',
          description: 'Scan 5 artifacts',
          requiredScans: 5,
          points: 50,
        ),
        AchievementMilestone(
          id: 5,
          name: 'Journey Mapper',
          description: 'Scan 7 artifacts',
          requiredScans: 7,
          points: 70,
        ),
        AchievementMilestone(
          id: 6,
          name: 'Dynasty Master',
          description: 'Scan 10 artifacts',
          requiredScans: 10,
          points: 100,
        ),
        AchievementMilestone(
          id: 7,
          name: 'Museum Expert',
          description: 'Scan all 15 artifacts',
          requiredScans: 15,
          points: 150,
        ),
      ];

  Map<String, dynamic> toJson() => {
        'museumId': museumId,
        'museumName': museumName,
        'scannedArtifactIds': scannedArtifactIds.toList(),
        'totalArtifactCount': totalArtifactCount,
        'milestones': milestones.map((m) => m.toJson()).toList(),
      };

  factory MuseumProgress.fromJson(Map<String, dynamic> json) {
    final milestonesJson = json['milestones'] as List<dynamic>?;
    return MuseumProgress(
      museumId: json['museumId'] as int,
      museumName: json['museumName'] as String? ?? '',
      scannedArtifactIds: (json['scannedArtifactIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toSet() ??
          {},
      totalArtifactCount: json['totalArtifactCount'] as int? ?? 15,
      milestones: milestonesJson != null
          ? milestonesJson
              .map((e) => AchievementMilestone.fromJson(e as Map<String, dynamic>))
              .toList()
          : _defaultMilestones(),
    );
  }
}

// ============================================================================
// STATE MANAGEMENT & CORE LOGIC  (Single Source of Truth)
// ============================================================================

class AchievementNotifier extends ChangeNotifier {
  static const String _storageKeyPrefix = 'museum_progress';

  String get _currentStorageKey {
    final uid = AppSession.userId.value;
    return uid != null ? '${_storageKeyPrefix}_$uid' : _storageKeyPrefix;
  }

  /// Maximum number of artifacts per museum (used for collection progress bar).
  final int maxArtifacts = 15;

  /// Museum ID → MuseumProgress map.
  final Map<int, MuseumProgress> _progressMap = {};

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // ── Computed getters for the CURRENT museum ──

  MuseumProgress? get currentProgress =>
      _progressMap[AppSession.currentMuseumId.value];

  /// Scanned artifact count for current museum (single source of truth).
  int get scannedCount => currentProgress?.scannedCount ?? 0;

  /// Total points for current museum.
  int get totalPoints => currentProgress?.totalPoints ?? 0;

  /// Milestones for current museum.
  List<AchievementMilestone> get milestones =>
      currentProgress?.milestones ?? [];

  /// Unlocked milestone count for current museum.
  int get unlockedMilestoneCount =>
      currentProgress?.unlockedMilestoneCount ?? 0;

  // ── Legacy compatibility: expose list for AchievementsScreen ──

  /// All museum-level progress entries (for the grid in AchievementsScreen).
  List<MuseumProgress> get allProgress => _progressMap.values.toList();

  AchievementNotifier() {
    _initProgress();
    AppSession.userId.addListener(_onUserChanged);
    AppSession.currentMuseumId.addListener(_onMuseumChanged);
  }

  void _onUserChanged() => _initProgress();
  void _onMuseumChanged() => notifyListeners();

  @override
  void dispose() {
    AppSession.userId.removeListener(_onUserChanged);
    AppSession.currentMuseumId.removeListener(_onMuseumChanged);
    super.dispose();
  }

  Future<void> _initProgress() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('[ACHIEVEMENTS] Loading progress data...');
      final museums = await BackendApi.instance.fetchMuseums();

      final prefs = await SharedPreferences.getInstance();
      final String? storedData = prefs.getString(_currentStorageKey);

      Map<int, MuseumProgress> storedMap = {};
      if (storedData != null) {
        final List<dynamic> decoded = jsonDecode(storedData);
        for (var item in decoded) {
          final progress = MuseumProgress.fromJson(item as Map<String, dynamic>);
          storedMap[progress.museumId] = progress;
        }
      }

      _progressMap.clear();
      for (final museum in museums) {
        if (storedMap.containsKey(museum.id)) {
          final existing = storedMap[museum.id]!;
          existing.museumName = museum.name;
          _progressMap[museum.id] = existing;
        } else {
          _progressMap[museum.id] = MuseumProgress(
            museumId: museum.id,
            museumName: museum.name,
          );
        }
      }

      debugPrint('[ACHIEVEMENTS] Progress loaded: ${_progressMap.values.map((p) => "${p.museumName} (scanned: ${p.scannedCount})").toList()}');
      _saveToStorage();
    } catch (e) {
      debugPrint('[ACHIEVEMENTS] Error loading progress: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _progressMap.values.map((p) => p.toJson()).toList(),
    );
    await prefs.setString(_currentStorageKey, encoded);
  }

  // ── INTEGRATION POINT ──

  /// Call this when a user scans an artifact.
  /// [museumId] – the museum the artifact belongs to.
  /// [artifactId] – unique artifact id (used to prevent duplicate counting).
  void recordScan(int museumId, int artifactId) {
    debugPrint('[ACHIEVEMENTS] recordScan: museumId=$museumId, artifactId=$artifactId');

    final progress = _progressMap[museumId];
    if (progress == null) {
      debugPrint('[ACHIEVEMENTS] Warning: Museum ID $museumId not found.');
      return;
    }

    // Avoid duplicate scans
    if (progress.scannedArtifactIds.contains(artifactId)) {
      debugPrint('[ACHIEVEMENTS] Artifact $artifactId already scanned. Skipping.');
      return;
    }

    progress.scannedArtifactIds.add(artifactId);
    debugPrint('[ACHIEVEMENTS] Scanned count for ${progress.museumName}: ${progress.scannedCount}/$maxArtifacts');

    // Evaluate milestones
    final newlyUnlocked = progress.evaluateMilestones();
    for (final m in newlyUnlocked) {
      debugPrint('[ACHIEVEMENTS] UNLOCKED: ${m.name}');
      final context = globalNavigatorKey.currentContext;
      if (context != null) {
        BannerQueue.instance.showBanner(
          context,
          'Achievement Unlocked: ${m.name}',
        );
      }
    }

    _saveToStorage();
    notifyListeners();
  }

  // ── Legacy adapter for old code that calls updateProgress ──
  void updateProgress(int museumId, int artifactId, int addedValue) {
    recordScan(museumId, artifactId);
  }
}

// Global instance for simple access
final achievementNotifier = AchievementNotifier();

// ============================================================================
// UNLOCK BANNER (QUEUE MANAGER & UI)
// ============================================================================

class BannerQueue {
  static final BannerQueue instance = BannerQueue._();
  BannerQueue._();

  final List<String> _queue = [];
  bool _isShowing = false;

  void showBanner(BuildContext context, String message) {
    _queue.add(message);
    if (!_isShowing) {
      _showNext(context);
    }
  }

  void _showNext(BuildContext context) async {
    if (_queue.isEmpty) {
      _isShowing = false;
      return;
    }
    _isShowing = true;
    final message = _queue.removeAt(0);

    final overlay = Overlay.of(context);
    final key = GlobalKey<_AnimatedBannerState>();
    
    final entry = OverlayEntry(
      builder: (context) => AnimatedBanner(key: key, message: message),
    );

    overlay.insert(entry);

    await Future.delayed(const Duration(seconds: 2));
    
    // Reverse animation before removing
    if (key.currentState != null) {
      await key.currentState!.reverse();
    }
    entry.remove();

    _showNext(context);
  }
}

class AnimatedBanner extends StatefulWidget {
  final String message;
  
  const AnimatedBanner({Key? key, required this.message}) : super(key: key);

  @override
  State<AnimatedBanner> createState() => _AnimatedBannerState();
}

class _AnimatedBannerState extends State<AnimatedBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> reverse() async {
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black26, offset: Offset(1, 1))
                      ]
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

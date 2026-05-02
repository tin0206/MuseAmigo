import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

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
  int progress;
  bool isUnlocked;

  AchievementMilestone({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredScans,
    required this.points,
    this.progress = 0,
    this.isUnlocked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'requiredScans': requiredScans,
        'points': points,
        'progress': progress,
        'isUnlocked': isUnlocked,
      };

  factory AchievementMilestone.fromJson(Map<String, dynamic> json) =>
      AchievementMilestone(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        requiredScans: json['requirement_value'] ?? json['requiredScans'] ?? 0,
        points: json['points'] ?? 0,
        progress: json['progress'] ?? 0,
        isUnlocked: json['is_completed'] ?? json['isUnlocked'] ?? false,
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

  static List<AchievementMilestone> _defaultMilestones() => [];

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

      Map<int, MuseumProgress> fetchedMap = {};
      
      final userId = AppSession.userId.value;
      if (userId != null) {
        for (final museum in museums) {
          try {
            final apiAchievements = await BackendApi.instance.fetchUserAchievements(userId, museum.id);
            final milestones = apiAchievements.map((e) => AchievementMilestone.fromJson(e as Map<String, dynamic>)).toList();
            fetchedMap[museum.id] = MuseumProgress(
              museumId: museum.id,
              museumName: museum.name,
              milestones: milestones,
            );
          } catch (e) {
            debugPrint('[ACHIEVEMENTS] Error fetching achievements for museum ${museum.id}: $e');
            // Create empty progress if fetch fails
            fetchedMap[museum.id] = MuseumProgress(
              museumId: museum.id,
              museumName: museum.name,
              milestones: [],
            );
          }
        }
      } else {
        // Fallback for not logged in users (or guest)
        for (final museum in museums) {
          fetchedMap[museum.id] = MuseumProgress(
            museumId: museum.id,
            museumName: museum.name,
            milestones: [],
          );
        }
      }

      _progressMap.clear();
      _progressMap.addAll(fetchedMap);

      debugPrint('[ACHIEVEMENTS] Progress loaded: ${_progressMap.values.map((p) => "${p.museumName} (scanned: ${p.scannedCount})").toList()}');
    } catch (e) {
      debugPrint('[ACHIEVEMENTS] Error loading progress: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── INTEGRATION POINT ──

  /// Call this when a user scans an artifact.
  /// [museumId] – the museum the artifact belongs to.
  /// [artifactId] – unique artifact id (used to prevent duplicate counting).
  Future<void> recordScan(int museumId, int artifactId) async {
    debugPrint('[ACHIEVEMENTS] recordScan: museumId=$museumId, artifactId=$artifactId');

    final progress = _progressMap[museumId];
    if (progress == null) {
      debugPrint('[ACHIEVEMENTS] Warning: Museum ID $museumId not found.');
      return;
    }

    final userId = AppSession.userId.value;
    if (userId != null) {
      // Find incomplete milestones and increment their progress via API
      for (final m in progress.milestones) {
        if (!m.isUnlocked) {
          m.progress += 1; // Increment locally first
          try {
            await BackendApi.instance.updateAchievementProgress(userId, m.id, m.progress);
          } catch (e) {
            debugPrint('[ACHIEVEMENTS] Failed to update progress for achievement ${m.id}: $e');
          }
        }
      }
      
      // Re-fetch from API to ensure sync
      await _initProgress();
    }
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

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
  List<AchievementMilestone> milestones;

  /// These come directly from the API wrapper response.
  int apiTotalPoints;
  int apiUnlockedCount;

  MuseumProgress({
    required this.museumId,
    required this.museumName,
    List<AchievementMilestone>? milestones,
    this.apiTotalPoints = 0,
    this.apiUnlockedCount = 0,
  }) : milestones = milestones ?? [];

  /// Computed from milestones — the highest progress value across all milestones.
  /// Since all milestones track "total scans", the max progress IS the scan count.
  int get scannedCount {
    if (milestones.isEmpty) return 0;
    return milestones.map((m) => m.progress).reduce((a, b) => a > b ? a : b);
  }

  /// Total points earned from unlocked milestones.
  int get totalPoints => apiTotalPoints;

  /// Number of unlocked milestones.
  int get unlockedMilestoneCount => apiUnlockedCount;
}

// ============================================================================
// STATE MANAGEMENT & CORE LOGIC  (Single Source of Truth)
// ============================================================================

class AchievementNotifier extends ChangeNotifier {
  /// Maximum number of artifacts per museum (used for collection progress bar).
  final int maxArtifacts = 15;

  /// Museum ID → MuseumProgress map.  THIS IS THE SINGLE SOURCE OF TRUTH.
  final Map<int, MuseumProgress> _progressMap = {};

  bool _isLoading = true;
  bool _isFetching = false;
  bool get isLoading => _isLoading;

  // ── Computed getters for the CURRENT museum ──

  MuseumProgress? get currentProgress =>
      _progressMap[AppSession.currentMuseumId.value];

  /// Scanned artifact count for current museum.
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

  /// Preload achievements if they haven't been loaded yet.
  Future<void> ensureLoaded() async {
    if (_progressMap.isEmpty) {
      await _initProgress();
    }
  }

  @override
  void dispose() {
    AppSession.userId.removeListener(_onUserChanged);
    AppSession.currentMuseumId.removeListener(_onMuseumChanged);
    super.dispose();
  }

  /// Fetch all achievement data from backend API in parallel.
  Future<void> _initProgress() async {
    if (_isFetching) return;
    _isFetching = true;
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('[ACHIEVEMENTS] Loading progress data...');
      final museums = await BackendApi.instance.fetchMuseums();
      final userId = AppSession.userId.value;

      // Fetch all museum achievements in parallel
      final results = await Future.wait(museums.map((museum) async {
        if (userId == null) {
          return MuseumProgress(
            museumId: museum.id,
            museumName: museum.name,
            milestones: [],
          );
        }
        try {
          final apiResponse = await BackendApi.instance.fetchUserAchievementsRaw(userId, museum.id);
          final achievementsList = apiResponse['achievements'] as List<dynamic>? ?? [];
          final milestones = achievementsList
              .map((e) => AchievementMilestone.fromJson(e as Map<String, dynamic>))
              .toList();
          return MuseumProgress(
            museumId: museum.id,
            museumName: museum.name,
            milestones: milestones,
            apiTotalPoints: apiResponse['total_points'] as int? ?? 0,
            apiUnlockedCount: apiResponse['unlocked_count'] as int? ?? 0,
          );
        } catch (e) {
          debugPrint('[ACHIEVEMENTS] Error fetching achievements for museum ${museum.id}: $e');
          return MuseumProgress(
            museumId: museum.id,
            museumName: museum.name,
            milestones: [],
          );
        }
      }));

      _progressMap.clear();
      for (final p in results) {
        _progressMap[p.museumId] = p;
      }

      debugPrint('[ACHIEVEMENTS] Successfully loaded progress for ${_progressMap.length} museums.');
    } catch (e) {
      debugPrint('[ACHIEVEMENTS] Error loading progress: $e');
    } finally {
      _isFetching = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Public method to force a refresh from API.
  Future<void> refresh() => _initProgress();

  // ── INTEGRATION POINT ──

  /// Call this when a user scans an artifact.
  Future<void> recordScan(int museumId, int artifactId, {int increment = 1}) async {
    debugPrint('[ACHIEVEMENTS] recordScan: museumId=$museumId, artifactId=$artifactId, inc=$increment');

    final progress = _progressMap[museumId];
    if (progress == null) {
      debugPrint('[ACHIEVEMENTS] Warning: Museum ID $museumId not found in progress map.');
      return;
    }

    final userId = AppSession.userId.value;
    if (userId == null) {
      debugPrint('[ACHIEVEMENTS] Warning: No userId found in session.');
      return;
    }

    // Capture current milestones to update them immutably
    final List<AchievementMilestone> currentMilestones = List.from(progress.milestones);
    final List<Future<void>> updateTasks = [];

    for (int i = 0; i < currentMilestones.length; i++) {
      final m = currentMilestones[i];
      if (!m.isUnlocked) {
        final newProgressValue = m.progress + increment;
        
        updateTasks.add(
          BackendApi.instance.updateAchievementProgress(userId, m.id, newProgressValue)
            .then((_) {
              // ── STEP 2: FIX STATE UPDATE AFTER SCAN (CRITICAL) ──
              // Create a NEW milestone instance to ensure the UI detects the change
              final updatedMilestone = AchievementMilestone(
                id: m.id,
                name: m.name,
                description: m.description,
                requiredScans: m.requiredScans,
                points: m.points,
                progress: newProgressValue,
                isUnlocked: newProgressValue >= m.requiredScans,
              );

              // Update the list reference (Immutability pattern)
              currentMilestones[i] = updatedMilestone;
              
              // Update the progress object's internal list reference
              progress.milestones = List.from(currentMilestones);

              if (updatedMilestone.isUnlocked && !m.isUnlocked) {
                progress.apiUnlockedCount += 1;
                progress.apiTotalPoints += updatedMilestone.points;
                
                // Show banner
                final context = globalNavigatorKey.currentContext;
                if (context != null) {
                  BannerQueue.instance.showBanner(context, 'Achievement Unlocked: ${updatedMilestone.name}');
                }
              }

              debugPrint('[ACHIEVEMENTS] Instant UI Sync: Milestone ${m.id} -> $newProgressValue');
              
              // ── STEP 3: FORCE UI REBUILD ──
              notifyListeners(); 
            })
            .catchError((e) {
              debugPrint('[ACHIEVEMENTS] API Update Failed for ${m.id}: $e');
            })
        );
      }
    }

    if (updateTasks.isEmpty) {
      debugPrint('[ACHIEVEMENTS] No locked milestones to update for this museum.');
      return;
    }

    await Future.wait(updateTasks);
    debugPrint('[ACHIEVEMENTS] recordScan completed for all milestones.');
  }

  // ── Legacy adapter for old code that calls updateProgress ──
  Future<void> updateProgress(int museumId, int artifactId, int addedValue) async {
    await recordScan(museumId, artifactId, increment: addedValue);
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

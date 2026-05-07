import 'dart:async';
import 'package:flutter/material.dart';

import 'package:museamigo/app_routes.dart';
import 'package:museamigo/font_size_notifier.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/main.dart'; // To access globalNavigatorKey
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/session.dart';
import 'package:museamigo/theme_notifier.dart';

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
        id: json['id'] is int
            ? json['id']
            : int.tryParse(json['id'].toString()) ?? 0,
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        requiredScans: json['requirement_value'] ?? json['requiredScans'] ?? 0,
        points: json['points'] ?? 0,
        progress: json['progress'] ?? 0,
        isUnlocked: json['is_completed'] ?? json['isUnlocked'] ?? false,
      );

  /// Create a copy with updated progress/unlock state.
  AchievementMilestone copyWith({int? progress, bool? isUnlocked}) =>
      AchievementMilestone(
        id: id,
        name: name,
        description: description,
        requiredScans: requiredScans,
        points: points,
        progress: progress ?? this.progress,
        isUnlocked: isUnlocked ?? this.isUnlocked,
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
  int get unlockedMilestoneCount =>
      milestones.where((m) => m.isUnlocked).length;
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

  /// Track which userId the data was loaded for (detects stale data).
  int? _loadedForUserId;
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

  void _onUserChanged() {
    // User changed — force reload even if a fetch is in progress
    _isFetching = false;
    _initProgress();
  }

  void _onMuseumChanged() => notifyListeners();

  /// Preload achievements if they haven't been loaded yet or data is stale.
  Future<void> ensureLoaded() async {
    final currentUserId = AppSession.userId.value;
    // Reload if: no data, OR data was loaded for a different user
    if (_progressMap.isEmpty || _loadedForUserId != currentUserId) {
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
      final results = await Future.wait(
        museums.map((museum) async {
          if (userId == null) {
            return MuseumProgress(
              museumId: museum.id,
              museumName: museum.name,
              milestones: [],
            );
          }
          try {
            final apiResponse = await BackendApi.instance
                .fetchUserAchievementsRaw(userId, museum.id);
            final achievementsList =
                apiResponse['achievements'] as List<dynamic>? ?? [];
            final milestones = achievementsList
                .map(
                  (e) =>
                      AchievementMilestone.fromJson(e as Map<String, dynamic>),
                )
                .toList();

            return MuseumProgress(
              museumId: museum.id,
              museumName: museum.name,
              milestones: milestones,
              apiTotalPoints: apiResponse['total_points'] as int? ?? 0,
              apiUnlockedCount: apiResponse['unlocked_count'] as int? ?? 0,
            );
          } catch (e) {
            debugPrint(
              '[ACHIEVEMENTS] Error fetching achievements for museum ${museum.id}: $e',
            );
            return MuseumProgress(
              museumId: museum.id,
              museumName: museum.name,
              milestones: [],
            );
          }
        }),
      );

      _progressMap.clear();
      for (final p in results) {
        _progressMap[p.museumId] = p;
      }
      _loadedForUserId = userId;

      debugPrint(
        '[ACHIEVEMENTS] Successfully loaded progress for ${_progressMap.length} museums.',
      );
    } catch (e) {
      debugPrint('[ACHIEVEMENTS] Error loading progress: $e');
    } finally {
      _isFetching = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Public method to force a refresh from API.
  Future<void> refresh() {
    _isFetching = false; // Allow re-fetch
    return _initProgress();
  }

  // ── INTEGRATION POINT ──

  /// Unified handler for achievement progress update after any scan.
  /// Called by BOTH QR scan and manual code input paths.
  ///
  /// Flow: API update → local state patch → notifyListeners() → UI rebuilds.
  Future<void> recordScan(
    int museumId,
    int artifactId, {
    int increment = 1,
  }) async {
    debugPrint(
      '[ACHIEVEMENTS] recordScan START: museumId=$museumId, artifactId=$artifactId, inc=$increment',
    );

    final progress = _progressMap[museumId];
    if (progress == null) {
      debugPrint(
        '[ACHIEVEMENTS] Warning: Museum ID $museumId not found in progress map. Keys: ${_progressMap.keys}',
      );
      return;
    }

    final userId = AppSession.userId.value;
    if (userId == null) {
      debugPrint('[ACHIEVEMENTS] Warning: No userId found in session.');
      return;
    }

    // Identify milestones that need updating
    final toUpdate = <int>[]; // indices
    for (int i = 0; i < progress.milestones.length; i++) {
      if (!progress.milestones[i].isUnlocked) {
        toUpdate.add(i);
      }
    }

    if (toUpdate.isEmpty) {
      debugPrint(
        '[ACHIEVEMENTS] No locked milestones to update for museum $museumId.',
      );
      return;
    }

    debugPrint('[ACHIEVEMENTS] Updating ${toUpdate.length} milestones...');

    // Process updates in parallel, but apply state changes safely
    final List<_PendingUpdate> pendingUpdates = [];

    // Prepare all updates
    for (final idx in toUpdate) {
      final m = progress.milestones[idx];
      final newProgressValue = m.progress + increment;
      pendingUpdates.add(
        _PendingUpdate(index: idx, milestone: m, newProgress: newProgressValue),
      );
    }

    // Fire all API calls in parallel
    final futures = pendingUpdates.map((pu) async {
      try {
        await BackendApi.instance.updateAchievementProgress(
          userId,
          pu.milestone.id,
          pu.newProgress,
        );
        pu.succeeded = true;
        debugPrint(
          '[ACHIEVEMENTS] API OK: milestone ${pu.milestone.id} -> ${pu.newProgress}',
        );
      } catch (e) {
        debugPrint('[ACHIEVEMENTS] API FAIL: milestone ${pu.milestone.id}: $e');
      }
    });

    await Future.wait(futures);

    // Now apply ALL successful updates to local state in one batch
    final List<AchievementMilestone> newMilestones = List.from(
      progress.milestones,
    );
    final List<AchievementMilestone> newlyUnlocked = [];
    int addedPoints = 0;
    int addedUnlocks = 0;

    for (final pu in pendingUpdates) {
      // OPTIMISTIC UPDATE: We apply the new progress regardless of whether the specific
      // PATCH request succeeded, because addToCollection may have already updated the backend
      // and caused the PATCH to return a duplicate/no-op error.
      final wasUnlocked = pu.milestone.isUnlocked;
      final nowUnlocked = pu.newProgress >= pu.milestone.requiredScans;

      // Create NEW milestone object (immutable update)
      newMilestones[pu.index] = pu.milestone.copyWith(
        progress: pu.newProgress,
        isUnlocked: nowUnlocked,
      );

      if (nowUnlocked && !wasUnlocked) {
        addedUnlocks++;
        addedPoints += pu.milestone.points;
        newlyUnlocked.add(newMilestones[pu.index]);
      }
    }

    // Replace the milestones list reference on the progress object
    progress.milestones = newMilestones;
    progress.apiUnlockedCount += addedUnlocks;
    progress.apiTotalPoints += addedPoints;

    debugPrint(
      '[ACHIEVEMENTS] State updated. Scanned: ${progress.scannedCount}, Unlocked: ${progress.unlockedMilestoneCount}/${progress.milestones.length}',
    );

    // FORCE UI REBUILD — single notification after all state is consistent
    notifyListeners();

    // Show unlock banners
    for (final m in newlyUnlocked) {
      debugPrint('[ACHIEVEMENTS] UNLOCKED: ${m.name}');
      final ctx = globalNavigatorKey.currentContext;
      if (ctx != null) {
        BannerQueue.instance.showBanner(ctx, 'Achievement Unlocked: ${m.name}');
      }
    }

    // Check if ALL milestones are now unlocked → show museum badge popup
    final allUnlocked =
        newlyUnlocked.isNotEmpty &&
        progress.milestones.every((m) => m.isUnlocked);
    if (allUnlocked) {
      await Future.delayed(const Duration(milliseconds: 600));
      _showMuseumBadgeDialog(progress.museumName);
    }

    debugPrint('[ACHIEVEMENTS] recordScan COMPLETE.');
  }

  // ── Legacy adapter for old code that calls updateProgress ──
  Future<void> updateProgress(
    int museumId,
    int artifactId,
    int addedValue,
  ) async {
    await recordScan(museumId, artifactId, increment: addedValue);
  }

  /// Show a dialog congratulating the user for collecting all badges of a museum.
  void _showMuseumBadgeDialog(String museumName) {
    final ctx = globalNavigatorKey.currentContext;
    if (ctx == null) return;
    showDialog<void>(
      context: ctx,
      barrierDismissible: true,
      builder: (_) => ListenableBuilder(
        listenable: Listenable.merge([
          themeNotifier,
          fontSizeNotifier,
          languageNotifier,
        ]),
        builder: (dialogCtx, _) {
          final primary = themeNotifier.primaryColor;
          final scale = fontSizeNotifier.scale;
          return Dialog(
            backgroundColor: themeNotifier.surfaceColor,
            insetPadding: EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: themeNotifier.surfaceColor,
                      size: 46,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '🎉 ${"Congratulations!".tr}',
                    style: TextStyle(
                      fontSize: 26 * scale,
                      fontWeight: FontWeight.w800,
                      color: themeNotifier.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15 * scale,
                        color: const Color(0xFF4B5563),
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: '${"You've earned the museum badge of".tr}\n',
                        ),
                        TextSpan(
                          text: museumName,
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16 * scale,
                          ),
                        ),
                        TextSpan(text: '!'),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogCtx, rootNavigator: true).pop();
                        globalNavigatorKey.currentState?.pushNamed(
                          AppRoutes.achievements,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: themeNotifier.surfaceColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        'View Badge'.tr,
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Internal helper for batching parallel updates.
class _PendingUpdate {
  final int index;
  final AchievementMilestone milestone;
  final int newProgress;
  bool succeeded = false;

  _PendingUpdate({
    required this.index,
    required this.milestone,
    required this.newProgress,
  });
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

    final overlay = globalNavigatorKey.currentState?.overlay;
    if (overlay == null) {
      // If we can't find an overlay, just discard the banner and continue
      _showNext(context);
      return;
    }

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

  const AnimatedBanner({super.key, required this.message});

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
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
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
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: themeNotifier.surfaceColor, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: themeNotifier.surfaceColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black26, offset: Offset(1, 1)),
                      ],
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

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

class MuseumAchievement {
  final int id;
  String name;
  int progress;
  bool isUnlocked;
  Set<int> scannedArtifactIds;

  MuseumAchievement({
    required this.id,
    required this.name,
    this.progress = 0,
    this.isUnlocked = false,
    Set<int>? scannedArtifactIds,
  }) : scannedArtifactIds = scannedArtifactIds ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'progress': progress,
        'isUnlocked': isUnlocked,
        'scannedArtifactIds': scannedArtifactIds.toList(),
      };

  factory MuseumAchievement.fromJson(Map<String, dynamic> json) =>
      MuseumAchievement(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
        name: json['name'],
        progress: json['progress'] ?? 0,
        isUnlocked: json['isUnlocked'] ?? false,
        scannedArtifactIds: (json['scannedArtifactIds'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toSet() ??
            {},
      );
}

// ============================================================================
// STATE MANAGEMENT & CORE LOGIC
// ============================================================================

class AchievementNotifier extends ChangeNotifier {
  static const String _storageKey = 'user_achievements';
  
  String get _currentStorageKey {
    final uid = AppSession.userId.value;
    return uid != null ? '${_storageKey}_$uid' : _storageKey;
  }

  final int unlockThreshold = 15;
  
  List<MuseumAchievement> _achievements = [];
  List<MuseumAchievement> get achievements => _achievements;
  
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AchievementNotifier() {
    _initAchievements();
    AppSession.userId.addListener(_onUserChanged);
  }

  void _onUserChanged() {
    _initAchievements();
  }

  @override
  void dispose() {
    AppSession.userId.removeListener(_onUserChanged);
    super.dispose();
  }

  Future<void> _initAchievements() async {
    try {
      debugPrint('[ACHIEVEMENTS] Fetching museum list from source...');
      final museums = await BackendApi.instance.fetchMuseums();
      debugPrint('[ACHIEVEMENTS] Museums loaded: ${museums.map((m) => "${m.name} (${m.id})").toList()}');

      final prefs = await SharedPreferences.getInstance();
      final String? storedData = prefs.getString(_currentStorageKey);
      
      Map<int, MuseumAchievement> storedMap = {};
      if (storedData != null) {
        final List<dynamic> decoded = jsonDecode(storedData);
        for (var item in decoded) {
          final ach = MuseumAchievement.fromJson(item);
          storedMap[ach.id] = ach;
        }
      }

      _achievements = [];
      for (final museum in museums) {
        if (storedMap.containsKey(museum.id)) {
          final existing = storedMap[museum.id]!;
          existing.name = museum.name; // Keep name synced
          _achievements.add(existing);
        } else {
          _achievements.add(
            MuseumAchievement(id: museum.id, name: museum.name),
          );
        }
      }

      debugPrint('[ACHIEVEMENTS] Mapped achievements: ${_achievements.map((a) => "${a.name} (Progress: ${a.progress}, Unlocked: ${a.isUnlocked})").toList()}');
      
      _saveToStorage();
    } catch (e) {
      debugPrint('[ACHIEVEMENTS] Error loading museum data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData =
        jsonEncode(_achievements.map((e) => e.toJson()).toList());
    await prefs.setString(_currentStorageKey, encodedData);
  }

  // INTEGRATION POINT
  void updateProgress(int museumId, int artifactId, int addedValue) {
    debugPrint('[ACHIEVEMENTS] Received progress update: museumId=$museumId, artifactId=$artifactId, addedValue=$addedValue');
    
    final index = _achievements.indexWhere((m) => m.id == museumId);
    if (index == -1) {
      debugPrint('[ACHIEVEMENTS] Warning: Museum ID $museumId not found in achievements map.');
      return;
    }

    final achievement = _achievements[index];

    // Avoid duplicate scans for the same artifact
    if (achievement.scannedArtifactIds.contains(artifactId)) {
      debugPrint('[ACHIEVEMENTS] Artifact $artifactId already scanned for ${achievement.name}. Skipping.');
      return;
    }

    // Avoid updating if already unlocked (but still track the artifact)
    achievement.scannedArtifactIds.add(artifactId);
    
    if (achievement.isUnlocked) {
      debugPrint('[ACHIEVEMENTS] Achievement already unlocked for ${achievement.name}. Skipping progress update.');
      _saveToStorage();
      return;
    }

    achievement.progress += addedValue;
    debugPrint('[ACHIEVEMENTS] Progress for ${achievement.name} is now ${achievement.progress} / $unlockThreshold');

    if (achievement.progress >= unlockThreshold && !achievement.isUnlocked) {
      achievement.progress = unlockThreshold; // Cap at max
      achievement.isUnlocked = true;
      debugPrint('[ACHIEVEMENTS] UNLOCK TRIGGERED for ${achievement.name}!');
      
      // Trigger Banner
      final context = globalNavigatorKey.currentContext;
      if (context != null) {
        BannerQueue.instance.showBanner(
          context,
          'Achievement Unlocked: ${achievement.name}',
        );
      }
    }

    _saveToStorage();
    notifyListeners();
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

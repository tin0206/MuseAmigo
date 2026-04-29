import 'package:flutter/material.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/session.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Map<String, dynamic>> _achievements = [];
  int _totalPoints = 0;
  int _totalUnlocked = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _isLoading = true);
    try {
      final userId = AppSession.userId.value;
      if (userId == null) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      final data = await BackendApi.instance.fetchUserAchievements(userId);
      print('Fetched ${data["achievements"]?.length ?? 0} achievements');
      setState(() {
        _achievements = List<Map<String, dynamic>>.from(data['achievements'] ?? []);
        _totalPoints = data['total_points'] ?? 0;
        _totalUnlocked = _achievements.where((a) => a['is_completed'] == true).length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load achievements: $e';
        _isLoading = false;
      });
    }
  }

  IconData _getIconForAchievement(String requirementType) {
    switch (requirementType) {
      case 'scan_count':
        return Icons.qr_code_scanner;
      case 'museum_scan_count':
        return Icons.museum;
      case 'museum_visit':
        return Icons.location_on;
      case 'all_museums':
        return Icons.public;
      case 'area_complete':
        return Icons.emoji_events;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF171A21),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Achievements'.tr,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAchievements,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Points'.tr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFFFCDD2),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_totalPoints',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unlocked'.tr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_totalUnlocked/${_achievements.length}',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF171A21),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Achievements list
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Text(
                                  'All Achievements'.tr,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF171A21),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_achievements.length} Total',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...List.generate(_achievements.length, (i) {
                            final achievement = _achievements[i];
                            final isCompleted = achievement['is_completed'] == true;
                            final progress = achievement['progress'] ?? 0;
                            final requirementValue = achievement['requirement_value'] ?? 0;
                            final requirementType = achievement['requirement_type'] ?? '';
                            
                            return _AchievementRow(
                              title: achievement['name'] ?? 'Unknown',
                              description: achievement['description'] ?? '',
                              points: achievement['points'] ?? 0,
                              unlocked: isCompleted,
                              icon: _getIconForAchievement(requirementType),
                              progress: progress,
                              maxProgress: requirementValue,
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.title,
    required this.description,
    required this.points,
    required this.unlocked,
    required this.icon,
    required this.progress,
    required this.maxProgress,
  });

  final String title;
  final String description;
  final int points;
  final bool unlocked;
  final IconData icon;
  final int progress;
  final int maxProgress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: unlocked
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              unlocked ? icon : Icons.lock_outline,
              size: 20,
              color: unlocked ? Colors.white : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: unlocked
                              ? const Color(0xFF171A21)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                    if (!unlocked && maxProgress > 0)
                      Text(
                        '$progress/$maxProgress',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
                if (!unlocked && maxProgress > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxProgress > 0 ? progress / maxProgress : 0,
                        backgroundColor: const Color(0xFFF3F4F6),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+$points',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: unlocked
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

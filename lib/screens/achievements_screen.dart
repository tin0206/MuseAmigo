import 'package:flutter/material.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/achievement_notifier.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

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
      body: ListenableBuilder(
        listenable: achievementNotifier,
        builder: (context, child) {
          final achievements = achievementNotifier.achievements;
          final threshold = achievementNotifier.unlockThreshold;

          if (achievementNotifier.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (achievements.isEmpty) {
            return const Center(child: Text('No achievements available.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return AchievementBadge(
                achievement: achievement,
                threshold: threshold,
              );
            },
          );
        },
      ),
    );
  }
}

class AchievementBadge extends StatelessWidget {
  final MuseumAchievement achievement;
  final int threshold;

  const AchievementBadge({
    Key? key,
    required this.achievement,
    required this.threshold,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool unlocked = achievement.isUnlocked;
    final double progressPercent = (achievement.progress / threshold).clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: unlocked ? Colors.amber.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: unlocked ? Colors.amber.shade400 : const Color(0xFFE5E7EB),
          width: 2,
        ),
        boxShadow: unlocked
            ? [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
            : [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.6,
        child: ColorFiltered(
          colorFilter: unlocked
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : const ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]), // Grayscale filter
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  unlocked ? Icons.museum : Icons.lock_outline,
                  size: 48,
                  color: unlocked ? Colors.amber.shade700 : const Color(0xFF9CA3AF),
                ),
                const SizedBox(height: 12),
                Text(
                  achievement.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: unlocked ? Colors.brown.shade800 : const Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      unlocked ? Colors.green : Theme.of(context).colorScheme.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${achievement.progress} / $threshold',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: unlocked ? Colors.green.shade700 : const Color(0xFF6B7280),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

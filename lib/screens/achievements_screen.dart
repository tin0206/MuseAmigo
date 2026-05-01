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
          if (achievementNotifier.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProgress = achievementNotifier.allProgress;
          if (allProgress.isEmpty) {
            return const Center(child: Text('No achievements available.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: allProgress.length,
            itemBuilder: (context, index) {
              final progress = allProgress[index];
              // A museum is "unlocked" if all artifacts have been scanned
              final unlocked = progress.scannedCount >= achievementNotifier.maxArtifacts;
              return AchievementBadge(
                museumName: progress.museumName,
                scannedCount: progress.scannedCount,
                maxArtifacts: achievementNotifier.maxArtifacts,
                unlocked: unlocked,
              );
            },
          );
        },
      ),
    );
  }
}

/// Achievement badge with 2-layer trophy icon system.
///
/// Layer 1 (Background): trophy_lock.png or trophy_unlock.png
/// Layer 2 (Overlay): lock icon, only visible when locked
class AchievementBadge extends StatelessWidget {
  final String museumName;
  final int scannedCount;
  final int maxArtifacts;
  final bool unlocked;

  const AchievementBadge({
    Key? key,
    required this.museumName,
    required this.scannedCount,
    required this.maxArtifacts,
    required this.unlocked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double progressPercent = (scannedCount / maxArtifacts).clamp(0.0, 1.0);

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
            ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
            : [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── 2-Layer Trophy Icon ──
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Layer 1: Background Trophy Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Image.asset(
                        unlocked
                            ? 'assets/images/Trophy_Unlock.jpg'
                            : 'assets/images/Trophy_Lock.jpg',
                        key: ValueKey(unlocked),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        opacity: AlwaysStoppedAnimation(unlocked ? 1.0 : 0.5),
                      ),
                    ),
                  ),
                  // Layer 2: Lock Icon Overlay (only when locked)
                  if (!unlocked)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock,
                          size: 32,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              museumName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
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
            const SizedBox(height: 6),
            Text(
              '$scannedCount / $maxArtifacts',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: unlocked ? Colors.green.shade700 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

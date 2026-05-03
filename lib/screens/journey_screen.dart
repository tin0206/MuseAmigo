import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/session.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/achievement_notifier.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  @override
  void initState() {
    super.initState();
    achievementNotifier.ensureLoaded();
    achievementNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    achievementNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  IconData _getIconForMilestone(int requiredScans) {
    if (requiredScans <= 1) return Icons.qr_code_scanner;
    if (requiredScans <= 3) return Icons.explore;
    if (requiredScans <= 5) return Icons.psychology;
    if (requiredScans <= 7) return Icons.map;
    if (requiredScans <= 10) return Icons.emoji_events;
    return Icons.star;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([languageNotifier, achievementNotifier]),
      builder: (context, _) {
        // ── STEP 4: REMOVE STALE DATA SOURCES (ONLY READ FROM NOTIFIER) ──
        final totalPoints = achievementNotifier.totalPoints;
        final milestones = achievementNotifier.milestones;
        final unlockedMilestones = milestones
            .where((m) => m.isUnlocked)
            .toList();
        final scanned = unlockedMilestones.isEmpty
            ? 0
            : unlockedMilestones
                  .map((m) => m.requiredScans)
                  .reduce((a, b) => a > b ? a : b);
        final unlockedCount = milestones.where((m) => m.isUnlocked).length;

        final maxArtifacts = achievementNotifier.maxArtifacts;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Journey'.tr,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF171A21),
                              ),
                            ),
                            const SizedBox(height: 2),
                            ValueListenableBuilder<String>(
                              valueListenable: AppSession.currentMuseumName,
                              builder: (context, name, _) {
                                return Text(
                                  name.tr,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showFinishJourneyDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: Text(
                          'Finish journey'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '$scanned',
                          label: 'Artifacts Discovered'.tr,
                          active: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          value: '$totalPoints',
                          label: 'Points Earned'.tr,
                          active: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProgressCard(
                    unlockedCount: unlockedCount,
                    maxArtifacts: maxArtifacts,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Achievements'.tr,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF171A21),
                          ),
                        ),
                      ),
                      Text(
                        '${unlockedCount}/${milestones.length}',

                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (achievementNotifier.isLoading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: milestones.length,
                        itemBuilder: (context, index) {
                          final milestone = milestones[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AchievementTile(
                              title: milestone.name.tr,
                              subtitle: milestone.description.tr,
                              points: milestone.isUnlocked
                                  ? '+${milestone.points} ${'points'.tr}'
                                  : '${milestone.progress}/${milestone.requiredScans}',
                              icon: _getIconForMilestone(
                                milestone.requiredScans,
                              ),
                              unlocked: milestone.isUnlocked,
                              progress: milestone.requiredScans > 0
                                  ? (milestone.progress /
                                            milestone.requiredScans)
                                        .clamp(0.0, 1.0)
                                  : 0.0,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFinishJourneyDialog(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF0A1A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Are you sure?'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF171A21),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'If you leave, you will not able to re-enter without a new ticket or you will have to contact the museum\'s manager for further assistance.'
                        .tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF2F343C),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE3E3E5),
                            foregroundColor: const Color(0xFF171A21),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Cancel'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF0A1A),
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: const Color(0x33FF0A1A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Leave'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (leave == true && context.mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.exploreMap);
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.active,
  });

  final String value;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context).colorScheme.primary
            : const Color(0xFFE5E5E7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: active
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.unlockedCount,
    required this.maxArtifacts,
  });

  final int unlockedCount;
  final int maxArtifacts;

  double get _progressValue =>
      unlockedCount >= maxArtifacts ? 1.0 : unlockedCount / maxArtifacts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Collection Progress'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171A21),
                  ),
                ),
              ),
              Text(
                '$unlockedCount/$maxArtifacts',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: _progressValue,
                backgroundColor: const Color(0xFFD6D8DD),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Expanded(flex: 2, child: SizedBox()),
                _ProgressStep(
                  label: '2',
                  icon: unlockedCount >= 2
                      ? Icons.emoji_events_outlined
                      : Icons.lock_outline,
                  active: unlockedCount >= 2,
                ),
                const Expanded(flex: 3, child: SizedBox()),
                _ProgressStep(
                  label: '5',
                  icon: unlockedCount >= 5
                      ? Icons.emoji_events_outlined
                      : Icons.lock_outline,
                  active: unlockedCount >= 5,
                ),
                const Expanded(flex: 5, child: SizedBox()),
                _ProgressStep(
                  label: '10',
                  icon: unlockedCount >= 10
                      ? Icons.emoji_events_outlined
                      : Icons.lock_outline,
                  active: unlockedCount >= 10,
                ),
                const Expanded(flex: 5, child: SizedBox()),
                _ProgressStep(
                  label: '15',
                  icon: unlockedCount >= 15
                      ? Icons.emoji_events_outlined
                      : Icons.lock_outline,
                  active: unlockedCount >= 15,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.label,
    required this.icon,
    required this.active,
  });

  final String label;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: active
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFFD8DADE),
          child: Icon(
            icon,
            size: 13,
            color: active ? Colors.white : const Color(0xFF8C93A1),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.icon,
    required this.unlocked,
    required this.progress,
  });

  final String title;
  final String subtitle;
  final String points;
  final IconData icon;
  final bool unlocked;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final borderColor = unlocked
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFFE5E5E7);
    final titleColor = unlocked
        ? Theme.of(context).colorScheme.primary
        : const Color(0xFF9CA3AF);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : const Color(0xFFE5E5E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: unlocked
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFFD9DCE2),
            child: Icon(
              icon,
              color: unlocked ? Colors.white : const Color(0xFF9CA3AF),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                if (!unlocked) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFD6D8DD),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (unlocked)
            Text(
              points,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Text(
              points,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

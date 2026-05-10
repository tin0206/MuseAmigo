import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/session.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/achievement_notifier.dart';
import 'package:museamigo/theme_notifier.dart';

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
      listenable: Listenable.merge([
        languageNotifier,
        achievementNotifier,
        themeNotifier,
      ]),
      builder: (context, _) {
        // ── STEP 4: REMOVE STALE DATA SOURCES (ONLY READ FROM NOTIFIER) ──
        final totalPoints = achievementNotifier.totalPoints;
        final milestones = achievementNotifier.milestones;
        final scanned = achievementNotifier.scannedCount;
        final unlockedCount = milestones.where((m) => m.isUnlocked).length;

        final maxArtifacts = achievementNotifier.maxArtifacts;

        return Scaffold(
          backgroundColor: themeNotifier.backgroundColor,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
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
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: themeNotifier.textPrimaryColor,
                              ),
                            ),
                            SizedBox(height: 2),
                            ValueListenableBuilder<String>(
                              valueListenable: AppSession.currentMuseumName,
                              builder: (context, name, _) {
                                return Text(
                                  name.tr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: themeNotifier.textSecondaryColor,
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
                          foregroundColor: themeNotifier.surfaceColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        icon: Icon(Icons.logout_rounded, size: 16),
                        label: Text(
                          'Finish journey'.tr,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '$scanned',
                          label: 'Artifacts Discovered'.tr,
                          active: true,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          value: '$totalPoints',
                          label: 'Points Earned'.tr,
                          active: false,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _ProgressCard(
                    unlockedCount: unlockedCount,
                    maxArtifacts: maxArtifacts,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Achievements'.tr,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: themeNotifier.textPrimaryColor,
                          ),
                        ),
                      ),
                      Text(
                        '$unlockedCount/${milestones.length}',

                        style: TextStyle(
                          fontSize: 14,
                          color: themeNotifier.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  if (achievementNotifier.isLoading)
                    Expanded(child: Center(child: CircularProgressIndicator()))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: milestones.length,
                        itemBuilder: (context, index) {
                          final milestone = milestones[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8),
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
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final primary = scheme.primary;

        return Dialog(
          backgroundColor: scheme.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    icon: Icon(
                      Icons.close,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: primary,
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
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'If you leave, you will not able to re-enter without a new ticket or you will have to contact the museum\'s manager for further assistance.'
                          .tr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: scheme.onSurface.withValues(alpha: 0.82),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary.withValues(alpha: 0.1),
                              foregroundColor: primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Cancel'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: scheme.onPrimary,
                              elevation: 2,
                              shadowColor: primary.withValues(alpha: 0.25),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Leave'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
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
        );
      },
    );

    if (leave == true && context.mounted) {
      AppSession.activeMuseumVisit.value = false;
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context).colorScheme.primary
            : themeNotifier.borderColor,
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
                  ? themeNotifier.surfaceColor
                  : Theme.of(context).colorScheme.primary,
              height: 1,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active
                  ? themeNotifier.surfaceColor
                  : themeNotifier.textSecondaryColor,
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeNotifier.borderColor,
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: themeNotifier.textPrimaryColor,
                  ),
                ),
              ),
              Text(
                '$unlockedCount/$maxArtifacts',
                style: TextStyle(
                  fontSize: 11,
                  color: themeNotifier.textSecondaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: _progressValue,
                backgroundColor: themeNotifier.borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(flex: 2, child: SizedBox()),
                _ProgressStep(
                  label: '2',
                  icon: unlockedCount >= 2
                      ? Icons.emoji_events_outlined
                      : Icons.lock_outline,
                  active: unlockedCount >= 2,
                ),
                Expanded(flex: 3, child: SizedBox()),
                _ProgressStep(
                  label: '5',
                  icon: unlockedCount >= 5
                      ? Icons.emoji_events_outlined
                      : Icons.lock_outline,
                  active: unlockedCount >= 5,
                ),
                Expanded(flex: 5, child: SizedBox()),
                _ProgressStep(
                  label: '10',
                  icon: unlockedCount >= 10
                      ? Icons.emoji_events_outlined
                      : Icons.lock_outline,
                  active: unlockedCount >= 10,
                ),
                Expanded(flex: 5, child: SizedBox()),
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
              : themeNotifier.borderColor,
          child: Icon(
            icon,
            size: 13,
            color: active
                ? themeNotifier.surfaceColor
                : themeNotifier.textSecondaryColor,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: themeNotifier.textSecondaryColor,
          ),
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
        : themeNotifier.borderColor;
    final titleColor = unlocked
        ? Theme.of(context).colorScheme.primary
        : themeNotifier.textSecondaryColor;

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: unlocked
            ? themeNotifier.surfaceColor
            : themeNotifier.borderColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: unlocked
                ? Theme.of(context).colorScheme.primary
                : themeNotifier.borderColor,
            child: Icon(
              icon,
              color: unlocked
                  ? themeNotifier.surfaceColor
                  : themeNotifier.textSecondaryColor,
              size: 18,
            ),
          ),
          SizedBox(width: 10),
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
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeNotifier.textSecondaryColor,
                  ),
                ),
                if (!unlocked) ...[
                  SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: themeNotifier.borderColor,
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
              style: TextStyle(
                fontSize: 11,
                color: themeNotifier.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/l10n/translations.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    child: Text(
                      'My Journey'.tr,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF171A21),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showFinishJourneyDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
                      value: '12',
                      label: 'Artifacts Discovered'.tr,
                      active: true,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      value: '1250',
                      label: 'Points Earned'.tr,
                      active: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ProgressCard(),
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
                  const Text(
                    '5/15',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: [
                    _AchievementTile(
                      title: 'First Steps'.tr,
                      subtitle: 'Visit your first artifact'.tr,
                      points: '+50 points',
                      icon: Icons.star_border_rounded,
                      unlocked: true,
                    ),
                    const SizedBox(height: 8),
                    _AchievementTile(
                      title: 'Explorer'.tr,
                      subtitle: 'Discover 10 artifacts'.tr,
                      points: '+150 points',
                      icon: Icons.emoji_events_outlined,
                      unlocked: true,
                    ),
                    const SizedBox(height: 8),
                    _AchievementTile(
                      title: 'AR Pioneer'.tr,
                      subtitle: 'View 5 artifacts in AR'.tr,
                      points: '+200 points',
                      icon: Icons.bolt_outlined,
                      unlocked: true,
                    ),
                    const SizedBox(height: 8),
                    _AchievementTile(
                      title: 'Curious Mind'.tr,
                      subtitle: 'Ask 20 questions to AI'.tr,
                      points: '+100 points',
                      icon: Icons.workspace_premium_outlined,
                      unlocked: true,
                    ),
                    const SizedBox(height: 8),
                    _AchievementTile(
                      title: 'Journey Mapper'.tr,
                      subtitle: 'Complete a full floor tour.'.tr,
                      points: '+250 points',
                      icon: Icons.map_outlined,
                      unlocked: true,
                    ),
                    const SizedBox(height: 8),
                    _AchievementTile(
                      title: 'Dynasty Master'.tr,
                      subtitle: 'Discover all artifacts from one dynasty'.tr,
                      points: '',
                      icon: Icons.auto_awesome_outlined,
                      unlocked: false,
                    ),
                    const SizedBox(height: 8),
                    _AchievementTile(
                      title: 'Museum Expert'.tr,
                      subtitle: 'Discover 25 artifacts'.tr,
                      points: '',
                      icon: Icons.military_tech_outlined,
                      unlocked: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
  const _ProgressCard();

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
                '12/50',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: 0.24,
              backgroundColor: Color(0xFFD6D8DD),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ProgressStep(
                label: '5',
                icon: Icons.emoji_events_outlined,
                active: true,
              ),
              _ProgressStep(
                label: '10',
                icon: Icons.emoji_events_outlined,
                active: true,
              ),
              _ProgressStep(
                label: '25',
                icon: Icons.lock_outline,
                active: false,
              ),
              _ProgressStep(
                label: '50',
                icon: Icons.lock_outline,
                active: false,
              ),
            ],
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
  });

  final String title;
  final String subtitle;
  final String points;
  final IconData icon;
  final bool unlocked;

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
            const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}

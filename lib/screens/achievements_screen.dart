import 'package:flutter/material.dart';

// Data model
class _Achievement {
  const _Achievement({
    required this.title,
    required this.points,
    required this.description,
    required this.unlocked,
    required this.icon,
  });

  final String title;
  final int points;
  final String description;
  final bool unlocked;
  final IconData icon;
}

class _Museum {
  const _Museum({
    required this.name,
    required this.location,
    required this.totalPoints,
    required this.unlocked,
    required this.total,
    required this.achievements,
  });

  final String name;
  final String location;
  final int totalPoints;
  final int unlocked;
  final int total;
  final List<_Achievement> achievements;
}

final _museums = [
  _Museum(
    name: 'National Museum of Ancient Art',
    location: 'Gallery Hall A',
    totalPoints: 600,
    unlocked: 4,
    total: 5,
    achievements: [
      _Achievement(
        title: 'First Steps',
        points: 100,
        description: 'Visit your first artifact',
        unlocked: true,
        icon: Icons.star_outline,
      ),
      _Achievement(
        title: 'Explorer',
        points: 150,
        description: 'Discover 10 artifacts',
        unlocked: true,
        icon: Icons.explore_outlined,
      ),
      _Achievement(
        title: 'AR Pioneer',
        points: 200,
        description: 'View 5 artifacts in AR',
        unlocked: true,
        icon: Icons.view_in_ar_outlined,
      ),
      _Achievement(
        title: 'Journey Mapper',
        points: 150,
        description: 'Complete a full floor tour',
        unlocked: true,
        icon: Icons.map_outlined,
      ),
      _Achievement(
        title: 'Dynasty Master',
        points: 400,
        description: 'Discover all artifacts. New discovery',
        unlocked: false,
        icon: Icons.emoji_events_outlined,
      ),
    ],
  ),
  _Museum(
    name: 'Contemporary Art Gallery',
    location: 'Exhibition Floor 3',
    totalPoints: 0,
    unlocked: 2,
    total: 4,
    achievements: [
      _Achievement(
        title: 'Modern Eye',
        points: 100,
        description: 'View 5 contemporary artworks',
        unlocked: true,
        icon: Icons.remove_red_eye_outlined,
      ),
      _Achievement(
        title: 'Art Critic',
        points: 150,
        description: 'Rate 10 artworks',
        unlocked: true,
        icon: Icons.rate_review_outlined,
      ),
      _Achievement(
        title: 'Curator',
        points: 200,
        description: 'Save 20 artworks to favorites',
        unlocked: false,
        icon: Icons.bookmark_border,
      ),
      _Achievement(
        title: 'Gallery Master',
        points: 350,
        description: 'Complete the full gallery tour',
        unlocked: false,
        icon: Icons.emoji_events_outlined,
      ),
    ],
  ),
  _Museum(
    name: 'Museum of Natural History',
    location: 'Mars Entrance',
    totalPoints: 0,
    unlocked: 0,
    total: 3,
    achievements: [
      _Achievement(
        title: 'Fossil Hunter',
        points: 120,
        description: 'Find 5 fossil specimens',
        unlocked: false,
        icon: Icons.search,
      ),
      _Achievement(
        title: 'Evolution Expert',
        points: 180,
        description: 'Complete the evolution trail',
        unlocked: false,
        icon: Icons.timeline,
      ),
      _Achievement(
        title: 'Nature\'s Champion',
        points: 300,
        description: 'Unlock all natural history badges',
        unlocked: false,
        icon: Icons.emoji_events_outlined,
      ),
    ],
  ),
];

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  // which museums are expanded
  final Set<int> _expanded = {};

  int get _totalPoints => _museums.fold(
    0,
    (sum, m) =>
        sum +
        m.achievements.where((a) => a.unlocked).fold(0, (s, a) => s + a.points),
  );

  int get _totalUnlocked => _museums.fold(0, (sum, m) => sum + m.unlocked);

  int get _totalAchievements => _museums.fold(0, (sum, m) => sum + m.total);

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
        title: const Text(
          'Achievements',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: ListView(
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
                      const Text(
                        'Total Points',
                        style: TextStyle(
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
                      const Text(
                        'Unlocked',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_totalUnlocked/$_totalAchievements',
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
          // Museum sections
          ...List.generate(_museums.length, (i) {
            final museum = _museums[i];
            final isExpanded = _expanded.contains(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    // Museum header
                    InkWell(
                      onTap: () => setState(() {
                        if (isExpanded) {
                          _expanded.remove(i);
                        } else {
                          _expanded.add(i);
                        }
                      }),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    museum.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF171A21),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    museum.location,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${museum.totalPoints} points · ${museum.unlocked}/${museum.total} unlocked',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded) ...[
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      ...museum.achievements.map(
                        (a) => _AchievementRow(achievement: a),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement});

  final _Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
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
              unlocked ? achievement.icon : Icons.lock_outline,
              size: 20,
              color: unlocked ? Colors.white : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: unlocked
                        ? const Color(0xFF171A21)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: unlocked
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '+${achievement.points}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: unlocked ? Colors.white : const Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

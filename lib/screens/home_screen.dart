import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/profile_notifier.dart';
import 'package:museamigo/language_notifier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _areas = <_AreaItem>[
    _AreaItem(label: 'Exhibition of paintings', sublabel: 'Hall C'),
    _AreaItem(label: 'Exhibition of weapons', sublabel: 'Ground Floor'),
    _AreaItem(label: 'Colonial History', sublabel: 'Hall A'),
  ];

  static const _artifacts = <_ArtifactItem>[
    _ArtifactItem(
      name: 'Money Frame',
      period: '1800-1900',
      color: Color(0xFFE8A04A),
    ),
    _ArtifactItem(name: 'AK47', period: '1942-1947', color: Color(0xFF6B7A8D)),
    _ArtifactItem(
      name: 'War Photograph',
      period: '1965-1975',
      color: Color(0xFF8B5E3C),
    ),
  ];

  static const _secondFloorArtifacts = <_ArtifactItem>[
    _ArtifactItem(
      name: 'Ancient Vase',
      period: '200-400 AD',
      color: Color(0xFF5E8A6E),
    ),
    _ArtifactItem(
      name: 'Bronze Cannon',
      period: '1700-1800',
      color: Color(0xFF7A5C3A),
    ),
    _ArtifactItem(
      name: 'Royal Seal',
      period: '1600-1700',
      color: Color(0xFF4A6A8A),
    ),
    _ArtifactItem(
      name: 'Silk Robe',
      period: '1800-1900',
      color: Color(0xFF8A4A6A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([profileNotifier, languageNotifier]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────────────────
                Container(
                  color: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pushNamed(AppRoutes.search),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.search,
                                  color: Color(0xFF9CA3AF),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Search artifacts, places...'.tr,
                                  style: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.settings),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/model.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Body ───────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            '${'Welcome'.tr} ${profileNotifier.name}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF171A21),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'You are exploring the Independence Palace'.tr,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6D7785),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // ── Areas ─────────────────────────────────────────
                        _SectionHeader(
                          title: 'Areas'.tr,
                          onSeeAll: () {},
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _areas.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                            itemBuilder: (context, i) {
                              return _AreaCard(
                                area: _areas[i],
                                onTap: () {},
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 28),
                        // ── Trending ──────────────────────────────────────
                        _SectionHeader(
                          title: 'Trending Artifacts'.tr,
                          onSeeAll: () {},
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(
                          _artifacts.length,
                          (i) => _ArtifactRow(
                            item: _artifacts[i],
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.artifactDetail,
                              arguments: <String, dynamic>{
                                'title': _artifacts[i].name,
                                'year': _artifacts[i].period,
                                'location': 'Ground Floor',
                                'currentLocation': 'Independence Palace',
                                'height': '~2.4 meters',
                                'weight': '~39.7 tons',
                                'imageAsset': 'assets/images/museum.jpg',
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // ── Floor 2 Highlights ────────────────────────────
                        _SectionHeader(
                          title: 'Floor 2 Highlights'.tr,
                          onSeeAll: () {},
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(
                          _secondFloorArtifacts.length,
                          (i) => _ArtifactRow(
                            item: _secondFloorArtifacts[i],
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.artifactDetail,
                              arguments: <String, dynamic>{
                                'title': _secondFloorArtifacts[i].name,
                                'year': _secondFloorArtifacts[i].period,
                                'location': 'Floor 2',
                                'currentLocation': 'Independence Palace',
                                'height': '~2.4 meters',
                                'weight': '~39.7 tons',
                                'imageAsset': 'assets/images/museum.jpg',
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF171A21),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onSeeAll,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
          child: Text(
            'See all'.tr,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ── Area card ──────────────────────────────────────────────────────────────────

class _AreaItem {
  const _AreaItem({required this.label, required this.sublabel});
  final String label;
  final String sublabel;
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area, required this.onTap});
  final _AreaItem area;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/museum.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 40,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      area.label.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          area.sublabel.tr,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
}

// ── Artifact row ───────────────────────────────────────────────────────────────

class _ArtifactItem {
  const _ArtifactItem({
    required this.name,
    required this.period,
    required this.color,
  });
  final String name;
  final String period;
  final Color color;
}

class _ArtifactRow extends StatelessWidget {
  const _ArtifactRow({required this.item, required this.onTap});
  final _ArtifactItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Image.asset(
                  'assets/images/museum.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: item.color.withValues(alpha: 0.3),
                    child: Icon(Icons.image, color: item.color, size: 28),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name.tr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF171A21),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.period.tr,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6D7785),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFAAAAAA)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/models/artifact.dart' as artifact_model;
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/profile_notifier.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/session.dart';
import 'package:museamigo/theme_notifier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final ScrollBehavior _horizontalScrollBehavior =
      const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
          PointerDeviceKind.invertedStylus,
        },
      );

  // ── Artifact data from API ──────────────────────────────────────────────
  List<ArtifactDto>? _loadedArtifacts;
  bool _isLoadingArtifacts = false;

  static const Map<String, String> _ipLocationMap = {
    // Exhibition 1 — Fall of Saigon: April 30, 1975 (Floor 1)
    'IP-001': 'Fall of Saigon Exhibition — Front Lawn (Tank 390)',
    'IP-002': 'Fall of Saigon Exhibition — Front Lawn (Tank 843)',
    'IP-007': 'Fall of Saigon Exhibition — Front Courtyard (Jeep M151A2)',
    'IP-006': 'Fall of Saigon Exhibition — Rooftop Terrace (F-5E Marks)',
    // Exhibition 2 — Presidential Power & Governance (Floor 1)
    'IP-009': 'Presidential Power Exhibition — First Floor Cabinet Room',
    'IP-015': 'Presidential Power Exhibition — Second Floor VP Office',
    'IP-013': 'Presidential Power Exhibition — Basement Command Room',
    // Exhibition 3 — Diplomacy & State Ceremony (Floor 1)
    'IP-008': 'Diplomacy Exhibition — First Floor Ambassador\'s Chamber',
    'IP-010': 'Diplomacy Exhibition — Second Floor State Banquet Hall',
    // Exhibition 4 — Presidential Lifestyle (Floor 1)
    'IP-004': 'Presidential Lifestyle Exhibition — Outdoor Vehicle Area',
    'IP-012': 'Presidential Lifestyle Exhibition — Second Floor Bedroom',
    // Exhibition 5 — War Command Bunker (Floor 2)
    'IP-005': 'War Command Bunker — Basement Command Center',
    'IP-011': 'War Command Bunker — Basement Telecommunications Room',
    // Exhibition 6 — Air Warfare & Evacuation (Floor 2)
    'IP-003': 'Air Warfare Exhibition — Rooftop Helipad',
    // Unassigned
    'IP-014': 'Basement Cinema Room',
  };

  static const List<Color> _artifactColors = [
    Color(0xFF6B7A8D),
    Color(0xFF8B5E3C),
    Color(0xFFE8A04A),
    Color(0xFF5E8A6E),
    Color(0xFF4A6A8A),
    Color(0xFF8A4A6A),
    Color(0xFF7A5C3A),
    Color(0xFF5E5E5E),
  ];

  @override
  void initState() {
    super.initState();
    _fetchArtifacts();
    AppSession.currentMuseumId.addListener(_onMuseumChanged);
  }

  @override
  void dispose() {
    AppSession.currentMuseumId.removeListener(_onMuseumChanged);
    super.dispose();
  }

  void _onMuseumChanged() {
    setState(() => _loadedArtifacts = null);
    _fetchArtifacts();
  }

  Future<void> _fetchArtifacts() async {
    if (_isLoadingArtifacts) return;
    final museumId = AppSession.currentMuseumId.value;
    setState(() => _isLoadingArtifacts = true);
    try {
      final artifacts = await BackendApi.instance.fetchArtifacts(museumId);
      if (mounted) {
        setState(() {
          _loadedArtifacts = artifacts;
          _isLoadingArtifacts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingArtifacts = false);
    }
  }

  String _locationForArtifact(ArtifactDto a) {
    if (a.museumId == 1) {
      return _ipLocationMap[a.artifactCode] ?? 'Ground Floor';
    }
    return 'Ground Floor';
  }

  // Builds first-section artifacts from API data (first 4 items).
  List<_ArtifactItem> _artifactsFromApi() {
    final list = (_loadedArtifacts ?? []).take(4).toList();
    return list.asMap().entries.map((e) {
      final a = e.value;
      return _ArtifactItem(
        name: a.title,
        period: a.year,
        color: _artifactColors[e.key % _artifactColors.length],
        location: _locationForArtifact(a),
        artifactCode: a.artifactCode,
      );
    }).toList();
  }

  // Builds second-section artifacts from API data (items 4–7).
  List<_ArtifactItem> _secondArtifactsFromApi() {
    final list = (_loadedArtifacts ?? []).skip(4).take(4).toList();
    return list.asMap().entries.map((e) {
      final a = e.value;
      return _ArtifactItem(
        name: a.title,
        period: a.year,
        color: _artifactColors[(e.key + 4) % _artifactColors.length],
        location: _locationForArtifact(a),
      );
    }).toList();
  }

  List<_AreaItem> _exhibitionsForMuseum(int museumId) {
    switch (museumId) {
      case 1:
        return const [
          // Floor 1 — Public & Ceremonial Spaces
          _AreaItem(
            label: 'Fall of Saigon: April 30, 1975',
            sublabel: 'Floor 1 · IP-001, IP-002, IP-007, IP-006',
          ),
          _AreaItem(
            label: 'Presidential Power & Governance',
            sublabel: 'Floor 1 · IP-009, IP-015, IP-013',
          ),
          _AreaItem(
            label: 'Diplomacy & State Ceremony',
            sublabel: 'Floor 1 · IP-008, IP-010',
          ),
          _AreaItem(
            label: 'Presidential Lifestyle',
            sublabel: 'Floor 1 · IP-004, IP-012',
          ),
          // Floor 2 — War Operations & Secret Infrastructure
          _AreaItem(
            label: 'War Command Bunker',
            sublabel: 'Floor 2 · IP-005, IP-011',
          ),
          _AreaItem(
            label: 'Air Warfare & Evacuation',
            sublabel: 'Floor 2 · IP-003',
          ),
        ];
      default:
        return _areasForMuseum(museumId);
    }
  }

  List<_AreaItem> _floorsForMuseum(int museumId) {
    switch (museumId) {
      case 1:
        return const [
          _AreaItem(
            label: 'Floor 1',
            sublabel: 'Ceremony, governance, diplomacy',
          ),
          _AreaItem(
            label: 'Floor 2',
            sublabel: 'War operations & secret infrastructure',
          ),
        ];
      default:
        return const [
          _AreaItem(label: 'Floor 1', sublabel: 'Main exhibition spaces'),
          _AreaItem(label: 'Floor 2', sublabel: 'Upper galleries'),
        ];
    }
  }

  String _detailLocationForArtifact(_ArtifactItem item, String fallback) {
    return item.location.isEmpty ? fallback : item.location;
  }

  List<_AreaItem> _areasForMuseum(int museumId) {
    switch (museumId) {
      case 2: // War Remnants Museum
        return const [
          _AreaItem(label: 'War Artifacts', sublabel: 'Hall A'),
          _AreaItem(label: 'Photography Exhibit', sublabel: 'Hall B'),
          _AreaItem(label: 'Outdoor Collection', sublabel: 'Courtyard'),
        ];
      case 3: // HCMC Museum of Fine Arts
        return const [
          _AreaItem(label: 'Modern Art', sublabel: 'Hall 1'),
          _AreaItem(label: 'Traditional Lacquer', sublabel: 'Hall 2'),
          _AreaItem(label: 'Sculpture Garden', sublabel: 'Ground Floor'),
        ];
      case 4: // Ho Chi Minh City Museum
        return const [
          _AreaItem(label: 'City History', sublabel: 'Floor 1'),
          _AreaItem(label: 'Archaeology', sublabel: 'Floor 2'),
          _AreaItem(label: 'Cultural Heritage', sublabel: 'Hall A'),
        ];
      default: // Independence Palace
        return const [
          _AreaItem(label: 'Exhibition of paintings', sublabel: 'Hall C'),
          _AreaItem(label: 'Exhibition of weapons', sublabel: 'Ground Floor'),
          _AreaItem(label: 'Colonial History', sublabel: 'Hall A'),
        ];
    }
  }

  List<_ArtifactItem> _artifactsForMuseum(int museumId) {
    switch (museumId) {
      case 2: // War Remnants Museum
        return const [
          _ArtifactItem(
            name: 'Tiger Cages',
            period: '1960s',
            color: Color(0xFF6B7A8D),
          ),
          _ArtifactItem(
            name: 'Guillotine',
            period: 'Early 1900s',
            color: Color(0xFF8B5E3C),
          ),
          _ArtifactItem(
            name: 'Bomb Casings',
            period: '1965-1975',
            color: Color(0xFF5E5E5E),
          ),
        ];
      case 3: // HCMC Museum of Fine Arts
        return const [
          _ArtifactItem(
            name: 'Lacquer Painting',
            period: '1942',
            color: Color(0xFFE8A04A),
          ),
          _ArtifactItem(
            name: 'Buddhist Statue',
            period: '17th Century',
            color: Color(0xFF4A6A8A),
          ),
          _ArtifactItem(
            name: 'Silk Painting',
            period: '1930s',
            color: Color(0xFF8A4A6A),
          ),
        ];
      case 4: // Ho Chi Minh City Museum
        return const [
          _ArtifactItem(
            name: 'Traditional Ao Dai',
            period: '1930s',
            color: Color(0xFF8A4A6A),
          ),
          _ArtifactItem(
            name: 'Saigon Map 1930',
            period: '1930',
            color: Color(0xFF5E8A6E),
          ),
          _ArtifactItem(
            name: 'Ancient Coins',
            period: '1800-1900',
            color: Color(0xFFE8A04A),
          ),
        ];
      default: // Independence Palace
        return const [
          _ArtifactItem(
            name: 'Money Frame',
            period: '1800-1900',
            color: Color(0xFFE8A04A),
          ),
          _ArtifactItem(
            name: 'AK47',
            period: '1942-1947',
            color: Color(0xFF6B7A8D),
          ),
          _ArtifactItem(
            name: 'War Photograph',
            period: '1965-1975',
            color: Color(0xFF8B5E3C),
          ),
        ];
    }
  }

  List<_ArtifactItem> _secondFloorArtifactsForMuseum(int museumId) {
    switch (museumId) {
      case 2: // War Remnants Museum
        return const [
          _ArtifactItem(
            name: 'Agent Orange Documents',
            period: '1960s',
            color: Color(0xFF5E8A6E),
          ),
          _ArtifactItem(
            name: 'Military Uniforms',
            period: '1940-1975',
            color: Color(0xFF7A5C3A),
          ),
          _ArtifactItem(
            name: 'Propaganda Posters',
            period: '1960s',
            color: Color(0xFF4A6A8A),
          ),
          _ArtifactItem(
            name: 'Helicopter Parts',
            period: '1970s',
            color: Color(0xFF8A4A6A),
          ),
        ];
      case 3: // HCMC Museum of Fine Arts
        return const [
          _ArtifactItem(
            name: 'Oil Portrait',
            period: '1950s',
            color: Color(0xFF5E8A6E),
          ),
          _ArtifactItem(
            name: 'Ceramic Vase',
            period: '15th Century',
            color: Color(0xFF7A5C3A),
          ),
          _ArtifactItem(
            name: 'Watercolor Landscape',
            period: '1940s',
            color: Color(0xFF4A6A8A),
          ),
          _ArtifactItem(
            name: 'Wood Carving',
            period: '18th Century',
            color: Color(0xFF8A4A6A),
          ),
        ];
      case 4: // Ho Chi Minh City Museum
        return const [
          _ArtifactItem(
            name: 'Colonial Documents',
            period: '1880s',
            color: Color(0xFF5E8A6E),
          ),
          _ArtifactItem(
            name: 'River Boat Model',
            period: '1900s',
            color: Color(0xFF7A5C3A),
          ),
          _ArtifactItem(
            name: 'Trade Ceramics',
            period: '17th Century',
            color: Color(0xFF4A6A8A),
          ),
          _ArtifactItem(
            name: 'Ethnic Costume',
            period: '1800s',
            color: Color(0xFF8A4A6A),
          ),
        ];
      default: // Independence Palace
        return const [
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        profileNotifier,
        languageNotifier,
        AppSession.currentMuseumName,
        themeNotifier,
      ]),
      builder: (context, _) {
        final museumId = AppSession.currentMuseumId.value;
        final museumName = AppSession.currentMuseumName.value;
        final exhibitions = _exhibitionsForMuseum(museumId);
        final floors = _floorsForMuseum(museumId);
        final bool useApi =
            museumId == 1 &&
            _loadedArtifacts != null &&
            _loadedArtifacts!.isNotEmpty;
        final artifacts = useApi
            ? _artifactsFromApi()
            : _artifactsForMuseum(museumId);

        return Scaffold(
          backgroundColor: themeNotifier.surfaceColor,
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────────────────
                Container(
                  color: Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 12,
                    16,
                    14,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pushNamed(AppRoutes.search),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: themeNotifier.surfaceColor,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                SizedBox(width: 12),
                                Icon(
                                  Icons.search,
                                  color: themeNotifier.textSecondaryColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Search artifacts, places...'.tr,
                                  style: TextStyle(
                                    color: themeNotifier.textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.settings),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeNotifier.surfaceColor,
                            border: Border.all(
                              color: themeNotifier.surfaceColor.withValues(
                                alpha: 0.8,
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/model.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: themeNotifier.surfaceColor.withValues(
                                    alpha: 0.25,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: themeNotifier.surfaceColor,
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
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            '${'Welcome'.tr} ${profileNotifier.name}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: themeNotifier.textPrimaryColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            '${'You are exploring the'.tr} ${museumName.tr}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: themeNotifier.textSecondaryColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        // ── Exhibitions ───────────────────────────────────
                        _SectionHeader(
                          title: 'Exhibitions'.tr,
                          onSeeAll: () => Navigator.of(context).pushNamed(
                            AppRoutes.search,
                            arguments: {
                              'initialExhibition': 'All',
                              'showResults': true,
                            },
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          height: 196,
                          child: ScrollConfiguration(
                            behavior: _horizontalScrollBehavior,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: exhibitions.length,
                              separatorBuilder: (_, _) => SizedBox(width: 14),
                              itemBuilder: (context, i) {
                                return _AreaCard(
                                  area: exhibitions[i],
                                  width: 228,
                                  onTap: () => Navigator.of(context).pushNamed(
                                    AppRoutes.search,
                                    arguments: {
                                      'initialExhibition': exhibitions[i].label,
                                      'showResults': true,
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 28),
                        // ── Trending ──────────────────────────────────────
                        _SectionHeader(
                          title: 'Trending Artifacts'.tr,
                          onSeeAll: () => Navigator.of(context).pushNamed(
                            AppRoutes.search,
                            arguments: {
                              'initialQuery': '',
                              'showResults': true,
                            },
                          ),
                        ),
                        SizedBox(height: 12),
                        ...List.generate(
                          artifacts.length,
                          (i) {
                            // Resolve artifact code from API data if available
                            String? artifactCode;
                            if (useApi && _loadedArtifacts != null && i < _loadedArtifacts!.length) {
                              artifactCode = _loadedArtifacts![i].artifactCode;
                            }
                            return _ArtifactRow(
                              item: artifacts[i],
                              onTap: artifactCode != null
                                  ? () => Navigator.of(context).pushNamed(
                                        AppRoutes.artifactDetail,
                                        arguments: <String, dynamic>{
                                          'artifactCode': artifactCode,
                                        },
                                      )
                                  : null,
                            );
                          },
                        ),
                        SizedBox(height: 20),
                        // ── Floors ────────────────────────────────────────
                        _SectionHeader(
                          title: 'Floors'.tr,
                          onSeeAll: () => Navigator.of(context).pushNamed(
                            AppRoutes.search,
                            arguments: {
                              'initialFilter': 'All',
                              'showResults': true,
                            },
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          height: 172,
                          child: ScrollConfiguration(
                            behavior: _horizontalScrollBehavior,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: floors.length,
                              separatorBuilder: (_, _) => SizedBox(width: 14),
                              itemBuilder: (context, i) {
                                return _AreaCard(
                                  area: floors[i],
                                  width: 228,
                                  onTap: () => Navigator.of(context).pushNamed(
                                    AppRoutes.search,
                                    arguments: {
                                      'initialFilter': floors[i].label,
                                      'showResults': true,
                                    },
                                  ),
                                );
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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: themeNotifier.textPrimaryColor,
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
            style: TextStyle(fontWeight: FontWeight.w600),
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
  const _AreaCard({required this.area, required this.onTap, this.width = 160});
  final _AreaItem area;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
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
                  child: Icon(Icons.image_not_supported_outlined, size: 40),
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
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Independence Palace'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      area.label.tr,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            area.sublabel.tr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 11,
                              height: 1.25,
                            ),
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
    this.location = '',
    this.artifactCode = '',
  });
  final String name;
  final String period;
  final Color color;
  final String location;
  final String artifactCode;

  /// Resolves the image path from the centralized Artifact model.
  String get imagePath => artifactCode.isNotEmpty
      ? artifact_model.Artifact.imagePathForCode(artifactCode)
      : artifact_model.Artifact.placeholderImage;
}

class _ArtifactRow extends StatelessWidget {
  const _ArtifactRow({required this.item, this.onTap});
  final _ArtifactItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeNotifier.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: themeNotifier.borderColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 68,
                height: 68,
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: themeNotifier.isDarkMode
                        ? const Color(0xFF27272A)
                        : item.color.withValues(alpha: 0.3),
                    child: Icon(Icons.image, color: item.color, size: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: themeNotifier.textPrimaryColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.period.tr,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeNotifier.textSecondaryColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: themeNotifier.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}

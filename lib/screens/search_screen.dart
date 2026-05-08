import 'package:flutter/gestures.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/l10n/artifact_localizer.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/models/artifact.dart';
import 'package:flutter/material.dart';
import 'package:museamigo/theme_notifier.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final bool showResults;
  final String? initialFilter;
  final String? initialExhibition;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.showResults = false,
    this.initialFilter,
    this.initialExhibition,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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

  late final TextEditingController _controller;
  bool _showingResults = false;
  String _activeQuery = '';
  String _selectedFloorFilter = 'All';
  String _selectedExhibitionFilter = 'All';
  String _activeFilterMode = 'exhibitions';
  String _sortBy = 'default'; // 'default' or 'a-z'

  static const _recentSearches = [
    'Fall of Saigon',
    'War Command Bunker',
    'Tank 390',
    'UH-1 Helicopter',
  ];
  static const _trending = [
    'Presidential Power & Governance',
    'Diplomacy & State Ceremony',
    'Floor 1',
    'Floor 2',
    'Air Warfare & Evacuation',
  ];
  static const _filterModes = ['Exhibitions', 'Floors'];
  static const _floorFilters = ['All', 'Floor 1', 'Floor 2'];
  static const _filterExhibitions = [
    'All',
    'Fall of Saigon: April 30, 1975',
    'Presidential Power & Governance',
    'Diplomacy & State Ceremony',
    'Presidential Lifestyle',
    'War Command Bunker',
    'Air Warfare & Evacuation',
  ];

  static const _allResults = <_ResultItem>[
    _ResultItem(
      artifactCode: 'IP-001',
      title: 'Tank 390',
      location: 'Main Gate Courtyard',
      floor: 'Floor 1',
      exhibition: 'Fall of Saigon — April 30, 1975',
    ),
    _ResultItem(
      artifactCode: 'IP-002',
      title: 'T-54 Tank',
      location: 'Side Gate Courtyard',
      floor: 'Floor 1',
      exhibition: 'Fall of Saigon — April 30, 1975',
    ),
    _ResultItem(
      artifactCode: 'IP-007',
      title: 'Jeep M151A2',
      location: 'Front Courtyard Military Display',
      floor: 'Floor 1',
      exhibition: 'Fall of Saigon — April 30, 1975',
    ),
    _ResultItem(
      artifactCode: 'IP-006',
      title: 'F-5E Bombing Marks',
      location: 'Rooftop Terrace',
      floor: 'Floor 1',
      exhibition: 'Fall of Saigon — April 30, 1975',
    ),
    _ResultItem(
      artifactCode: 'IP-009',
      title: 'Cabinet Room Table',
      location: 'Cabinet Room',
      floor: 'Floor 1',
      exhibition: 'Presidential Power & Governance',
    ),
    _ResultItem(
      artifactCode: 'IP-015',
      title: 'Vice President\'s Desk',
      location: 'Vice President Office',
      floor: 'Floor 1',
      exhibition: 'Presidential Power & Governance',
    ),
    _ResultItem(
      artifactCode: 'IP-013',
      title: 'National Security Council Maps',
      location: 'Tactical Command Room',
      floor: 'Floor 1',
      exhibition: 'Presidential Power & Governance',
    ),
    _ResultItem(
      artifactCode: 'IP-008',
      title: 'Binh Ngo Dai Cao Lacquer Painting',
      location: 'Ambassador\'s Chamber',
      floor: 'Floor 1',
      exhibition: 'Art & Diplomatic Heritage',
    ),
    _ResultItem(
      artifactCode: 'IP-010',
      title: 'The Golden Dragon Tapestry',
      location: 'State Banquet Hall',
      floor: 'Floor 1',
      exhibition: 'Art & Diplomatic Heritage',
    ),
    _ResultItem(
      artifactCode: 'IP-004',
      title: 'Mercedes-Benz 200 W110',
      location: 'Outdoor Vehicle Display Area',
      floor: 'Floor 1',
      exhibition: 'Presidential Transport & Lifestyle',
    ),
    _ResultItem(
      artifactCode: 'IP-012',
      title: 'The Presidential Bed',
      location: 'Presidential Bedroom',
      floor: 'Floor 1',
      exhibition: 'Presidential Transport & Lifestyle',
    ),
    _ResultItem(
      artifactCode: 'IP-005',
      title: 'War Command Bunker Map',
      location: 'Command Bunker',
      floor: 'Floor 2',
      exhibition: 'Underground War Command Center',
    ),
    _ResultItem(
      artifactCode: 'IP-011',
      title: 'Telecommunications Center',
      location: 'Telecommunications Room',
      floor: 'Floor 2',
      exhibition: 'Underground War Command Center',
    ),
    _ResultItem(
      artifactCode: 'IP-003',
      title: 'UH-1 Helicopter',
      location: 'Rooftop Helipad',
      floor: 'Floor 2',
      exhibition: 'Fall of Saigon — April 30, 1975',
    ),
    _ResultItem(
      artifactCode: 'IP-014',
      title: 'Basement Cinema Projector',
      location: 'Basement Cinema Room',
      floor: 'Floor 2',
      exhibition: 'Presidential Transport & Lifestyle',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _activeQuery = widget.initialQuery ?? '';
    if (widget.initialExhibition != null &&
        _filterExhibitions.contains(widget.initialExhibition)) {
      _selectedExhibitionFilter = widget.initialExhibition!;
      _activeFilterMode = 'exhibitions';
    }
    if (widget.initialFilter != null &&
        _floorFilters.contains(widget.initialFilter)) {
      _selectedFloorFilter = widget.initialFilter!;
      _activeFilterMode = 'floors';
    }
    _showingResults = _shouldShowResults;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() {
      _activeQuery = query;
      _showingResults = _shouldShowResults;
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _activeQuery = '';
      _showingResults = _shouldShowResults;
    });
  }

  bool get _shouldShowResults {
    return widget.showResults ||
        _activeQuery.isNotEmpty ||
        _selectedFloorFilter != 'All' ||
        _selectedExhibitionFilter != 'All';
  }

  List<_ResultItem> get _filteredResults {
    var results = List<_ResultItem>.from(_allResults);
    final q = _activeQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      results = results
          .where(
            (r) =>
                r.title.toLowerCase().contains(q) ||
                r.location.toLowerCase().contains(q) ||
                r.floor.toLowerCase().contains(q) ||
                r.exhibition.toLowerCase().contains(q),
          )
          .toList();
    }
    if (_activeFilterMode == 'floors' && _selectedFloorFilter != 'All') {
      results = results.where((r) => r.floor == _selectedFloorFilter).toList();
    }
    if (_activeFilterMode == 'exhibitions' &&
        _selectedExhibitionFilter != 'All') {
      results = results
          .where((r) => r.exhibition == _selectedExhibitionFilter)
          .toList();
    }
    if (_sortBy == 'a-z') {
      results.sort((a, b) => a.title.compareTo(b.title));
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) {
        return Scaffold(
      backgroundColor: themeNotifier.surfaceColor,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ────────────────────────────────────────────────
            Container(
              color: Theme.of(context).colorScheme.primary,
              padding: EdgeInsets.fromLTRB(
                4,
                MediaQuery.of(context).padding.top + 10,
                16,
                12,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: themeNotifier.surfaceColor,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: themeNotifier.surfaceColor,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: !widget.showResults,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _search,
                        onChanged: (v) {
                          if (v.isEmpty) _clearSearch();
                        },
                        style: TextStyle(
                          fontSize: 14,
                          color: themeNotifier.textPrimaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search artifacts, places...'.tr,
                          hintStyle: TextStyle(
                            color: themeNotifier.textSecondaryColor,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: themeNotifier.textSecondaryColor,
                            size: 20,
                          ),
                          suffixIcon: _activeQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: _clearSearch,
                                  child: Icon(
                                    Icons.close,
                                    color: themeNotifier.textSecondaryColor,
                                    size: 20,
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showingResults) ...[
              SizedBox(
                height: 50,
                child: ScrollConfiguration(
                  behavior: _horizontalScrollBehavior,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filterModes.length,
                    separatorBuilder: (_, _) => SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final mode = _filterModes[index];
                      final selected =
                          (_activeFilterMode == 'exhibitions' &&
                              mode == 'Exhibitions') ||
                          (_activeFilterMode == 'floors' && mode == 'Floors');
                      return GestureDetector(
                        onTap: () => setState(() {
                          _activeFilterMode = mode == 'Exhibitions'
                              ? 'exhibitions'
                              : 'floors';
                          _showingResults = _shouldShowResults;
                        }),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : themeNotifier.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : themeNotifier.borderColor,
                            ),
                          ),
                          child: Text(
                            mode,
                            style: TextStyle(
                              color: selected
                                  ? themeNotifier.surfaceColor
                                  : themeNotifier.textPrimaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_activeFilterMode == 'floors')
                SizedBox(
                  height: 50,
                  child: ScrollConfiguration(
                    behavior: _horizontalScrollBehavior,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _floorFilters.length,
                      separatorBuilder: (_, _) => SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = _floorFilters[index];
                        final selected = _selectedFloorFilter == filter;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedFloorFilter = filter;
                            _activeFilterMode = 'floors';
                            _showingResults = _shouldShowResults;
                          }),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : themeNotifier.surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : themeNotifier.borderColor,
                              ),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: selected
                                    ? themeNotifier.surfaceColor
                                    : themeNotifier.textPrimaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (_activeFilterMode == 'exhibitions')
                SizedBox(
                  height: 50,
                  child: ScrollConfiguration(
                    behavior: _horizontalScrollBehavior,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _filterExhibitions.length,
                      separatorBuilder: (_, _) => SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = _filterExhibitions[index];
                        final selected = _selectedExhibitionFilter == filter;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedExhibitionFilter = filter;
                            _activeFilterMode = 'exhibitions';
                            _showingResults = _shouldShowResults;
                          }),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : themeNotifier.surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : themeNotifier.borderColor,
                              ),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: selected
                                    ? themeNotifier.surfaceColor
                                    : themeNotifier.textPrimaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // ── Results count + sort ──────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  children: [
                    Text(
                      '${_filteredResults.length} ${'Results'.tr}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: themeNotifier.textPrimaryColor,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() {
                        _sortBy = _sortBy == 'default' ? 'a-z' : 'default';
                      }),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 18,
                            color: themeNotifier.textSecondaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _sortBy == 'default' ? 'Sort by'.tr : 'A-Z',
                            style: TextStyle(
                              color: themeNotifier.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Results list ──────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _filteredResults.length,
                  itemBuilder: (context, index) =>
                      _ResultCard(item: _filteredResults[index]),
                ),
              ),
            ] else ...[
              // ── Recent + Trending ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recent header
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: themeNotifier.textPrimaryColor,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Recent'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: themeNotifier.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      ..._recentSearches.map(
                        (item) => _RecentRow(
                          label: item,
                          onTap: () {
                            _controller.text = item;
                            _search(item);
                          },
                        ),
                      ),
                      SizedBox(height: 22),
                      // Trending
                      Text(
                        'Trending'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _trending.map((t) {
                          return GestureDetector(
                            onTap: () {
                              _controller.text = t;
                              _search(t);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Text(
                                t,
                                style: TextStyle(
                                  color: themeNotifier.surfaceColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
      },
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────

class _ResultItem {
  const _ResultItem({
    required this.artifactCode,
    required this.title,
    required this.location,
    required this.floor,
    required this.exhibition,
  });

  final String artifactCode;
  final String title;
  final String location;
  final String floor;
  final String exhibition;

  /// Resolves the artifact image via the central [Artifact] model.
  String get imagePath => Artifact.imagePathForCode(artifactCode);
}

// ── Recent row ─────────────────────────────────────────────────────────────────

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: themeNotifier.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: themeNotifier.textPrimaryColor,
                ),
              ),
            ),
            Icon(
              Icons.search,
              size: 18,
              color: themeNotifier.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Result card ────────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.item});
  final _ResultItem item;

  void _openDetail(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.artifactDetail,
      arguments: <String, dynamic>{
        'artifactCode': item.artifactCode,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeNotifier.borderColor.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 76,
                height: 76,
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: themeNotifier.isDarkMode
                        ? const Color(0xFF27272A)
                        : Colors.grey.shade300,
                    child: Icon(Icons.image, size: 32,
                        color: themeNotifier.textSecondaryColor),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ArtifactLocalizer.title(
                      item.artifactCode,
                      languageNotifier.currentLanguage,
                      englishFallback: item.title,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: themeNotifier.textPrimaryColor,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    ArtifactLocalizer.location(
                      item.artifactCode,
                      languageNotifier.currentLanguage,
                      englishFallback: item.location,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: themeNotifier.textSecondaryColor,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        item.floor.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: themeNotifier.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            // Detail button
            FilledButton(
              onPressed: () => _openDetail(context),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Detail'.tr,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

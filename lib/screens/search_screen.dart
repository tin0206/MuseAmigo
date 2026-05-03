import 'package:museamigo/app_routes.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/session.dart';
import 'package:museamigo/services/audio_assets.dart';
import 'package:flutter/material.dart';

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
  late final TextEditingController _controller;
  bool _showingResults = false;
  String _activeQuery = '';
  String _selectedFilterType = 'All';
  String _selectedFilterExhibition = 'All';
  String _activeFilterMode = 'floor'; // 'floor' or 'exhibition'
  String _sortBy = 'default'; // 'default' or 'a-z'

  static const _recentSearches = ['Tank', 'Weapons', 'Room', 'Exhibition'];
  static const _trending = ['Garden', 'Tank', 'Weapons', 'Room', 'Exhibition'];
  static const _filterTypes = ['All', 'B1', 'Floor 1', 'Floor 2', 'Hall'];
  static const _filterExhibitions = [
    'All',
    'Exhibition of paintings',
    'Exhibition of weapons',
    'Colonial History',
  ];

  static const _allResults = <_ResultItem>[
    _ResultItem(
      title: "President's Office",
      location: 'In the Hall',
      floor: 'Floor 1',
      exhibition: 'Exhibition of paintings',
    ),
    _ResultItem(
      title: 'The old war room',
      location: 'Underground',
      floor: 'B1',
      exhibition: 'Exhibition of weapons',
    ),
    _ResultItem(
      title: 'Roof of Reunification Palace',
      location: 'In the Hall',
      floor: 'Floor 2',
      exhibition: 'Colonial History',
    ),
    _ResultItem(
      title: "President's Office 1",
      location: 'In the Hall',
      floor: 'Floor 1',
      exhibition: 'Exhibition of paintings',
    ),
    _ResultItem(
      title: 'The old war room 1',
      location: 'Underground',
      floor: 'B1',
      exhibition: 'Exhibition of weapons',
    ),
    _ResultItem(
      title: 'Roof of Reunification Palace 1',
      location: 'In the Hall',
      floor: 'Floor 2',
      exhibition: 'Colonial History',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _activeQuery = widget.initialQuery ?? '';
    if (widget.initialFilter != null &&
        _filterTypes.contains(widget.initialFilter)) {
      _selectedFilterType = widget.initialFilter!;
      _activeFilterMode = 'floor';
    }
    if (widget.initialExhibition != null &&
        _filterExhibitions.contains(widget.initialExhibition)) {
      _selectedFilterExhibition = widget.initialExhibition!;
      if (widget.initialExhibition != 'All') {
        _activeFilterMode = 'exhibition';
      }
    }
    _showingResults = widget.showResults || (_activeQuery.isNotEmpty);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    setState(() {
      _activeQuery = query;
      _showingResults = query.isNotEmpty;
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _activeQuery = '';
      _showingResults = false;
    });
  }

  List<_ResultItem> get _filteredResults {
    var results = List<_ResultItem>.from(_allResults);
    if (_selectedFilterType != 'All') {
      results = results
          .where((r) => r.floor.contains(_selectedFilterType))
          .toList();
    }
    if (_selectedFilterExhibition != 'All') {
      results = results
          .where((r) => r.exhibition == _selectedFilterExhibition)
          .toList();
    }
    // Apply sorting
    if (_sortBy == 'a-z') {
      results.sort((a, b) => a.title.compareTo(b.title));
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ────────────────────────────────────────────────
            Container(
              color: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.fromLTRB(4, 10, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF171A21),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search artifacts, places...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                          suffixIcon: _activeQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: _clearSearch,
                                  child: const Icon(
                                    Icons.close,
                                    color: Color(0xFF9CA3AF),
                                    size: 20,
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showingResults) ...[
              // ── Filter chips (Type) - Show only when in floor mode ────
              if (_activeFilterMode == 'floor')
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _filterTypes.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filterTypes[index];
                      final selected = _selectedFilterType == filter;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedFilterType = filter;
                          _activeFilterMode = 'floor';
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : const Color(0xFFDDDDDD),
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF171A21),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // ── Filter chips (Exhibition) - Show only when in exhibition mode ───
              if (_activeFilterMode == 'exhibition')
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _filterExhibitions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filterExhibitions[index];
                      final selected = _selectedFilterExhibition == filter;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedFilterExhibition = filter;
                          _activeFilterMode = 'exhibition';
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : const Color(0xFFDDDDDD),
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF171A21),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              // ── Results count + sort ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  children: [
                    Text(
                      '${_filteredResults.length} Results',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF171A21),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() {
                        _sortBy = _sortBy == 'default' ? 'a-z' : 'default';
                      }),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.filter_list_rounded,
                            size: 18,
                            color: Color(0xFF6D7785),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _sortBy == 'default' ? 'Sort by' : 'A-Z',
                            style: const TextStyle(
                              color: Color(0xFF6D7785),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _filteredResults.length,
                  itemBuilder: (context, index) =>
                      _ResultCard(item: _filteredResults[index]),
                ),
              ),
            ] else ...[
              // ── Recent + Trending ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recent header
                      const Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: Color(0xFF171A21),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Recent',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF171A21),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._recentSearches.map(
                        (item) => _RecentRow(
                          label: item,
                          onTap: () {
                            _controller.text = item;
                            _search(item);
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      // Trending
                      const Text(
                        'Trending',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF171A21),
                        ),
                      ),
                      const SizedBox(height: 12),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  color: Colors.white,
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
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────

class _ResultItem {
  const _ResultItem({
    required this.title,
    required this.location,
    required this.floor,
    required this.exhibition,
    this.has3dModel = false,
    this.modelName = '',
  });

  final String title;
  final String location;
  final String floor;
  final String exhibition;
  final bool has3dModel;
  final String modelName;
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: Color(0xFF171A21)),
              ),
            ),
            const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
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
        'title': item.title,
        'year': '1947',
        'location': item.floor,
        'currentLocation': AppSession.currentMuseumName.value,
        'height': '~2.4 meters',
        'weight': '~39.7 tons',
        'imageAsset': 'assets/images/museum.jpg',
        'audioAsset': AudioAssets.standardPath,
        // 'modelAsset': item.has3dModel ? 'assets/models/${item.modelName}.obj' : '', // Temporarily commented
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: Image.asset(
                  'assets/images/museum.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, size: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF171A21),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.location,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6D7785),
                    ),
                  ),
                  const SizedBox(height: 4),
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
                      const SizedBox(width: 4),
                      Text(
                        item.floor,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D7785),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Detail button
            FilledButton(
              onPressed: () => _openDetail(context),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Detail',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

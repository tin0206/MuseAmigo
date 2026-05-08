import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/session.dart';
import 'package:museamigo/theme_notifier.dart';
import 'package:geolocator/geolocator.dart';

class Museum3DMapScreen extends StatefulWidget {
  const Museum3DMapScreen({
    super.key,
    this.initialFromLocationName,
    this.initialToLocationName,
    this.onBack,
    this.autoStartRouteFlow = false,
  });

  final String? initialFromLocationName;
  final String? initialToLocationName;
  final VoidCallback? onBack;
  final bool autoStartRouteFlow;

  @override
  State<Museum3DMapScreen> createState() => _Museum3DMapScreenState();
}

class _Museum3DMapScreenState extends State<Museum3DMapScreen> {
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

  late String _selectedFloor;
  bool _show3D = true;
  _RouteOption? _activeRoute;
  int _currentStopIndex = 0;
  bool _isPreviewRoute = false;
  String? _selectedExhibition;

  final TextEditingController _searchController = TextEditingController();
  List<_LocationOption> _searchResults = [];

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _searchResults = _currentConfig.locationOptions
          .where(
            (l) =>
                l.name.toLowerCase().contains(q) ||
                l.subtitle.toLowerCase().contains(q),
          )
          .toList();
    });
  }

  static const Color _restroomColor = Color(0xFFF59E0B);
  static const Color _cafeColor = Color(0xFF8B5E3C);
  static const Color _stairsColor = Color(0xFF60A5FA);

  List<String> get _floors => _currentConfig.floors;

  bool _isUtilityLocation(_MapLocation location) {
    return location.name.contains('Entrance') ||
        location.name.contains('Restroom') ||
        location.name.contains('Stairs');
  }

  List<_MapLocation> _floorLegendLocations() {
    return _currentConfig.locations
        .where(
          (location) =>
              location.floor == _selectedFloor && !_isUtilityLocation(location),
        )
        .toList();
  }

  List<_MapLocation> _locationsForCurrentFloor() {
    return _currentConfig.locations
        .where((location) => location.floor == _selectedFloor)
        .toList();
  }

  _MuseumMapConfig get _currentConfig {
    final museumId = AppSession.currentMuseumId.value;
    return _museumConfigs[museumId] ?? _museumConfigs[1]!;
  }

  @override
  void initState() {
    super.initState();
    _selectedFloor = _currentConfig.floors.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.autoStartRouteFlow) {
        _openRouteFlow();
        return;
      }
      final route = _buildInitialRoute();
      if (route != null) {
        _showPreviewRoute(route);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeNotifier.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF171A21),
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    'Map'.tr,
                    style: const TextStyle(
                      color: Color(0xFF171A21),
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // ── Search bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Color(0xFF9CA3AF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search artifacts, locations...'.tr,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF9CA3AF),
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // ── Floor filters + 3D toggle ──────────────────────────────
            SizedBox(
              height: 50,
              child: ScrollConfiguration(
                behavior: _horizontalScrollBehavior,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _floors.length + 1,
                  separatorBuilder: (_, index) =>
                      SizedBox(width: index == _floors.length - 1 ? 140 : 8),
                  itemBuilder: (context, index) {
                    if (index == _floors.length) {
                      return GestureDetector(
                        onTap: () => setState(() => _show3D = !_show3D),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: themeNotifier.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: themeNotifier.borderColor,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.layers_outlined,
                                size: 16,
                                color: themeNotifier.textSecondaryColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '3D',
                                style: TextStyle(
                                  color: themeNotifier.textSecondaryColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final floor = _floors[index];
                    final selected = _selectedFloor == floor;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFloor = floor),
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
                          floor.tr,
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
            // ── 3D Map canvas ──────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  Container(
                    color: const Color(0xFF1A1A1A),
                    child: CustomPaint(
                      painter: Museum3DPainter(
                        locations: _locationsForCurrentFloor(),
                        routePoints: _routePointsForCurrentFloor(),
                        visitedStopNames: _visitedStopNamesForCurrentFloor(),
                        currentStopName: _currentStopNameForCurrentFloor(),
                        show3D: _show3D,
                        labelMaxWidth: 120,
                        markerColor: Theme.of(context).colorScheme.primary,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                  // Route navigation button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: _openRouteFlow,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.route,
                          color: themeNotifier.surfaceColor,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  // ── Search Results Overlay ───────────────────────────────
                  if (_searchResults.isNotEmpty)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withOpacity(0.95),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final loc = _searchResults[i];
                            return ListTile(
                              leading: Icon(loc.icon, color: loc.iconColor),
                              title: Text(
                                loc.name.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                loc.subtitle.tr,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () async {
                                _searchController.clear();
                                _onSearchChanged('');
                                final floor = _floorOfStop(loc.name);
                                if (floor != null) {
                                  setState(() => _selectedFloor = floor);
                                }

                                final fromLoc =
                                    await showModalBottomSheet<_LocationOption>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.white,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (_) => _LocationPickerSheet(
                                        options: _currentConfig.locationOptions,
                                      ),
                                    );
                                if (fromLoc == null || !mounted) return;

                                final route = _buildInitialRouteFromLocations(
                                  fromLoc.name,
                                  loc.name,
                                );
                                if (route != null) {
                                  _showRouteReady(route);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ── Legend ──────────────────────────────────────────────────
            if (_activeRoute != null && !_isPreviewRoute)
              _NavigationPanel(
                route: _activeRoute!,
                currentStopIndex: _currentStopIndex,
                description: _descriptionForCurrentStop(),
                onStop: _stopNavigation,
                onNext: _nextStop,
              )
            else
              Container(
                color: themeNotifier.surfaceColor,
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _LegendItem(
                          color: Theme.of(context).colorScheme.primary,
                          label: _currentConfig.artifactLegendLabel.tr,
                        ),
                        SizedBox(width: 16),
                        _LegendItem(
                          color: _restroomColor,
                          label: 'Restrooms'.tr,
                        ),
                        SizedBox(width: 16),
                        _LegendItem(color: _stairsColor, label: 'Stairs'.tr),
                        SizedBox(width: 16),
                        _LegendItem(color: _cafeColor, label: 'Cafes'.tr),
                      ],
                    ),
                    if (AppSession.currentMuseumId.value == 1) ...[
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${'Exhibitions on'.tr} ${_selectedFloor.tr}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: themeNotifier.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ScrollConfiguration(
                        behavior: _horizontalScrollBehavior,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _floorLegendLocations().map((location) {
                              final selected =
                                  _selectedExhibition == location.name;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      _onExhibitionChipPressed(location.name),
                                  onDoubleTap: () =>
                                      _onExhibitionChipPressed(location.name),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? (location.color ??
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary)
                                                .withValues(alpha: 0.28)
                                          : (location.color ??
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary)
                                                .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        width: selected ? 1.6 : 1,
                                        color:
                                            location.color ??
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                                    ),
                                    child: Text(
                                      location.name.tr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: themeNotifier.textPrimaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Navigation flow ────────────────────────────────────────────────────

  Future<void> _openRouteFlow() async {
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => const _DetectingScreen(),
      ),
    );
    if (!mounted) return;
    if (success == null) return;
    _showLocationPicker();
  }

  Future<void> _showLocationPicker() async {
    final loc = await showModalBottomSheet<_LocationOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeNotifier.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _LocationPickerSheet(options: _currentConfig.locationOptions),
    );
    if (loc == null || !mounted) return;
    _showRoutePicker(loc, _currentConfig.routes);
  }

  Future<void> _showRoutePicker(
    _LocationOption from,
    List<_RouteOption> routes,
  ) async {
    List<_RouteOption> suggestedRoutes = routes
        .where((route) => route.stops.first.name == from.name)
        .toList();

    if (suggestedRoutes.isEmpty) {
      suggestedRoutes = _generateDynamicRoutes(from);
    }
    final route = await showModalBottomSheet<_RouteOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeNotifier.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RoutePickerSheet(routes: suggestedRoutes),
    );
    if (route == null || !mounted) return;
    _showRouteReady(route);
  }

  List<_RouteOption> _generateDynamicRoutes(_LocationOption fromOption) {
    final fromLoc = _findLocationByName(fromOption.name);
    if (fromLoc == null) return [];

    final allLocs = _currentConfig.locations
        .where(
          (l) =>
              l.name != fromLoc.name &&
              !l.name.contains('Restroom') &&
              !l.name.contains('Stairs') &&
              !l.name.contains('Entrance'),
        )
        .toList();

    final sameFloor = allLocs.where((l) => l.floor == fromLoc.floor).toList();
    final quickTargets = sameFloor.isNotEmpty
        ? sameFloor.take(2).toList()
        : allLocs.take(2).toList();

    final fullTargets = allLocs.take(5).toList();

    List<_RouteStop> buildStops(List<_MapLocation> targets) {
      final stops = <_RouteStop>[];
      var currentLoc = fromLoc;

      stops.add(
        _RouteStop(
          name: currentLoc.name,
          subtitle: _subtitleForLocation(currentLoc),
        ),
      );

      for (var target in targets) {
        if (currentLoc.floor != target.floor) {
          final fromStairs = _findLocationByName(
            'Stairs - ${currentLoc.floor}',
          );
          final toStairs = _findLocationByName('Stairs - ${target.floor}');
          if (fromStairs != null && stops.last.name != fromStairs.name) {
            stops.add(
              _RouteStop(
                name: fromStairs.name,
                subtitle: _subtitleForLocation(fromStairs),
              ),
            );
          }
          if (toStairs != null) {
            stops.add(
              _RouteStop(
                name: toStairs.name,
                subtitle: _subtitleForLocation(toStairs),
              ),
            );
          }
        }
        if (stops.isEmpty || stops.last.name != target.name) {
          stops.add(
            _RouteStop(
              name: target.name,
              subtitle: _subtitleForLocation(target),
            ),
          );
        }
        currentLoc = target;
      }
      return stops;
    }

    final quickStops = buildStops(quickTargets);
    final fullStops = buildStops(fullTargets);

    return [
      if (quickTargets.isNotEmpty)
        _RouteOption(
          emoji: '🚶',
          name: 'Quick Explorer',
          description: 'A short walk from your current location',
          duration: '15 min',
          stopsCount: quickStops.length,
          stops: quickStops,
        ),
      if (fullTargets.isNotEmpty)
        _RouteOption(
          emoji: '🧭',
          name: 'Deep Dive',
          description: 'Explore the main highlights from here',
          duration: '45 min',
          stopsCount: fullStops.length,
          stops: fullStops,
        ),
    ];
  }

  Future<void> _showRouteReady(_RouteOption route) async {
    final started = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeNotifier.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RouteReadySheet(route: route),
    );
    if (started == true && mounted) {
      _startNavigation(route);
    }
  }

  void _onExhibitionChipPressed(String exhibitionName) {
    setState(() {
      _selectedExhibition = exhibitionName;
    });
    _showExhibitionArtifactsPopup(exhibitionName);
  }

  List<_MapLocation> _spreadArtifactCluster(
    List<_MapLocation> artifacts,
    _MapLocation? anchor,
  ) {
    const double left = 0.20;
    const double right = 0.80;
    const double top = 0.12;
    const double bottom = 0.72;

    final n = artifacts.length;
    if (n == 0) return [];

    // Special case: 3 items → 2 on left column, 1 on right center
    if (n == 3) {
      final positions = [
        (x: left, y: top),
        (x: left, y: bottom),
        (x: right, y: (top + bottom) / 2),
      ];
      return List.generate(n, (i) {
        final artifact = artifacts[i];
        return _MapLocation(
          name: artifact.name,
          floor: artifact.floor,
          x: positions[i].x,
          y: positions[i].y,
          color: artifact.color,
          mapLabel: _popupLabelForArtifact(artifact.name),
        );
      });
    }

    final cols = math.max(1, math.sqrt(n.toDouble()).ceil());
    final rows = math.max(1, (n / cols).ceil());

    final spread = <_MapLocation>[];
    for (int i = 0; i < n; i++) {
      final artifact = artifacts[i];
      final row = i ~/ cols;
      final col = i % cols;

      // Center the last row if it has fewer items than cols
      final itemsInRow = (row == rows - 1) ? (n - row * cols) : cols;
      final stepX = cols > 1 ? (right - left) / (cols - 1) : 0.0;

      double x;
      if (itemsInRow == 1) {
        x = (left + right) / 2;
      } else {
        final rowWidth = (itemsInRow - 1) * stepX;
        final rowLeft = (left + right) / 2 - rowWidth / 2;
        x = rowLeft + col * stepX;
      }

      final y = rows == 1
          ? (top + bottom) / 2
          : top + row * (bottom - top) / (rows - 1);

      spread.add(
        _MapLocation(
          name: artifact.name,
          floor: artifact.floor,
          x: x,
          y: y,
          color: artifact.color,
          mapLabel: _popupLabelForArtifact(artifact.name),
        ),
      );
    }

    return spread;
  }

  String _popupLabelForArtifact(String name) {
    final codeMatch = RegExp(r'\(([^)]+)\)').firstMatch(name);
    if (codeMatch == null) {
      return name;
    }
    final code = codeMatch.group(1) ?? '';
    final title = name.replaceAll(RegExp(r'\s*\([^)]+\)'), '').trim();
    return '$title\n$code';
  }

  Future<void> _showExhibitionArtifactsPopup(String exhibitionName) async {
    if (AppSession.currentMuseumId.value != 1 || !mounted) {
      return;
    }

    final exhibitionLocation = _findLocationByName(exhibitionName);
    final artifacts =
        _independencePalaceArtifactsByExhibition[exhibitionName]
            ?.where((artifact) => artifact.floor == _selectedFloor)
            .toList() ??
        const <_MapLocation>[];

    final spreadArtifacts = _spreadArtifactCluster(
      artifacts,
      exhibitionLocation,
    );

    // Fixed entrance marker at bottom-center of popup
    final entranceMarker = _MapLocation(
      name: 'Entrance',
      floor: _selectedFloor,
      x: 0.5,
      y: 0.88,
      color: const Color(0xFF22C55E),
      mapLabel: 'Entrance',
    );

    final popupLocations = <_MapLocation>[entranceMarker, ...spreadArtifacts];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${'Artifact Map'.tr} · ${_selectedFloor.tr}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: Icon(
                        Icons.close,
                        color: themeNotifier.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  exhibitionName.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeNotifier.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: Container(
                      color: const Color(0xFF1A1A1A),
                      child: CustomPaint(
                        painter: Museum3DPainter(
                          locations: popupLocations,
                          routePoints: const <_MapLocation>[],
                          visitedStopNames: const <String>{},
                          currentStopName: null,
                          show3D: _show3D,
                          compactBackdrop: true,
                          labelMaxWidth: 126,
                          markerColor: Theme.of(
                            dialogContext,
                          ).colorScheme.primary,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  artifacts.isEmpty
                      ? 'No artifacts mapped on this floor yet.'.tr
                      : '${artifacts.length} ${'artifacts'.tr}',
                  style: TextStyle(
                    fontSize: 11,
                    color: themeNotifier.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startNavigation(_RouteOption route) {
    final firstFloor = _floorOfStop(route.stops.first.name);
    setState(() {
      _isPreviewRoute = false;
      _activeRoute = route;
      _currentStopIndex = 0;
      if (firstFloor != null) {
        _selectedFloor = firstFloor;
      }
    });
  }

  void _showPreviewRoute(_RouteOption route) {
    final firstFloor = _floorOfStop(route.stops.first.name);
    setState(() {
      _isPreviewRoute = true;
      _activeRoute = route;
      _currentStopIndex = 0;
      if (firstFloor != null) {
        _selectedFloor = firstFloor;
      }
    });
  }

  void _stopNavigation() {
    setState(() {
      _isPreviewRoute = false;
      _activeRoute = null;
      _currentStopIndex = 0;
    });
  }

  void _nextStop() {
    final route = _activeRoute;
    if (route == null) return;
    if (_currentStopIndex >= route.stops.length - 1) {
      _stopNavigation();
      return;
    }
    final nextIndex = _currentStopIndex + 1;
    final nextFloor = _floorOfStop(route.stops[nextIndex].name);
    setState(() {
      _currentStopIndex = nextIndex;
      if (nextFloor != null) {
        _selectedFloor = nextFloor;
      }
    });
  }

  List<_MapLocation> _routePointsForCurrentFloor() {
    final route = _activeRoute;
    if (route == null) {
      return const <_MapLocation>[];
    }
    final points = <_MapLocation>[];
    for (final stop in route.stops) {
      final loc = _findLocationByName(stop.name);
      if (loc != null && loc.floor == _selectedFloor) {
        points.add(loc);
      }
    }
    return points;
  }

  Set<String> _visitedStopNamesForCurrentFloor() {
    final route = _activeRoute;
    if (route == null || _isPreviewRoute) {
      return const <String>{};
    }
    final visited = <String>{};
    for (int i = 0; i < _currentStopIndex; i++) {
      final stopName = route.stops[i].name;
      final loc = _findLocationByName(stopName);
      if (loc != null && loc.floor == _selectedFloor) {
        visited.add(stopName);
      }
    }
    return visited;
  }

  String? _currentStopNameForCurrentFloor() {
    final route = _activeRoute;
    if (route == null || route.stops.isEmpty || _isPreviewRoute) {
      return null;
    }
    final stopName = route.stops[_currentStopIndex].name;
    final loc = _findLocationByName(stopName);
    if (loc != null && loc.floor == _selectedFloor) {
      return stopName;
    }
    return null;
  }

  String _descriptionForCurrentStop() {
    final route = _activeRoute;
    if (route == null) {
      return '';
    }
    final stopName = route.stops[_currentStopIndex].name;
    return _currentConfig.stopDescriptions[stopName] ??
        'Follow the highlighted path to continue your museum journey.';
  }

  _MapLocation? _findLocationByName(String name) {
    for (final loc in _currentConfig.locations) {
      if (loc.name == name) {
        return loc;
      }
    }
    return null;
  }

  String? _floorOfStop(String stopName) {
    return _findLocationByName(stopName)?.floor;
  }

  _RouteOption? _buildInitialRouteFromLocations(
    String fromName,
    String toName,
  ) {
    final from = _findLocationByName(fromName);
    final to = _findLocationByName(toName);
    if (from == null || to == null) {
      return null;
    }

    final stops = <_RouteStop>[];

    void addStop(_MapLocation location) {
      if (stops.any((stop) => stop.name == location.name)) {
        return;
      }
      stops.add(
        _RouteStop(
          name: location.name,
          subtitle: _subtitleForLocation(location),
        ),
      );
    }

    addStop(from);
    if (from.floor != to.floor) {
      final fromStairs = _findLocationByName('Stairs - ${from.floor}');
      final toStairs = _findLocationByName('Stairs - ${to.floor}');
      if (fromStairs != null) {
        addStop(fromStairs);
      }
      if (toStairs != null) {
        addStop(toStairs);
      }
    }
    addStop(to);

    return _RouteOption(
      emoji: '🧭',
      name: 'Custom Route',
      description: 'Guidance from ${from.name} to ${to.name}',
      duration: from.floor == to.floor ? 'Direct route' : 'Cross-floor route',
      stopsCount: stops.length,
      stops: stops,
    );
  }

  _RouteOption? _buildInitialRoute() {
    if (widget.initialFromLocationName == null ||
        widget.initialToLocationName == null) {
      return null;
    }
    return _buildInitialRouteFromLocations(
      widget.initialFromLocationName!,
      widget.initialToLocationName!,
    );
  }

  static String _subtitleForLocation(_MapLocation location) {
    final hall = location.name.contains('Entrance')
        ? 'Entrance'
        : location.name.contains('Restroom')
        ? 'Facilities'
        : location.name.contains('Stairs')
        ? 'Transition Point'
        : 'Gallery';
    return '$hall · ${location.floor}';
  }
}

class _MuseumMapConfig {
  const _MuseumMapConfig({
    required this.artifactLegendLabel,
    required this.locations,
    required this.stopDescriptions,
    required this.locationOptions,
    required this.routes,
    this.floors = const ['Floor 1', 'Floor 2'],
  });

  final String artifactLegendLabel;
  final List<_MapLocation> locations;
  final Map<String, String> stopDescriptions;
  final List<_LocationOption> locationOptions;
  final List<_RouteOption> routes;
  final List<String> floors;
}

// ── Route data ────────────────────────────────────────────────────────────

class _LocationOption {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  _LocationOption({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });
}

class _RouteStop {
  final String name;
  final String subtitle;
  const _RouteStop({required this.name, required this.subtitle});
}

class _RouteOption {
  final String emoji;
  final String name;
  final String description;
  final String duration;
  final int stopsCount;
  final List<_RouteStop> stops;
  const _RouteOption({
    required this.emoji,
    required this.name,
    required this.description,
    required this.duration,
    required this.stopsCount,
    required this.stops,
  });
}

Map<int, _MuseumMapConfig> _museumConfigs = <int, _MuseumMapConfig>{
  1: _MuseumMapConfig(
    artifactLegendLabel: 'Exhibitions',
    floors: const ['Floor 1', 'Floor 2'],
    locations: <_MapLocation>[
      _MapLocation(
        name: 'Main Entrance',
        floor: 'Floor 1',
        x: 0.5,
        y: 0.82,
        color: Color(0xFF22C55E),
        mapLabel: 'Entrance',
      ),
      _MapLocation(
        name: 'Fall of Saigon: April 30, 1975',
        floor: 'Floor 1',
        x: 0.22,
        y: 0.26,
        mapLabel: 'Fall of Saigon:\nApril 30, 1975',
      ),
      _MapLocation(
        name: 'Presidential Power & Governance',
        floor: 'Floor 1',
        x: 0.74,
        y: 0.24,
        mapLabel: 'Presidential Power\n& Governance',
      ),
      _MapLocation(
        name: 'Diplomacy & State Ceremony',
        floor: 'Floor 1',
        x: 0.24,
        y: 0.58,
        mapLabel: 'Diplomacy &\nState Ceremony',
      ),
      _MapLocation(
        name: 'Presidential Lifestyle',
        floor: 'Floor 1',
        x: 0.74,
        y: 0.58,
        mapLabel: 'Presidential\nLifestyle',
      ),
      _MapLocation(
        name: 'Restroom - Floor 1',
        floor: 'Floor 1',
        x: 0.14,
        y: 0.72,
        color: _Museum3DMapScreenState._restroomColor,
        mapLabel: 'WC',
      ),
      _MapLocation(
        name: 'Stairs - Floor 1',
        floor: 'Floor 1',
        x: 0.88,
        y: 0.76,
        color: _Museum3DMapScreenState._stairsColor,
        mapLabel: 'Stairs',
      ),
      _MapLocation(
        name: 'War Command Bunker',
        floor: 'Floor 2',
        x: 0.3,
        y: 0.34,
        mapLabel: 'War Command\nBunker',
      ),
      _MapLocation(
        name: 'Air Warfare & Evacuation',
        floor: 'Floor 2',
        x: 0.72,
        y: 0.34,
        mapLabel: 'Air Warfare &\nEvacuation',
      ),
      _MapLocation(
        name: 'Restroom - Floor 2',
        floor: 'Floor 2',
        x: 0.14,
        y: 0.72,
        color: _Museum3DMapScreenState._restroomColor,
        mapLabel: 'WC',
      ),
      _MapLocation(
        name: 'Stairs - Floor 2',
        floor: 'Floor 2',
        x: 0.88,
        y: 0.76,
        color: _Museum3DMapScreenState._stairsColor,
        mapLabel: 'Stairs',
      ),
    ],
    stopDescriptions: <String, String>{
      'Main Entrance':
          'Start from the main entrance and continue through the exhibition route of Independence Palace.',
      'Fall of Saigon: April 30, 1975':
          'This highlight exhibition presents Tank 390, Tank 843, Jeep M151A2, and F-5E bombing marks as the narrative of April 30, 1975 unfolds.',
      'Presidential Power & Governance':
          'A decision-making zone focused on the Cabinet Room Table, Vice President\'s Desk, and National Security Council Maps.',
      'Diplomacy & State Ceremony':
          'A ceremonial exhibition centered on the Binh Ngo Dai Cao lacquer painting and The Golden Dragon Tapestry.',
      'Presidential Lifestyle':
          'A domestic and symbolic power exhibition featuring the Mercedes-Benz 200 W110 and The Presidential Bed.',
      'War Command Bunker':
          'A bunker-centered exhibition covering the War Command Bunker Map and Telecommunications Center.',
      'Air Warfare & Evacuation':
          'A centerpiece exhibition about the UH-1 Helicopter, rooftop evacuation, and the final days of the war.',
    },
    locationOptions: _buildIndependencePalaceLocationOptions(),
    routes: _independencePalaceRoutes,
  ),
  2: _MuseumMapConfig(
    artifactLegendLabel: 'War Exhibits',
    locations: <_MapLocation>[
      _MapLocation(
        name: 'War Crimes Exhibition',
        floor: 'Floor 1',
        x: 0.22,
        y: 0.22,
      ),
      _MapLocation(name: 'Guillotine', floor: 'Floor 1', x: 0.62, y: 0.28),
      _MapLocation(name: 'Tiger Cages', floor: 'Floor 1', x: 0.78, y: 0.56),
      _MapLocation(
        name: 'Main Entrance',
        floor: 'Floor 1',
        x: 0.32,
        y: 0.82,
        color: Color(0xFF22C55E),
      ),
      _MapLocation(
        name: 'Restroom - Floor 1',
        floor: 'Floor 1',
        x: 0.12,
        y: 0.7,
        color: _Museum3DMapScreenState._restroomColor,
      ),
      _MapLocation(
        name: 'Stairs - Floor 1',
        floor: 'Floor 1',
        x: 0.88,
        y: 0.78,
        color: _Museum3DMapScreenState._stairsColor,
      ),
      _MapLocation(
        name: 'International Support Gallery',
        floor: 'Floor 2',
        x: 0.2,
        y: 0.22,
      ),
      _MapLocation(
        name: 'Peace and Reconciliation Display',
        floor: 'Floor 2',
        x: 0.62,
        y: 0.34,
      ),
      _MapLocation(
        name: 'Documentary Corner',
        floor: 'Floor 2',
        x: 0.78,
        y: 0.56,
      ),
      _MapLocation(
        name: 'Souvenir Shop',
        floor: 'Floor 2',
        x: 0.42,
        y: 0.56,
        color: Color(0xFFF59E0B),
      ),
      _MapLocation(
        name: 'Cafe Break',
        floor: 'Floor 2',
        x: 0.3,
        y: 0.78,
        color: Color(0xFF8B5E3C),
      ),
      _MapLocation(
        name: 'Restroom - Floor 2',
        floor: 'Floor 2',
        x: 0.12,
        y: 0.72,
        color: _Museum3DMapScreenState._restroomColor,
      ),
      _MapLocation(
        name: 'Stairs - Floor 2',
        floor: 'Floor 2',
        x: 0.88,
        y: 0.75,
        color: _Museum3DMapScreenState._stairsColor,
      ),
    ],
    stopDescriptions: <String, String>{
      'War Crimes Exhibition':
          'A central gallery documenting wartime devastation and eyewitness evidence.',
      'Guillotine':
          'A preserved execution device from the colonial era, reflecting a dark chapter in resistance history.',
      'Tiger Cages':
          'A reconstruction of prison cells used to detain political prisoners in brutal conditions.',
      'International Support Gallery':
          'This gallery highlights anti-war solidarity from around the world.',
      'Peace and Reconciliation Display':
          'An exhibit focused on recovery, remembrance, and reconciliation after conflict.',
    },
    locationOptions: _buildWarRemnantsLocationOptions(),
    routes: _warRemnantsRoutes,
  ),
  3: _MuseumMapConfig(
    artifactLegendLabel: 'Artworks',
    locations: <_MapLocation>[
      _MapLocation(
        name: 'Contemporary Vietnamese Art',
        floor: 'Floor 1',
        x: 0.2,
        y: 0.24,
      ),
      _MapLocation(
        name: 'Lacquer Painting Rural Life',
        floor: 'Floor 1',
        x: 0.58,
        y: 0.34,
      ),
      _MapLocation(
        name: 'Main Entrance',
        floor: 'Floor 1',
        x: 0.34,
        y: 0.82,
        color: Color(0xFF22C55E),
      ),
      _MapLocation(
        name: 'Restroom - Floor 1',
        floor: 'Floor 1',
        x: 0.12,
        y: 0.72,
        color: _Museum3DMapScreenState._restroomColor,
      ),
      _MapLocation(
        name: 'Stairs - Floor 1',
        floor: 'Floor 1',
        x: 0.88,
        y: 0.78,
        color: _Museum3DMapScreenState._stairsColor,
      ),
      _MapLocation(
        name: 'Traditional Crafts Exhibition',
        floor: 'Floor 2',
        x: 0.2,
        y: 0.22,
      ),
      _MapLocation(name: 'Buddhist Statue', floor: 'Floor 2', x: 0.6, y: 0.36),
      _MapLocation(
        name: 'International Art Collection',
        floor: 'Floor 2',
        x: 0.8,
        y: 0.56,
      ),
      _MapLocation(
        name: 'Museum Cafe',
        floor: 'Floor 2',
        x: 0.32,
        y: 0.78,
        color: Color(0xFF8B5E3C),
      ),
      _MapLocation(
        name: 'Restroom - Floor 2',
        floor: 'Floor 2',
        x: 0.12,
        y: 0.72,
        color: _Museum3DMapScreenState._restroomColor,
      ),
      _MapLocation(
        name: 'Stairs - Floor 2',
        floor: 'Floor 2',
        x: 0.88,
        y: 0.76,
        color: _Museum3DMapScreenState._stairsColor,
      ),
    ],
    stopDescriptions: <String, String>{
      'Contemporary Vietnamese Art':
          'A curated display of modern Vietnamese artistic expression and cultural themes.',
      'Lacquer Painting Rural Life':
          'A lacquer masterpiece that captures the rhythm and beauty of rural Vietnamese life.',
      'Traditional Crafts Exhibition':
          'An exhibit showcasing handcrafted objects and decorative arts from across Vietnam.',
      'Buddhist Statue':
          'A 17th-century bronze statue highlighting the spiritual and sculptural heritage of Vietnam.',
      'International Art Collection':
          'A mixed collection of international works presented alongside Vietnamese fine arts.',
    },
    locationOptions: _buildFineArtsLocationOptions(),
    routes: _fineArtsRoutes,
  ),
  4: _MuseumMapConfig(
    artifactLegendLabel: 'City Heritage',
    locations: <_MapLocation>[
      _MapLocation(
        name: 'City History Journey Hall',
        floor: 'Floor 1',
        x: 0.22,
        y: 0.24,
      ),
      _MapLocation(
        name: 'Traditional Ao Dai',
        floor: 'Floor 1',
        x: 0.62,
        y: 0.34,
      ),
      _MapLocation(
        name: 'Main Entrance',
        floor: 'Floor 1',
        x: 0.35,
        y: 0.82,
        color: Color(0xFF22C55E),
      ),
      _MapLocation(
        name: 'Restroom - Floor 1',
        floor: 'Floor 1',
        x: 0.12,
        y: 0.72,
        color: _Museum3DMapScreenState._restroomColor,
      ),
      _MapLocation(
        name: 'Stairs - Floor 1',
        floor: 'Floor 1',
        x: 0.88,
        y: 0.78,
        color: _Museum3DMapScreenState._stairsColor,
      ),
      _MapLocation(
        name: 'Cultural Heritage Trail Hall',
        floor: 'Floor 2',
        x: 0.22,
        y: 0.22,
      ),
      _MapLocation(name: 'Saigon Map 1930', floor: 'Floor 2', x: 0.62, y: 0.38),
      _MapLocation(
        name: 'Archive Reading Corner',
        floor: 'Floor 2',
        x: 0.78,
        y: 0.56,
      ),
      _MapLocation(
        name: 'Museum Cafe',
        floor: 'Floor 2',
        x: 0.3,
        y: 0.78,
        color: Color(0xFF8B5E3C),
      ),
      _MapLocation(
        name: 'Restroom - Floor 2',
        floor: 'Floor 2',
        x: 0.12,
        y: 0.72,
        color: _Museum3DMapScreenState._restroomColor,
      ),
      _MapLocation(
        name: 'Stairs - Floor 2',
        floor: 'Floor 2',
        x: 0.88,
        y: 0.75,
        color: _Museum3DMapScreenState._stairsColor,
      ),
    ],
    stopDescriptions: <String, String>{
      'City History Journey Hall':
          'A gallery introducing the transformation of Ho Chi Minh City across major historical eras.',
      'Traditional Ao Dai':
          'A classic Ao Dai garment illustrating cultural identity and changing urban fashion.',
      'Cultural Heritage Trail Hall':
          'An exhibit about the city\'s architecture, communities, and cultural continuity.',
      'Saigon Map 1930':
          'A historical map that reveals the colonial-era layout and expansion of Saigon.',
      'Archive Reading Corner':
          'A quiet corner where curated archive reproductions and city records are displayed.',
    },
    locationOptions: _buildCityMuseumLocationOptions(),
    routes: _cityMuseumRoutes,
  ),
};

const Map<String, List<_MapLocation>>
_independencePalaceArtifactsByExhibition = {
  'Fall of Saigon: April 30, 1975': <_MapLocation>[
    _MapLocation(name: 'Tank 390 (IP-001)', floor: 'Floor 1', x: 0.16, y: 0.2),
    _MapLocation(name: 'Tank 843 (IP-002)', floor: 'Floor 1', x: 0.29, y: 0.18),
    _MapLocation(
      name: 'Jeep M151A2 (IP-007)',
      floor: 'Floor 1',
      x: 0.21,
      y: 0.34,
    ),
    _MapLocation(
      name: 'F-5E Bombing Marks (IP-006)',
      floor: 'Floor 1',
      x: 0.33,
      y: 0.3,
    ),
  ],
  'Presidential Power & Governance': <_MapLocation>[
    _MapLocation(
      name: 'Cabinet Room Table (IP-009)',
      floor: 'Floor 1',
      x: 0.67,
      y: 0.2,
    ),
    _MapLocation(
      name: 'Vice President\'s Desk (IP-015)',
      floor: 'Floor 1',
      x: 0.79,
      y: 0.18,
    ),
    _MapLocation(
      name: 'National Security Council Maps (IP-013)',
      floor: 'Floor 1',
      x: 0.73,
      y: 0.34,
    ),
  ],
  'Diplomacy & State Ceremony': <_MapLocation>[
    _MapLocation(
      name: 'Binh Ngo Dai Cao Lacquer Painting (IP-008)',
      floor: 'Floor 1',
      x: 0.18,
      y: 0.5,
    ),
    _MapLocation(
      name: 'The Golden Dragon Tapestry (IP-010)',
      floor: 'Floor 1',
      x: 0.29,
      y: 0.64,
    ),
  ],
  'Presidential Lifestyle': <_MapLocation>[
    _MapLocation(
      name: 'Mercedes-Benz 200 W110 (IP-004)',
      floor: 'Floor 1',
      x: 0.68,
      y: 0.5,
    ),
    _MapLocation(
      name: 'The Presidential Bed (IP-012)',
      floor: 'Floor 1',
      x: 0.8,
      y: 0.63,
    ),
  ],
  'War Command Bunker': <_MapLocation>[
    _MapLocation(
      name: 'War Command Bunker Map (IP-005)',
      floor: 'Floor 2',
      x: 0.26,
      y: 0.3,
    ),
    _MapLocation(
      name: 'Telecommunications Center (IP-011)',
      floor: 'Floor 2',
      x: 0.36,
      y: 0.42,
    ),
  ],
  'Air Warfare & Evacuation': <_MapLocation>[
    _MapLocation(
      name: 'UH-1 Helicopter (IP-003)',
      floor: 'Floor 2',
      x: 0.74,
      y: 0.3,
    ),
  ],
};

List<_LocationOption> _buildIndependencePalaceLocationOptions() =>
    <_LocationOption>[
      _LocationOption(
        name: 'Main Entrance',
        subtitle: 'Entrance — Floor 1',
        icon: Icons.meeting_room_outlined,
        iconColor: const Color(0xFF22C55E),
      ),
      _LocationOption(
        name: 'Fall of Saigon: April 30, 1975',
        subtitle: 'Highlight Exhibition — Floor 1',
        icon: Icons.history_edu_outlined,
        iconColor: Colors.redAccent,
      ),
      _LocationOption(
        name: 'Presidential Power & Governance',
        subtitle: 'Decision-Making Center — Floor 1',
        icon: Icons.account_balance_outlined,
        iconColor: Colors.redAccent,
      ),
      _LocationOption(
        name: 'Diplomacy & State Ceremony',
        subtitle: 'Diplomatic Hall — Floor 1',
        icon: Icons.auto_awesome_outlined,
        iconColor: Colors.redAccent,
      ),
      _LocationOption(
        name: 'Presidential Lifestyle',
        subtitle: 'Private Quarters — Floor 1',
        icon: Icons.king_bed_outlined,
        iconColor: Colors.redAccent,
      ),
      _LocationOption(
        name: 'Restroom - Floor 1',
        subtitle: 'Facilities — Floor 1',
        icon: Icons.wc_outlined,
        iconColor: Color(0xFFF59E0B),
      ),
      _LocationOption(
        name: 'Stairs - Floor 1',
        subtitle: 'Transition — Floor 1',
        icon: Icons.stairs_outlined,
        iconColor: Color(0xFF60A5FA),
      ),
      _LocationOption(
        name: 'War Command Bunker',
        subtitle: 'Command Center — Floor 2',
        icon: Icons.security_outlined,
        iconColor: Colors.redAccent,
      ),
      _LocationOption(
        name: 'Air Warfare & Evacuation',
        subtitle: 'Helipad Centerpiece — Floor 2',
        icon: Icons.flight_takeoff_outlined,
        iconColor: Colors.redAccent,
      ),
      _LocationOption(
        name: 'Restroom - Floor 2',
        subtitle: 'Facilities — Floor 2',
        icon: Icons.wc_outlined,
        iconColor: Color(0xFFF59E0B),
      ),
      _LocationOption(
        name: 'Stairs - Floor 2',
        subtitle: 'Transition — Floor 2',
        icon: Icons.stairs_outlined,
        iconColor: Color(0xFF60A5FA),
      ),
    ];

List<_LocationOption> _buildWarRemnantsLocationOptions() => <_LocationOption>[
  _LocationOption(
    name: 'War Crimes Exhibition',
    subtitle: 'Building A — Floor 1',
    icon: Icons.location_on,
    iconColor: Colors.red,
  ),
  _LocationOption(
    name: 'Guillotine',
    subtitle: 'Historical Hall — Floor 1',
    icon: Icons.account_balance_outlined,
    iconColor: Colors.red,
  ),
  _LocationOption(
    name: 'Tiger Cages',
    subtitle: 'Outdoor Area — Floor 1',
    icon: Icons.grid_view_outlined,
    iconColor: Colors.red,
  ),
  _LocationOption(
    name: 'Main Entrance',
    subtitle: 'Entrance — Floor 1',
    icon: Icons.meeting_room_outlined,
    iconColor: themeNotifier.textSecondaryColor,
  ),
  _LocationOption(
    name: 'Restroom - Floor 1',
    subtitle: 'South Wing — Floor 1',
    icon: Icons.wc_outlined,
    iconColor: Color(0xFFF59E0B),
  ),
  _LocationOption(
    name: 'Stairs - Floor 1',
    subtitle: 'East Wing — Floor 1',
    icon: Icons.stairs_outlined,
    iconColor: Color(0xFF60A5FA),
  ),
  _LocationOption(
    name: 'International Support Gallery',
    subtitle: 'Building B — Floor 2',
    icon: Icons.location_on,
    iconColor: Colors.red,
  ),
  _LocationOption(
    name: 'Peace and Reconciliation Display',
    subtitle: 'Memorial Wing — Floor 2',
    icon: Icons.location_on,
    iconColor: Colors.red,
  ),
  _LocationOption(
    name: 'Documentary Corner',
    subtitle: 'Archive Hall — Floor 2',
    icon: Icons.visibility_outlined,
    iconColor: Colors.red,
  ),
  _LocationOption(
    name: 'Restroom - Floor 2',
    subtitle: 'South Wing — Floor 2',
    icon: Icons.wc_outlined,
    iconColor: Color(0xFFF59E0B),
  ),
  _LocationOption(
    name: 'Stairs - Floor 2',
    subtitle: 'East Wing — Floor 2',
    icon: Icons.stairs_outlined,
    iconColor: Color(0xFF60A5FA),
  ),
  _LocationOption(
    name: 'Cafe Break',
    subtitle: 'Upper Lobby — Floor 2',
    icon: Icons.coffee_outlined,
    iconColor: Color(0xFF8B5E3C),
  ),
];

List<_LocationOption> _buildFineArtsLocationOptions() => <_LocationOption>[
  _LocationOption(
    name: 'Contemporary Vietnamese Art',
    subtitle: 'Main Gallery — Floor 1',
    icon: Icons.palette_outlined,
    iconColor: Colors.deepPurple,
  ),
  _LocationOption(
    name: 'Lacquer Painting Rural Life',
    subtitle: 'Main Gallery — Floor 1',
    icon: Icons.brush_outlined,
    iconColor: Colors.deepPurple,
  ),
  _LocationOption(
    name: 'Main Entrance',
    subtitle: 'Entrance — Floor 1',
    icon: Icons.meeting_room_outlined,
    iconColor: themeNotifier.textSecondaryColor,
  ),
  _LocationOption(
    name: 'Restroom - Floor 1',
    subtitle: 'South Wing — Floor 1',
    icon: Icons.wc_outlined,
    iconColor: Color(0xFFF59E0B),
  ),
  _LocationOption(
    name: 'Stairs - Floor 1',
    subtitle: 'East Wing — Floor 1',
    icon: Icons.stairs_outlined,
    iconColor: Color(0xFF60A5FA),
  ),
  _LocationOption(
    name: 'Traditional Crafts Exhibition',
    subtitle: 'Heritage Wing — Floor 2',
    icon: Icons.palette_outlined,
    iconColor: Colors.deepPurple,
  ),
  _LocationOption(
    name: 'Buddhist Statue',
    subtitle: 'Sculpture Hall — Floor 2',
    icon: Icons.account_balance_outlined,
    iconColor: Colors.deepPurple,
  ),
  _LocationOption(
    name: 'International Art Collection',
    subtitle: 'International Gallery — Floor 2',
    icon: Icons.image_outlined,
    iconColor: Colors.deepPurple,
  ),
  _LocationOption(
    name: 'Restroom - Floor 2',
    subtitle: 'South Wing — Floor 2',
    icon: Icons.wc_outlined,
    iconColor: Color(0xFFF59E0B),
  ),
  _LocationOption(
    name: 'Stairs - Floor 2',
    subtitle: 'East Wing — Floor 2',
    icon: Icons.stairs_outlined,
    iconColor: Color(0xFF60A5FA),
  ),
  _LocationOption(
    name: 'Museum Cafe',
    subtitle: 'Upper Lobby — Floor 2',
    icon: Icons.coffee_outlined,
    iconColor: Color(0xFF8B5E3C),
  ),
];

List<_LocationOption> _buildCityMuseumLocationOptions() => <_LocationOption>[
  _LocationOption(
    name: 'City History Journey Hall',
    subtitle: 'Main Gallery — Floor 1',
    icon: Icons.history_edu_outlined,
    iconColor: Colors.teal,
  ),
  _LocationOption(
    name: 'Traditional Ao Dai',
    subtitle: 'Textile Hall — Floor 1',
    icon: Icons.checkroom_outlined,
    iconColor: Colors.teal,
  ),
  _LocationOption(
    name: 'Main Entrance',
    subtitle: 'Entrance — Floor 1',
    icon: Icons.meeting_room_outlined,
    iconColor: themeNotifier.textSecondaryColor,
  ),
  _LocationOption(
    name: 'Restroom - Floor 1',
    subtitle: 'South Wing — Floor 1',
    icon: Icons.wc_outlined,
    iconColor: Color(0xFFF59E0B),
  ),
  _LocationOption(
    name: 'Stairs - Floor 1',
    subtitle: 'East Wing — Floor 1',
    icon: Icons.stairs_outlined,
    iconColor: Color(0xFF60A5FA),
  ),
  _LocationOption(
    name: 'Cultural Heritage Trail Hall',
    subtitle: 'Heritage Wing — Floor 2',
    icon: Icons.history_edu_outlined,
    iconColor: Colors.teal,
  ),
  _LocationOption(
    name: 'Saigon Map 1930',
    subtitle: 'Archive Hall — Floor 2',
    icon: Icons.map_outlined,
    iconColor: Colors.teal,
  ),
  _LocationOption(
    name: 'Archive Reading Corner',
    subtitle: 'Research Corner — Floor 2',
    icon: Icons.menu_book_outlined,
    iconColor: Colors.teal,
  ),
  _LocationOption(
    name: 'Restroom - Floor 2',
    subtitle: 'South Wing — Floor 2',
    icon: Icons.wc_outlined,
    iconColor: Color(0xFFF59E0B),
  ),
  _LocationOption(
    name: 'Stairs - Floor 2',
    subtitle: 'East Wing — Floor 2',
    icon: Icons.stairs_outlined,
    iconColor: Color(0xFF60A5FA),
  ),
  _LocationOption(
    name: 'Museum Cafe',
    subtitle: 'Upper Lobby — Floor 2',
    icon: Icons.coffee_outlined,
    iconColor: Color(0xFF8B5E3C),
  ),
];

const _independencePalaceRoutes = <_RouteOption>[
  _RouteOption(
    emoji: '⚡',
    name: 'Floor 1 Highlights',
    description: 'A fast route through the ceremonial and public-facing spaces',
    duration: '30 min',
    stopsCount: 4,
    stops: [
      _RouteStop(name: 'Main Entrance', subtitle: 'Entrance · Floor 1'),
      _RouteStop(
        name: 'Fall of Saigon: April 30, 1975',
        subtitle: 'Highlight Exhibition · Floor 1',
      ),
      _RouteStop(
        name: 'Diplomacy & State Ceremony',
        subtitle: 'Diplomatic Hall · Floor 1',
      ),
      _RouteStop(
        name: 'Presidential Lifestyle',
        subtitle: 'Private Quarters · Floor 1',
      ),
    ],
  ),
  _RouteOption(
    emoji: '🏛',
    name: 'Public & Ceremonial Route',
    description:
        'Follow governance, diplomacy, and presidential lifestyle across Floor 1',
    duration: '90 min',
    stopsCount: 5,
    stops: [
      _RouteStop(name: 'Main Entrance', subtitle: 'Entrance · Floor 1'),
      _RouteStop(
        name: 'Presidential Power & Governance',
        subtitle: 'Decision-Making Center · Floor 1',
      ),
      _RouteStop(
        name: 'Diplomacy & State Ceremony',
        subtitle: 'Diplomatic Hall · Floor 1',
      ),
      _RouteStop(
        name: 'Presidential Lifestyle',
        subtitle: 'Private Quarters · Floor 1',
      ),
      _RouteStop(
        name: 'Fall of Saigon: April 30, 1975',
        subtitle: 'Highlight Exhibition · Floor 1',
      ),
    ],
  ),
  _RouteOption(
    emoji: '🕵',
    name: 'War Operations & Bunker',
    description:
        'Focus on secret command infrastructure and the evacuation narrative on Floor 2',
    duration: '60 min',
    stopsCount: 5,
    stops: [
      _RouteStop(name: 'Main Entrance', subtitle: 'Entrance · Floor 1'),
      _RouteStop(name: 'Stairs - Floor 1', subtitle: 'Transition · Floor 1'),
      _RouteStop(name: 'Stairs - Floor 2', subtitle: 'Transition · Floor 2'),
      _RouteStop(
        name: 'War Command Bunker',
        subtitle: 'Command Center · Floor 2',
      ),
      _RouteStop(
        name: 'Air Warfare & Evacuation',
        subtitle: 'Helipad Centerpiece · Floor 2',
      ),
    ],
  ),
  _RouteOption(
    emoji: '🌟',
    name: 'Full Palace Narrative',
    description:
        'Complete walkthrough of all six exhibitions across two thematic floors',
    duration: '2 hours',
    stopsCount: 9,
    stops: [
      _RouteStop(name: 'Main Entrance', subtitle: 'Entrance · Floor 1'),
      _RouteStop(
        name: 'Fall of Saigon: April 30, 1975',
        subtitle: 'Highlight Exhibition · Floor 1',
      ),
      _RouteStop(
        name: 'Presidential Power & Governance',
        subtitle: 'Decision-Making Center · Floor 1',
      ),
      _RouteStop(
        name: 'Diplomacy & State Ceremony',
        subtitle: 'Diplomatic Hall · Floor 1',
      ),
      _RouteStop(
        name: 'Presidential Lifestyle',
        subtitle: 'Private Quarters · Floor 1',
      ),
      _RouteStop(name: 'Stairs - Floor 1', subtitle: 'Transition · Floor 1'),
      _RouteStop(name: 'Stairs - Floor 2', subtitle: 'Transition · Floor 2'),
      _RouteStop(
        name: 'War Command Bunker',
        subtitle: 'Command Center · Floor 2',
      ),
      _RouteStop(
        name: 'Air Warfare & Evacuation',
        subtitle: 'Helipad Centerpiece · Floor 2',
      ),
    ],
  ),
];

const _warRemnantsRoutes = <_RouteOption>[
  _RouteOption(
    emoji: '🔥',
    name: 'War History Path',
    description: 'Key wartime exhibits and evidence galleries',
    duration: '90 min',
    stopsCount: 7,
    stops: [
      _RouteStop(name: 'Main Entrance', subtitle: 'Entrance · Floor 1'),
      _RouteStop(
        name: 'War Crimes Exhibition',
        subtitle: 'Building A · Floor 1',
      ),
      _RouteStop(name: 'Guillotine', subtitle: 'Historical Hall · Floor 1'),
      _RouteStop(name: 'Tiger Cages', subtitle: 'Outdoor Area · Floor 1'),
      _RouteStop(name: 'Stairs - Floor 1', subtitle: 'Transition · Floor 1'),
      _RouteStop(name: 'Stairs - Floor 2', subtitle: 'Transition · Floor 2'),
      _RouteStop(
        name: 'Peace and Reconciliation Display',
        subtitle: 'Memorial Wing · Floor 2',
      ),
    ],
  ),
  _RouteOption(
    emoji: '⚡',
    name: 'Quick Overview',
    description: 'A short route through the core museum highlights',
    duration: '30 min',
    stopsCount: 5,
    stops: [
      _RouteStop(name: 'Main Entrance', subtitle: 'Entrance · Floor 1'),
      _RouteStop(
        name: 'War Crimes Exhibition',
        subtitle: 'Building A · Floor 1',
      ),
      _RouteStop(name: 'Stairs - Floor 1', subtitle: 'Transition · Floor 1'),
      _RouteStop(name: 'Stairs - Floor 2', subtitle: 'Transition · Floor 2'),
      _RouteStop(
        name: 'International Support Gallery',
        subtitle: 'Building B · Floor 2',
      ),
    ],
  ),
];

const _fineArtsRoutes = <_RouteOption>[
  _RouteOption(
    emoji: '🎨',
    name: 'Masterpieces Collection',
    description: 'A curated route through signature fine art works',
    duration: '60 min',
    stopsCount: 6,
    stops: [
      _RouteStop(name: 'Main Entrance', subtitle: 'Entrance · Floor 1'),
      _RouteStop(
        name: 'Contemporary Vietnamese Art',
        subtitle: 'Main Gallery · Floor 1',
      ),
      _RouteStop(
        name: 'Lacquer Painting Rural Life',
        subtitle: 'Main Gallery · Floor 1',
      ),
      _RouteStop(name: 'Stairs - Floor 1', subtitle: 'Transition · Floor 1'),
      _RouteStop(name: 'Stairs - Floor 2', subtitle: 'Transition · Floor 2'),
      _RouteStop(name: 'Buddhist Statue', subtitle: 'Sculpture Hall · Floor 2'),
    ],
  ),
  _RouteOption(
    emoji: '🪷',
    name: 'Traditional Arts Walk',
    description: 'Explore traditional Vietnamese craft and sculpture',
    duration: '40 min',
    stopsCount: 5,
    stops: [
      _RouteStop(name: 'Main Entrance', subtitle: 'Entrance · Floor 1'),
      _RouteStop(name: 'Stairs - Floor 1', subtitle: 'Transition · Floor 1'),
      _RouteStop(name: 'Stairs - Floor 2', subtitle: 'Transition · Floor 2'),
      _RouteStop(
        name: 'Traditional Crafts Exhibition',
        subtitle: 'Heritage Wing · Floor 2',
      ),
      _RouteStop(name: 'Buddhist Statue', subtitle: 'Sculpture Hall · Floor 2'),
    ],
  ),
];

const _cityMuseumRoutes = <_RouteOption>[
  _RouteOption(
    emoji: '🏙',
    name: 'City History Journey',
    description:
        'A route through key exhibits on the history of Saigon and Ho Chi Minh City',
    duration: '75 min',
    stopsCount: 6,
    stops: [
      _RouteStop(name: 'Main Entrance', subtitle: 'Entrance · Floor 1'),
      _RouteStop(
        name: 'City History Journey Hall',
        subtitle: 'Main Gallery · Floor 1',
      ),
      _RouteStop(
        name: 'Traditional Ao Dai',
        subtitle: 'Textile Hall · Floor 1',
      ),
      _RouteStop(name: 'Stairs - Floor 1', subtitle: 'Transition · Floor 1'),
      _RouteStop(name: 'Stairs - Floor 2', subtitle: 'Transition · Floor 2'),
      _RouteStop(name: 'Saigon Map 1930', subtitle: 'Archive Hall · Floor 2'),
    ],
  ),
  _RouteOption(
    emoji: '📜',
    name: 'Cultural Heritage Trail',
    description: 'Highlights of local heritage, archives, and urban memory',
    duration: '50 min',
    stopsCount: 5,
    stops: [
      _RouteStop(name: 'Main Entrance', subtitle: 'Entrance · Floor 1'),
      _RouteStop(name: 'Stairs - Floor 1', subtitle: 'Transition · Floor 1'),
      _RouteStop(name: 'Stairs - Floor 2', subtitle: 'Transition · Floor 2'),
      _RouteStop(
        name: 'Cultural Heritage Trail Hall',
        subtitle: 'Heritage Wing · Floor 2',
      ),
      _RouteStop(
        name: 'Archive Reading Corner',
        subtitle: 'Research Corner · Floor 2',
      ),
    ],
  ),
];

// ── Detecting Screen ──────────────────────────────────────────────────────

class _DetectingScreen extends StatefulWidget {
  const _DetectingScreen();
  @override
  State<_DetectingScreen> createState() => _DetectingScreenState();
}

class _DetectingScreenState extends State<_DetectingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));

    _checkLocation();
  }

  Future<void> _checkLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _failAndPop();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _failAndPop();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _failAndPop();
      return;
    }

    try {
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 5),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      _failAndPop();
    }
  }

  void _failAndPop() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('GPS Unavailable. Please enable GPS.'.tr)),
    );
    Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeNotifier.textSecondaryColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: Icon(Icons.gps_fixed, color: Color(0xFF22C55E), size: 52),
            ),
            SizedBox(height: 24),
            Text(
              'Detecting your position...'.tr,
              style: TextStyle(
                color: themeNotifier.surfaceColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Using indoor positioning'.tr,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Location Picker Sheet ─────────────────────────────────────────────────

class _LocationPickerSheet extends StatelessWidget {
  const _LocationPickerSheet({required this.options});

  final List<_LocationOption> options;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeNotifier.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Where are you now?'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: themeNotifier.textPrimaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: themeNotifier.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Indoor positioning unavailable. Select your nearest location.'
                    .tr,
                style: TextStyle(
                  fontSize: 13,
                  color: themeNotifier.textSecondaryColor,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: options.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, i) {
                  final loc = options[i];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: loc.iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(loc.icon, color: loc.iconColor, size: 18),
                    ),
                    title: Text(
                      loc.name.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: themeNotifier.textPrimaryColor,
                      ),
                    ),
                    subtitle: Text(
                      loc.subtitle.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeNotifier.textSecondaryColor,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(loc),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Route Picker Sheet ────────────────────────────────────────────────────

class _RoutePickerSheet extends StatelessWidget {
  const _RoutePickerSheet({required this.routes});

  final List<_RouteOption> routes;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeNotifier.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '✨ Recommended Routes'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: themeNotifier.textPrimaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: themeNotifier.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Choose a guided path to explore the museum'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: themeNotifier.textSecondaryColor,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: routes.length,
                separatorBuilder: (_, _) => SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final route = routes[i];
                  final preview = route.stops
                      .take(3)
                      .map((s) => s.name.tr)
                      .join(' → ');
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(route),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeNotifier.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: themeNotifier.borderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(route.emoji, style: TextStyle(fontSize: 26)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  route.name.tr,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: themeNotifier.textPrimaryColor,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  route.description.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: themeNotifier.textSecondaryColor,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 12,
                                      color: themeNotifier.textSecondaryColor,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      route.duration.tr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: themeNotifier.textSecondaryColor,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Icon(
                                      Icons.place,
                                      size: 12,
                                      color: themeNotifier.textSecondaryColor,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '${route.stopsCount} stops'.tr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: themeNotifier.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '$preview →',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: themeNotifier.textSecondaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: themeNotifier.textSecondaryColor,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Route Ready Sheet ─────────────────────────────────────────────────────

class _RouteReadySheet extends StatelessWidget {
  const _RouteReadySheet({required this.route});
  final _RouteOption route;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeNotifier.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Route Ready'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: themeNotifier.textPrimaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: themeNotifier.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Text(route.emoji, style: TextStyle(fontSize: 24)),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                      Text(
                        '${route.duration.tr} • ${route.stopsCount} ${'stops'.tr}',
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
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: List.generate(route.stops.length, (i) {
                  final stop = route.stops[i];
                  final isFirst = i == 0;
                  final isLast = i == route.stops.length - 1;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isFirst
                                  ? const Color(0xFF22C55E)
                                  : isLast
                                  ? Theme.of(context).colorScheme.primary
                                  : themeNotifier.surfaceColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isFirst
                                    ? const Color(0xFF22C55E)
                                    : isLast
                                    ? Theme.of(context).colorScheme.primary
                                    : themeNotifier.textSecondaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 38,
                              color: themeNotifier.borderColor,
                            ),
                        ],
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.name.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: themeNotifier.textPrimaryColor,
                                ),
                              ),
                              Text(
                                stop.subtitle.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeNotifier.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: themeNotifier.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel'.tr,
                        style: TextStyle(
                          color: themeNotifier.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: Icon(Icons.navigation_outlined, size: 18),
                      label: Text(
                        'Start Navigation'.tr,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: themeNotifier.surfaceColor,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({
    required this.route,
    required this.currentStopIndex,
    required this.description,
    required this.onStop,
    required this.onNext,
  });

  final _RouteOption route;
  final int currentStopIndex;
  final String description;
  final VoidCallback onStop;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final currentStop = route.stops[currentStopIndex];
    final isLast = currentStopIndex == route.stops.length - 1;
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${'Navigating - Stop'.tr} ${currentStopIndex + 1}/${route.stops.length}',
                style: TextStyle(
                  color: themeNotifier.surfaceColor,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onStop,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.24),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Stop'.tr,
                    style: TextStyle(
                      color: themeNotifier.surfaceColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'To:'.tr,
            style: TextStyle(color: themeNotifier.surfaceColor, fontSize: 16),
          ),
          SizedBox(height: 2),
          Text(
            currentStop.name.tr,
            style: TextStyle(
              color: themeNotifier.surfaceColor,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: List.generate(route.stops.length, (i) {
              final done = i <= currentStopIndex;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: i == route.stops.length - 1 ? 0 : 4,
                  ),
                  height: 3,
                  decoration: BoxDecoration(
                    color: done ? Colors.white : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: themeNotifier.surfaceColor,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentStop.name.tr,
                        style: TextStyle(
                          color: themeNotifier.textPrimaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.volume_up_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  description.tr,
                  style: TextStyle(
                    color: Color(0xFF4B5563),
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: themeNotifier.surfaceColor,
                foregroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                isLast ? 'Finish'.tr : 'Next  →'.tr,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom 3D Painter ──────────────────────────────────────────────────────

class Museum3DPainter extends CustomPainter {
  final List<_MapLocation> locations;
  final List<_MapLocation> routePoints;
  final Set<String> visitedStopNames;
  final String? currentStopName;
  final bool show3D;
  final bool compactBackdrop;
  final double labelMaxWidth;
  final Color markerColor;

  Museum3DPainter({
    required this.locations,
    required this.routePoints,
    required this.visitedStopNames,
    required this.currentStopName,
    required this.show3D,
    this.compactBackdrop = false,
    this.labelMaxWidth = 84,
    required this.markerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = show3D ? const Color(0xFF2B3340) : const Color(0xFF3A3A3A)
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = show3D ? const Color(0xFF151C28) : const Color(0xFF202020);

    canvas.drawRect(Offset.zero & size, fillPaint);

    if (compactBackdrop) {
      _drawFocusPanel(canvas, size);
    } else {
      // Draw basic 3D floor plan
      _draw3DFloor(canvas, size, paint, fillPaint);
    }

    // Draw active route path if available
    _drawRoutePath(canvas, size);

    // Draw location markers
    for (final location in locations) {
      _drawLocationMarker(canvas, size, location);
    }
  }

  void _drawFocusPanel(Canvas canvas, Size size) {
    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.08,
        size.width * 0.8,
        size.height * 0.84,
      ),
      const Radius.circular(12),
    );

    canvas.drawRRect(panelRect, Paint()..color = const Color(0xFF1B2638));
    canvas.drawRRect(
      panelRect,
      Paint()
        ..color = const Color(0xFF2E3C53)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawRoutePath(Canvas canvas, Size size) {
    if (routePoints.length < 2) {
      return;
    }

    for (int i = 0; i < routePoints.length - 1; i++) {
      final from = routePoints[i];
      final to = routePoints[i + 1];
      final isCompletedSegment = visitedStopNames.contains(to.name);

      final glowPaint = Paint()
        ..color = isCompletedSegment
            ? const Color(0x8822C55E)
            : const Color(0x88FF4A4A)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final linePaint = Paint()
        ..color = isCompletedSegment
            ? const Color(0xFF22C55E)
            : const Color(0xFFFF4A4A)
        ..strokeWidth = 2.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final fromOffset = Offset(size.width * from.x, size.height * from.y);
      final toOffset = Offset(size.width * to.x, size.height * to.y);

      canvas.drawLine(fromOffset, toOffset, glowPaint);
      canvas.drawLine(fromOffset, toOffset, linePaint);
    }
  }

  void _draw3DFloor(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    // Draw simplified 3D isometric view
    final width = size.width;
    final height = size.height;

    // Draw floor grid
    for (int i = 0; i <= 4; i++) {
      final x = (width / 4) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, height), paint);
    }

    for (int i = 0; i <= 3; i++) {
      final y = (height / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(width, y), paint);
    }

    // Draw some room areas
    final roomPaint = Paint()
      ..color = show3D ? const Color(0xFF1D2433) : const Color(0xFF262626)
      ..style = PaintingStyle.fill;

    // Room 1
    canvas.drawRect(
      Rect.fromLTWH(width * 0.1, height * 0.15, width * 0.3, height * 0.3),
      roomPaint,
    );

    // Room 2
    canvas.drawRect(
      Rect.fromLTWH(width * 0.5, height * 0.15, width * 0.4, height * 0.35),
      roomPaint,
    );

    // Room 3
    canvas.drawRect(
      Rect.fromLTWH(width * 0.1, height * 0.5, width * 0.8, height * 0.35),
      roomPaint,
    );
  }

  void _drawLocationMarker(Canvas canvas, Size size, _MapLocation location) {
    final x = size.width * location.x;
    final y = size.height * location.y;

    final isVisited = visitedStopNames.contains(location.name);
    final isCurrent = currentStopName == location.name;
    final baseColor = location.color ?? markerColor;
    final markerColorByProgress = isVisited
        ? const Color(0xFF22C55E)
        : isCurrent
        ? const Color(0xFFF59E0B)
        : baseColor;

    // Draw marker circle
    final markerPaint = Paint()
      ..color = markerColorByProgress
      ..style = PaintingStyle.fill;

    if (isCurrent) {
      final ringPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(Offset(x, y), 9, ringPaint);
    }

    canvas.drawCircle(Offset(x, y), 6, markerPaint);

    final label = location.mapLabel ?? location.name;
    final textPainter = TextPainter(
      text: TextSpan(
        text: label.tr,
        style: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: compactBackdrop
              ? (label.contains('\n') ? 11 : 12)
              : (label.contains('\n') ? 10 : 11),
          fontWeight: FontWeight.w600,
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: labelMaxWidth);

    final labelOffset = Offset(x - textPainter.width / 2 - 5, y + 10);
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        labelOffset.dx,
        labelOffset.dy - 2,
        textPainter.width + 10,
        textPainter.height + 6,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(labelRect, Paint()..color = const Color(0xAA0F172A));
    textPainter.paint(canvas, Offset(labelOffset.dx + 5, labelOffset.dy + 1));
  }

  @override
  bool shouldRepaint(Museum3DPainter oldDelegate) {
    return oldDelegate.locations != locations ||
        oldDelegate.routePoints != routePoints ||
        oldDelegate.visitedStopNames != visitedStopNames ||
        oldDelegate.currentStopName != currentStopName ||
        oldDelegate.show3D != show3D ||
        oldDelegate.compactBackdrop != compactBackdrop ||
        oldDelegate.labelMaxWidth != labelMaxWidth;
  }
}

class _MapLocation {
  final String name;
  final String floor;
  final double x; // 0.0 to 1.0
  final double y; // 0.0 to 1.0
  final Color? color; // override marker color
  final String? mapLabel;

  const _MapLocation({
    required this.name,
    required this.floor,
    required this.x,
    required this.y,
    this.color,
    this.mapLabel,
  });
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: themeNotifier.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

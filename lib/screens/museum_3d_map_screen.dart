import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/session.dart';
import 'package:museamigo/theme_notifier.dart';
import 'package:geolocator/geolocator.dart';

/// Uniform scale factor from [InteractiveViewer]'s transform (for label-size compensation).
double _uniformScaleFromMatrix(Matrix4 m) {
  final sx = math.sqrt(
    m.entry(0, 0) * m.entry(0, 0) + m.entry(1, 0) * m.entry(1, 0),
  );
  if (sx.isFinite && sx > 0) return sx.clamp(0.05, 50.0);
  return 1.0;
}

Color? _parseMarkerColorHex(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  if (s.startsWith('#')) s = s.substring(1);
  if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
  if (s.length == 6) s = 'FF$s';
  try {
    return Color(int.parse(s, radix: 16));
  } catch (_) {
    return null;
  }
}

class Museum3DMapScreen extends StatefulWidget {
  const Museum3DMapScreen({
    super.key,
    this.initialFromLocationName,
    this.initialToLocationName,
    this.initialFloorName,
    this.onBack,
    this.autoStartRouteFlow = false,
  });

  final String? initialFromLocationName;
  final String? initialToLocationName;
  final String? initialFloorName;
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
  bool _showArtifactMarkers = true;
  bool _showExhibitionMarkers = true;
  bool _showDestinationMarkers = true;
  _RouteOption? _activeRoute;
  int _currentStopIndex = 0;
  bool _isPreviewRoute = false;
  String? _selectedExhibition;

  final TextEditingController _searchController = TextEditingController();
  List<_LocationOption> _searchResults = [];

  List<ArtifactDto> _artifacts = [];
  List<ExhibitionDto> _exhibitions = [];
  Map<String, ArtifactDto> _artifactByCode = {};

  /// Artifact markers from API (normalized coordinates on the indoor map image).
  List<_MapLocation> _apiMapLocations = [];
  List<_MapLocation> _exhibitionMapLocations = [];
  List<_MapLocation> _destinationMapLocations = [];
  List<MuseumFloorDto> _museumFloors = [];
  List<MapDestinationDto> _mapDestinations = [];
  String? _resolvedMap2dUrl;
  String? _resolvedMap3dUrl;
  bool _indoorMapMetaLoaded = false;
  /// First paint: show loading UI until `_loadMapData` finishes (success or error).
  bool _initialMapLoading = true;

  String? get _activeRasterMapUrl {
    if (!_indoorMapMetaLoaded) return null;
    if (_show3D) {
      return _resolvedMap3dUrl ?? _resolvedMap2dUrl;
    }
    return _resolvedMap2dUrl ?? _resolvedMap3dUrl;
  }

  List<_MapLocation> get _allLocationsForLookup {
    return [
      ..._apiMapLocations,
      ..._exhibitionMapLocations,
      ..._destinationMapLocations,
    ];
  }

  int _floorSortKey(String label) {
    final m = RegExp(r'(\d+)').firstMatch(label);
    if (m != null) return int.tryParse(m.group(1)!) ?? 0;
    return 0;
  }

  String? _exhibitionFloor(
    ExhibitionDto e,
    Map<String, ArtifactDto> byCode,
  ) {
    if (e.mapFloor != null && e.mapFloor!.trim().isNotEmpty) {
      return e.mapFloor!.trim();
    }
    for (final c in e.artifactCodes) {
      final a = byCode[c];
      if (a?.mapFloor != null && a!.mapFloor!.trim().isNotEmpty) {
        return a.mapFloor!.trim();
      }
    }
    return null;
  }

  List<String> get _floors {
    final set = <String>{};
    for (final f in _museumFloors) {
      set.add(f.label.trim());
    }
    for (final a in _artifacts) {
      if (a.mapFloor != null && a.mapFloor!.trim().isNotEmpty) {
        set.add(a.mapFloor!.trim());
      }
    }
    for (final e in _exhibitions) {
      final f = _exhibitionFloor(e, _artifactByCode);
      if (f != null) set.add(f);
    }
    if (set.isEmpty) return const ['Floor 1'];
    if (_museumFloors.isNotEmpty) {
      final ordered = _museumFloors.map((f) => f.label.trim()).toList();
      final known = ordered.toSet();
      final extras =
          set.difference(known).toList()
            ..sort((a, b) => _floorSortKey(a).compareTo(_floorSortKey(b)));
      return [...ordered, ...extras];
    }
    final list = set.toList()
      ..sort((a, b) => _floorSortKey(a).compareTo(_floorSortKey(b)));
    return list;
  }

  String _computeFallbackFloor(
    List<ArtifactDto> arts,
    List<ExhibitionDto> exhs,
    Map<String, ArtifactDto> byCode,
  ) {
    for (final a in arts) {
      if (a.mapFloor != null && a.mapFloor!.trim().isNotEmpty) {
        return a.mapFloor!.trim();
      }
    }
    for (final e in exhs) {
      if (e.mapFloor != null && e.mapFloor!.trim().isNotEmpty) {
        return e.mapFloor!.trim();
      }
      final f = _exhibitionFloor(e, byCode);
      if (f != null) return f;
    }
    return 'Floor 1';
  }

  Color _exhibitionPaletteColor(int id) {
    const colors = [
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFF06B6D4),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
    ];
    return colors[id.abs() % colors.length];
  }

  _MapLocation? _buildExhibitionMarker(
    ExhibitionDto e,
    Map<String, ArtifactDto> byCode,
    String fallbackFloor,
  ) {
    var floor = fallbackFloor;
    final ef = _exhibitionFloor(e, byCode);
    if (ef != null) floor = ef;

    double? x = e.mapX, y = e.mapY;
    if (x == null || y == null) {
      var sx = 0.0;
      var sy = 0.0;
      var n = 0;
      for (final c in e.artifactCodes) {
        final a = byCode[c];
        if (a?.mapX != null && a?.mapY != null) {
          sx += a!.mapX!;
          sy += a.mapY!;
          n++;
        }
      }
      if (n == 0) return null;
      x = sx / n;
      y = sy / n;
    }

    return _MapLocation(
      name: e.name,
      floor: floor,
      x: x,
      y: y,
      mapLabel: e.name,
      color: _exhibitionPaletteColor(e.id),
      isExhibition: true,
    );
  }

  List<_LocationOption> _locationOptions() {
    final primary = themeNotifier.primaryColor;
    const exhFallback = Color(0xFF9333EA);
    final opts = <_LocationOption>[];
    for (final loc in _apiMapLocations) {
      ArtifactDto? art;
      for (final a in _artifacts) {
        if (a.title == loc.name) {
          art = a;
          break;
        }
      }
      final desc = art?.description.trim() ?? '';
      final sub =
          desc.isEmpty
              ? loc.floor
              : (desc.length <= 72 ? desc : '${desc.substring(0, 69)}...');
      opts.add(
        _LocationOption(
          name: loc.name,
          subtitle: sub,
          icon: Icons.museum_outlined,
          iconColor: primary,
        ),
      );
    }
    for (final loc in _exhibitionMapLocations) {
      ExhibitionDto? ex;
      for (final e in _exhibitions) {
        if (e.name == loc.name) {
          ex = e;
          break;
        }
      }
      opts.add(
        _LocationOption(
          name: loc.name,
          subtitle: ex?.location ?? loc.floor,
          icon: Icons.collections_bookmark_outlined,
          iconColor: loc.color ?? exhFallback,
        ),
      );
    }
    for (final loc in _destinationMapLocations) {
      opts.add(
        _LocationOption(
          name: loc.name,
          subtitle: loc.floor,
          icon: Icons.place_outlined,
          iconColor: loc.color ?? const Color(0xFF6366F1),
        ),
      );
    }
    return opts;
  }

  List<ExhibitionDto> _exhibitionsOnSelectedFloor() {
    final namesOnFloor = _exhibitionMapLocations
        .where((m) => m.floor == _selectedFloor)
        .map((m) => m.name)
        .toSet();
    return _exhibitions.where((e) => namesOnFloor.contains(e.name)).toList();
  }

  Future<void> _loadMapData() async {
    final mid = AppSession.currentMuseumId.value;
    try {
      final api = BackendApi.instance;
      final mapDto = await api.fetchIndoorMap(mid);
      final arts = await api.fetchArtifacts(mid);
      final exhs = await api.fetchExhibitions(mid);

      List<MuseumFloorDto> museumFloors = [];
      try {
        museumFloors = await api.fetchMuseumFloors(mid);
      } catch (_) {}

      List<MapDestinationDto> mapDestinations = [];
      try {
        mapDestinations = await api.fetchMapDestinations(mid);
      } catch (_) {}

      if (!mounted) return;

      final byCode = {for (final a in arts) a.artifactCode: a};
      final fallbackFloor = _computeFallbackFloor(arts, exhs, byCode);

      final artifactMarkers = <_MapLocation>[];
      for (final a in arts) {
        if (a.mapX != null && a.mapY != null) {
          final floor =
              (a.mapFloor != null && a.mapFloor!.trim().isNotEmpty)
              ? a.mapFloor!.trim()
              : fallbackFloor;
          artifactMarkers.add(
            _MapLocation(
              name: a.title,
              floor: floor,
              x: a.mapX!,
              y: a.mapY!,
              mapLabel: a.title,
            ),
          );
        }
      }

      final exhMarkers = <_MapLocation>[];
      for (final e in exhs) {
        final m = _buildExhibitionMarker(e, byCode, fallbackFloor);
        if (m != null) exhMarkers.add(m);
      }

      final destMarkers = <_MapLocation>[];
      for (final d in mapDestinations) {
        final fl = d.floorLabel.trim();
        if (fl.isEmpty) continue;
        final col = _parseMarkerColorHex(d.markerColor);
        destMarkers.add(
          _MapLocation(
            name: d.title,
            floor: fl,
            x: d.mapX,
            y: d.mapY,
            color: col,
            mapLabel: d.title,
            isManagedDestination: true,
            category: d.category,
          ),
        );
      }

      final floorSet = <String>{};
      for (final f in museumFloors) {
        floorSet.add(f.label.trim());
      }
      for (final a in arts) {
        if (a.mapFloor != null && a.mapFloor!.trim().isNotEmpty) {
          floorSet.add(a.mapFloor!.trim());
        }
      }
      for (final e in exhs) {
        final f = _exhibitionFloor(e, byCode);
        if (f != null) floorSet.add(f);
      }
      if (floorSet.isEmpty) floorSet.add('Floor 1');

      late final List<String> floorsList;
      if (museumFloors.isNotEmpty) {
        final ordered =
            museumFloors.map((f) => f.label.trim()).toList(growable: false);
        final known = ordered.toSet();
        final extras =
            floorSet.difference(known).toList()
              ..sort((a, b) => _floorSortKey(a).compareTo(_floorSortKey(b)));
        floorsList = [...ordered, ...extras];
      } else {
        floorsList = floorSet.toList()
          ..sort((a, b) => _floorSortKey(a).compareTo(_floorSortKey(b)));
      }

      var nextFloor = _selectedFloor;
      if (nextFloor.isEmpty || !floorsList.contains(nextFloor)) {
        nextFloor = floorsList.first;
      }

      if (!mounted) return;
      setState(() {
        _artifacts = arts;
        _exhibitions = exhs;
        _artifactByCode = byCode;
        _museumFloors = museumFloors;
        _mapDestinations = mapDestinations;
        _apiMapLocations = artifactMarkers;
        _exhibitionMapLocations = exhMarkers;
        _destinationMapLocations = destMarkers;
        _resolvedMap2dUrl = api.resolveApiAssetUrl(mapDto.map2dPath);
        _resolvedMap3dUrl = api.resolveApiAssetUrl(mapDto.map3dPath);
        _indoorMapMetaLoaded = true;
        _selectedFloor = nextFloor;

        if (!widget.autoStartRouteFlow) {
          final route = _buildInitialRoute();
          if (route != null) {
            _isPreviewRoute = true;
            _activeRoute = _normalizeRouteForFloorTransfer(route);
            _currentStopIndex = 0;
          }
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _indoorMapMetaLoaded = true;
          if (_selectedFloor.isEmpty) {
            _selectedFloor = 'Floor 1';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _initialMapLoading = false);
      }
    }
  }

  Widget _buildInitialMapLoading(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          minHeight: 3,
          backgroundColor: themeNotifier.borderColor,
          color: primary,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Material(
              elevation: 2,
              color: themeNotifier.surfaceColor,
              shadowColor: Colors.black26,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: themeNotifier.textPrimaryColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loading map...'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: themeNotifier.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fetching indoor map and locations.'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: themeNotifier.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _searchResults = _locationOptions()
          .where(
            (l) =>
                l.name.toLowerCase().contains(q) ||
                l.subtitle.toLowerCase().contains(q),
          )
          .toList();
    });
  }

  List<_MapLocation> _locationsForCurrentFloor() {
    final floor = _selectedFloor;
    final out = <_MapLocation>[];
    if (_showArtifactMarkers) {
      out.addAll(
        _apiMapLocations.where((location) => location.floor == floor),
      );
    }
    if (_showExhibitionMarkers) {
      out.addAll(
        _exhibitionMapLocations.where((location) => location.floor == floor),
      );
    }
    if (_showDestinationMarkers) {
      out.addAll(
        _destinationMapLocations.where((location) => location.floor == floor),
      );
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    _selectedFloor = widget.initialFloorName?.trim() ?? '';

    if (widget.autoStartRouteFlow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openRouteFlow();
        }
      });
    }

    _loadMapData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeNotifier.surfaceColor,
      body: SafeArea(
        child:
            _initialMapLoading
                ? _buildInitialMapLoading(context)
                : LayoutBuilder(
                  builder: (context, constraints) {
                    final mapViewportHeight = math.max(
                      360.0,
                      MediaQuery.sizeOf(context).height * 0.56,
                    );
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      clipBehavior: Clip.hardEdge,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                          hintText: 'Search artifacts, places...'.tr,
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
                  itemCount: _floors.length + 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == _floors.length) {
                      return FilterChip(
                        label: Text(
                          'Artifacts'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: _showArtifactMarkers,
                        showCheckmark: false,
                        onSelected: (v) =>
                            setState(() => _showArtifactMarkers = v),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }
                    if (index == _floors.length + 1) {
                      return FilterChip(
                        label: Text(
                          'Exhibitions'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: _showExhibitionMarkers,
                        showCheckmark: false,
                        onSelected: (v) =>
                            setState(() => _showExhibitionMarkers = v),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }
                    if (index == _floors.length + 2) {
                      return FilterChip(
                        label: Text(
                          'Map places'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        selected: _showDestinationMarkers,
                        showCheckmark: false,
                        onSelected: (v) =>
                            setState(() => _showDestinationMarkers = v),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }
                    if (index == _floors.length + 3) {
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
            // ── Map: fixed tall viewport; page scrolls for legend / navigation ──
            SizedBox(
              height: mapViewportHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(child: _buildMainMapCanvas(context)),
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
                              onTap: () =>
                                  _selectLocationAsDestination(loc.name),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // ── Navigation card OR legend (below map; scroll page to see all) ──
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
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _LegendItem(
                          color: Theme.of(context).colorScheme.primary,
                          label: 'Artifacts'.tr,
                        ),
                        _LegendItem(
                          color: _exhibitionPaletteColor(0),
                          label: 'Exhibitions'.tr,
                        ),
                        _LegendItem(
                          color: const Color(0xFF6366F1),
                          label: 'Map places'.tr,
                        ),
                      ],
                    ),
                    if (_exhibitionsOnSelectedFloor().isNotEmpty) ...[
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
                            children: _exhibitionsOnSelectedFloor().map((ex) {
                              final markerColor = _exhibitionPaletteColor(ex.id);
                              final selected = _selectedExhibition == ex.name;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      _onExhibitionChipPressed(ex.name),
                                  onDoubleTap: () =>
                                      _onExhibitionChipPressed(ex.name),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? markerColor.withValues(alpha: 0.28)
                                          : markerColor.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        width: selected ? 1.6 : 1,
                                        color: markerColor,
                                      ),
                                    ),
                                    child: Text(
                                      ex.name.tr,
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
                    );
                  },
                ),
      ),
    );
  }

  /// Same flow as choosing a search result: floor → pick "from" → route sheet.
  Future<void> _selectLocationAsDestination(String placeName) async {
    _searchController.clear();
    _onSearchChanged('');
    final floor = _floorOfStop(placeName);
    if (floor != null) {
      setState(() => _selectedFloor = floor);
    }

    final fromLoc = await showModalBottomSheet<_LocationOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeNotifier.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LocationPickerSheet(options: _locationOptions()),
    );
    if (fromLoc == null || !mounted) return;

    final route = _buildInitialRouteFromLocations(fromLoc.name, placeName);
    if (route != null) {
      _showRouteReady(route);
    }
  }

  Widget _buildMainMapCanvas(BuildContext context) {
    final url = _activeRasterMapUrl;
    if (url != null && url.isNotEmpty) {
      return _IndoorMapRasterView(
        imageUrl: url,
        locations: _locationsForCurrentFloor(),
        routePoints: _routePointsForCurrentFloor(),
        visitedStopNames: _visitedStopNamesForCurrentFloor(),
        currentStopName: _currentStopNameForCurrentFloor(),
        markerColor: Theme.of(context).colorScheme.primary,
        labelMaxWidth: 120,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
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
              rasterMapMode: false,
            ),
            size: Size.infinite,
          ),
        );
      },
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
      builder: (_) => _LocationPickerSheet(options: _locationOptions()),
    );
    if (loc == null || !mounted) return;
    final suggestedRoutes = await _resolveSuggestedRoutes(loc);
    if (!mounted) return;
    _showRoutePicker(suggestedRoutes);
  }

  Future<void> _showRoutePicker(List<_RouteOption> suggestedRoutes) async {
    final normalizedRoutes = suggestedRoutes
        .map(_normalizeRouteForFloorTransfer)
        .toList();
    final route = await showModalBottomSheet<_RouteOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeNotifier.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RoutePickerSheet(routes: normalizedRoutes),
    );
    if (route == null || !mounted) return;
    _showRouteReady(route);
  }

  Future<List<_RouteOption>> _resolveSuggestedRoutes(
    _LocationOption from,
  ) async {
    final museumId = AppSession.currentMuseumId.value;

    try {
      final apiRoutes = await BackendApi.instance.fetchRoutes(museumId);
      final mapped = _mapApiRoutesToOptions(apiRoutes, from);
      if (mapped.isNotEmpty) {
        return mapped;
      }
    } catch (_) {
      // Fall through to locally generated routes when backend is unavailable.
    }

    return _generateDynamicRoutes(from);
  }

  List<_RouteOption> _mapApiRoutesToOptions(
    List<RouteDto> apiRoutes,
    _LocationOption from,
  ) {
    return apiRoutes.map((dto) {
      final fallback = _generateFallbackRouteFromApi(from, dto);
      return _RouteOption(
        emoji: fallback.emoji,
        name: dto.name,
        description: 'Guided route generated from museum route data.'.tr,
        duration: dto.estimatedTime,
        stopsCount: dto.stopsCount,
        stops: fallback.stops,
      );
    }).toList();
  }

  _RouteOption _generateFallbackRouteFromApi(
    _LocationOption from,
    RouteDto dto,
  ) {
    final dynamicRoutes = _generateDynamicRoutes(from);
    if (dynamicRoutes.isEmpty) {
      final fromLoc = _findLocationByName(from.name);
      final singleStop = fromLoc == null
          ? const <_RouteStop>[]
          : <_RouteStop>[
              _RouteStop(
                name: fromLoc.name,
                subtitle: _subtitleForLocation(fromLoc),
              ),
            ];
      return _RouteOption(
        emoji: '🧭',
        name: dto.name,
        description: 'Guided route generated from museum route data.'.tr,
        duration: dto.estimatedTime,
        stopsCount: dto.stopsCount,
        stops: singleStop,
      );
    }

    final pickIndex = dto.stopsCount >= 6 && dynamicRoutes.length > 1 ? 1 : 0;
    final seed = dynamicRoutes[pickIndex];
    return _RouteOption(
      emoji: seed.emoji,
      name: dto.name,
      description: seed.description,
      duration: dto.estimatedTime,
      stopsCount: dto.stopsCount,
      stops: seed.stops,
    );
  }

  List<_RouteOption> _generateDynamicRoutes(_LocationOption fromOption) {
    final fromLoc = _findLocationByName(fromOption.name);
    if (fromLoc == null) return [];

    final allLocs = _allLocationsForLookup
        .where((l) => l.name != fromLoc.name)
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
          final fromStairs = _stairsOnFloor(currentLoc.floor);
          final toStairs = _stairsOnFloor(target.floor);
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

  _RouteOption _normalizeRouteForFloorTransfer(_RouteOption route) {
    if (route.stops.length < 2) {
      return route;
    }

    final normalizedStops = <_RouteStop>[];

    void addStopByName(String stopName) {
      if (normalizedStops.isNotEmpty && normalizedStops.last.name == stopName) {
        return;
      }

      final location = _findLocationByName(stopName);
      if (location != null) {
        normalizedStops.add(
          _RouteStop(
            name: location.name,
            subtitle: _subtitleForLocation(location),
          ),
        );
        return;
      }

      normalizedStops.add(
        _RouteStop(name: stopName, subtitle: 'Transition Point'),
      );
    }

    for (var i = 0; i < route.stops.length; i++) {
      final current = route.stops[i];
      addStopByName(current.name);

      if (i == route.stops.length - 1) {
        continue;
      }

      final next = route.stops[i + 1];
      final currentFloor = _floorOfStop(current.name);
      final nextFloor = _floorOfStop(next.name);

      if (currentFloor != null &&
          nextFloor != null &&
          currentFloor != nextFloor) {
        final fromStairs = _stairsOnFloor(currentFloor);
        final toStairs = _stairsOnFloor(nextFloor);
        if (fromStairs != null) {
          addStopByName(fromStairs.name);
        }
        if (toStairs != null) {
          addStopByName(toStairs.name);
        }
      }
    }

    return _RouteOption(
      emoji: route.emoji,
      name: route.name,
      description: route.description,
      duration: route.duration,
      stopsCount: normalizedStops.length,
      stops: normalizedStops,
    );
  }

  Future<void> _showRouteReady(_RouteOption route) async {
    final normalizedRoute = _normalizeRouteForFloorTransfer(route);
    final started = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: themeNotifier.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RouteReadySheet(route: normalizedRoute),
    );
    if (started == true && mounted) {
      _startNavigation(normalizedRoute);
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
    if (!mounted) return;

    ExhibitionDto? ex;
    for (final e in _exhibitions) {
      if (e.name == exhibitionName) {
        ex = e;
        break;
      }
    }
    if (ex == null) return;

    final exhibitionLocation = _findLocationByName(exhibitionName);
    final artifacts = <_MapLocation>[];
    for (final code in ex.artifactCodes) {
      final a = _artifactByCode[code];
      if (a == null || a.mapX == null || a.mapY == null) continue;
      final floor =
          (a.mapFloor != null && a.mapFloor!.trim().isNotEmpty)
          ? a.mapFloor!.trim()
          : (_floors.isNotEmpty ? _floors.first : 'Floor 1');
      if (floor != _selectedFloor) continue;
      final label = '${a.title} (${a.artifactCode})';
      artifacts.add(
        _MapLocation(
          name: label,
          floor: floor,
          x: a.mapX!,
          y: a.mapY!,
          mapLabel: _popupLabelForArtifact(label),
        ),
      );
    }

    final spreadArtifacts = _spreadArtifactCluster(
      artifacts,
      exhibitionLocation,
    );

    final popupLocations = spreadArtifacts;

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
                          rasterMapMode: false,
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
    final normalizedRoute = _normalizeRouteForFloorTransfer(route);
    final firstFloor = _floorOfStop(normalizedRoute.stops.first.name);
    setState(() {
      _isPreviewRoute = false;
      _activeRoute = normalizedRoute;
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
    for (final a in _artifacts) {
      if (a.title == stopName) {
        final d = a.description.trim();
        if (d.isNotEmpty) return d;
      }
      if ('${a.title} (${a.artifactCode})' == stopName) {
        final d = a.description.trim();
        if (d.isNotEmpty) return d;
      }
    }
    for (final e in _exhibitions) {
      if (e.name == stopName) {
        final loc = e.location.trim();
        if (loc.isNotEmpty) return loc;
      }
    }
    for (final d in _mapDestinations) {
      if (d.title == stopName) {
        return '${d.title} · ${d.floorLabel}'.trim();
      }
    }
    return 'Follow the highlighted path to continue your museum journey.'.tr;
  }

  static String _normalizeLocationLookupKey(String name) {
    var normalized = name.trim().toLowerCase();

    // Remove codes/notes in parentheses, e.g. "(IP-005)".
    normalized = normalized.replaceAll(RegExp(r'\s*\([^)]*\)'), '');

    // Treat "... Map" as the base area for lookup purposes.
    normalized = normalized.replaceAll(RegExp(r'\s+map$'), '');

    // Collapse duplicated whitespace.
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized;
  }

  _MapLocation? _findLocationByName(String name) {
    if (name.isEmpty) return null;

    // First try exact match
    for (final loc in _allLocationsForLookup) {
      if (loc.name == name) {
        return loc;
      }
    }

    // Fallback: try case-insensitive match
    final nameLower = name.toLowerCase().trim();
    for (final loc in _allLocationsForLookup) {
      if (loc.name.toLowerCase().trim() == nameLower) {
        return loc;
      }
    }

    // Final fallback: compare normalized keys to bridge naming variants
    // such as "War Command Bunker Map" vs "War Command Bunker".
    final queryKey = _normalizeLocationLookupKey(name);
    for (final loc in _allLocationsForLookup) {
      if (_normalizeLocationLookupKey(loc.name) == queryKey) {
        return loc;
      }
    }

    return null;
  }

  String? _floorOfStop(String stopName) {
    return _findLocationByName(stopName)?.floor;
  }

  _MapLocation? _stairsOnFloor(String floorLabel) {
    for (final loc in _destinationMapLocations) {
      if (loc.floor == floorLabel && loc.category == 'stairs') {
        return loc;
      }
    }
    return _findLocationByName('Stairs - $floorLabel');
  }

  String _managedDestinationCategoryLabel(String? category) {
    switch (category) {
      case 'restroom':
        return 'Restrooms'.tr;
      case 'cafe':
        return 'Cafes'.tr;
      case 'stairs':
        return 'Stairs'.tr;
      case 'entrance':
        return 'Entrance'.tr;
      default:
        return 'Map places'.tr;
    }
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
      final fromStairs = _stairsOnFloor(from.floor);
      final toStairs = _stairsOnFloor(to.floor);
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

  String _subtitleForLocation(_MapLocation location) {
    if (location.isManagedDestination) {
      return '${_managedDestinationCategoryLabel(location.category)} · ${location.floor}';
    }
    if (location.isExhibition) {
      return '${'Exhibitions'.tr} · ${location.floor}';
    }
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
                                      '${route.stopsCount} ${'stops'.tr}',
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
    final primary = Theme.of(context).colorScheme.primary;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${'Navigating - Stop'.tr} ${currentStopIndex + 1}/${route.stops.length}',
                style: TextStyle(
                  color: themeNotifier.surfaceColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: onStop,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
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
            fontSize: 26,
            height: 1.15,
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
                  color: done ? Colors.white : Colors.white.withValues(alpha: 0.3),
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
                    color: primary,
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
              foregroundColor: primary,
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
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Material(
        elevation: 12,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        color: primary,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: body,
        ),
      ),
    );
  }
}

// ── Indoor map image (from backend) + overlay ─────────────────────────────

class _IndoorMapRasterView extends StatefulWidget {
  const _IndoorMapRasterView({
    required this.imageUrl,
    required this.locations,
    required this.routePoints,
    required this.visitedStopNames,
    required this.currentStopName,
    required this.markerColor,
    this.labelMaxWidth = 120,
  });

  final String imageUrl;
  final List<_MapLocation> locations;
  final List<_MapLocation> routePoints;
  final Set<String> visitedStopNames;
  final String? currentStopName;
  final Color markerColor;
  final double labelMaxWidth;

  @override
  State<_IndoorMapRasterView> createState() => _IndoorMapRasterViewState();
}

class _IndoorMapRasterViewState extends State<_IndoorMapRasterView> {
  double? _w;
  double? _h;
  late final TransformationController _transformationController;
  double _viewerScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformChanged);
    _resolveImage();
  }

  void _onTransformChanged() {
    final s = _uniformScaleFromMatrix(_transformationController.value);
    if (!mounted) return;
    if ((s - _viewerScale).abs() > 0.002) {
      setState(() => _viewerScale = s);
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _IndoorMapRasterView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _w = null;
      _h = null;
      _resolveImage();
    }
  }

  void _resolveImage() {
    final provider = NetworkImage(widget.imageUrl);
    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        stream.removeListener(listener);
        if (!mounted) return;
        setState(() {
          _w = info.image.width.toDouble();
          _h = info.image.height.toDouble();
        });
      },
      onError: (Object _, StackTrace? __) {
        stream.removeListener(listener);
        if (!mounted) return;
        setState(() {
          _w = 400;
          _h = 300;
        });
      },
    );
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    if (_w == null || _h == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ColoredBox(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.35,
          maxScale: 5,
          constrained: true,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _w,
            height: _h,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  widget.imageUrl,
                  width: _w,
                  height: _h,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: Colors.grey.shade800,
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey.shade500,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                CustomPaint(
                  size: Size(_w!, _h!),
                  painter: Museum3DPainter(
                    locations: widget.locations,
                    routePoints: widget.routePoints,
                    visitedStopNames: widget.visitedStopNames,
                    currentStopName: widget.currentStopName,
                    show3D: false,
                    compactBackdrop: false,
                    labelMaxWidth: widget.labelMaxWidth,
                    markerColor: widget.markerColor,
                    rasterMapMode: true,
                    viewerScale: _viewerScale,
                  ),
                ),
              ],
            ),
          ),
        ),
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
  final bool rasterMapMode;
  /// [InteractiveViewer] scale so label text stays ~constant size on screen when zooming.
  final double viewerScale;

  Museum3DPainter({
    required this.locations,
    required this.routePoints,
    required this.visitedStopNames,
    required this.currentStopName,
    required this.show3D,
    this.compactBackdrop = false,
    this.labelMaxWidth = 84,
    required this.markerColor,
    this.rasterMapMode = false,
    this.viewerScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!rasterMapMode) {
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
    final baseFs = compactBackdrop
        ? (label.contains('\n') ? 11.0 : 12.0)
        : (label.contains('\n') ? 10.0 : 11.0);
    final inv =
        rasterMapMode && viewerScale > 0 ? (1.0 / viewerScale) : 1.0;
    final fs = baseFs * inv;
    final maxW = labelMaxWidth * inv;
    final pad = 5.0 * inv;
    final padV = 2.0 * inv;
    final gapBelowDot = 10.0 * inv;
    final radius = 8.0 * inv;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label.tr,
        style: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: fs,
          fontWeight: FontWeight.w600,
          height: 1.15,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxW);

    final labelOffset = Offset(x - textPainter.width / 2 - pad, y + gapBelowDot);
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        labelOffset.dx,
        labelOffset.dy - padV,
        textPainter.width + pad * 2,
        textPainter.height + padV * 2,
      ),
      Radius.circular(radius),
    );

    canvas.drawRRect(labelRect, Paint()..color = const Color(0xAA0F172A));
    textPainter.paint(canvas, Offset(labelOffset.dx + pad, labelOffset.dy + padV * 0.5));
  }

  @override
  bool shouldRepaint(Museum3DPainter oldDelegate) {
    return oldDelegate.locations != locations ||
        oldDelegate.routePoints != routePoints ||
        oldDelegate.visitedStopNames != visitedStopNames ||
        oldDelegate.currentStopName != currentStopName ||
        oldDelegate.show3D != show3D ||
        oldDelegate.compactBackdrop != compactBackdrop ||
        oldDelegate.labelMaxWidth != labelMaxWidth ||
        oldDelegate.rasterMapMode != rasterMapMode ||
        oldDelegate.viewerScale != viewerScale;
  }
}

class _MapLocation {
  final String name;
  final String floor;
  final double x; // 0.0 to 1.0
  final double y; // 0.0 to 1.0
  final Color? color; // override marker color
  final String? mapLabel;
  final bool isExhibition;
  /// Dashboard-edited POI (WC, café, stairs, …).
  final bool isManagedDestination;
  /// Backend category: restroom, cafe, stairs, entrance, other.
  final String? category;

  const _MapLocation({
    required this.name,
    required this.floor,
    required this.x,
    required this.y,
    this.color,
    this.mapLabel,
    this.isExhibition = false,
    this.isManagedDestination = false,
    this.category,
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

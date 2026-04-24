import 'package:flutter/material.dart';

class Museum3DMapScreen extends StatefulWidget {
  const Museum3DMapScreen({super.key});

  @override
  State<Museum3DMapScreen> createState() => _Museum3DMapScreenState();
}

class _Museum3DMapScreenState extends State<Museum3DMapScreen> {
  String _selectedFloor = 'Floor 1';
  bool _show3D = true;
  _RouteOption? _activeRoute;
  int _currentStopIndex = 0;

  static const Color _restroomColor = Color(0xFFF59E0B);
  static const Color _cafeColor = Color(0xFF8B5E3C);

  static const _floors = ['Floor 1', 'Floor 2'];

  static const _locations = <_MapLocation>[
    _MapLocation(name: 'Room of War', floor: 'Floor 1', x: 0.2, y: 0.25),
    _MapLocation(name: 'President Room', floor: 'Floor 1', x: 0.65, y: 0.35),
    _MapLocation(name: 'Tank T-54', floor: 'Floor 1', x: 0.4, y: 0.55),
    _MapLocation(name: 'Classroom', floor: 'Floor 1', x: 0.75, y: 0.55),
    _MapLocation(
      name: 'Main Entrance',
      floor: 'Floor 1',
      x: 0.35,
      y: 0.8,
      color: Color(0xFF22C55E),
    ),
    // ── Floor 2 ──────────────────────────────────────────────────────
    _MapLocation(name: 'Art Gallery', floor: 'Floor 2', x: 0.2, y: 0.25),
    _MapLocation(
      name: 'Photography Gallery',
      floor: 'Floor 2',
      x: 0.18,
      y: 0.2,
    ),
    _MapLocation(name: 'Conference Hall', floor: 'Floor 2', x: 0.65, y: 0.3),
    _MapLocation(name: 'Peace Memorial', floor: 'Floor 2', x: 0.55, y: 0.44),
    _MapLocation(name: 'Diplomatic Room', floor: 'Floor 2', x: 0.78, y: 0.42),
    _MapLocation(name: 'Media Room', floor: 'Floor 2', x: 0.74, y: 0.6),
    _MapLocation(name: 'Library', floor: 'Floor 2', x: 0.75, y: 0.55),
    _MapLocation(
      name: 'Souvenir Shop',
      floor: 'Floor 2',
      x: 0.4,
      y: 0.55,
      color: Color(0xFFF59E0B),
    ),
    _MapLocation(
      name: 'Rooftop Cafe',
      floor: 'Floor 2',
      x: 0.3,
      y: 0.78,
      color: Color(0xFF8B5E3C),
    ),
  ];

  static const _stopDescriptions = <String, String>{
    'Main Entrance':
        'Start from the main entrance, then follow the route markers to your next stop.',
    'Tank T-54':
        'T-54 tank No. 843 is a legendary Vietnam People\'s Army tank linked to April 30, 1975 history.',
    'Room of War':
        'Explore archival photos and artifacts that document key wartime events.',
    'President Room':
        'The President Room preserves original furniture and command equipment.',
    'Peace Memorial':
        'This area highlights the transition from conflict to peace and reunification.',
    'Rooftop Cafe':
        'Take a break with a panoramic rooftop view before continuing your visit.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: const Center(
                child: Text(
                  'Map',
                  style: TextStyle(
                    color: Color(0xFF171A21),
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // ── Floor filters + 3D toggle ──────────────────────────────
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _floors.length + 1,
                separatorBuilder: (_, index) =>
                    SizedBox(width: index == _floors.length - 1 ? 140 : 8),
                itemBuilder: (context, index) {
                  if (index == _floors.length) {
                    // 3D Toggle button
                    return GestureDetector(
                      onTap: () => setState(() => _show3D = !_show3D),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFDDDDDD)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              size: 16,
                              color: Color(0xFF6D7785),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '3D',
                              style: TextStyle(
                                color: Color(0xFF6D7785),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? Theme.of(context).colorScheme.primary : const Color(0xFFDDDDDD),
                        ),
                      ),
                      child: Text(
                        floor,
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
            // ── 3D Map canvas ──────────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  Container(
                    color: const Color(0xFF1A1A1A),
                    child: CustomPaint(
                      painter: Museum3DPainter(
                        locations: _locations
                            .where((loc) => loc.floor == _selectedFloor)
                            .toList(),
                        routePoints: _routePointsForCurrentFloor(),
                        visitedStopNames: _visitedStopNamesForCurrentFloor(),
                        currentStopName: _currentStopNameForCurrentFloor(),
                        show3D: _show3D,
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
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.route,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Legend ──────────────────────────────────────────────────
            if (_activeRoute != null)
              _NavigationPanel(
                route: _activeRoute!,
                currentStopIndex: _currentStopIndex,
                description: _descriptionForCurrentStop(),
                onStop: _stopNavigation,
                onNext: _nextStop,
              )
            else
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    _LegendItem(
                      color: Theme.of(context).colorScheme.primary,
                      label: 'Artifacts',
                    ),
                    const SizedBox(width: 16),
                    const _LegendItem(
                      color: _restroomColor,
                      label: 'Restrooms',
                    ),
                    const SizedBox(width: 16),
                    const _LegendItem(color: _cafeColor, label: 'Cafes'),
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
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const _DetectingScreen(),
      ),
    );
    if (!mounted) return;
    _showLocationPicker();
  }

  Future<void> _showLocationPicker() async {
    final loc = await showModalBottomSheet<_LocationOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _LocationPickerSheet(),
    );
    if (loc == null || !mounted) return;
    _showRoutePicker(loc);
  }

  Future<void> _showRoutePicker(_LocationOption from) async {
    final route = await showModalBottomSheet<_RouteOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _RoutePickerSheet(),
    );
    if (route == null || !mounted) return;
    _showRouteReady(route);
  }

  Future<void> _showRouteReady(_RouteOption route) async {
    final started = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RouteReadySheet(route: route),
    );
    if (started == true && mounted) {
      _startNavigation(route);
    }
  }

  void _startNavigation(_RouteOption route) {
    final firstFloor = _floorOfStop(route.stops.first.name);
    setState(() {
      _activeRoute = route;
      _currentStopIndex = 0;
      if (firstFloor != null) {
        _selectedFloor = firstFloor;
      }
    });
  }

  void _stopNavigation() {
    setState(() {
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
    if (route == null) {
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
    if (route == null || route.stops.isEmpty) {
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
    return _stopDescriptions[stopName] ??
        'Follow the highlighted path to continue your museum journey.';
  }

  _MapLocation? _findLocationByName(String name) {
    for (final loc in _locations) {
      if (loc.name == name) {
        return loc;
      }
    }
    return null;
  }

  String? _floorOfStop(String stopName) {
    return _findLocationByName(stopName)?.floor;
  }
}

// ── Route data ────────────────────────────────────────────────────────────

class _LocationOption {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  const _LocationOption({
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

List<_LocationOption> _getAllLocationOptions(Color primary) => <_LocationOption>[
  _LocationOption(
    name: 'Room of War',
    subtitle: 'Hall A — Floor 1',
    icon: Icons.location_on,
    iconColor: primary,
  ),
  _LocationOption(
    name: 'President Room',
    subtitle: 'Hall B — Floor 1',
    icon: Icons.location_on,
    iconColor: primary,
  ),
  _LocationOption(
    name: 'Tank T-54',
    subtitle: 'Hall C — Floor 1',
    icon: Icons.location_on,
    iconColor: primary,
  ),
  _LocationOption(
    name: 'Classroom',
    subtitle: 'Hall D — Floor 1',
    icon: Icons.visibility_outlined,
    iconColor: primary,
  ),
  _LocationOption(
    name: 'Main Entrance',
    subtitle: 'Entrance — Floor 1',
    icon: Icons.meeting_room_outlined,
    iconColor: Color(0xFF6B7280),
  ),
  _LocationOption(
    name: 'Cafe Nile',
    subtitle: 'Central — Floor 1',
    icon: Icons.coffee_outlined,
    iconColor: Color(0xFFF59E0B),
  ),
  _LocationOption(
    name: 'Photography Gallery',
    subtitle: 'Hall E — Floor 2',
    icon: Icons.visibility_outlined,
    iconColor: primary,
  ),
  _LocationOption(
    name: 'Peace Memorial',
    subtitle: 'Hall F — Floor 2',
    icon: Icons.location_on,
    iconColor: primary,
  ),
  _LocationOption(
    name: 'Diplomatic Room',
    subtitle: 'Hall G — Floor 2',
    icon: Icons.location_on,
    iconColor: primary,
  ),
  _LocationOption(
    name: 'Media Room',
    subtitle: 'Hall H — Floor 2',
    icon: Icons.visibility_outlined,
    iconColor: primary,
  ),
  _LocationOption(
    name: 'Rooftop Cafe',
    subtitle: 'Rooftop — Floor 2',
    icon: Icons.coffee_outlined,
    iconColor: Color(0xFFF59E0B),
  ),
];

const _recommendedRoutes = <_RouteOption>[
  _RouteOption(
    emoji: '⭐',
    name: 'Museum Highlights',
    description: 'See the most iconic exhibits in a quick tour',
    duration: '45 min',
    stopsCount: 4,
    stops: [
      _RouteStop(name: 'Main Entrance', subtitle: 'Entrance · Floor 1'),
      _RouteStop(name: 'Tank T-54', subtitle: 'Hall C · Floor 1'),
      _RouteStop(name: 'Room of War', subtitle: 'Hall A · Floor 1'),
      _RouteStop(name: 'President Room', subtitle: 'Hall B · Floor 1'),
    ],
  ),
  _RouteOption(
    emoji: '🏛',
    name: 'Full Experience',
    description: 'Complete tour covering both floors',
    duration: '2 hours',
    stopsCount: 9,
    stops: [
      _RouteStop(name: 'Main Entrance', subtitle: 'Entrance · Floor 1'),
      _RouteStop(name: 'Room of War', subtitle: 'Hall A · Floor 1'),
      _RouteStop(name: 'President Room', subtitle: 'Hall B · Floor 1'),
      _RouteStop(name: 'Tank T-54', subtitle: 'Hall C · Floor 1'),
      _RouteStop(name: 'Classroom', subtitle: 'Hall D · Floor 1'),
      _RouteStop(name: 'Photography Gallery', subtitle: 'Hall E · Floor 2'),
      _RouteStop(name: 'Peace Memorial', subtitle: 'Hall F · Floor 2'),
      _RouteStop(name: 'Diplomatic Room', subtitle: 'Hall G · Floor 2'),
      _RouteStop(name: 'Rooftop Cafe', subtitle: 'Rooftop · Floor 2'),
    ],
  ),
  _RouteOption(
    emoji: '🇰',
    name: 'War History Path',
    description: 'Deep dive into wartime history and artifacts',
    duration: '1.5 hours',
    stopsCount: 5,
    stops: [
      _RouteStop(name: 'Main Entrance', subtitle: 'Entrance · Floor 1'),
      _RouteStop(name: 'Room of War', subtitle: 'Hall A · Floor 1'),
      _RouteStop(name: 'Tank T-54', subtitle: 'Hall C · Floor 1'),
      _RouteStop(name: 'President Room', subtitle: 'Hall B · Floor 1'),
      _RouteStop(name: 'Peace Memorial', subtitle: 'Hall F · Floor 2'),
    ],
  ),
  _RouteOption(
    emoji: '⚡',
    name: 'Quick Visit',
    description: 'Perfect for visitors with limited time',
    duration: '25 min',
    stopsCount: 3,
    stops: [
      _RouteStop(name: 'Main Entrance', subtitle: 'Entrance · Floor 1'),
      _RouteStop(name: 'Tank T-54', subtitle: 'Hall C · Floor 1'),
      _RouteStop(name: 'President Room', subtitle: 'Hall B · Floor 1'),
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
    // Simulate scan failure after 2 s then pop
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B7280),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scale,
              child: const Icon(
                Icons.gps_fixed,
                color: Color(0xFF22C55E),
                size: 52,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Detecting your position...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Using indoor positioning',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
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
  const _LocationPickerSheet();

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
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Where are you now?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Indoor positioning unavailable. Select your nearest location.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Builder(
                builder: (context) {
                  final options = _getAllLocationOptions(Theme.of(context).colorScheme.primary);
                  return ListView.separated(
                    controller: scrollController,
                    itemCount: options.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) {
                      final loc = options[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: loc.iconColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(loc.icon, color: loc.iconColor, size: 18),
                        ),
                        title: Text(
                          loc.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        subtitle: Text(
                          loc.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(loc),
                      );
                    },
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
  const _RoutePickerSheet();

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
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '✨ Recommended Routes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Choose a guided path to explore the museum',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: _recommendedRoutes.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final route = _recommendedRoutes[i];
                  final preview = route.stops
                      .take(3)
                      .map((s) => s.name)
                      .join(' → ');
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(route),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  route.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  route.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule,
                                      size: 12,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      route.duration,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.place,
                                      size: 12,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${route.stopsCount} stops',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$preview →',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF9CA3AF),
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
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Route Ready',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Text(route.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '${route.duration} • ${route.stopsCount} stops',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isFirst
                                    ? const Color(0xFF22C55E)
                                    : isLast
                                    ? Theme.of(context).colorScheme.primary
                                    : const Color(0xFF9CA3AF),
                                width: 2,
                              ),
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 38,
                              color: const Color(0xFFE5E7EB),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              Text(
                                stop.subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.navigation_outlined, size: 18),
                      label: const Text(
                        'Start Navigation',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Navigating - Stop ${currentStopIndex + 1}/${route.stops.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onStop,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Stop',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'To:',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            currentStop.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
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
                    color: done
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentStop.name,
                        style: const TextStyle(
                          color: Color(0xFF111827),
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
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                isLast ? 'Finish' : 'Next  →',
                style: const TextStyle(fontWeight: FontWeight.w600),
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
  final Color markerColor;

  Museum3DPainter({
    required this.locations,
    required this.routePoints,
    required this.visitedStopNames,
    required this.currentStopName,
    required this.show3D,
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

    // Draw basic 3D floor plan
    _draw3DFloor(canvas, size, paint, fillPaint);

    // Draw active route path if available
    _drawRoutePath(canvas, size);

    // Draw location markers
    for (final location in locations) {
      _drawLocationMarker(canvas, size, location);
    }
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

    // Draw location label
    final textPainter = TextPainter(
      text: TextSpan(
        text: location.name,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y + 12));
  }

  @override
  bool shouldRepaint(Museum3DPainter oldDelegate) {
    return oldDelegate.locations != locations ||
        oldDelegate.routePoints != routePoints ||
        oldDelegate.visitedStopNames != visitedStopNames ||
        oldDelegate.currentStopName != currentStopName ||
        oldDelegate.show3D != show3D;
  }
}

class _MapLocation {
  final String name;
  final String floor;
  final double x; // 0.0 to 1.0
  final double y; // 0.0 to 1.0
  final Color? color; // override marker color

  const _MapLocation({
    required this.name,
    required this.floor,
    required this.x,
    required this.y,
    this.color,
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
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6D7785)),
        ),
      ],
    );
  }
}

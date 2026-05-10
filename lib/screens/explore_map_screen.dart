import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/theme_notifier.dart';
import 'package:museamigo/session.dart';
import 'package:geolocator/geolocator.dart';
import 'payment_screens.dart';

class ExploreMapScreen extends StatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen> {
  late Future<List<_Museum>> _museumsFuture;
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  int? _selectedMuseumId;
  LatLng? _currentPosition;
  List<LatLng> _routePoints = [];
  bool _museumLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _museumsFuture = _loadMuseums();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<_Museum>> _loadMuseums() async {
    try {
      _museumLoadFailed = false;
      final data = await BackendApi.instance.fetchMuseums();
      return data
          .map(
            (m) => _Museum(
              id: m.id,
              name: m.name,
              position: LatLng(m.latitude, m.longitude),
              description: m.description.trim().isNotEmpty
                  ? m.description.trim()
                  : 'Tap for hours, tickets, and directions.'.tr,
              hours: m.operatingHours,
              baseTicketPrice: m.baseTicketPrice,
            ),
          )
          .where(
            (m) =>
                m.position.latitude >= -90 &&
                m.position.latitude <= 90 &&
                m.position.longitude >= -180 &&
                m.position.longitude <= 180 &&
                !(m.position.latitude == 0 && m.position.longitude == 0),
          )
          .toList();
    } catch (_) {
      _museumLoadFailed = true;
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ListenableBuilder(
      listenable: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) {
        return FutureBuilder<List<_Museum>>(
          future: _museumsFuture,
          builder: (context, snapshot) {
            final loading =
                snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;
            final museums = snapshot.data ?? const <_Museum>[];
            final query = _searchController.text.trim().toLowerCase();
            final filteredMuseums = query.isEmpty
                ? museums
                : museums
                      .where(
                        (m) =>
                            m.name.toLowerCase().contains(query) ||
                            m.name.tr.toLowerCase().contains(query),
                      )
                      .toList();
                      
            Widget tileLayer = TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.museamigo',
            );
            
            if (isDark) {
              tileLayer = ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  -1,  0,  0, 0, 255,
                   0, -1,  0, 0, 255,
                   0,  0, -1, 0, 255,
                   0,  0,  0, 1,   0,
                ]),
                child: tileLayer,
              );
            }
            
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: SafeArea(
                top: false,
                bottom: false,
                child: Column(
                  children: [
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
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: themeNotifier.surfaceColor,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.search,
                                    color: themeNotifier.textSecondaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      style: TextStyle(
                                        color: themeNotifier.textPrimaryColor,
                                        fontSize: 14,
                                      ),
                                      onChanged: (_) {
                                        setState(() {});
                                        final q = _searchController.text
                                            .trim()
                                            .toLowerCase();
                                        if (q.isEmpty) return;
                                        final matches = museums
                                            .where(
                                              (m) => m.name
                                                  .toLowerCase()
                                                  .contains(q),
                                            )
                                            .toList();
                                        if (matches.isEmpty) return;
                                        _mapController.move(
                                          matches.first.position,
                                          14,
                                        );
                                      },
                                      decoration: InputDecoration(
                                        hintText: 'Where do you want to go?'.tr,
                                        hintStyle: TextStyle(
                                          color: themeNotifier.textSecondaryColor,
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: themeNotifier.surfaceColor,
                                border: Border.all(
                                  color: themeNotifier.surfaceColor.withValues(alpha: 0.8),
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
                              child: const ClipOval(
                                child: Image(
                                  image: AssetImage('assets/images/model.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: filteredMuseums.isNotEmpty
                                  ? filteredMuseums.first.position
                                  : const LatLng(10.7769, 106.6980),
                              initialZoom: 14.0,
                            ),
                            children: [
                              tileLayer,
                              MarkerLayer(
                                markers: [
                                  if (_currentPosition != null)
                                    Marker(
                                      point: _currentPosition!,
                                      width: 40,
                                      height: 40,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.3),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.person_pin_circle,
                                          color: Colors.blue,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ...filteredMuseums.map(
                                    (museum) => Marker(
                                      point: museum.position,
                                      width: 120,
                                      height: 100,
                                      child: GestureDetector(
                                        onTap: () => _showMuseumDetailSheet(
                                          context,
                                          museum,
                                        ),
                                        child: _MuseumMarker(
                                          name: museum.name,
                                          isSelected: _selectedMuseumId == museum.id,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_routePoints.isNotEmpty)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: _routePoints,
                                      strokeWidth: 5,
                                      color: Colors.blue.withValues(alpha: 0.7),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (loading)
                            Positioned.fill(
                              child: Container(
                                color: theme.scaffoldBackgroundColor
                                    .withValues(alpha: 0.82),
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          if (!loading &&
                              museums.isEmpty &&
                              query.isEmpty)
                            Positioned.fill(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    (_museumLoadFailed
                                            ? 'Could not load museums. Check your connection.'
                                            : 'No museums available.')
                                        .tr,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ),
                              ),
                            ),
                          if (query.isNotEmpty && filteredMuseums.isEmpty)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                width: double.infinity,
                                color: theme.colorScheme.errorContainer,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Text(
                                  '${'No museum found for'.tr} "$query"',
                                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                                ),
                              ),
                            ),
                          if (_routePoints.isNotEmpty)
                            Positioned(
                              top: 80,
                              left: 16,
                              child: FloatingActionButton.extended(
                                onPressed: () {
                                  setState(() {
                                    _routePoints = [];
                                  });
                                },
                                label: Text('Clear Route'.tr),
                                icon: const Icon(Icons.close),
                                backgroundColor: theme.colorScheme.errorContainer,
                                foregroundColor: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          Positioned(
                            bottom: 16 + MediaQuery.paddingOf(context).bottom,
                            right: 16,
                            child: FloatingActionButton(
                              onPressed: _getCurrentLocation,
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              elevation: 4,
                              mini: true,
                              child: const Icon(Icons.my_location),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showMuseumDetailSheet(BuildContext context, _Museum museum) {
    // Update current museum context so other screens (Journey, Scan) use the right museum
    AppSession.currentMuseumId.value = museum.id;
    AppSession.currentMuseumName.value = museum.name;

    setState(() => _selectedMuseumId = museum.id);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width,
      ),
      backgroundColor: Colors.transparent,
      builder: (_) => _MuseumDetailSheet(
        museum: museum,
        onBuyTicket: () {
          Navigator.of(context).pop();
          _showTicketSheet(context, museum);
        },
        onStartRoute: () => _handleStartRoute(museum),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _selectedMuseumId = null);
    });
  }

  Future<void> _showTicketSheet(BuildContext context, _Museum museum) {
    final base = museum.baseTicketPrice;
    final options = <_TicketOption>[
      _TicketOption(
        label: 'Adult'.tr,
        countText: '1 ticket'.tr,
        price: 'VND $base',
      ),
      _TicketOption(
        label: 'Student'.tr,
        countText: '1 ticket'.tr,
        price: 'VND ${(base * 0.7).round()}',
      ),
      _TicketOption(
        label: 'Children'.tr,
        countText: '1 ticket'.tr,
        price: 'VND ${(base * 0.5).round()}',
      ),
      _TicketOption(
        label: 'Preview'.tr,
        countText: '1 ticket'.tr,
        price: 'VND 5000',
      ),
    ];

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width,
      ),
      backgroundColor: Colors.transparent,
      builder: (_) => _TicketSheet(
        museumName: museum.name,
        museumId: museum.id,
        baseTicketPrice: museum.baseTicketPrice,
        options: options,
        onSelect: (ticket) {
          // Keep ticket-selection sheet open so payment-method sheet can pop back to it.
          _showPaymentSheet(context, museum, ticket);
        },
      ),
    );
  }

  Future<void> _showPaymentSheet(
    BuildContext context,
    _Museum museum,
    _TicketOption ticket,
  ) {
    final info = TicketPaymentInfo(
      museumName: museum.name,
      ticketLabel: ticket.label,
      price: ticket.price,
      museumId: museum.id,
    );

    final methods = <_PaymentMethodOption>[
      _PaymentMethodOption(
        title: 'QR Scan'.tr,
        subtitle: 'VNPay, MoMo, ZaloPay, Banking App'.tr,
        icon: Icons.qr_code_2,
      ),
    ];

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width,
      ),
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentMethodSheet(
        ticket: ticket,
        methods: methods,
        onSelect: (method) {
          // Keep payment-method sheet open so the QR/card sheet can pop back to it.
          if (method.title == 'QR Scan'.tr) {
            _showQrPaymentSheet(context, info, museum);
          } else {
            _showCardPaymentSheet(context, info, museum);
          }
        },
      ),
    );
  }

  Future<void> _showQrPaymentSheet(
    BuildContext context,
    TicketPaymentInfo info,
    _Museum museum,
  ) async {
    showCheckingPaymentDialog(context); // Show loading while creating payment
    int? orderId;
    String? qrUrl;
    try {
      final res = await BackendApi.instance.createPayment(
        userId: AppSession.userId.value ?? 1,
        museumId: museum.id,
        ticketType: info.ticketLabel,
      );
      orderId = res['order_id'];
      qrUrl = res['qr_url'];
    } catch (_) {}
    
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Close checking dialog

    if (orderId == null || qrUrl == null) {
      // Fallback
      _runPaymentFlow(context, info, museum, info.ticketLabel);
      return;
    }

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width,
      ),
      backgroundColor: Colors.transparent,
      builder: (_) => QrPaymentSheet(
        ticket: info,
        qrUrl: qrUrl!,
        orderId: orderId!,
        onSuccess: (ticketQr) {
          info.qrCode = ticketQr;
          // Pop QR sheet, payment-method sheet, and ticket-selection sheet.
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          
          showPaymentSuccessDialog(context);
          Future.delayed(const Duration(seconds: 2), () {
            if (!context.mounted) return;
            Navigator.of(context).pop();
            showTicketSheet(context, info);
          });
        },
      ),
    );
  }

  Future<void> _showCardPaymentSheet(
    BuildContext context,
    TicketPaymentInfo info,
    _Museum museum,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width,
      ),
      backgroundColor: Colors.transparent,
      builder: (_) => CardPaymentSheet(
        ticket: info,
        onPay: () {
          // Pop card sheet, payment-method sheet, and ticket-selection sheet.
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          Navigator.of(context).pop();
          _runPaymentFlow(context, info, museum, info.ticketLabel);
        },
      ),
    );
  }

  Future<void> _runPaymentFlow(
    BuildContext context,
    TicketPaymentInfo info,
    _Museum museum,
    String ticketType,
  ) async {
    showCheckingPaymentDialog(context);
    try {
      final ticketDto = await BackendApi.instance.purchaseTicket(
        userId: AppSession.userId.value ?? 1,
        museumId: museum.id,
        ticketType: ticketType,
      );
      info.qrCode = ticketDto.qrCode;
    } catch (_) {
      // Keep existing success flow for demo mode when backend is unavailable.
    }
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    Navigator.of(context).pop();
    showPaymentSuccessDialog(context);
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return;
    Navigator.of(context).pop();
    showTicketSheet(context, info);
  }

  /// GNSS + fused provider settings so fixes use full precision (not coarse /
  /// cached network location), matching OpenStreetMap’s WGS84 tiles.
  LocationSettings _highAccuracyLocationSettings() {
    if (kIsWeb) {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          timeLimit: const Duration(seconds: 45),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          activityType: ActivityType.otherNavigation,
          distanceFilter: 0,
          timeLimit: const Duration(seconds: 45),
          pauseLocationUpdatesAutomatically: false,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        );
    }
  }

  Future<LatLng?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location services are disabled.'.tr)),
        );
      }
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permissions are denied'.tr)),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location permissions are permanently denied, we cannot request permissions.'.tr,
            ),
          ),
        );
      }
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: _highAccuracyLocationSettings(),
      );
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = newPos;
      });
      _mapController.move(newPos, 15);
      return newPos;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _fetchRoute(LatLng destination) async {
    LatLng? start = _currentPosition;
    if (start == null) {
      start = await _getCurrentLocation();
    }
    if (start == null) return;

    // Show loading snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Finding best route...'.tr),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    final url = 'http://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final List<LatLng> points = coords.map((c) => LatLng(c[1], c[0])).toList();
          
          setState(() {
            _routePoints = points;
          });

          // Fit camera to see the whole route
          final bounds = LatLngBounds.fromPoints([start, destination, ...points]);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.fromLTRB(40, 100, 40, 100),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch route: $e')),
        );
      }
    }
  }

  Future<void> _handleStartRoute(_Museum museum) async {
    Navigator.of(context).pop(); // Close detail sheet
    await _fetchRoute(museum.position);
  }
}

class _MuseumMarker extends StatelessWidget {
  const _MuseumMarker({required this.name, required this.isSelected});
  
  final String name;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = isSelected ? 1.15 : 1.0;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 1.0, end: scale),
      builder: (context, val, child) {
        return Transform.scale(
          scale: val,
          child: child,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? theme.colorScheme.primary.withValues(alpha: 0.35) 
                      : theme.colorScheme.primary.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isSelected 
                          ? theme.colorScheme.primary.withValues(alpha: 0.6) 
                          : theme.colorScheme.primary.withValues(alpha: 0.45),
                      blurRadius: isSelected ? 20 : 16,
                      spreadRadius: isSelected ? 4 : 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              name.tr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuseumDetailSheet extends StatefulWidget {
  const _MuseumDetailSheet({
    required this.museum,
    required this.onBuyTicket,
    required this.onStartRoute,
  });

  final _Museum museum;
  final VoidCallback onBuyTicket;
  final VoidCallback onStartRoute;

  @override
  State<_MuseumDetailSheet> createState() => _MuseumDetailSheetState();
}

class _MuseumDetailSheetState extends State<_MuseumDetailSheet> {
  bool _downloadOffline = false;

  static const double _sheetTopRadius = 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return museAmigoBottomSheetShell(
      context: context,
      backgroundColor: theme.cardColor,
      topCornerRadius: _sheetTopRadius,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(_sheetTopRadius),
                  ),
                  child: Image.asset(
                        'assets/images/museum.jpg',
                        height: 260,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 260,
                          color: theme.colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 52,
                            color: theme.iconTheme.color,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: CircleAvatar(
                        backgroundColor: theme.scaffoldBackgroundColor,
                        child: IconButton(
                          icon: Icon(Icons.close, color: theme.iconTheme.color),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Text(
                    widget.museum.name.tr,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
                  child: Text(
                    widget.museum.description.tr,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.6,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MuseumMetaItem(
                          icon: Icons.access_time,
                          label: 'Hours'.tr,
                          value: widget.museum.hours.tr,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MuseumMetaItem(
                          icon: Icons.attach_money,
                          label: 'Price'.tr,
                          value: 'VND ${widget.museum.baseTicketPrice}',
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: widget.onStartRoute,
                          style: FilledButton.styleFrom(
                            backgroundColor: Color.lerp(
                              theme.cardColor,
                              Colors.black,
                              theme.brightness == Brightness.dark
                                  ? 0.32
                                  : 0.09,
                            ),
                            foregroundColor: theme.textTheme.bodyLarge?.color,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          icon: const Icon(Icons.near_me_outlined),
                          label: Text(
                            'Start Route'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: widget.onBuyTicket,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size.fromHeight(50),
                          ),
                          icon: const Icon(Icons.confirmation_number_outlined),
                          label: Text(
                            'Buy Ticket'.tr,
                            style: const TextStyle(fontWeight: FontWeight.w700),
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

class _TicketSheet extends StatefulWidget {
  const _TicketSheet({
    required this.museumName,
    required this.museumId,
    required this.baseTicketPrice,
    required this.options,
    required this.onSelect,
  });

  final String museumName;
  final int museumId;
  final int baseTicketPrice;
  final List<_TicketOption> options;
  final ValueChanged<_TicketOption> onSelect;

  @override
  State<_TicketSheet> createState() => _TicketSheetState();
}

class _TicketSheetState extends State<_TicketSheet> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _priceForTicketType(String ticketType) {
    final base = widget.baseTicketPrice;
    switch (ticketType) {
      case 'Student':
        return 'VND ${(base * 0.7).round()}';
      case 'Children':
        return 'VND ${(base * 0.5).round()}';
      case 'Preview':
        return 'VND 5000';
      default:
        return 'VND $base';
    }
  }

  Future<void> _redeemFriendTicket(BuildContext context) async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enter the ticket or QR code.'.tr)),
      );
      return;
    }
    final uid = AppSession.userId.value;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in required to use a ticket code.'.tr)),
      );
      return;
    }
    try {
      final data = await BackendApi.instance.redeemTicket(
        userId: uid,
        ticketCode: code,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      final mid = data['museum_id'];
      showTicketSheet(
        context,
        TicketPaymentInfo(
          museumName: data['museum_name'] as String,
          ticketLabel: data['ticket_type'] as String,
          price: _priceForTicketType(data['ticket_type'] as String),
          qrCode: data['qr_code'] as String,
          museumId: mid is int ? mid : int.tryParse('$mid'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not apply ticket code. Check code or login.'.tr)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return museAmigoBottomSheetShell(
      context: context,
      backgroundColor: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Tickets'.tr,
                  style: TextStyle(
                    fontSize: 42,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 30),
                  color: theme.iconTheme.color,
                ),
              ],
            ),
            Text(
              widget.museumName.tr,
              style: TextStyle(
                fontSize: 22,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Have a ticket code from someone else?'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                hintText: 'Ticket code (my tickets in settings)'.tr,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _redeemFriendTicket(context),
                icon: const Icon(Icons.card_membership_outlined, size: 20),
                label: Text('Use ticket code'.tr),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Or buy a new ticket'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...widget.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => widget.onSelect(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        theme.cardColor,
                        Colors.black,
                        theme.brightness == Brightness.dark ? 0.32 : 0.09,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.label,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option.countText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          option.price,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: theme.iconTheme.color,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodSheet extends StatelessWidget {
  const _PaymentMethodSheet({
    required this.ticket,
    required this.methods,
    required this.onSelect,
  });

  final _TicketOption ticket;
  final List<_PaymentMethodOption> methods;
  final ValueChanged<_PaymentMethodOption> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return museAmigoBottomSheetShell(
      context: context,
      backgroundColor: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: Text('Return'.tr),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 30),
                      color: theme.iconTheme.color,
                    ),
                  ],
                ),
                Text(
                  'Payment methods'.tr,
                  style: TextStyle(
                    fontSize: 42,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.label,
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Text(
                        ticket.price,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...methods.map(
                  (method) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onSelect(method),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            theme.cardColor,
                            Colors.black,
                            theme.brightness == Brightness.dark ? 0.32 : 0.09,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              method.icon,
                              size: 30,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    method.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    method.subtitle,
                                    style: TextStyle(
                                      color: theme.textTheme.bodySmall?.color,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: theme.iconTheme.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _Museum {
  const _Museum({
    required this.id,
    required this.name,
    required this.position,
    required this.description,
    required this.hours,
    required this.baseTicketPrice,
  });

  final int id;
  final String name;
  final LatLng position;
  final String description;
  final String hours;
  final int baseTicketPrice;
}

class _MuseumMetaItem extends StatelessWidget {
  const _MuseumMetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.iconTheme.color, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _TicketOption {
  const _TicketOption({
    required this.label,
    required this.countText,
    required this.price,
  });

  final String label;
  final String countText;
  final String price;
}

class _PaymentMethodOption {
  const _PaymentMethodOption({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

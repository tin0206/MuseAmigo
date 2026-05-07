import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/session.dart';
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

  static const _fallbackMuseums = <_Museum>[
    _Museum(
      id: 1,
      name: 'Independence Palace',
      position: LatLng(10.7769, 106.6953),
      description:
          'The Independence Palace is one of the most significant historical and architectural landmarks of Ho Chi Minh City.',
      hours: '8:00 AM - 5:00 PM',
      baseTicketPrice: 30000,
    ),
    _Museum(
      id: 2,
      name: 'HCMC Museum of Fine Arts',
      position: LatLng(10.7716, 106.6992),
      description:
          'A beautiful blend of architecture and art collections from modern to traditional Vietnam.',
      hours: '9:00 AM - 5:00 PM',
      baseTicketPrice: 30000,
    ),
    _Museum(
      id: 3,
      name: 'War Remnants Museum',
      position: LatLng(10.7794, 106.6920),
      description:
          'A powerful museum featuring important exhibitions documenting modern history.',
      hours: '7:30 AM - 6:00 PM',
      baseTicketPrice: 30000,
    ),
  ];

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
      final data = await BackendApi.instance.fetchMuseums();
      if (data.isEmpty) {
        return _fallbackMuseums;
      }
      final mapped = data
          .map(
            (m) => _Museum(
              id: m.id,
              name: m.name,
              position: LatLng(m.latitude, m.longitude),
              description:
                  'Museum information is loaded from backend. Tap to view details.',
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
                // Ignore placeholder coordinates from backend seeds.
                !(m.position.latitude == 0 && m.position.longitude == 0),
          )
          .toList();
      return mapped.isEmpty ? _fallbackMuseums : mapped;
    } catch (_) {
      return _fallbackMuseums;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ListenableBuilder(
      listenable: languageNotifier,
      builder: (context, _) {
        return FutureBuilder<List<_Museum>>(
          future: _museumsFuture,
          builder: (context, snapshot) {
            final museums = snapshot.data ?? _fallbackMuseums;
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
                child: Column(
                  children: [
                    Container(
                      color: theme.colorScheme.primary,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: theme.iconTheme.color,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
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
                                        hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.settings),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(24),
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
                      child: FlutterMap(
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
                            markers: filteredMuseums
                                .map(
                                  (museum) => Marker(
                                    point: museum.position,
                                    width: 84,
                                    height: 84,
                                    child: GestureDetector(
                                      onTap: () => _showMuseumDetailSheet(
                                        context,
                                        museum,
                                      ),
                                      child: const _MuseumMarker(),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    if (query.isNotEmpty && filteredMuseums.isEmpty)
                      Container(
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

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MuseumDetailSheet(
        museum: museum,
        onBuyTicket: () {
          Navigator.of(context).pop();
          _showTicketSheet(context, museum);
        },
      ),
    );
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
      backgroundColor: Colors.transparent,
      builder: (_) => _TicketSheet(
        museumName: museum.name,
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
    );

    final methods = <_PaymentMethodOption>[
      _PaymentMethodOption(
        title: 'QR Scan'.tr,
        subtitle: 'VNPay, MoMo, ZaloPay, Banking App'.tr,
        icon: Icons.qr_code_2,
      ),
      _PaymentMethodOption(
        title: 'ATM/Visa/Mastercard'.tr,
        subtitle: 'Debit and Credit'.tr,
        icon: Icons.credit_card,
      ),
    ];

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
}

class _MuseumMarker extends StatelessWidget {
  const _MuseumMarker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.22),
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
                color: theme.colorScheme.primary.withValues(alpha: 0.45),
                blurRadius: 16,
                spreadRadius: 2,
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
    );
  }
}

class _MuseumDetailSheet extends StatefulWidget {
  const _MuseumDetailSheet({required this.museum, required this.onBuyTicket});

  final _Museum museum;
  final VoidCallback onBuyTicket;

  @override
  State<_MuseumDetailSheet> createState() => _MuseumDetailSheetState();
}

class _MuseumDetailSheetState extends State<_MuseumDetailSheet> {
  bool _downloadOffline = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
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
                      height: 1.45,
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
                          value: 'VND 30000',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Download Offline Data'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Map & Audio Guides'.tr,
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _downloadOffline,
                          onChanged: (value) {
                            setState(() {
                              _downloadOffline = value;
                            });
                          },
                          activeTrackColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () =>
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.home,
                                (route) => false,
                              ),
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceContainerHigh,
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
        ),
      ),
    );
  }
}

class _TicketSheet extends StatelessWidget {
  const _TicketSheet({
    required this.museumName,
    required this.options,
    required this.onSelect,
  });

  final String museumName;
  final List<_TicketOption> options;
  final ValueChanged<_TicketOption> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
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
                  museumName.tr,
                  style: TextStyle(
                    fontSize: 22,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 14),
                ...options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onSelect(option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainer,
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
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
                          color: theme.colorScheme.surfaceContainer,
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

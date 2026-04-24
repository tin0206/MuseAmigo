import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/l10n/translations.dart';
import 'payment_screens.dart';

class ExploreMapScreen extends StatelessWidget {
  const ExploreMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const museums = <_Museum>[
      _Museum(
        name: 'Independence Palace',
        position: LatLng(10.7769, 106.6953),
        description:
            'The Independence Palace is one of the most significant historical and architectural landmarks of Ho Chi Minh City.',
        hours: '8:00 AM - 5:00 PM',
      ),
      _Museum(
        name: 'HCMC Museum of Fine Arts',
        position: LatLng(10.7716, 106.6992),
        description:
            'A beautiful blend of architecture and art collections from modern to traditional Vietnam.',
        hours: '9:00 AM - 5:00 PM',
      ),
      _Museum(
        name: 'War Remnants Museum',
        position: LatLng(10.7794, 106.6920),
        description:
            'A powerful museum featuring important exhibitions documenting modern history.',
        hours: '7:30 AM - 6:00 PM',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.black87),
                          const SizedBox(width: 10),
                          Text(
                            'Where do you want to go?'.tr,
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.85),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.settings),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                options: const MapOptions(
                  initialCenter: LatLng(10.7769, 106.6980),
                  initialZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.museamigo',
                  ),
                  MarkerLayer(
                    markers: museums
                        .map(
                          (museum) => Marker(
                            point: museum.position,
                            width: 84,
                            height: 84,
                            child: GestureDetector(
                              onTap: () =>
                                  _showMuseumDetailSheet(context, museum),
                              child: const _MuseumMarker(),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMuseumDetailSheet(BuildContext context, _Museum museum) {
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
    final options = <_TicketOption>[
      _TicketOption(
        label: 'Adult'.tr,
        countText: '1 ticket'.tr,
        price: 'VND 30000',
      ),
      _TicketOption(
        label: 'Student'.tr,
        countText: '1 ticket'.tr,
        price: 'VND 21000',
      ),
      _TicketOption(
        label: 'Children'.tr,
        countText: '1 ticket'.tr,
        price: 'VND 15000',
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
          Navigator.of(context).pop();
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
          Navigator.of(context).pop();
          if (method.title == 'QR Scan'.tr) {
            _showQrPaymentSheet(context, info);
          } else {
            _showCardPaymentSheet(context, info);
          }
        },
      ),
    );
  }

  Future<void> _showQrPaymentSheet(
    BuildContext context,
    TicketPaymentInfo info,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QrPaymentSheet(
        ticket: info,
        onPay: () {
          Navigator.of(context).pop();
          _runPaymentFlow(context, info);
        },
      ),
    );
  }

  Future<void> _showCardPaymentSheet(
    BuildContext context,
    TicketPaymentInfo info,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CardPaymentSheet(
        ticket: info,
        onPay: () {
          Navigator.of(context).pop();
          _runPaymentFlow(context, info);
        },
      ),
    );
  }

  Future<void> _runPaymentFlow(
    BuildContext context,
    TicketPaymentInfo info,
  ) async {
    showCheckingPaymentDialog(context);
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
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF7D5EF7).withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7D5EF7).withValues(alpha: 0.45),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance,
            color: Color(0xFF7D5EF7),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F4),
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
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 52,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.black87),
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
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 14),
                  child: Text(
                    widget.museum.description.tr,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.45,
                      color: Color(0xFF4D5562),
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
                      color: const Color(0xFFE8E8EA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: Theme.of(context).colorScheme.primary,
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
                                style: const TextStyle(
                                  color: Color(0xFF6F7886),
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
                          activeTrackColor: Theme.of(
                            context,
                          ).colorScheme.primary,
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
                            backgroundColor: const Color(0xFFE4E4E6),
                            foregroundColor: const Color(0xFF171A21),
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
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F4),
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
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 30),
                    ),
                  ],
                ),
                Text(
                  museumName.tr,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Color(0xFF6D7785),
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
                          color: const Color(0xFFE5E5E7),
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
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6D7785),
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
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF949CAA),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F4),
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
                      label: const Text('Return'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 30),
                    ),
                  ],
                ),
                Text(
                  'Payment methods'.tr,
                  style: TextStyle(
                    fontSize: 42,
                    color: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ticket.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Text(
                        ticket.price,
                        style: const TextStyle(
                          color: Colors.white,
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
                          color: const Color(0xFFE5E5E7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              method.icon,
                              size: 30,
                              color: Theme.of(context).colorScheme.primary,
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
                                    style: const TextStyle(
                                      color: Color(0xFF6D7785),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF949CAA),
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
    required this.name,
    required this.position,
    required this.description,
    required this.hours,
  });

  final String name;
  final LatLng position;
  final String description;
  final String hours;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFA0A8B4), size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: Color(0xFF758193)),
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

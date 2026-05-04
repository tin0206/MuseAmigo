import 'package:flutter/material.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/services/backend_api.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  late final Future<List<_TicketData>> _ticketsFuture;

  static const int _defaultTicketPriceVnd = 30000;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _loadTickets();
  }

  Future<List<_TicketData>> _loadTickets() async {
    try {
      final museums = await BackendApi.instance.fetchMuseums();
      if (museums.isEmpty) {
        return _fallbackTickets();
      }

      return museums.asMap().entries.map((entry) {
        final index = entry.key;
        final museum = entry.value;
        final serial = (index + 1).toString().padLeft(3, '0');
        return _TicketData(
          title: museum.name,
          subtitle: 'Adult - General Admission',
          date: _sampleDateForIndex(index),
          time: _sampleTimeForIndex(index),
          location: 'Main Entrance',
          id: 'TKT$serial',
          priceVnd: _defaultTicketPriceVnd,
          active: index % 2 == 0,
        );
      }).toList();
    } catch (_) {
      return _fallbackTickets();
    }
  }

  static String _sampleDateForIndex(int index) {
    const dates = <String>[
      'May 08, 2026',
      'May 14, 2026',
      'May 22, 2026',
      'May 30, 2026',
    ];
    return dates[index % dates.length];
  }

  static String _sampleTimeForIndex(int index) {
    const times = <String>['09:00 AM', '10:30 AM', '01:30 PM', '03:00 PM'];
    return times[index % times.length];
  }

  static List<_TicketData> _fallbackTickets() {
    const museumNames = <String>[
      'Independence Palace',
      'War Remnants Museum',
      'HCMC Museum of Fine Arts',
      'Ho Chi Minh City Museum',
    ];

    return museumNames.asMap().entries.map((entry) {
      final index = entry.key;
      final serial = (index + 1).toString().padLeft(3, '0');
      return _TicketData(
        title: entry.value,
        subtitle: 'Adult - General Admission',
        date: _sampleDateForIndex(index),
        time: _sampleTimeForIndex(index),
        location: 'Main Entrance',
        id: 'TKT$serial',
        priceVnd: _defaultTicketPriceVnd,
        active: index % 2 == 0,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageNotifier,
      builder: (context, _) {
        return FutureBuilder<List<_TicketData>>(
          future: _ticketsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final tickets = snapshot.data ?? _fallbackTickets();

            return DefaultTabController(
              length: 3,
              child: Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF171A21),
                  elevation: 0,
                  title: Text(
                    'My Tickets'.tr,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(18),
                          ),
                        ),
                        splashBorderRadius: const BorderRadius.all(
                          Radius.circular(18),
                        ),
                        overlayColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.hovered)) {
                            return Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1);
                          }
                          if (states.contains(WidgetState.pressed)) {
                            return Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2);
                          }
                          return null;
                        }),
                        labelColor: Colors.white,
                        unselectedLabelColor: const Color(0xFF6B7280),
                        tabs: [
                          Tab(text: 'All'.tr),
                          Tab(text: 'Upcoming'.tr),
                          Tab(text: 'Past'.tr),
                        ],
                      ),
                    ),
                  ),
                ),
                body: TabBarView(
                  children: [
                    _TicketList(tickets: tickets),
                    _TicketList(
                      tickets: tickets.where((e) => e.active).toList(),
                    ),
                    _TicketList(
                      tickets: tickets.where((e) => !e.active).toList(),
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
}

class _TicketList extends StatelessWidget {
  const _TicketList({required this.tickets});

  final List<_TicketData> tickets;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: tickets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (context, i) => _TicketCard(ticket: tickets[i]),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final _TicketData ticket;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final headerGradient = ticket.active
        ? LinearGradient(colors: [primary, primary])
        : const LinearGradient(colors: [Color(0xFF687283), Color(0xFF9AA3B2)]);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: const Color(0xFFE5E7EB),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(gradient: headerGradient),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ticket.subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (ticket.active ? 'Valid' : 'Used').tr,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _metaRow(Icons.event_outlined, ticket.date),
                      const SizedBox(height: 8),
                      _metaRow(Icons.schedule_outlined, ticket.time),
                      const SizedBox(height: 8),
                      _metaRow(Icons.place_outlined, ticket.location),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFD1D5DB)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ticket ID'.tr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          Text(
                            'Price'.tr,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ticket.id,
                              style: const TextStyle(
                                fontSize: 22,
                                color: Color(0xFF171A21),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            _formatPriceByLanguage(ticket.priceVnd),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF171A21),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (ticket.active) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showQrDialog(context, ticket),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            icon: const Icon(Icons.qr_code_2, size: 18),
                            label: Text(
                              'Show QR Code'.tr,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: -10,
                  top: -10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: -10,
                  top: -10,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF171A21)),
        ),
      ],
    );
  }

  static String _formatPriceByLanguage(int amountVnd) {
    final vnd = _formatVnd(amountVnd);
    final isEnglish = languageNotifier.currentLanguage == 'English';
    if (!isEnglish) {
      return '$vnd VND';
    }

    const usdRate = 25500.0; // Approximate conversion rate.
    final usd = (amountVnd / usdRate).toStringAsFixed(2);
    return '$vnd VND (~\$$usd)';
  }

  static String _formatVnd(int amount) {
    final text = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final fromEnd = text.length - i;
      buffer.write(text[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  Future<void> _showQrDialog(BuildContext context, _TicketData ticket) {
    final maxDialogHeight = MediaQuery.of(context).size.height * 0.88;

    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFF3F4F6),
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxDialogHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your ticket'.tr,
                        style: TextStyle(
                          fontSize: 34,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 22),
                    ),
                  ],
                ),
                Text(
                  'Please provide this QR code at the entrance'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.qr_code_2_rounded,
                              size: 102,
                              color: Color(0xFF9CA3AF),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '#AVLBQWJ05',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SCAN ME'.tr,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Museum:'.tr, value: ticket.title),
                      _InfoRow(label: 'Ticket type:'.tr, value: 'Adult'.tr),
                      _InfoRow(label: 'Purchase date:'.tr, value: ticket.date),
                      _InfoRow(
                        label: 'Total amount:'.tr,
                        value: _formatPriceByLanguage(ticket.priceVnd),
                        bold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE9C672)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFB45309),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${'Warning:'.tr}\n${'You might have to provide this to the museum\'s ticket inspectors to print you a paper ticket.'.tr}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB45309),
                            height: 1.5,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    if (bold) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF171A21),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF171A21),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketData {
  const _TicketData({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.time,
    required this.location,
    required this.id,
    required this.priceVnd,
    required this.active,
  });

  final String title;
  final String subtitle;
  final String date;
  final String time;
  final String location;
  final String id;
  final int priceVnd;
  final bool active;
}

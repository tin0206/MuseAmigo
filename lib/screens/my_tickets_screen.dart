import 'package:flutter/material.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/theme_notifier.dart';
import 'package:museamigo/session.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
    final userId = AppSession.userId.value;
    if (userId == null) {
      return <_TicketData>[];
    }
    try {
      final rawTickets = await BackendApi.instance.fetchUserTickets(userId);
      return rawTickets.map((json) => _mapBackendTicket(json)).toList();
    } catch (_) {
      return <_TicketData>[];
    }
  }

  static _TicketData _mapBackendTicket(Map<String, dynamic> json) {
    final purchaseDate = json['purchase_date'] as String? ?? '';
    final isUsed = json['is_used'] as bool? ?? false;
    final today = _formatDate(DateTime.now());

    // Upcoming = today's ticket AND not used
    // Past = used OR expired (purchase_date < today)
    final isUpcoming = purchaseDate == today && !isUsed;
    final isPast = isUsed || (purchaseDate.isNotEmpty && purchaseDate != today);

    return _TicketData(
      title: json['museum_name'] as String? ?? 'Unknown Museum',
      subtitle: json['ticket_type'] as String? ?? 'General Admission',
      date: _formatDateFriendly(purchaseDate),
      time: '09:00 AM',
      location: 'Main Entrance',
      id: json['qr_code'] as String? ?? 'N/A',
      priceVnd: _defaultTicketPriceVnd,
      active: !isUsed && purchaseDate == today,
      isUpcoming: isUpcoming,
      isPast: isPast,
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  static String _formatDateFriendly(String raw) {
    if (raw.isEmpty) return 'N/A';
    try {
      final parts = raw.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        final monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${monthNames[month - 1]} ${day.toString().padLeft(2, '0')}, $year';
      }
    } catch (_) {}
    return raw;
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

            final tickets = snapshot.data ?? <_TicketData>[];
            final upcoming = tickets.where((e) => e.isUpcoming).toList();
            final past = tickets.where((e) => e.isPast).toList();

            return DefaultTabController(
              length: 3,
              child: Scaffold(
                backgroundColor: themeNotifier.surfaceColor,
                appBar: AppBar(
                  backgroundColor: themeNotifier.surfaceColor,
                  foregroundColor: themeNotifier.textPrimaryColor,
                  elevation: 0,
                  title: Text(
                    'My Tickets'.tr,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Container(
                      margin: EdgeInsets.fromLTRB(12, 0, 12, 8),
                      decoration: BoxDecoration(
                        color: themeNotifier.borderColor,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TabBar(
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                        ),
                        splashBorderRadius: BorderRadius.all(
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
                        labelColor: themeNotifier.surfaceColor,
                        unselectedLabelColor: themeNotifier.textSecondaryColor,
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
                    _TicketList(tickets: upcoming),
                    _TicketList(tickets: past),
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
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_num_outlined,
              size: 64,
              color: const Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            Text(
              'No tickets found'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tickets you purchase will appear here'.tr,
              style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
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
        color: themeNotifier.borderColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: themeNotifier.surfaceColor,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          ticket.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: themeNotifier.borderColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: themeNotifier.surfaceColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      (ticket.active ? 'Valid' : 'Used').tr,
                      style: TextStyle(
                        fontSize: 10,
                        color: themeNotifier.surfaceColor,
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
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _metaRow(Icons.event_outlined, ticket.date),
                      SizedBox(height: 8),
                      _metaRow(Icons.schedule_outlined, ticket.time),
                      SizedBox(height: 8),
                      _metaRow(Icons.place_outlined, ticket.location),
                      SizedBox(height: 12),
                      Divider(height: 1, color: themeNotifier.borderColor),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ticket ID'.tr,
                              style: TextStyle(
                                fontSize: 11,
                                color: themeNotifier.textSecondaryColor,
                              ),
                            ),
                          ),
                          Text(
                            'Price'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              color: themeNotifier.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ticket.id,
                              style: TextStyle(
                                fontSize: 22,
                                color: themeNotifier.textPrimaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            _formatPriceByLanguage(ticket.priceVnd),
                            style: TextStyle(
                              fontSize: 16,
                              color: themeNotifier.textPrimaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      if (ticket.active) ...[
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showQrDialog(context, ticket),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: themeNotifier.surfaceColor,
                              elevation: 3,
                              shadowColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 11),
                            ),
                            icon: Icon(Icons.qr_code_2, size: 18),
                            label: Text(
                              'Show QR Code'.tr,
                              style: TextStyle(fontWeight: FontWeight.w700),
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
                    decoration: BoxDecoration(
                      color: themeNotifier.backgroundColor,
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
                    decoration: BoxDecoration(
                      color: themeNotifier.backgroundColor,
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
        Icon(icon, size: 15, color: themeNotifier.textSecondaryColor),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: themeNotifier.textPrimaryColor),
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
        backgroundColor: themeNotifier.backgroundColor,
        insetPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxDialogHeight),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 18),
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
                      icon: Icon(Icons.close, size: 22),
                    ),
                  ],
                ),
                Text(
                  'Please provide this QR code at the entrance'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: themeNotifier.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeNotifier.borderColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          color: themeNotifier.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            QrImageView(
                              data: ticket.id,
                              version: QrVersions.auto,
                              size: 102.0,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ticket.id,
                              style: TextStyle(
                                fontSize: 14,
                                color: themeNotifier.textSecondaryColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'SCAN ME'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: themeNotifier.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
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
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE9C672)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFB45309),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${'Warning:'.tr}\n${'You might have to provide this to the museum\'s ticket inspectors to print you a paper ticket.'.tr}',
                          style: TextStyle(
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
        padding: EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: themeNotifier.textSecondaryColor,
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                color: themeNotifier.textPrimaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: themeNotifier.textSecondaryColor,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                color: themeNotifier.textPrimaryColor,
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
    this.isUpcoming = false,
    this.isPast = false,
  });

  final String title;
  final String subtitle;
  final String date;
  final String time;
  final String location;
  final String id;
  final int priceVnd;
  final bool active;
  final bool isUpcoming;
  final bool isPast;
}

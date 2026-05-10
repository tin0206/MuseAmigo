import 'package:flutter/material.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/theme_notifier.dart';
import 'package:museamigo/session.dart';
import 'package:museamigo/screens/payment_screens.dart';

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

  static const List<String> _monthNames = [
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

  static DateTime? _parsePurchaseInstant(Map<String, dynamic> json) {
    for (final key in [
      'purchase_date',
      'purchased_at',
      'created_at',
    ]) {
      final v = json[key];
      if (v == null) continue;
      if (v is int) {
        final ms = v < 100000000000 ? v * 1000 : v;
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
      }
      if (v is double) {
        final vi = v.round();
        final ms = vi < 100000000000 ? vi * 1000 : vi;
        return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
      }
      if (v is! String || v.isEmpty) continue;
      final trimmed = v.trim();
      final iso = DateTime.tryParse(trimmed);
      if (iso != null) return iso.toLocal();
      final datePart = trimmed.split(RegExp(r'[T\s]')).first;
      final parts = datePart.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return DateTime(y, m, d);
        }
      }
    }
    return null;
  }

  static String _formatDateFriendlyFromDateTime(DateTime dt) {
    return '${_monthNames[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  static String _formatTimeHm(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  static int _priceFromJson(Map<String, dynamic> json) {
    final p = json['price_vnd'] ?? json['amount'] ?? json['price'];
    if (p is int) return p;
    if (p is double) return p.round();
    return _defaultTicketPriceVnd;
  }

  /// Server may send MySQL tinyint as bool, int (0/1), or string.
  static bool _coerceTicketUsed(dynamic v) {
    if (v == true) return true;
    if (v == false || v == null) return false;
    if (v is int) return v != 0;
    if (v is double) return v != 0;
    if (v is String) {
      final s = v.trim().toLowerCase();
      return s == '1' || s == 'true' || s == 'yes';
    }
    return false;
  }

  static _TicketData _mapBackendTicket(Map<String, dynamic> json) {
    final parsed = _parsePurchaseInstant(json);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final purchaseDay = parsed != null
        ? DateTime(parsed.year, parsed.month, parsed.day)
        : null;

    final qr = json['qr_code'] as String? ?? 'N/A';
    final isUsed = _coerceTicketUsed(json['is_used']);

    final isTodayPurchase = purchaseDay != null && purchaseDay == today;
    final isUpcoming = isTodayPurchase && !isUsed;
    // Past tab: used, or purchased on any day other than today (matches previous list logic).
    final isPast =
        isUsed || (purchaseDay != null && purchaseDay != today);

    final dateStr = parsed != null
        ? _formatDateFriendlyFromDateTime(parsed)
        : 'N/A';
    final timeStr = parsed != null ? _formatTimeHm(parsed) : '--:--';

    final midRaw = json['museum_id'];
    final museumId = midRaw is int
        ? midRaw
        : (midRaw != null ? int.tryParse(midRaw.toString()) : null);

    return _TicketData(
      title: json['museum_name'] as String? ?? 'Unknown Museum',
      subtitle: json['ticket_type'] as String? ?? 'General Admission',
      date: dateStr,
      time: timeStr,
      location: 'Main Entrance',
      id: qr,
      museumId: museumId,
      priceVnd: _priceFromJson(json),
      active: !isUsed && isTodayPurchase,
      isUpcoming: isUpcoming,
      isPast: isPast,
    );
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
            Container(
              width: double.infinity,
              color: Color.lerp(
                themeNotifier.surfaceColor,
                Colors.black,
                Theme.of(context).brightness == Brightness.dark ? 0.28 : 0.09,
              ),
              child: Stack(
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
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
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
    return showTicketSheet(
      context,
      TicketPaymentInfo(
        museumName: ticket.title,
        ticketLabel: ticket.subtitle,
        price: _formatPriceByLanguage(ticket.priceVnd),
        qrCode: ticket.id,
        museumId: ticket.museumId,
      ),
      showSaveForLaterButton: false,
      purchaseDateOverride: '${ticket.date} · ${ticket.time}',
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
    this.museumId,
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
  final int? museumId;
  final int priceVnd;
  final bool active;
  final bool isUpcoming;
  final bool isPast;
}

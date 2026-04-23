import 'package:flutter/material.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  static const _tickets = <_TicketData>[
    _TicketData(
      title: 'National Museum of Ancient Art',
      subtitle: 'Adult - General Admission',
      date: 'March 15, 2026',
      time: '10:00 AM',
      location: 'Gallery Hall A',
      id: 'TKT001',
      price: '\$25.00',
      active: false,
    ),
    _TicketData(
      title: 'Contemporary Art Gallery',
      subtitle: 'Adult - Special Exhibition',
      date: 'March 28, 2026',
      time: '2:00 PM',
      location: 'Exhibition Floor 3',
      id: 'TKT002',
      price: '\$35.00',
      active: false,
    ),
    _TicketData(
      title: 'Museum of Natural History',
      subtitle: 'Adult - General Admission',
      date: 'April 10, 2026',
      time: '11:30 AM',
      location: 'Main Entrance',
      id: 'TKT003',
      price: '\$30.00',
      active: true,
    ),
    _TicketData(
      title: 'Science & Technology Center',
      subtitle: 'Adult - One Day Pass',
      date: 'April 20, 2026',
      time: '9:00 AM',
      location: 'Innovation Wing',
      id: 'TKT004',
      price: '\$40.00',
      active: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF171A21),
          elevation: 0,
          title: const Text(
            'My Tickets',
            style: TextStyle(fontWeight: FontWeight.w700),
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
                indicator: const BoxDecoration(
                  color: Color(0xFFCC353A),
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
                splashBorderRadius: const BorderRadius.all(Radius.circular(18)),
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return const Color(0x1ACC353A);
                  }
                  if (states.contains(WidgetState.pressed)) {
                    return const Color(0x33CC353A);
                  }
                  return null;
                }),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF6B7280),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _TicketList(tickets: _tickets),
            _TicketList(tickets: _tickets.where((e) => e.active).toList()),
            _TicketList(tickets: _tickets.where((e) => !e.active).toList()),
          ],
        ),
      ),
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
    final headerGradient = ticket.active
        ? const LinearGradient(colors: [Color(0xFFCC353A), Color(0xFFCC353A)])
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
                      ticket.active ? 'Valid' : 'Used',
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
                          const Expanded(
                            child: Text(
                              'Ticket ID',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          const Text(
                            'Price',
                            style: TextStyle(
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
                            ticket.price,
                            style: const TextStyle(
                              fontSize: 34,
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
                            onPressed: () => _showQrDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCC353A),
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shadowColor: const Color(0x33CC353A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            icon: const Icon(Icons.qr_code_2, size: 18),
                            label: const Text(
                              'Show QR Code',
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

  Future<void> _showQrDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFFF3F4F6),
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your ticket',
                      style: TextStyle(
                        fontSize: 40,
                        color: Color(0xFFCC353A),
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
              const Text(
                'Please provide this QR code at the entrance',
                style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
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
                        children: const [
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 102,
                            color: Color(0xFF9CA3AF),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '#AVLBQWJ05',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'SCAN ME',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _InfoRow(
                      label: 'Museum:',
                      value: 'Independence Palace',
                    ),
                    const _InfoRow(label: 'Ticket type:', value: 'Adult'),
                    const _InfoRow(label: 'Purchase date:', value: '6/4/2026'),
                    const _InfoRow(
                      label: 'Total amount:',
                      value: 'VND 30000',
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
                child: const Row(
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
                        'Warning:\nYou might have to provide this to the museum\'s ticket inspectors to print you a paper ticket.',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 32 : 15,
              color: const Color(0xFF171A21),
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
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
    required this.price,
    required this.active,
  });

  final String title;
  final String subtitle;
  final String date;
  final String time;
  final String location;
  final String id;
  final String price;
  final bool active;
}

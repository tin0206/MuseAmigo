import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class TicketPaymentInfo {
  const TicketPaymentInfo({
    required this.museumName,
    required this.ticketLabel,
    required this.price,
  });

  final String museumName;
  final String ticketLabel;
  final String price;
}

// ─── Card Payment Sheet ───────────────────────────────────────────────────────

class CardPaymentSheet extends StatefulWidget {
  const CardPaymentSheet({
    super.key,
    required this.ticket,
    required this.onPay,
  });

  final TicketPaymentInfo ticket;
  final VoidCallback onPay;

  @override
  State<CardPaymentSheet> createState() => _CardPaymentSheetState();
}

class _CardPaymentSheetState extends State<CardPaymentSheet> {
  final _cardNumberController = TextEditingController();
  final _cardholderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  // TODO: implement card payment API
  void _handleCardPayment() {}

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardholderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 10,
          right: 10,
          top: 10,
          bottom: MediaQuery.of(context).viewInsets.bottom + 10,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F4),
            borderRadius: BorderRadius.circular(22),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Return'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFCC353A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 28),
                    ),
                  ],
                ),
                const Text(
                  'Card Information',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFCC353A),
                  ),
                ),
                const SizedBox(height: 22),
                const _FieldLabel('Card number'),
                _PaymentTextField(
                  controller: _cardNumberController,
                  hint: '1234 5678 9012 3456',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Cardholder name'),
                _PaymentTextField(
                  controller: _cardholderController,
                  hint: 'NGUYEN VAN A',
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Expiry date'),
                          _PaymentTextField(
                            controller: _expiryController,
                            hint: 'MM/YY',
                            keyboardType: TextInputType.datetime,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('CVV'),
                          _PaymentTextField(
                            controller: _cvvController,
                            hint: '123',
                            keyboardType: TextInputType.number,
                            obscureText: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () {
                    _handleCardPayment();
                    widget.onPay();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFCC353A),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Pay ${widget.ticket.price}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
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

// ─── QR Payment Sheet ─────────────────────────────────────────────────────────

class QrPaymentSheet extends StatelessWidget {
  const QrPaymentSheet({super.key, required this.ticket, required this.onPay});

  final TicketPaymentInfo ticket;
  final VoidCallback onPay;

  // TODO: implement QR payment verification API
  void _handleQrPayment() {}

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header row ──────────────────────────────────────────
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Return'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFCC353A),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 24),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const Text(
                  'Scan QR code',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFCC353A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Use digital banking app or e-wallet app to scan the QR below',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6D7785)),
                ),
                const SizedBox(height: 12),
                // ── QR card ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_2,
                        size: 130,
                        color: Color(0xFFAAAAAA),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Money to pay',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6D7785),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ticket.price,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFCC353A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${ticket.ticketLabel} - ${ticket.museumName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4D5562),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // ── Pay via ─────────────────────────────────────────────
                const Text(
                  'Pay via:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6D7785)),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QrPayApp(
                      label: 'VNPay',
                      icon: Icons.account_balance_wallet,
                    ),
                    _QrPayApp(label: 'MoMo', icon: Icons.wallet),
                    _QrPayApp(label: 'ZaloPay', icon: Icons.payment),
                    _QrPayApp(label: 'Banking', icon: Icons.account_balance),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Guide ───────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCC02)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFFE65100),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Guide:',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE65100),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Open banking or e-wallet app',
                        style: TextStyle(
                          color: Color(0xFFE65100),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Choose QR code payment (scanner)',
                        style: TextStyle(
                          color: Color(0xFFE65100),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Scan the QR code to complete',
                        style: TextStyle(
                          color: Color(0xFFE65100),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () {
                    _handleQrPayment();
                    onPay();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFCC353A),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

class _QrPayApp extends StatelessWidget {
  const _QrPayApp({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFFCC353A), size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF4D5562)),
        ),
      ],
    );
  }
}

// ─── Checking Payment Dialog ──────────────────────────────────────────────────

Future<void> showCheckingPaymentDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _CheckingPaymentDialog(),
  );
}

class _CheckingPaymentDialog extends StatelessWidget {
  const _CheckingPaymentDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: Color(0xFFCC353A),
                strokeWidth: 5,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Checking payment',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Please wait...',
              style: TextStyle(color: Color(0xFF6D7785)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Payment Success Dialog ───────────────────────────────────────────────────

Future<void> showPaymentSuccessDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PaymentSuccessDialog(),
  );
}

class _PaymentSuccessDialog extends StatelessWidget {
  const _PaymentSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 4),
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Creating QR code for your ticket...',
              style: TextStyle(color: Color(0xFF6D7785)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ticket Result Sheet ──────────────────────────────────────────────────────

Future<void> showTicketSheet(BuildContext context, TicketPaymentInfo ticket) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TicketResultSheet(ticket: ticket),
  );
}

class _TicketResultSheet extends StatelessWidget {
  const _TicketResultSheet({required this.ticket});

  final TicketPaymentInfo ticket;

  // TODO: implement save ticket to local storage / API
  void _handleSaveTicket() {}

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F4),
            borderRadius: BorderRadius.circular(22),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Your ticket',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 28),
                    ),
                  ],
                ),
                const Text(
                  'Please provide this QR code at the entrance',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6D7785)),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.qr_code_2,
                            size: 140,
                            color: Color(0xFFCCCCCC),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '#AVLBQWJ05',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Text(
                        'SCAN ME',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6D7785),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFE0E0E0)),
                const SizedBox(height: 8),
                _TicketDetailRow(label: 'Museum', value: ticket.museumName),
                _TicketDetailRow(
                  label: 'Ticket type',
                  value: ticket.ticketLabel,
                ),
                _TicketDetailRow(label: 'Purchase date', value: dateStr),
                _TicketDetailRow(
                  label: 'Total amount',
                  value: ticket.price,
                  bold: true,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCC02)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFFE65100),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Warning:',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE65100),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "You might have to provide this to the museum's ticket inspectors to print you a paper ticket.",
                              style: TextStyle(
                                color: Color(0xFFE65100),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handleSaveTicket,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF171A21),
                          side: const BorderSide(color: Color(0xFFCCCCCC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text(
                          'Save for later use',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.home,
                              (route) => false,
                            ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFCC353A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text(
                          "I'm in",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketDetailRow extends StatelessWidget {
  const _TicketDetailRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6D7785), fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Color(0xFF6D7785)),
      ),
    );
  }
}

class _PaymentTextField extends StatelessWidget {
  const _PaymentTextField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCC353A), width: 1.5),
        ),
      ),
    );
  }
}

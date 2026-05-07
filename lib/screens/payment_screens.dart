import 'dart:async';
import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/theme_notifier.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

class TicketPaymentInfo {
  TicketPaymentInfo({
    required this.museumName,
    required this.ticketLabel,
    required this.price,
    this.qrCode = '#AVLBQWJ05',
  });

  final String museumName;
  final String ticketLabel;
  final String price;
  String qrCode;
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
            color: themeNotifier.surfaceColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back, size: 18),
                      label: Text('Return'.tr),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, size: 28),
                    ),
                  ],
                ),
                Text(
                  'Card Information'.tr,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 22),
                _FieldLabel('Card number'.tr),
                _PaymentTextField(
                  controller: _cardNumberController,
                  hint: '1234 5678 9012 3456',
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                _FieldLabel('Cardholder name'.tr),
                _PaymentTextField(
                  controller: _cardholderController,
                  hint: 'NGUYEN VAN A',
                  textCapitalization: TextCapitalization.characters,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Expiry date'.tr),
                          _PaymentTextField(
                            controller: _expiryController,
                            hint: 'MM/YY',
                            keyboardType: TextInputType.datetime,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 14),
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
                SizedBox(height: 28),
                FilledButton(
                  onPressed: () {
                    _handleCardPayment();
                    widget.onPay();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Pay '.tr + widget.ticket.price,
                    style: TextStyle(
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

class QrPaymentSheet extends StatefulWidget {
  const QrPaymentSheet({
    super.key,
    required this.ticket,
    required this.qrUrl,
    required this.orderId,
    required this.onSuccess,
  });

  final TicketPaymentInfo ticket;
  final String qrUrl;
  final int orderId;
  final ValueChanged<String> onSuccess;

  @override
  State<QrPaymentSheet> createState() => _QrPaymentSheetState();
}

class _QrPaymentSheetState extends State<QrPaymentSheet> {
  Timer? _timer;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final res = await BackendApi.instance.checkPaymentStatus(widget.orderId);
        if (res['status'] == 'PAID' && res['ticket'] != null) {
          timer.cancel();
          final ticketQr = res['ticket']['qr_code'] as String;
          widget.onSuccess(ticketQr);
        }
      } catch (_) {}
    });
  }

  void _simulateWebhook() async {
    try {
      await BackendApi.instance.simulatePaymentWebhook(widget.orderId);
      // The polling will automatically pick up the PAID status in the next tick
    } catch (_) {}
  }

  void _openAppAndSimulate(String appName) {
    setState(() => _isProcessing = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang mở ứng dụng $appName...'.tr),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _simulateWebhook();
    });
  }

  void _simulateSaveQr() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate delay
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mã QR đã được lưu vào thư viện ảnh!'.tr),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 16, 10, 16),
        child: Container(
          decoration: BoxDecoration(
            color: themeNotifier.surfaceColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header row ──────────────────────────────────────────
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back, size: 16),
                      label: Text('Return'.tr),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, size: 24),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                Text(
                  'Scan QR code'.tr,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Use digital banking app or e-wallet app to scan the QR below'
                      .tr,
                  style: TextStyle(
                    fontSize: 13,
                    color: themeNotifier.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 12),
                // ── QR card ─────────────────────────────────────────────
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: themeNotifier.surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.network(
                        widget.qrUrl,
                        width: 130,
                        height: 130,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.qr_code_2,
                          size: 130,
                          color: themeNotifier.textSecondaryColor,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Money to pay'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          color: themeNotifier.textSecondaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.ticket.price,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: themeNotifier.surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.ticket.ticketLabel} - ${widget.ticket.museumName.tr}',
                          style: TextStyle(
                            fontSize: 13,
                            color: themeNotifier.textSecondaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _simulateSaveQr,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text('Lưu mã QR'.tr),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                // ── Pay via ─────────────────────────────────────────────
                Text(
                  'Pay via:'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    color: themeNotifier.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QrPayApp(
                      label: 'VNPay',
                      icon: Icons.account_balance_wallet,
                      onTap: () => _openAppAndSimulate('VNPay'),
                    ),
                    _QrPayApp(
                      label: 'MoMo',
                      icon: Icons.wallet,
                      onTap: () => _openAppAndSimulate('MoMo'),
                    ),
                    _QrPayApp(
                      label: 'ZaloPay',
                      icon: Icons.payment,
                      onTap: () => _openAppAndSimulate('ZaloPay'),
                    ),
                    _QrPayApp(
                      label: 'Banking'.tr,
                      icon: Icons.account_balance,
                      onTap: () => _openAppAndSimulate('Banking'.tr),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // ── Guide ───────────────────────────────────────────────
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeNotifier.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.primary),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Guide:'.tr,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Open banking or e-wallet app'.tr,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Choose QR code payment (scanner)'.tr,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Scan the QR code to complete'.tr,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    ),
  ),
    );
  }
}

class _QrPayApp extends StatelessWidget {
  const _QrPayApp({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4D5562)),
            ),
          ],
        ),
      ),
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
      backgroundColor: themeNotifier.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close),
              ),
            ),
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
                strokeWidth: 5,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Checking payment'.tr,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Please wait...'.tr,
              style: TextStyle(color: themeNotifier.textSecondaryColor),
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
      backgroundColor: themeNotifier.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 4),
              ),
              child: Icon(Icons.check, color: Colors.green, size: 44),
            ),
            SizedBox(height: 20),
            Text(
              'Payment successful!'.tr,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Creating QR code for your ticket...'.tr,
              style: TextStyle(color: themeNotifier.textSecondaryColor),
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

  void _handleSaveTicket(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(AppRoutes.myTickets);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            color: themeNotifier.surfaceColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Your ticket'.tr,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, size: 28),
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
                SizedBox(height: 20),
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
                        child: Center(
                          child: QrImageView(
                            data: ticket.qrCode,
                            version: QrVersions.auto,
                            size: 160.0,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.qrCode,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'SCAN ME'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: themeNotifier.textSecondaryColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                const Divider(color: Color(0xFFE0E0E0)),
                SizedBox(height: 8),
                _TicketDetailRow(
                  label: 'Museum'.tr,
                  value: ticket.museumName.tr,
                ),
                _TicketDetailRow(
                  label: 'Ticket type'.tr,
                  value: ticket.ticketLabel,
                ),
                _TicketDetailRow(label: 'Purchase date'.tr, value: dateStr),
                _TicketDetailRow(
                  label: 'Total amount'.tr,
                  value: ticket.price,
                  bold: true,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: themeNotifier.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).colorScheme.primary),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Warning:'.tr,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "You might have to provide this to the museum's ticket inspectors to print you a paper ticket."
                                  .tr,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleSaveTicket(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: themeNotifier.textPrimaryColor,
                          side: BorderSide(color: Color(0xFFCCCCCC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: Text(
                          'Save for later use'.tr,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: Text(
                          "I'm in".tr,
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
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: themeNotifier.textSecondaryColor, fontSize: 14),
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
      padding: EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: themeNotifier.textSecondaryColor),
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
        hintStyle: TextStyle(color: themeNotifier.textSecondaryColor),
        filled: true,
        fillColor: themeNotifier.surfaceColor,
        contentPadding: EdgeInsets.symmetric(
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
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

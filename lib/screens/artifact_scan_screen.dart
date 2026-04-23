import 'package:flutter/material.dart';

class ArtifactScanScreen extends StatefulWidget {
  const ArtifactScanScreen({super.key});

  @override
  State<ArtifactScanScreen> createState() => _ArtifactScanScreenState();
}

class _ArtifactScanScreenState extends State<ArtifactScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;

  static const _brandRed = Color(0xFFCC353A);

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _showEnterCodeDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Artifact Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF171A21),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Type the code shown near the artifact.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: ctrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Eg: T54-843',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF374151)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final code = ctrl.text.trim();
                        if (code.isEmpty) return;
                        Navigator.of(ctx).pop(code);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Submit',
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
    );

    if (!context.mounted || value == null || value.isEmpty) {
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030A16),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.chevron_left_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop('T54-843'),
                        child: SizedBox(
                          width: 300,
                          height: 240,
                          child: Stack(
                            children: [
                              const Positioned(
                                left: 10,
                                top: 6,
                                child: _ScanCorner(top: true, left: true),
                              ),
                              const Positioned(
                                right: 10,
                                top: 6,
                                child: _ScanCorner(top: true, left: false),
                              ),
                              const Positioned(
                                left: 10,
                                bottom: 6,
                                child: _ScanCorner(top: false, left: true),
                              ),
                              const Positioned(
                                right: 10,
                                bottom: 6,
                                child: _ScanCorner(top: false, left: false),
                              ),
                              Center(
                                child: Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  size: 52,
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _scanController,
                                builder: (_, __) {
                                  final top =
                                      28 + (_scanController.value * 155);
                                  return Positioned(
                                    left: 16,
                                    right: 16,
                                    top: top,
                                    child: Container(
                                      height: 2.2,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0x00CC353A),
                                            Color(0xFFFF5E64),
                                            Color(0x00CC353A),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _brandRed.withValues(
                                              alpha: 0.75,
                                            ),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Align the QR code within the frame',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B95A7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showEnterCodeDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Enter the artifact\'s code instead',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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

class _ScanCorner extends StatelessWidget {
  const _ScanCorner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: !left,
      flipY: !top,
      child: SizedBox(
        width: 42,
        height: 42,
        child: CustomPaint(painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFCC353A)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const r = 8.0;
    final path = Path()
      ..moveTo(size.width, r)
      ..arcToPoint(
        Offset(size.width - r, 0),
        radius: const Radius.circular(r),
        clockwise: false,
      )
      ..lineTo(0, 0)
      ..lineTo(0, size.height);

    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

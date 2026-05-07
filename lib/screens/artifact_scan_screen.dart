import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/services/audio_assets.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/session.dart';
import 'package:museamigo/achievement_notifier.dart';
import 'package:museamigo/theme_notifier.dart';

class ArtifactScanScreen extends StatefulWidget {
  const ArtifactScanScreen({super.key});

  @override
  State<ArtifactScanScreen> createState() => _ArtifactScanScreenState();
}

class _ArtifactScanScreenState extends State<ArtifactScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  bool _isScanning = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _processScannedCode(String code) async {
    try {
      print('Fetching artifact with code: $code');
      print('Base URL: ${BackendApi.instance.baseUrl}');
      final artifact = await BackendApi.instance.fetchArtifact(code);
      if (!mounted) return;

      // Validate artifact belongs to current museum
      final currentMuseumId = AppSession.currentMuseumId.value;
      if (artifact.museumId != currentMuseumId) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The artifact is not in this museum.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Add to collection
      final userId = AppSession.userId.value;
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        return;
      }

      await BackendApi.instance.addToCollection(
        userId: userId,
        artifactId: artifact.id,
      );

      // Notify listeners that the collection has changed
      AppSession.collectionUpdated.value++;

      // UPDATE ACHIEVEMENT PROGRESS
      print('===========================================================');
      print(
        '[SCAN_TRACE] Initiating achievement update for museum ${artifact.museumId}',
      );
      print(
        '[SCAN_TRACE] Current AppSession.currentMuseumId is: $currentMuseumId',
      );
      print('[SCAN_TRACE] Calling achievementNotifier.updateProgress...');
      // We use artifact.museumId to ensure progress is recorded for the correct museum
      await achievementNotifier.updateProgress(
        artifact.museumId,
        artifact.id,
        1,
      );
      print('[SCAN_TRACE] achievementNotifier.updateProgress FINISHED');
      print('===========================================================');

      if (!mounted) return;

      // Navigate to artifact detail
      String audioAsset = AudioAssets.standardPath;
      if (code == 'IP-001') {
        audioAsset = 'assets/audio/presidential_desk.mp3';
      } else if (code == 'IP-002') {
        audioAsset = 'assets/audio/t54_tank.mp3';
      }

      Navigator.of(context).pushNamed(
        AppRoutes.artifactDetail,
        arguments: <String, dynamic>{
          'title': artifact.title,
          'year': artifact.year,
          'location': 'Unknown location',
          'currentLocation': 'Museum',
          'height': 'Unknown',
          'weight': 'Unknown',
          'imageAsset': 'assets/images/museum.jpg',
          'audioAsset': audioAsset,
        },
      );
    } catch (e) {
      if (!mounted) return;
      String errorMessage;
      if (e is ApiException) {
        errorMessage = e.message;
      } else {
        errorMessage = 'Error: $e';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      print('Error scanning artifact: $e');
    }
  }

  void _startQRScanner() {
    setState(() => _isScanning = true);
    _scannerController = MobileScannerController();
  }

  Future<void> _showEnterCodeDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: themeNotifier.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Artifact Code',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: themeNotifier.textPrimaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Type the code shown near the artifact.',
                style: TextStyle(fontSize: 13, color: themeNotifier.textSecondaryColor),
              ),
              SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: themeNotifier.backgroundColor,
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
              SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: themeNotifier.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: themeNotifier.textSecondaryColor),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final code = ctrl.text.trim();
                        if (code.isEmpty) return;
                        Navigator.of(ctx).pop(code);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: themeNotifier.surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
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

    // Process the entered code
    _processScannedCode(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: Icon(Icons.close, color: themeNotifier.surfaceColor),
            onPressed: () {
              setState(() {
                _isScanning = false;
                _scannerController?.stop();
              });
            },
          ),
        ),
        body: MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final code = capture.barcodes.first.rawValue;
            if (code != null) {
              _processScannedCode(code);
            }
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF030A16),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 10, 14, 22),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.chevron_left_rounded),
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
                        onTap: _startQRScanner,
                        child: SizedBox(
                          width: 300,
                          height: 240,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 10,
                                top: 6,
                                child: _ScanCorner(top: true, left: true),
                              ),
                              Positioned(
                                right: 10,
                                top: 6,
                                child: _ScanCorner(top: true, left: false),
                              ),
                              Positioned(
                                left: 10,
                                bottom: 6,
                                child: _ScanCorner(top: false, left: true),
                              ),
                              Positioned(
                                right: 10,
                                bottom: 6,
                                child: _ScanCorner(top: false, left: false),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner,
                                      size: 64,
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Tap to Scan QR Code',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _scanController,
                                builder: (_, _) {
                                  final top =
                                      30 + (_scanController.value * 156);
                                  return Positioned(
                                    left: 16,
                                    right: 16,
                                    top: top,
                                    child: Container(
                                      height: 2.2,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0),
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.75),
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
                      SizedBox(height: 24),
                      TextButton(
                        onPressed: () => _showEnterCodeDialog(context),
                        child: Text(
                          'Enter Code Manually',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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
        child: CustomPaint(
          painter: _CornerPainter(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
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

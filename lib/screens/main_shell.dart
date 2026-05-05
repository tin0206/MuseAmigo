import 'package:flutter/material.dart';
import 'package:museamigo/screens/ai_assistant_screen.dart';
import 'package:museamigo/screens/artifact_scan_screen.dart';
import 'package:museamigo/screens/home_screen.dart';
import 'package:museamigo/screens/journey_screen.dart';
import 'package:museamigo/screens/museum_3d_map_screen.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/session.dart';
import 'package:museamigo/widgets/app_bottom_nav.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/achievement_notifier.dart';

/// Shell widget that hosts all bottom-nav tab screens in an [IndexedStack].
/// Switching tabs never destroys a screen — state is fully preserved.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  Future<void> _openScanFlow() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ArtifactScanScreen(),
        fullscreenDialog: true,
      ),
    );

    if (!mounted || scannedCode == null || scannedCode.isEmpty) {
      return;
    }

    String unlockedTitle = 'T-54 Tank No. 843';
    try {
      final artifact = await BackendApi.instance.fetchArtifact(scannedCode);
      unlockedTitle = artifact.title;
      final userId = AppSession.userId.value ?? 1;

      // Update collection
      await BackendApi.instance.addToCollection(
        userId: userId,
        artifactId: artifact.id,
      );
      AppSession.collectionUpdated.value++;

      // UNIFIED HANDLER: update achievements using single source of truth
      await achievementNotifier.recordScan(artifact.museumId, artifact.id);
    } catch (_) {
      // Keep UI flow alive if backend collection call fails.
    }

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Congratulations!'.tr,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF171A21),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    height: 1.35,
                  ),
                  children: [
                    TextSpan(text: 'You\'ve unlocked '.tr),
                    TextSpan(
                      text: unlockedTitle.tr,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' in your Virtual 3D Collection!'.tr),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EFFD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '✨ This artifact now has enhanced storytelling and 3D viewing available'
                      .tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7B42D9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '🎉 Added to your collection'.tr,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageNotifier,
      builder: (context, _) {
        return Scaffold(
          // Keep all tab bodies alive via IndexedStack — no rebuilds on switch.
          body: IndexedStack(
            index: _currentIndex,
            children: [
              const HomeScreen(),
              Museum3DMapScreen(onBack: () => _onTabTap(0)),
              Museum3DMapScreen(onBack: () => _onTabTap(0)),
              const AIAssistantScreen(),
              const JourneyScreen(),
            ],
          ),
          bottomNavigationBar: AppBottomNav(
            selectedIndex: _currentIndex,
            onTap: _onTabTap,
            onCenterTap: _openScanFlow,
          ),
        );
      },
    );
  }
}

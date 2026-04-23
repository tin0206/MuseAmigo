import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/screens/ai_assistant_screen.dart';
import 'package:museamigo/screens/home_screen.dart';
import 'package:museamigo/screens/journey_screen.dart';
import 'package:museamigo/screens/museum_3d_map_screen.dart';
import 'package:museamigo/widgets/app_bottom_nav.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep all tab bodies alive via IndexedStack — no rebuilds on switch.
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          Museum3DMapScreen(),
          Museum3DMapScreen(),
          AIAssistantScreen(),
          JourneyScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

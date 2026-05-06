import 'package:flutter/material.dart';

/// A global [ChangeNotifier] that holds the app's primary theme color.
///
/// When [setPrimaryColor] is called, all listeners (including the
/// [MaterialApp] wrapper) rebuild with the updated [ColorScheme].
class ThemeNotifier extends ChangeNotifier {
  Color _primaryColor = const Color(0xFFCC353A);
  ThemeMode _themeMode = ThemeMode.light;

  /// The current primary color used across the entire app.
  Color get primaryColor => _primaryColor;

  /// The current app brightness mode.
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Updates the primary color and notifies all listeners so
  /// the [MaterialApp] rebuilds its theme.
  void setPrimaryColor(Color color) {
    if (_primaryColor == color) return;
    _primaryColor = color;
    notifyListeners();
  }

  /// Updates app theme mode (light/dark) and notifies listeners.
  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }
}

/// Single global instance so every screen can access the same notifier.
final ThemeNotifier themeNotifier = ThemeNotifier();

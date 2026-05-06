import 'package:flutter/material.dart';

class AppTheme {
  static const Color redPrimary = Color(0xFFC73739);
  static const Color yellowPrimary = Color(0xFFD4AF37);

  static ThemeData lightTheme(Color primaryColor) {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      cardColor: const Color(0xFFEEEEEE),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: const Color(0xFFFFFFFF),
      ),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        surface: const Color(0xFFEEEEEE),
        onSurface: const Color(0xFF0A0A0A),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: const Color(0xFFFFFFFF),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: const Color(0xFFFFFFFF),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF0A0A0A)),
        bodyMedium: TextStyle(color: Color(0xFF0A0A0A)),
        titleLarge: TextStyle(color: Color(0xFF0A0A0A)),
      ),
    );
  }

  static ThemeData darkTheme(Color primaryColor) {
    final bool isYellow = primaryColor.value == yellowPrimary.value;
    final Color topCardColor = isYellow ? const Color(0xFF18181B) : const Color(0xFFFFFFFF);
    final Color onTopCardColor = isYellow ? const Color(0xFFFFFFFF) : const Color(0xFF0A0A0A);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF09090B),
      cardColor: const Color(0xFF18181B),
      appBarTheme: AppBarTheme(
        backgroundColor: topCardColor,
        foregroundColor: onTopCardColor,
      ),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        surface: const Color(0xFF18181B),
        onSurface: const Color(0xFFA1A1AA),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: const Color(0xFFFFFFFF),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: const Color(0xFFFFFFFF),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFA1A1AA)),
        bodyMedium: TextStyle(color: Color(0xFFA1A1AA)),
        titleLarge: TextStyle(color: Color(0xFFA1A1AA)),
      ),
    );
  }
}

/// A global [ChangeNotifier] that holds the app's primary theme color and theme mode.
///
/// When [setPrimaryColor] or [setThemeMode] is called, all listeners (including the
/// [MaterialApp] wrapper) rebuild with the updated theme settings.
class ThemeNotifier extends ChangeNotifier {
  Color _primaryColor = AppTheme.redPrimary;
  ThemeMode _themeMode = ThemeMode.light;

  /// The current primary color used across the entire app.
  Color get primaryColor => _primaryColor;

  /// The current theme mode (light, dark, or system).
  ThemeMode get themeMode => _themeMode;

  /// Convenience getter for whether the current mode is dark.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Color get backgroundColor => isDarkMode ? const Color(0xFF09090B) : const Color(0xFFFFFFFF);
  Color get surfaceColor => isDarkMode ? const Color(0xFF18181B) : const Color(0xFFEEEEEE);
  Color get textPrimaryColor => isDarkMode ? const Color(0xFFA1A1AA) : const Color(0xFF0A0A0A);
  Color get textSecondaryColor => isDarkMode ? const Color(0xFFA1A1AA).withAlpha(179) : const Color(0xFF0A0A0A).withAlpha(179);
  Color get borderColor => isDarkMode ? const Color(0xFF18181B) : const Color(0xFFEEEEEE);


  /// Updates the primary color and notifies all listeners so
  /// the [MaterialApp] rebuilds its theme.
  void setPrimaryColor(Color color) {
    if (_primaryColor == color) return;
    _primaryColor = color;
    notifyListeners();
  }

  /// Updates the theme mode and notifies all listeners so
  /// the [MaterialApp] rebuilds its theme.
  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }
}

/// Single global instance so every screen can access the same notifier.
final ThemeNotifier themeNotifier = ThemeNotifier();

import 'package:flutter/material.dart';
import 'package:museamigo/achievement_notifier.dart';
import 'package:museamigo/font_size_notifier.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/profile_notifier.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/session.dart';
import 'package:museamigo/theme_notifier.dart';

/// Applies [AuthLoginResult] to [AppSession] and global UI notifiers (theme, language, etc.).
void applyAuthLoginResult(AuthLoginResult result, String email) {
  AppSession.userId.value = result.userId;
  AppSession.fullName.value = result.fullName;
  profileNotifier.setUser(name: result.fullName, email: email);

  final languageRaw = result.language.trim().toLowerCase();
  final resolvedLanguage =
      (languageRaw == 'vi' || languageRaw == 'vietnamese')
      ? 'Vietnamese'
      : 'English';
  languageNotifier.setLanguage(resolvedLanguage);

  final themeRaw = result.theme.trim().toLowerCase();
  themeNotifier.setThemeMode(
    themeRaw == 'dark' ? ThemeMode.dark : ThemeMode.light,
  );

  final fontSizeStr = result.fontSize.toLowerCase();
  FontSizeLevel fontSizeLevel = FontSizeLevel.medium;
  if (fontSizeStr == 'small') fontSizeLevel = FontSizeLevel.small;
  if (fontSizeStr == 'large') fontSizeLevel = FontSizeLevel.large;
  fontSizeNotifier.setLevel(fontSizeLevel);

  try {
    final rawScheme = result.scheme.trim();
    late final int colorValue;
    if (rawScheme.startsWith('0x') || rawScheme.startsWith('0X')) {
      colorValue = int.parse(rawScheme);
    } else {
      final cleanHex = rawScheme.replaceAll('#', '');
      final normalizedHex = cleanHex.length == 6 ? 'FF$cleanHex' : cleanHex;
      colorValue = int.parse('0x$normalizedHex');
    }
    themeNotifier.setPrimaryColor(Color(colorValue));
  } catch (_) {
    themeNotifier.setPrimaryColor(Color(int.parse('0xFFCC353A')));
  }

  achievementNotifier.ensureLoaded();
}

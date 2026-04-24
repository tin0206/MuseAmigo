import 'package:flutter/material.dart';

class LanguageNotifier extends ChangeNotifier {
  String _currentLanguage = 'English';

  String get currentLanguage => _currentLanguage;

  void setLanguage(String language) {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();
  }
}

final LanguageNotifier languageNotifier = LanguageNotifier();

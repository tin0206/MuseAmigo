import 'package:flutter/material.dart';

enum FontSizeLevel {
  small(0.85),
  medium(1.0),
  large(1.5);
  final double scale;
  const FontSizeLevel(this.scale);
}

class FontSizeNotifier extends ChangeNotifier {
  FontSizeLevel _level = FontSizeLevel.medium;

  FontSizeLevel get level => _level;
  double get scale => _level.scale;

  void setLevel(FontSizeLevel newLevel) {
    if (_level == newLevel) return;
    _level = newLevel;
    notifyListeners();
  }

  String get levelName {
    switch (_level) {
      case FontSizeLevel.small:
        return 'Small';
      case FontSizeLevel.medium:
        return 'Medium';
      case FontSizeLevel.large:
        return 'Large';
    }
  }
}

final fontSizeNotifier = FontSizeNotifier();

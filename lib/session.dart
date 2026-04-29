import 'package:flutter/foundation.dart';

class AppSession {
  static final ValueNotifier<int?> userId = ValueNotifier<int?>(null);
  static final ValueNotifier<String> fullName = ValueNotifier<String>('');
  static final ValueNotifier<int> currentMuseumId = ValueNotifier<int>(1);
  static final ValueNotifier<String> currentMuseumName = ValueNotifier<String>('Independence Palace');
}

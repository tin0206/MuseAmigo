import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  static final ValueNotifier<int?> userId = ValueNotifier<int?>(null);
  static final ValueNotifier<String> fullName = ValueNotifier<String>('');
  
  static final ValueNotifier<int> currentMuseumId = ValueNotifier<int>(1);
  static final ValueNotifier<String> currentMuseumName = ValueNotifier<String>('Independence Palace');

  /// Incremented after a new artifact is added to the collection.
  static final ValueNotifier<int> collectionUpdated = ValueNotifier<int>(0);

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    final savedId = prefs.getInt('current_museum_id');
    if (savedId != null) {
      currentMuseumId.value = savedId;
    }

    final savedName = prefs.getString('current_museum_name');
    if (savedName != null) {
      currentMuseumName.value = savedName;
    }

    // Listen for changes to persist them
    currentMuseumId.addListener(() {
      prefs.setInt('current_museum_id', currentMuseumId.value);
    });
    currentMuseumName.addListener(() {
      prefs.setString('current_museum_name', currentMuseumName.value);
    });
  }
}

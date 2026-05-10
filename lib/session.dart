import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSession {
  static final ValueNotifier<int?> userId = ValueNotifier<int?>(null);
  static final ValueNotifier<String> fullName = ValueNotifier<String>('');
  
  static final ValueNotifier<int> currentMuseumId = ValueNotifier<int>(1);
  static final ValueNotifier<String> currentMuseumName = ValueNotifier<String>('Independence Palace');

  /// Incremented after a new artifact is added to the collection.
  static final ValueNotifier<int> collectionUpdated = ValueNotifier<int>(0);

  /// True after **I'm in** check-in succeeds; cleared when user taps **Finish journey**
  /// on the Journey screen. Used to hide duplicate **I'm in** from My Tickets while visiting.
  static final ValueNotifier<bool> activeMuseumVisit =
      ValueNotifier<bool>(false);

  static const String _prefActiveMuseumVisit = 'active_museum_visit';
  static const String _prefMuseumJourneyUserId = 'museum_journey_user_id';

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

    activeMuseumVisit.value =
        prefs.getBool(_prefActiveMuseumVisit) ?? false;

    // Listen for changes to persist them
    currentMuseumId.addListener(() {
      SharedPreferences.getInstance().then((p) {
        p.setInt('current_museum_id', currentMuseumId.value);
      });
    });
    currentMuseumName.addListener(() {
      SharedPreferences.getInstance().then((p) {
        p.setString('current_museum_name', currentMuseumName.value);
      });
    });
    activeMuseumVisit.addListener(_persistActiveMuseumVisit);
  }

  /// Persists check-in state so it survives app restart and logout/login for the same user.
  static void _persistActiveMuseumVisit() {
    SharedPreferences.getInstance().then((p) async {
      await p.setBool(_prefActiveMuseumVisit, activeMuseumVisit.value);
      if (activeMuseumVisit.value) {
        final uid = userId.value;
        if (uid != null) {
          await p.setInt(_prefMuseumJourneyUserId, uid);
        }
      } else {
        await p.remove(_prefMuseumJourneyUserId);
      }
    });
  }

  /// Whether stored prefs say this user should land in [MainShell] after login.
  static Future<bool> shouldResumeMuseumJourney(int userId) async {
    final p = await SharedPreferences.getInstance();
    final active = p.getBool(_prefActiveMuseumVisit) ?? false;
    final journeyUid = p.getInt(_prefMuseumJourneyUserId);
    return active && journeyUid == userId;
  }

  /// Clears **Remember me** email/password (e.g. on logout). Museum journey prefs are kept.
  static Future<void> clearSavedLoginCredentials() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('saved_email');
    await p.remove('saved_password');
    await p.setBool('remember_me', false);
  }
}

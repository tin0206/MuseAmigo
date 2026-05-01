import 'package:flutter/material.dart';

/// A global [ChangeNotifier] that holds the user's profile information.
class ProfileNotifier extends ChangeNotifier {
  String _name = '';
  String _email = '';
  String _dob = '';
  String _bio = '';
  String _interests = '';

  String get name => _name;
  String get email => _email;
  String get dob => _dob;
  String get bio => _bio;
  String get interests => _interests;

  void setUser({required String name, required String email}) {
    _name = name;
    _email = email;
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? dob,
    String? bio,
    String? interests,
  }) {
    if (name != null) _name = name;
    if (dob != null) _dob = dob;
    if (bio != null) _bio = bio;
    if (interests != null) _interests = interests;
    notifyListeners();
  }
}

/// Single global instance so every screen can access the same notifier.
final ProfileNotifier profileNotifier = ProfileNotifier();

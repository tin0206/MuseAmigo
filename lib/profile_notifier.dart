import 'package:flutter/material.dart';

/// A global [ChangeNotifier] that holds the user's profile information.
class ProfileNotifier extends ChangeNotifier {
  String _name = 'Justin Nguyen';
  final String _email = 'justin@museum.com'; // Read-only
  String _dob = '';
  String _bio = '';
  String _interests = 'Ancient Egypt, Mythology, Archaeology';

  String get name => _name;
  String get email => _email;
  String get dob => _dob;
  String get bio => _bio;
  String get interests => _interests;

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

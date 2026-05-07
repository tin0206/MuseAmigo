import 'package:flutter/material.dart';
import 'package:museamigo/profile_notifier.dart';
import 'package:museamigo/session.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/theme_notifier.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _interestsCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: profileNotifier.name);
    _dobCtrl = TextEditingController(text: profileNotifier.dob);
    _bioCtrl = TextEditingController(text: profileNotifier.bio);
    _interestsCtrl = TextEditingController(text: profileNotifier.interests);
    _loadUserFromBackend();
  }

  Future<void> _loadUserFromBackend() async {
    final userId = AppSession.userId.value;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await BackendApi.instance.fetchUser(userId);
      if (!mounted) return;
      final fullName = data['full_name'] as String? ?? '';
      final email = data['email'] as String? ?? '';
      profileNotifier.setUser(name: fullName, email: email);
      _nameCtrl.text = fullName;
    } on ApiException {
      if (!mounted) return;
      // Silently fallback to session data
      _nameCtrl.text = AppSession.fullName.value;
    } catch (_) {
      if (!mounted) return;
      _nameCtrl.text = AppSession.fullName.value;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final userId = AppSession.userId.value;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to update your profile.')),
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name cannot be empty.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await BackendApi.instance.updateUserProfile(userId, fullName: name);
      if (!mounted) return;
      AppSession.fullName.value = name;
      profileNotifier.updateProfile(
        name: name,
        dob: _dobCtrl.text,
        bio: _bioCtrl.text,
        interests: _interestsCtrl.text,
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update profile. $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _bioCtrl.dispose();
    _interestsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themeNotifier.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit Profile'.tr,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: themeNotifier.textPrimaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, size: 22),
                    color: themeNotifier.textSecondaryColor,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: themeNotifier.borderColor,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/model.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 13,
                                    color: themeNotifier.surfaceColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Click camera icon to change avatar'.tr,
                            style: TextStyle(
                              fontSize: 10,
                              color: themeNotifier.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    _fieldLabel('Full Name'.tr),
                    _textField(_nameCtrl),
                    SizedBox(height: 8),
                    _fieldLabel('Email (Read-only)'.tr),
                    _textField(
                      null,
                      hint: profileNotifier.email.isEmpty ? 'Loading...' : profileNotifier.email,
                      enabled: false,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Email cannot be changed'.tr,
                      style: TextStyle(
                        fontSize: 10,
                        color: themeNotifier.textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    _fieldLabel('Date of Birth'.tr),
                    _textField(_dobCtrl),
                    SizedBox(height: 8),
                    _fieldLabel('Bio'.tr),
                    _textField(
                      _bioCtrl,
                      hint: 'Tell us about yourself'.tr,
                      maxLines: 2,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Help AI personalize your experience'.tr,
                      style: TextStyle(
                        fontSize: 10,
                        color: themeNotifier.textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    _fieldLabel('Interests'.tr),
                    _textField(_interestsCtrl),
                    SizedBox(height: 2),
                    Text(
                      'Separate interests with commas'.tr,
                      style: TextStyle(
                        fontSize: 10,
                        color: themeNotifier.textSecondaryColor,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: themeNotifier.surfaceColor,
                          elevation: 3,
                          shadowColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.27),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 13),
                        ),
                        icon: _isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: themeNotifier.surfaceColor,
                                ),
                              )
                            : Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          'Save Changes'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _fieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: themeNotifier.textSecondaryColor,
        ),
      ),
    );
  }

  static Widget _textField(
    TextEditingController? controller, {
    String? hint,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: themeNotifier.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: themeNotifier.textSecondaryColor, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          color: enabled ? themeNotifier.textPrimaryColor : themeNotifier.textSecondaryColor,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/theme_notifier.dart';
import 'package:museamigo/profile_notifier.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/font_size_notifier.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/session.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _audioGuide = true;
  bool _autoPlay = false;
  bool _indoorNavigation = true;

  double _horizontalDragDistance = 0;
  bool _isEdgeSwipe = false;
  bool _hasPoppedBySwipe = false;

  Future<void> _saveSettingsToBackend() async {
    if (AppSession.userId.value == null) return;
    try {
      await BackendApi.instance.updateUserSettings(
        AppSession.userId.value!,
        theme: themeNotifier.isDarkMode ? 'dark' : 'light',
        language: languageNotifier.currentLanguage,
        fontSize: fontSizeNotifier.levelName,
        scheme:
            '0x${themeNotifier.primaryColor.value.toRadixString(16).padLeft(8, '0').toUpperCase()}',
      );
    } catch (e) {
      debugPrint('Failed to save settings to backend: $e');
    }
  }

  void _handleSwipeStart(DragStartDetails details) {
    _horizontalDragDistance = 0;
    _hasPoppedBySwipe = false;
    _isEdgeSwipe = details.globalPosition.dx <= 32;
  }

  void _handleSwipeUpdate(DragUpdateDetails details) {
    if (!_isEdgeSwipe || _hasPoppedBySwipe) return;
    final delta = details.primaryDelta ?? 0;
    if (delta <= 0) return;
    _horizontalDragDistance += delta;
    if (_horizontalDragDistance > 90 && Navigator.of(context).canPop()) {
      _hasPoppedBySwipe = true;
      Navigator.of(context).pop();
    }
  }

  void _handleSwipeEnd(DragEndDetails details) {
    _horizontalDragDistance = 0;
    _isEdgeSwipe = false;
    _hasPoppedBySwipe = false;
  }

  void _showColorSchemeDialog(BuildContext context) {
    const quickPicks = [
      Color(0xFF6C4BE8),
      Color(0xFFF59E0B),
      Color(0xFFB45309),
      Color(0xFF10B981),
      Color(0xFF3B82F6),
      Color(0xFF60A5FA),
      Color(0xFFCC353A),
    ];
    Color selected = themeNotifier.primaryColor;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Dialog(
          backgroundColor: themeNotifier.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom Color'.tr,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            'Enter a hex color code'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: themeNotifier.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Text(
                  'Hex Color Code'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: themeNotifier.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeNotifier.backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: selected,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Primary Color'.tr,
                              style: TextStyle(
                                fontSize: 11,
                                color: themeNotifier.textSecondaryColor,
                              ),
                            ),
                            Text(
                              '#${selected.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: themeNotifier.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: themeNotifier.backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: themeNotifier.surfaceColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: themeNotifier.borderColor,
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Secondary Color'.tr,
                              style: TextStyle(
                                fontSize: 11,
                                color: themeNotifier.textSecondaryColor,
                              ),
                            ),
                            Text(
                              '#FFFFFF',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: themeNotifier.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                Text(
                  'Quick picks'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: themeNotifier.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickPicks.map((c) {
                    final isSel = selected.toARGB32() == c.toARGB32();
                    return GestureDetector(
                      onTap: () => ss(() => selected = c),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSel
                              ? Border.all(
                                  color: themeNotifier.textPrimaryColor,
                                  width: 2.5,
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: themeNotifier.borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Cancel'.tr,
                          style: TextStyle(
                            color: themeNotifier.textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          themeNotifier.setPrimaryColor(selected);
                          _saveSettingsToBackend();
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: themeNotifier.surfaceColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: Icon(Icons.check, size: 16),
                        label: Text('Apply'.tr),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    String temp = languageNotifier.currentLanguage;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Dialog(
          backgroundColor: themeNotifier.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Language'.tr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                ...[('Vietnamese', '🇻🇳'), ('English', '🇬🇧')].map((e) {
                  final sel = temp == e.$1;
                  return GestureDetector(
                    onTap: () => ss(() => temp = e.$1),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.08)
                            : themeNotifier.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: sel
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(e.$2, style: TextStyle(fontSize: 22)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.$1.tr,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: sel
                                    ? Theme.of(context).colorScheme.primary
                                    : themeNotifier.textSecondaryColor,
                              ),
                            ),
                          ),
                          if (sel)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      languageNotifier.setLanguage(temp);
                      _saveSettingsToBackend();
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: themeNotifier.surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Apply'.tr,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    FontSizeLevel temp = fontSizeNotifier.level;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Dialog(
          backgroundColor: themeNotifier.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Font Size'.tr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Choose your preferred reading size'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    color: themeNotifier.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 16),
                ...FontSizeLevel.values.map((level) {
                  final sel = temp == level;
                  String label =
                      level.name[0].toUpperCase() + level.name.substring(1);
                  return GestureDetector(
                    onTap: () => ss(() => temp = level),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.08)
                            : themeNotifier.backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: sel
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label.tr,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: sel
                                    ? Theme.of(context).colorScheme.primary
                                    : themeNotifier.textSecondaryColor,
                              ),
                            ),
                          ),
                          if (sel)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      fontSizeNotifier.setLevel(temp);
                      _saveSettingsToBackend();
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: themeNotifier.surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Apply'.tr,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacySecurityDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: themeNotifier.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Privacy & Security'.tr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: themeNotifier.textPrimaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _privacyRow('Change Password'.tr, () {
                Navigator.of(ctx).pop();
                _showChangePasswordDialog(context);
              }),
              SizedBox(height: 8),
              _privacyRow('Data & Permissions'.tr, () {
                Navigator.of(ctx).pop();
                _showDataPermissionsDialog(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacyRow(String label, VoidCallback onTap) {
    return Material(
      color: themeNotifier.backgroundColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: themeNotifier.textPrimaryColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: themeNotifier.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    bool showCurrent = false, showNew = false, showConfirm = false;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Dialog(
          backgroundColor: themeNotifier.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Change Password'.tr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 14),
                _pwField(
                  'Current Password'.tr,
                  !showCurrent,
                  () => ss(() => showCurrent = !showCurrent),
                ),
                SizedBox(height: 10),
                _pwField(
                  'New Password'.tr,
                  !showNew,
                  () => ss(() => showNew = !showNew),
                ),
                SizedBox(height: 10),
                _pwField(
                  'Confirm New Password'.tr,
                  !showConfirm,
                  () => ss(() => showConfirm = !showConfirm),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: themeNotifier.surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: Icon(Icons.key_rounded, size: 18),
                    label: Text(
                      'Change Password'.tr,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pwField(String label, bool obscure, VoidCallback onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: themeNotifier.textSecondaryColor,
          ),
        ),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: themeNotifier.backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            obscureText: obscure,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: themeNotifier.textSecondaryColor,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDataPermissionsDialog(BuildContext context) {
    bool saveLocally = true;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => Dialog(
          backgroundColor: themeNotifier.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Data & Permissions'.tr,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeNotifier.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: themeNotifier.borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.storage_rounded,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Local Data Storage'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: themeNotifier.textPrimaryColor,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'This setting allows the app to save your achievements, discovered artifacts, and museum journey data locally on your device for offline access.'
                                  .tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF3B82F6),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Save Museum Data Locally'.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: saveLocally,
                      onChanged: (v) => ss(() => saveLocally = v),
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                Text(
                  'Allow the app to store your achievements, progress, and discovered artifacts on your device'
                      .tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeNotifier.textSecondaryColor,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeNotifier.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data that will be saved:'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: themeNotifier.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 6),
                      ...[
                        'Achievements and badges earned',
                        "Artifacts you've discovered",
                        'Journey progress and points',
                        'Favorite exhibits and bookmarks',
                      ].map(
                        (s) => Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  s.tr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: themeNotifier.textSecondaryColor,
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
                SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: themeNotifier.surfaceColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      'Save Preferences'.tr,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final primary = scheme.primary;

        return Dialog(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confirm Logout'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to log out?'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          backgroundColor: primary.withValues(alpha: 0.06),
                          side: BorderSide(
                            color: primary.withValues(alpha: 0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'No'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.login,
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: scheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Yes'.tr,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        profileNotifier,
        languageNotifier,
        themeNotifier,
        fontSizeNotifier,
        profileNotifier,
      ]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: themeNotifier.backgroundColor,
          body: SafeArea(
            child: GestureDetector(
              onHorizontalDragStart: _handleSwipeStart,
              onHorizontalDragUpdate: _handleSwipeUpdate,
              onHorizontalDragEnd: _handleSwipeEnd,
              onHorizontalDragCancel: () {
                _horizontalDragDistance = 0;
                _isEdgeSwipe = false;
                _hasPoppedBySwipe = false;
              },
              behavior: HitTestBehavior.translucent,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(14, 6, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Settings'.tr,
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF171A21),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Customize your museum experience'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: Theme.of(context).colorScheme.primary,
                          tooltip: 'Back',
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Material(
                      color: themeNotifier.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.editProfile),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/model.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profileNotifier.name,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      profileNotifier.email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: themeNotifier.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: themeNotifier.textSecondaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _SectionLabel(text: 'APPEARANCE'.tr),
                    SizedBox(height: 8),
                    _ToggleTile(
                      icon: themeNotifier.isDarkMode
                          ? Icons.nightlight_round
                          : Icons.wb_sunny_outlined,
                      title: 'Theme',
                      subtitle: themeNotifier.isDarkMode ? 'Dark' : 'Light',
                      value: !themeNotifier.isDarkMode,
                      onChanged: (v) {
                        themeNotifier.setThemeMode(
                          v ? ThemeMode.light : ThemeMode.dark,
                        );
                        _saveSettingsToBackend();
                      },
                    ),
                    SizedBox(height: 8),
                    _ArrowTile(
                      icon: Icons.palette_outlined,
                      title: 'Color Scheme',
                      subtitle: 'Custom',
                      trailingDot: true,
                      onTap: () => _showColorSchemeDialog(context),
                    ),
                    SizedBox(height: 8),
                    _ArrowTile(
                      icon: Icons.text_fields_rounded,
                      title: 'Font Size',
                      subtitle: fontSizeNotifier.levelName,
                      onTap: () => _showFontSizeDialog(context),
                    ),
                    SizedBox(height: 16),
                    _SectionLabel(text: 'MUSEUM EXPERIENCE'.tr),
                    SizedBox(height: 8),
                    _ArrowTile(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: languageNotifier.currentLanguage,
                      onTap: () => _showLanguageDialog(context),
                    ),
                    SizedBox(height: 8),
                    _ToggleTile(
                      icon: Icons.record_voice_over_outlined,
                      title: 'Audio Guide',
                      subtitle: 'Narrated tours',
                      value: _audioGuide,
                      onChanged: (v) => setState(() => _audioGuide = v),
                    ),
                    SizedBox(height: 8),
                    _ToggleTile(
                      icon: Icons.play_circle_outline,
                      title: 'Auto-Play Tours',
                      subtitle: 'Automatic playback',
                      value: _autoPlay,
                      onChanged: (v) => setState(() => _autoPlay = v),
                    ),
                    SizedBox(height: 8),
                    _ToggleTile(
                      icon: Icons.location_on_outlined,
                      title: 'Indoor Navigation',
                      subtitle: 'Track your location',
                      value: _indoorNavigation,
                      onChanged: (v) => setState(() => _indoorNavigation = v),
                    ),
                    SizedBox(height: 16),
                    _SectionLabel(text: 'ACCOUNT & PRIVACY'.tr),
                    SizedBox(height: 8),
                    _ArrowTile(
                      icon: Icons.shield_outlined,
                      title: 'Privacy & Security',
                      subtitle: 'Data preferences',
                      onTap: () => _showPrivacySecurityDialog(context),
                    ),
                    SizedBox(height: 8),
                    _ArrowTile(
                      icon: Icons.confirmation_number_outlined,
                      title: 'My Tickets',
                      subtitle: 'View bookings',
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.myTickets),
                    ),
                    SizedBox(height: 8),
                    _ArrowTile(
                      icon: Icons.emoji_events_outlined,
                      title: 'Achievements',
                      subtitle: 'View badges',
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.achievements),
                    ),
                    SizedBox(height: 16),
                    _SectionLabel(text: 'SUPPORT'.tr),
                    SizedBox(height: 8),
                    const _ArrowTile(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      subtitle: 'FAQs & guides',
                    ),
                    SizedBox(height: 8),
                    const _ArrowTile(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'Version 2.4.3',
                    ),
                    SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showLogoutConfirmDialog(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.35),
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.06),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: Icon(Icons.logout_rounded),
                        label: Text(
                          'Log Out'.tr,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        'MuseAmigo · MobileDev252HCMUT',
                        style: TextStyle(
                          fontSize: 10,
                          color: themeNotifier.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      color: themeNotifier.textSecondaryColor,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _ArrowTile extends StatelessWidget {
  const _ArrowTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingDot = false,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool trailingDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: themeNotifier.surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: themeNotifier.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: themeNotifier.textPrimaryColor,
                      ),
                    ),
                    Text(
                      subtitle.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: themeNotifier.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingDot)
                CircleAvatar(
                  radius: 9,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: themeNotifier.textSecondaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeNotifier.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: themeNotifier.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: themeNotifier.textPrimaryColor,
                  ),
                ),
                Text(
                  subtitle.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: themeNotifier.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

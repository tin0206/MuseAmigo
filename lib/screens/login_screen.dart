import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/l10n/translations.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/session.dart';
import 'package:museamigo/profile_notifier.dart';
import 'package:museamigo/widgets/auth_form_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:museamigo/achievement_notifier.dart';
import 'package:museamigo/theme_notifier.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/font_size_notifier.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final rememberMe = prefs.getBool('remember_me') ?? false;
    if (savedEmail != null) {
      _emailController.text = savedEmail;
    }
    if (savedPassword != null && rememberMe) {
      _passwordController.text = savedPassword;
    }
    if (mounted) {
      setState(() {
        _rememberMe = rememberMe;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<AuthLoginResult> _loginWithRetryOnColdStart({
    required String email,
    required String password,
  }) async {
    try {
      return await BackendApi.instance.login(email: email, password: password);
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Server is waking up. Retrying login once, please wait...',
            ),
          ),
        );
      }
      await BackendApi.instance.warmUp();
      return BackendApi.instance.login(email: email, password: password);
    } on SocketException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Network is unstable. Retrying login once, please wait...',
            ),
          ),
        );
      }
      await BackendApi.instance.warmUp();
      return BackendApi.instance.login(email: email, password: password);
    }
  }

  Future<void> _submitLogin() async {
    if (_isSubmitting) return;

    // Validate inputs before making the API call
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _loginWithRetryOnColdStart(
        email: email,
        password: password,
      );
      await _saveCredentials();
      AppSession.userId.value = result.userId;
      AppSession.fullName.value = result.fullName;
      profileNotifier.setUser(
        name: result.fullName,
        email: _emailController.text.trim(),
      );
      final languageRaw = result.language.trim().toLowerCase();
      final resolvedLanguage =
          (languageRaw == 'vi' || languageRaw == 'vietnamese')
          ? 'Vietnamese'
          : 'English';

      // Apply settings from backend
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
      } catch (e) {
        // fallback
        themeNotifier.setPrimaryColor(Color(int.parse('0xFFCC353A')));
      }

      // Start preloading achievements right after login
      achievementNotifier.ensureLoaded();
    } on SocketException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network error: ${e.message}')));
      return;
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login timeout. Please try again.')),
      );
      return;
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to login: $e')));
      return;
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.exploreMap);
  }

  void _openSignUp() {
    Navigator.of(context).pushNamed(AppRoutes.signUp);
  }

  void _openForgotPassword() {
    Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Login', style: TextStyle(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(
              themeNotifier.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
              color: colorScheme.onPrimary,
            ),
            onPressed: () {
              themeNotifier.setThemeMode(
                themeNotifier.isDarkMode ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.color_lens, color: colorScheme.onPrimary),
            onPressed: () {
              themeNotifier.setPrimaryColor(
                themeNotifier.primaryColor == AppTheme.redPrimary 
                    ? AppTheme.yellowPrimary 
                    : AppTheme.redPrimary,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  Text(
                    'Welcome Back',
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Log in to continue your journey through museum'.tr,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 22,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 42),
                  const FieldLabel(text: 'Email'),
                  AppTextField(
                    controller: _emailController,
                    hintText: 'Enter your email',
                  ),
                  const SizedBox(height: 24),
                  const FieldLabel(text: 'Password'),
                  AppTextField(
                    controller: _passwordController,
                    hintText: 'Enter your password',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          visualDensity: VisualDensity.compact,
                          activeColor: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Remember me',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _openForgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          'Don\'t have an account?',
                          style: TextStyle(fontSize: 17, color: colorScheme.onSurface),
                        ),
                        InkWell(
                          onTap: _openSignUp,
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

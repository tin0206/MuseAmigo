import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/theme_notifier.dart';
import 'package:museamigo/screens/main_shell.dart';
import 'package:museamigo/screens/explore_map_screen.dart';
import 'package:museamigo/screens/forgot_password_screen.dart';
import 'package:museamigo/screens/login_screen.dart';
import 'package:museamigo/screens/artifact_detail_screen.dart';
import 'package:museamigo/screens/my_tickets_screen.dart';
import 'package:museamigo/screens/search_screen.dart';
import 'package:museamigo/screens/settings_screen.dart';
import 'package:museamigo/screens/edit_profile_screen.dart';
import 'package:museamigo/screens/achievements_screen.dart';
import 'package:museamigo/screens/onboarding_flow_screen.dart';
import 'package:museamigo/screens/sign_up_screen.dart';
import 'package:museamigo/services/backend_api.dart';
import 'package:museamigo/language_notifier.dart';
import 'package:museamigo/profile_notifier.dart';
import 'package:museamigo/font_size_notifier.dart';
import 'package:museamigo/achievement_notifier.dart';

import 'package:museamigo/session.dart';
import 'package:museamigo/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSession.init();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MuseAmigoApp(),
    ),
  );
}

class MuseAmigoApp extends StatelessWidget {
  const MuseAmigoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        themeNotifier,
        languageNotifier,
        profileNotifier,
        fontSizeNotifier,
        achievementNotifier,
      ]),
      builder: (context, _) {
        final primary = themeNotifier.primaryColor;
        return MaterialApp(
          navigatorKey: globalNavigatorKey,
          debugShowCheckedModeBanner: false,
          locale: DevicePreview.locale(context),
          builder: (context, child) {
            final appChild = DevicePreview.appBuilder(context, child);
            return ListenableBuilder(
              listenable: Listenable.merge([
                languageNotifier,
                profileNotifier,
                themeNotifier,
                fontSizeNotifier,
                achievementNotifier,
              ]),
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(fontSizeNotifier.scale),
                  ),
                  child: appChild,
                );
              },
            );
          },
          title: 'MuseAmigo',
          themeMode: themeNotifier.themeMode,
          theme: AppTheme.lightTheme(primary),
          darkTheme: AppTheme.darkTheme(primary),
          routes: {
            AppRoutes.login: (_) => const LoginScreen(),
            AppRoutes.signUp: (_) => const SignUpScreen(),
            AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
            AppRoutes.onboarding: (_) => const OnboardingFlowScreen(),
            AppRoutes.home: (_) => const MainShell(),
            AppRoutes.exploreMap: (_) => const ExploreMapScreen(),
            AppRoutes.myTickets: (_) => const MyTicketsScreen(),
            AppRoutes.settings: (_) => const SettingsScreen(),
            AppRoutes.editProfile: (_) => const EditProfileScreen(),
            AppRoutes.achievements: (_) => const AchievementsScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.search) {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => SearchScreen(
                  initialQuery: args?['query'] as String?,
                  showResults: args?['showResults'] as bool? ?? false,
                  initialFilter:
                      args?['initialFilter'] as String? ??
                      args?['filter'] as String?,
                  initialExhibition:
                      args?['initialExhibition'] as String? ??
                      args?['exhibition'] as String?,
                ),
              );
            }
            if (settings.name == AppRoutes.artifactDetail) {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (_) => ArtifactDetailScreen(
                  artifactCode: args?['artifactCode'] as String? ?? '',
                ),
              );
            }
            return null;
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Pre-warm backend while splash is visible to reduce cold-start delay.
    unawaited(BackendApi.instance.warmUp());

    Future<void>.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool('remember_me') ?? false;
      if (!remember) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        return;
      }

      final email = prefs.getString('saved_email')?.trim() ?? '';
      final password = prefs.getString('saved_password') ?? '';
      if (email.isEmpty || password.isEmpty) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        return;
      }

      try {
        final result = await BackendApi.instance.login(
          email: email,
          password: password,
        );
        applyAuthLoginResult(result, email);
        final resumeJourney =
            await AppSession.shouldResumeMuseumJourney(result.userId);
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          resumeJourney ? AppRoutes.home : AppRoutes.exploreMap,
        );
      } catch (_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF6F2E1),
      body: Center(
        child: Image(
          image: AssetImage('assets/images/logo.jpg'),
          width: 280,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

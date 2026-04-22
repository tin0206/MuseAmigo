import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:museamigo/app_routes.dart';
import 'package:museamigo/screens/explore_map_screen.dart';
import 'package:museamigo/screens/forgot_password_screen.dart';
import 'package:museamigo/screens/home_screen.dart';
import 'package:museamigo/screens/login_screen.dart';
import 'package:museamigo/screens/artifact_detail_screen.dart';
import 'package:museamigo/screens/search_screen.dart';
import 'package:museamigo/screens/onboarding_flow_screen.dart';
import 'package:museamigo/screens/sign_up_screen.dart';

void main() {
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'MuseAmigo',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFCC353A),
          primary: const Color(0xFFCC353A),
        ),
      ),
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.signUp: (_) => const SignUpScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.onboarding: (_) => const OnboardingFlowScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.exploreMap: (_) => const ExploreMapScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.search) {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => SearchScreen(
              initialQuery: args?['query'] as String?,
              showResults: args?['showResults'] as bool? ?? false,
              initialFilter: args?['filter'] as String?,
              initialExhibition: args?['exhibition'] as String?,
            ),
          );
        }
        if (settings.name == AppRoutes.artifactDetail) {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => ArtifactDetailScreen(
              title: args?['title'] as String? ?? 'Artifact',
              location: args?['location'] as String? ?? 'Unknown location',
              year: args?['year'] as String? ?? 'N/A',
              currentLocation:
                  args?['currentLocation'] as String? ?? 'Independence Palace',
              height: args?['height'] as String? ?? '~2.4 meters',
              weight: args?['weight'] as String? ?? '~39.7 tons',
              imageAsset:
                  args?['imageAsset'] as String? ?? 'assets/images/museum.jpg',
            ),
          );
        }
        return null;
      },
      home: const SplashScreen(),
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
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
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

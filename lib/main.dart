import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'backend/services/auth_service.dart';
import 'backend/services/location_service.dart';
import 'backend/services/notification_service.dart';
import 'backend/services/ride_service.dart';
import 'frontend/screens/splash_screen.dart';
import 'frontend/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Pre-load station location stops and services
  await Future.wait([
    AuthService().initialize(),
    LocationService().initialize(),
    RideService().initialize(),
    NotificationService().initialize(),
  ]);

  runApp(const RideMateApp());
}

class RideMateApp extends StatelessWidget {
  const RideMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

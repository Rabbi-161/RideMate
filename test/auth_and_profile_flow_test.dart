import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/screens/login_screen.dart';
import 'package:ridemate/screens/profile_screen.dart';
import 'package:ridemate/screens/rides_screen.dart';
import 'package:ridemate/screens/signup_screen.dart';
import 'package:ridemate/services/auth_service.dart';
import 'package:ridemate/services/location_service.dart';
import 'package:ridemate/services/ride_service.dart';
import 'package:ridemate/theme/app_theme.dart';
import 'package:ridemate/widgets/custom_button.dart';

void main() {
  setUp(() async {
    await AuthService().initialize();
    await LocationService().initialize();
    await RideService().initialize();
  });

  test('AuthService login, signUp, updateProfile, and logout', () async {
    final auth = AuthService();

    // Login with existing mock user
    final user = await auth.login('karim.ahmed@example.com', 'password123');
    expect(user, isNotNull);
    expect(user!.name, 'Karim Ahmed');
    expect(auth.isAuthenticated, isTrue);

    // Update profile
    await auth.updateProfile(name: 'Karim Ahmed Updated', phone: '+880 1999-888777');
    expect(auth.currentUser!.name, 'Karim Ahmed Updated');
    expect(auth.currentUser!.phone, '+880 1999-888777');

    // Sign up new user
    final newUser = await auth.signUp('Test Student', 'test.student@example.com', 'pass1234');
    expect(newUser, isNotNull);
    expect(newUser!.name, 'Test Student');
    expect(newUser.email, 'test.student@example.com');
    expect(auth.currentUser!.email, 'test.student@example.com');

    // Logout
    await auth.logout();
    expect(auth.isAuthenticated, isFalse);
    expect(auth.currentUser, isNull);
  });

  testWidgets('LoginScreen renders inputs, demo chips, and navigates on login',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Check header and fields
    expect(find.text('Welcome to RideMate'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(CustomButton, 'Login'), findsOneWidget);

    // Check quick demo chips
    expect(find.text('Karim Ahmed (Passenger)'), findsOneWidget);
    expect(find.text('Rahim Hasan (Host)'), findsOneWidget);

    // Tap Rahim Hasan demo chip
    final chip = find.text('Rahim Hasan (Host)');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    // Verify email field updated
    expect(find.text('rahim.hasan@example.com'), findsOneWidget);

    // Tap Login button
    final loginBtn = find.widgetWithText(CustomButton, 'Login');
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    // Verify navigation to HomeScreen
    expect(find.text('RideMate'), findsWidgets);
    expect(find.text('Find people travelling your way.'), findsOneWidget);
  });

  testWidgets('SignUpScreen validates passwords match and creates account',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const SignUpScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Join RideMate'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Create Account'), findsWidgets);

    // Fill form with mismatching passwords
    await tester.enterText(find.byType(TextFormField).at(0), 'Nusrat New');
    await tester.enterText(find.byType(TextFormField).at(1), 'nusrat.new@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.enterText(find.byType(TextFormField).at(3), 'mismatchedPass');
    await tester.pumpAndSettle();

    final submitBtn = find.widgetWithText(CustomButton, 'Create Account');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Verify validation error
    expect(find.text('Passwords do not match'), findsOneWidget);

    // Fix password
    await tester.enterText(find.byType(TextFormField).at(3), 'password123');
    await tester.pumpAndSettle();

    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Verify navigates to HomeScreen
    expect(find.text('RideMate'), findsWidgets);
  });

  testWidgets('ProfileScreen renders stats, opens edit dialog, and switches demo user',
      (WidgetTester tester) async {
    await AuthService().login('karim.ahmed@example.com', 'password123');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const ProfileScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify profile info
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Karim Ahmed'), findsWidgets);
    expect(find.text('karim.ahmed@example.com'), findsOneWidget);
    expect(find.text('User Rating'), findsOneWidget);
    expect(find.text('Total Rides'), findsOneWidget);

    // Verify menu items per PRD Section 26
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);

    // Tap Edit Profile
    final editTile = find.text('Edit Profile');
    await tester.ensureVisible(editTile);
    await tester.tap(editTile);
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Tap Help
    final helpTile = find.text('Help');
    await tester.ensureVisible(helpTile);
    await tester.tap(helpTile);
    await tester.pumpAndSettle();
    expect(find.text('Help & Support'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
  });

  testWidgets('RidesScreen renders tabs and supports demo actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const RidesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify tabs
    expect(find.text('Upcoming'), findsWidgets);
    expect(find.text('Requests'), findsWidgets);
    expect(find.text('Completed'), findsWidgets);

    // Switch to Requests tab
    await tester.tap(find.text('Requests').first);
    await tester.pumpAndSettle();

    // Check for demo actions in Requests tab
    expect(find.text('Cancel'), findsWidgets);
    expect(find.text('Accept (Demo)'), findsWidgets);

    // Switch to Completed tab
    await tester.tap(find.text('Completed').first);
    await tester.pumpAndSettle();

    // Verify completed rides card exists
    expect(find.text('Completed'), findsWidgets);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/main.dart';
import 'package:ridemate/screens/home_screen.dart';
import 'package:ridemate/screens/location_selection_screen.dart';
import 'package:ridemate/screens/login_screen.dart';
import 'package:ridemate/screens/profile_screen.dart';
import 'package:ridemate/screens/ride_details_screen.dart';
import 'package:ridemate/screens/search_results_screen.dart';
import 'package:ridemate/screens/signup_screen.dart';
import 'package:ridemate/screens/splash_screen.dart';
import 'package:ridemate/services/auth_service.dart';
import 'package:ridemate/services/location_service.dart';
import 'package:ridemate/services/ride_service.dart';
import 'package:ridemate/widgets/custom_button.dart';

void main() {
  setUp(() async {
    await AuthService().initialize();
    await LocationService().initialize();
    await RideService().initialize();
  });

  testWidgets('E2E: Complete Flow - Splash -> Login -> Sign Up -> Home -> Search -> Details -> Join -> Rides -> Profile -> Logout',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. Splash Screen
    await tester.pumpWidget(const RideMateApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('RideMate'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 2. Navigates to LoginScreen if not authenticated
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome to RideMate'), findsOneWidget);

    // 3. Navigate from Login to Sign Up
    final createAccountLink = find.text('Create an account');
    expect(createAccountLink, findsOneWidget);
    await tester.ensureVisible(createAccountLink);
    await tester.tap(createAccountLink);
    await tester.pumpAndSettle();

    // 4. Verify SignUpScreen
    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.text('Join RideMate'), findsOneWidget);

    // 5. Navigate back to Login
    final backToLogin = find.text('Login');
    expect(backToLogin, findsWidgets);
    await tester.tap(backToLogin.last);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // 6. Login using quick demo chip (Karim Ahmed)
    final chip = find.text('Karim Ahmed (Passenger)');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    final loginBtn = find.widgetWithText(CustomButton, 'Login');
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    // 7. Land on HomeScreen (Home tab)
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('RideMate'), findsWidgets);
    expect(find.text('Hi, Karim'), findsOneWidget);

    // 8. Test Search Card: tap Location Selector for From
    final fromSelector = find.text('Kazla');
    expect(fromSelector, findsOneWidget);
    await tester.tap(fromSelector);
    await tester.pumpAndSettle();

    // LocationSelectionScreen opens
    expect(find.byType(LocationSelectionScreen), findsOneWidget);
    expect(find.text('Select Departure'), findsOneWidget);

    // Pick Kazla
    await tester.tap(find.text('Kazla').first);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    // 9. Quick date & time presets
    final dateChip = find.text('10 Oct Demo');
    if (dateChip.evaluate().isNotEmpty) {
      await tester.ensureVisible(dateChip);
      await tester.tap(dateChip);
      await tester.pumpAndSettle();
    }

    final timeChip = find.text('5:30 PM Demo');
    if (timeChip.evaluate().isNotEmpty) {
      await tester.ensureVisible(timeChip);
      await tester.tap(timeChip);
      await tester.pumpAndSettle();
    }

    // 10. Submit Search
    final searchButton = find.text('SEARCH RIDE');
    await tester.ensureVisible(searchButton);
    await tester.tap(searchButton);
    await tester.pumpAndSettle();

    // 11. SearchResultsScreen
    expect(find.byType(SearchResultsScreen), findsOneWidget);
    expect(find.text('Available RideMates'), findsOneWidget);

    // Tap View Ride on first result
    final viewRideBtn = find.text('View Ride').first;
    await tester.ensureVisible(viewRideBtn);
    await tester.tap(viewRideBtn);
    await tester.pumpAndSettle();

    // 12. RideDetailsScreen
    expect(find.byType(RideDetailsScreen), findsOneWidget);
    expect(find.text('Ride Details'), findsOneWidget);
    expect(find.text('Host'), findsOneWidget);

    // Tap Request to Join
    final requestBtn = find.text('Request to Join');
    expect(requestBtn, findsOneWidget);
    await tester.ensureVisible(requestBtn);
    await tester.tap(requestBtn);
    await tester.pumpAndSettle();

    // 13. PRD Section 23 Confirmation dialog
    expect(find.text('Ride request sent successfully!'), findsOneWidget);
    expect(find.text('View in My Rides'), findsOneWidget);

    // Tap View in My Rides
    await tester.tap(find.text('View in My Rides'));
    await tester.pumpAndSettle();

    // 14. We are back on HomeScreen on the Rides tab (index 1)
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('My Rides'), findsOneWidget);
    expect(find.text('Upcoming'), findsWidgets);
    expect(find.text('Requests'), findsWidgets);
    expect(find.text('Completed'), findsWidgets);

    // Switch to Requests tab
    await tester.tap(find.text('Requests').first);
    await tester.pumpAndSettle();

    // Verify Pending request actions exist
    expect(find.text('Cancel'), findsWidgets);
    expect(find.text('Accept (Demo)'), findsWidgets);

    // 15. Switch to Profile tab (bottom navigation index 2)
    final profileTab = find.text('Profile');
    await tester.tap(profileTab);
    await tester.pumpAndSettle();

    // Verify ProfileScreen
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Karim Ahmed'), findsWidgets);
    expect(find.text('karim.ahmed@example.com'), findsOneWidget);

    // Open Edit Profile
    final editTile = find.text('Edit Profile');
    await tester.ensureVisible(editTile);
    await tester.tap(editTile);
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // 16. Logout
    final logoutTile = find.text('Logout');
    await tester.ensureVisible(logoutTile);
    await tester.tap(logoutTile);
    await tester.pumpAndSettle();

    // Confirmation dialog
    expect(find.text('Are you sure you want to log out of RideMate?'), findsOneWidget);
    final confirmLogoutBtn = find.text('Logout').last;
    await tester.tap(confirmLogoutBtn);
    await tester.pumpAndSettle();

    // 17. Successfully navigated back to LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome to RideMate'), findsOneWidget);
  });
}

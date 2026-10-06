import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/models/location.dart';
import 'package:ridemate/screens/home_screen.dart';
import 'package:ridemate/screens/search_results_screen.dart';
import 'package:ridemate/services/auth_service.dart';
import 'package:ridemate/services/location_service.dart';
import 'package:ridemate/services/matching_service.dart';
import 'package:ridemate/services/ride_service.dart';
import 'package:ridemate/theme/app_theme.dart';

void main() {
  setUp(() async {
    await AuthService().initialize();
    await LocationService().initialize();
    await RideService().initialize();
    await AuthService().login('karim.ahmed@example.com', 'password123');
  });

  test('MatchingService returns exact matches and route matches', () async {
    final matchingService = MatchingService();
    const fromLoc = Location(division: 'Rajshahi', city: 'Rajshahi City', area: 'Kazla');
    const toLoc = Location(division: 'Rajshahi', city: 'Rajshahi City', area: 'Shaheb Bazar');

    final results = await matchingService.searchRides(
      from: fromLoc,
      to: toLoc,
      date: '10 October 2026',
      time: '5:30 PM',
    );

    expect(results.isNotEmpty, isTrue);
    // Exact match is first
    expect(results.first.hostName, 'Rahim Hasan');
    expect(results.first.matchStatus, '100% Route Match');
  });

  testWidgets('SearchResultsScreen displays rides and navigates to RideDetailsScreen',
      (WidgetTester tester) async {
    const fromLoc = Location(division: 'Rajshahi', city: 'Rajshahi City', area: 'Kazla');
    const toLoc = Location(division: 'Rajshahi', city: 'Rajshahi City', area: 'Shaheb Bazar');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const SearchResultsScreen(
          from: fromLoc,
          to: toLoc,
          date: '10 October 2026',
          time: '5:30 PM',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header banner
    expect(find.text('Available RideMates'), findsOneWidget);
    expect(find.text('Kazla'), findsWidgets);
    expect(find.text('Shaheb Bazar'), findsWidgets);

    // Verify ride card elements per PRD Section 20
    expect(find.text('Rahim Hasan'), findsOneWidget);
    expect(find.text('4.8'), findsWidgets);
    expect(find.text('View Ride'), findsWidgets);

    // Tap View Ride to open details
    await tester.tap(find.text('View Ride').first);
    await tester.pumpAndSettle();

    // Verify Ride Details screen per PRD Section 22
    expect(find.text('Ride Details'), findsOneWidget);
    expect(find.text('Host'), findsOneWidget);
    expect(find.text('Rahim Hasan'), findsWidgets);
    expect(find.text('4.8 ★'), findsOneWidget);
    expect(find.text('Rajshahi → Rajshahi City → Kazla'), findsOneWidget);
    expect(find.text('Rajshahi → Rajshahi City → Shaheb Bazar'), findsOneWidget);
    expect(find.text('Request to Join'), findsOneWidget);
  });

  testWidgets('Full PRD Section 36 Flow: Request to Join and Confirmation',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Search Ride
    final searchButton = find.text('SEARCH RIDE');
    expect(searchButton, findsOneWidget);
    await tester.ensureVisible(searchButton);
    await tester.pumpAndSettle();
    await tester.tap(searchButton);
    await tester.pumpAndSettle();

    // We are on Search Results
    expect(find.text('Available RideMates'), findsOneWidget);
    final viewRideBtn = find.text('View Ride').first;
    await tester.ensureVisible(viewRideBtn);
    await tester.tap(viewRideBtn);
    await tester.pumpAndSettle();

    // We are on Ride Details
    expect(find.text('Ride Details'), findsOneWidget);
    final requestBtn = find.text('Request to Join');
    expect(requestBtn, findsOneWidget);
    await tester.ensureVisible(requestBtn);

    // Tap Request to Join
    await tester.tap(requestBtn);
    await tester.pumpAndSettle();

    // Verify PRD Section 23 Confirmation dialog
    expect(find.text('Ride request sent successfully!'), findsOneWidget);
    expect(find.text('View in My Rides'), findsOneWidget);

    // Tap View in My Rides
    await tester.tap(find.text('View in My Rides'));
    await tester.pumpAndSettle();

    // Verify it navigated back to HomeScreen on My Rides tab
    expect(find.text('My Rides'), findsOneWidget);
    expect(find.text('Upcoming'), findsWidgets);
    expect(find.text('Requests'), findsWidgets);
  });
}

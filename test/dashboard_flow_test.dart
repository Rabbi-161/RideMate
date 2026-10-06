import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/models/location.dart';
import 'package:ridemate/screens/home_screen.dart';
import 'package:ridemate/screens/location_selection_screen.dart';
import 'package:ridemate/services/location_service.dart';
import 'package:ridemate/theme/app_theme.dart';
import 'package:ridemate/widgets/search_card.dart';

void main() {
  setUp(() async {
    await LocationService().initialize();
  });

  testWidgets('Dashboard renders railway search card and elements', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header branding
    expect(find.text('RideMate'), findsWidgets);
    expect(find.text('Find people travelling your way.'), findsOneWidget);

    // Verify search card inputs
    expect(find.text('WHERE ARE YOU LEAVING FROM?'), findsOneWidget);
    expect(find.text('WHERE ARE YOU GOING?'), findsOneWidget);
    expect(find.text('TRAVEL DATE'), findsOneWidget);
    expect(find.text('DEPARTURE TIME'), findsOneWidget);
    expect(find.text('SEARCH RIDE'), findsOneWidget);

    // Verify popular routes header and chips
    expect(find.text('POPULAR RAJSHAHI ROUTES'), findsOneWidget);
    expect(find.text('Kazla → Shaheb Bazar'), findsOneWidget);
    expect(find.text('HOW RIDEMATE WORKS'), findsOneWidget);
  });

  testWidgets('Location swap button swaps departure and destination', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Defaults are Kazla (From) and Shaheb Bazar (To)
    expect(find.text('Kazla'), findsOneWidget);
    expect(find.text('Shaheb Bazar'), findsOneWidget);

    // Tap swap button
    final swapButton = find.byIcon(Icons.swap_vert_rounded);
    expect(swapButton, findsOneWidget);
    await tester.tap(swapButton);
    await tester.pumpAndSettle();

    // Verify snackbar feedback
    expect(find.text('Swapped departure and destination locations.'), findsOneWidget);
  });

  testWidgets('Search card validates empty fields per PRD Section 17', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: SearchCard(
            initialFrom: null,
            initialTo: const Location(division: 'Rajshahi', city: 'Rajshahi City', area: 'Shaheb Bazar'),
            initialDate: DateTime(2026, 10, 10),
            initialTime: const TimeOfDay(hour: 17, minute: 30),
            onSearch: (from, to, date, time, seats) {},
            onSelectFrom: () {},
            onSelectTo: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap SEARCH RIDE with null initialFrom
    await tester.tap(find.text('SEARCH RIDE'));
    await tester.pumpAndSettle();

    // Verify PRD exact error message
    expect(find.text('Please select your departure location.'), findsOneWidget);
  });

  testWidgets('LocationSelectionScreen allows searching and selecting an area', (WidgetTester tester) async {
    Location? selectedResult;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              selectedResult = await Navigator.push<Location>(
                context,
                MaterialPageRoute(
                  builder: (_) => const LocationSelectionScreen(title: 'Select Departure'),
                ),
              );
            },
            child: const Text('Open Picker'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Select Departure'), findsOneWidget);
    expect(find.text('Search location...'), findsOneWidget);

    // Enter search text 'Kazla'
    await tester.enterText(find.byType(TextField), 'Kazla');
    await tester.pumpAndSettle();

    // Tap on Kazla in the filtered list
    expect(find.text('Kazla'), findsWidgets);
    await tester.tap(find.text('Kazla').last);
    await tester.pumpAndSettle();

    // Screen dismissed and returned Kazla
    expect(selectedResult, isNotNull);
    expect(selectedResult!.area, 'Kazla');
  });
}

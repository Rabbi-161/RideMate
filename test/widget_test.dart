import 'package:flutter_test/flutter_test.dart';
import 'package:ridemate/main.dart';

void main() {
  testWidgets('RideMate app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RideMateApp());
    expect(find.text('RideMate'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}

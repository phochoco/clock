import 'package:flutter_test/flutter_test.dart';

import 'package:myclock/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyClockApp());

    // Verify that the lobby screen loads
    expect(find.text('시계 배우기'), findsWidgets);
  });

  testWidgets('Guardian info is available from lobby', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyClockApp());

    await tester.tap(find.byTooltip('보호자 안내'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('보호자 안내'), findsWidgets);
    expect(find.textContaining('어린이 대상'), findsOneWidget);
  });
}

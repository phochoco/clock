import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myclock/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyClockApp());

    // Verify that the lobby screen loads
    expect(find.text('시계 배우기'), findsWidgets);
  });
}

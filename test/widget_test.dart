import 'package:flutter_test/flutter_test.dart';

import 'package:myclock/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyClockApp());

    // Verify that the lobby screen loads with the primary learning path.
    expect(find.text('레벨 1 이어 하기'), findsOneWidget);
    expect(find.text('바늘 움직여 보기'), findsOneWidget);
    expect(find.text('놀이 모드'), findsOneWidget);
    expect(find.text('내 시계들'), findsOneWidget);
  });

  testWidgets('Guardian info is available from lobby', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyClockApp());

    await tester.tap(find.byTooltip('보호자 안내'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('보호자 안내'), findsWidgets);
    expect(find.textContaining('광고, 계정 가입, 외부 전송 없이'), findsOneWidget);
    expect(find.textContaining('Google AdMob'), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:myclock/main.dart';
import 'package:myclock/models/quiz_level.dart';
import 'package:myclock/screens/quiz_screen.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyClockApp());

    // Verify that the lobby screen loads with the primary learning path.
    expect(find.bySemanticsLabel(RegExp('^시작하기')), findsOneWidget);
    expect(find.bySemanticsLabel('바늘 연습'), findsOneWidget);
    expect(find.bySemanticsLabel('놀이 모드'), findsOneWidget);
    expect(find.bySemanticsLabel('내 시계들'), findsOneWidget);
  });

  testWidgets('Treasure map shows five islands with only the first open', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyClockApp());
    await tester.pump();

    expect(
      find.bySemanticsLabel(RegExp('^1번 야자수 해변.*지금 탐험할 섬')),
      findsOneWidget,
    );
    for (final name in ['버섯 숲', '화산섬', '얼음섬', '황금성']) {
      expect(find.bySemanticsLabel(RegExp('$name.*아직 잠겨 있음')), findsOneWidget);
    }
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

  testWidgets(
    'Quiz island tabs stay locked until earlier islands are cleared',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'completed_levels': '[1]'});
      await tester.pumpWidget(
        const MaterialApp(home: QuizScreen(initialLevel: QuizLevel.level2)),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('1번 야자수 해변 완료'), findsOneWidget);
      expect(find.bySemanticsLabel('2번 버섯 숲 열림'), findsOneWidget);
      expect(find.bySemanticsLabel('3번 화산섬 잠김'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('3번 화산섬 잠김'));
      await tester.pump();

      expect(find.text('2번 버섯 숲'), findsOneWidget);
      expect(find.text('버섯 숲부터 탐험해 줘!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:myclock/models/clock_time.dart';
import 'package:myclock/models/quiz_level.dart';
import 'package:myclock/utils/clock_hint.dart';
import 'package:myclock/utils/korean_text.dart';

void main() {
  group('level unlock', () {
    test('only level 1 is open on a fresh start', () {
      expect(nextLevelToPlay({}), QuizLevel.level1);
      expect(isLevelOpen(QuizLevel.level1, {}), isTrue);
      expect(isLevelOpen(QuizLevel.level2, {}), isFalse);
    });

    test('next uncompleted level opens after clearing earlier ones', () {
      final completed = {1, 2};
      expect(nextLevelToPlay(completed), QuizLevel.level3);
      expect(isLevelOpen(QuizLevel.level3, completed), isTrue);
      expect(isLevelOpen(QuizLevel.level4, completed), isFalse);
    });

    test('all levels open when everything is completed', () {
      final completed = {1, 2, 3, 4, 5};
      expect(nextLevelToPlay(completed), QuizLevel.level5);
      for (final level in QuizLevel.values) {
        expect(isLevelOpen(level, completed), isTrue);
      }
    });
  });

  group('clock hint', () {
    test('points to the minute number when the long hand is off', () {
      final hint = ClockHint.forAnswer(
        ClockTime(hour: 3, minute: 0),
        ClockTime(hour: 3, minute: 30),
      );
      expect(hint, '긴 바늘을 숫자 6에 맞춰 봐!');
    });

    test('points to 12 for o-clock answers', () {
      final hint = ClockHint.forAnswer(
        ClockTime(hour: 7, minute: 20),
        ClockTime(hour: 7, minute: 0),
      );
      expect(hint, '긴 바늘을 숫자 12에 맞춰 봐!');
    });

    test('talks about the short hand when only the hour is off', () {
      expect(
        ClockHint.forAnswer(
          ClockTime(hour: 2, minute: 0),
          ClockTime(hour: 9, minute: 0),
        ),
        '짧은 바늘을 숫자 9에 맞춰 봐!',
      );
      expect(
        ClockHint.forAnswer(
          ClockTime(hour: 4, minute: 30),
          ClockTime(hour: 11, minute: 30),
        ),
        '짧은 바늘은 숫자 11과 12 사이에 있어야 해!',
      );
    });
  });

  group('korean word wrap', () {
    test('joins syllables inside a word but keeps spaces breakable', () {
      final text = '새 시계를 열 수 있어요'.keepWords;
      expect(text.replaceAll('\u2060', ''), '새 시계를 열 수 있어요');
      expect(text.split(' ').last, '있\u2060어\u2060요');
      expect('7시에 별!'.keepWords, '7\u2060시\u2060에 별!');
    });
  });
}

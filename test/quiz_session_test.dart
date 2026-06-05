import 'package:flutter_test/flutter_test.dart';
import 'package:myclock/models/clock_time.dart';
import 'package:myclock/models/quiz_level.dart';
import 'package:myclock/models/quiz_session.dart';

void main() {
  test(
    'switching level resets progress and creates a question for that level',
    () {
      var nextHour = 1;
      final session = QuizSession(
        questionGenerator: QuizQuestionGenerator(
          randomInt: (max) {
            if (max == 12) return nextHour++ % max;
            return 0;
          },
        ),
      );

      session.start();
      session.answer(ClockTime(hour: session.currentQuestion!.hour, minute: 0));
      session.switchLevel(QuizLevel.level3);

      expect(session.currentLevel, QuizLevel.level3);
      expect(session.score, 0);
      expect(session.combo, 0);
      expect(session.showResult, isFalse);
      expect(session.userAnswer, isNull);
      expect(session.currentQuestion!.level, QuizLevel.level3);
    },
  );

  test('correct answers expose earned stars without mutating storage', () {
    final session = QuizSession(
      questionGenerator: QuizQuestionGenerator(randomInt: (_) => 0),
    );

    session.start();
    final first = session.answer(ClockTime(hour: 12, minute: 0));
    session.nextQuestion();
    final second = session.answer(ClockTime(hour: 12, minute: 0));
    session.nextQuestion();
    final third = session.answer(ClockTime(hour: 12, minute: 0));

    expect(first.earnedStars, 1);
    expect(second.earnedStars, 1);
    expect(third.earnedStars, 2);
    expect(session.score, 3);
    expect(session.comboMessage, '멋져요! 🌟');
  });
}

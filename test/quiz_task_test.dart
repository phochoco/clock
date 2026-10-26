import 'package:flutter_test/flutter_test.dart';
import 'package:myclock/models/clock_time.dart';
import 'package:myclock/models/quiz_level.dart';
import 'package:myclock/models/quiz_session.dart';

void main() {
  test('first island only uses set-hands, later islands mix tasks', () {
    expect(quizTaskPlan[QuizLevel.level1]!.toSet(), {QuizTask.setHands});
    expect(quizTaskPlan[QuizLevel.level2]!.toSet(), {
      QuizTask.setHands,
      QuizTask.readClock,
    });
    for (final level in [
      QuizLevel.level3,
      QuizLevel.level4,
      QuizLevel.level5,
    ]) {
      expect(quizTaskPlan[level]!.toSet().length, 3);
    }
  });

  test('only the last question of the golden castle is the boss', () {
    expect(isBossQuestion(QuizLevel.level5, 4, 5), isTrue);
    expect(isBossQuestion(QuizLevel.level5, 3, 5), isFalse);
    expect(isBossQuestion(QuizLevel.level4, 4, 5), isFalse);
  });

  test('read-clock options are three distinct times including the answer', () {
    var seed = 0;
    for (final level in QuizLevel.values) {
      for (var hour = 0; hour < 12; hour++) {
        for (final minute in [0, 1, 29, 30, 55, 59]) {
          final q = QuizQuestion(hour: hour, minute: minute, level: level);
          final options = readClockOptions(q, (max) => seed++ % max);
          expect(options.length, 3);
          final keys = options.map((t) => t.hour * 60 + t.minute).toSet();
          expect(keys.length, 3);
          expect(keys, contains((hour % 12) * 60 + minute));
        }
      }
    }
  });

  test('picking an option is graded exactly, not with hand tolerance', () {
    final session = QuizSession()..start(level: QuizLevel.level4);
    final q = session.currentQuestion!;
    final oneMinuteOff = ClockTime(hour: q.hour, minute: (q.minute + 1) % 60);
    expect(session.answerChoice(oneMinuteOff).isCorrect, isFalse);
    session.retryQuestion();
    expect(
      session.answerChoice(ClockTime(hour: q.hour, minute: q.minute)).isCorrect,
      isTrue,
    );
  });

  test('task stays the same after answering until the next question', () {
    final session = QuizSession()..start(level: QuizLevel.level3);
    expect(session.currentTask, QuizTask.setHands);
    final q = session.currentQuestion!;
    session.answer(ClockTime(hour: q.hour, minute: q.minute));
    expect(session.currentTask, QuizTask.setHands);
    session.nextQuestion();
    expect(session.currentTask, QuizTask.readClock);
  });

  test('an island never repeats a time and set-hands never asks 12:00', () {
    for (var run = 0; run < 200; run++) {
      final session = QuizSession()..start(level: QuizLevel.level1);
      final seen = <int>{};
      for (var i = 0; i < 5; i++) {
        final q = session.currentQuestion!;
        final key = (q.hour % 12) * 60 + q.minute;
        expect(seen.add(key), isTrue);
        expect(key, isNot(0));
        session.answer(ClockTime(hour: q.hour, minute: q.minute));
        session.nextQuestion();
      }
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myclock/models/clock_time.dart';
import 'package:myclock/utils/clock_answer_validator.dart';
import 'package:myclock/widgets/analog_clock.dart';

void main() {
  group('ClockAnswerValidator', () {
    test('rejects same-minute answers with the wrong hour', () {
      final correct = ClockTime(hour: 3, minute: 30);
      final answer = ClockTime(hour: 7, minute: 30);

      expect(ClockAnswerValidator.isCorrect(answer, correct), isFalse);
    });

    test('accepts close answers across the minute wraparound', () {
      final correct = ClockTime(hour: 12, minute: 0);
      final answer = ClockTime(hour: 11, minute: 59);

      expect(ClockAnswerValidator.isCorrect(answer, correct), isTrue);
    });

    test('rejects answers that only match the hour hand approximately', () {
      final correct = ClockTime(hour: 4, minute: 0);
      final answer = ClockTime(hour: 4, minute: 20);

      expect(ClockAnswerValidator.isCorrect(answer, correct), isFalse);
    });
  });

  group('AnalogClock initial callback', () {
    testWidgets('can avoid reporting an initial answer before interaction', (
      tester,
    ) async {
      ClockTime? reportedTime;

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: AnalogClock(
                initialTime: ClockTime(hour: 12, minute: 0),
                notifyInitialTime: false,
                onTimeChanged: (time) {
                  reportedTime = time;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(reportedTime, isNull);
    });
  });
}

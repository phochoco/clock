import 'package:flutter_test/flutter_test.dart';
import 'package:myclock/models/quiz_level.dart';

void main() {
  test('avoids repeating the previous question when another option exists', () {
    final rolls = <int>[2, 2, 3];
    final generator = QuizQuestionGenerator(
      randomInt: (max) => rolls.removeAt(0) % max,
    );

    final question = generator.next(
      QuizLevel.level1,
      previous: QuizQuestion(hour: 2, minute: 0, level: QuizLevel.level1),
    );

    expect(question.hour, 3);
    expect(question.minute, 0);
  });

  test('keeps master level questions in the hard minute range', () {
    final generator = QuizQuestionGenerator(randomInt: (_) => 0);

    final question = generator.next(QuizLevel.level5);

    expect(question.minute, inInclusiveRange(50, 59));
  });
}

import '../models/clock_time.dart';

/// Shared answer validation for clock-learning games.
class ClockAnswerValidator {
  static const double defaultHourToleranceDegrees = 15.0;
  static const double defaultMinuteToleranceDegrees = 10.0;

  const ClockAnswerValidator._();

  static bool isCorrect(
    ClockTime answer,
    ClockTime correct, {
    double hourToleranceDegrees = defaultHourToleranceDegrees,
    double minuteToleranceDegrees = defaultMinuteToleranceDegrees,
  }) {
    final hourDiff = _circularDifference(answer.hourAngle, correct.hourAngle);
    final minuteDiff = _circularDifference(
      answer.minuteAngle,
      correct.minuteAngle,
    );

    return hourDiff <= hourToleranceDegrees &&
        minuteDiff <= minuteToleranceDegrees;
  }

  static double _circularDifference(double firstAngle, double secondAngle) {
    var first = firstAngle % 360;
    var second = secondAngle % 360;
    if (first < 0) first += 360;
    if (second < 0) second += 360;

    var diff = (first - second).abs();
    if (diff > 180) {
      diff = 360 - diff;
    }
    return diff;
  }
}

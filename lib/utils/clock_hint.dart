import '../models/clock_time.dart';

/// 오답일 때 째깍이가 들려줄 힌트
/// 긴 바늘(분)이 틀렸으면 분부터, 맞았으면 짧은 바늘(시)을 알려준다
class ClockHint {
  const ClockHint._();

  static String forAnswer(ClockTime answer, ClockTime correct) {
    final minuteDiff = (answer.minute - correct.minute).abs();
    final minuteWrong = minuteDiff > 1 && minuteDiff < 59;

    if (minuteWrong) {
      final minute = correct.minute;
      if (minute == 0) return '긴 바늘을 숫자 12에 맞춰 봐!';
      if (minute % 5 == 0) return '긴 바늘을 숫자 ${minute ~/ 5}에 맞춰 봐!';
      return '긴 바늘을 $minute분 자리에 맞춰 봐!';
    }

    final hour = _displayHour(correct.hour);
    if (correct.minute == 0) return '짧은 바늘을 숫자 $hour에 맞춰 봐!';
    final nextHour = _displayHour(correct.hour + 1);
    return '짧은 바늘은 $hour에서 $nextHour 쪽으로 조금 가 있어야 해!';
  }

  static int _displayHour(int hour) {
    final h = hour % 12;
    return h == 0 ? 12 : h;
  }
}

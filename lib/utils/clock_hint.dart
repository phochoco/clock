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
    return '짧은 바늘은 숫자 $hour${_andParticle(hour)} $nextHour 사이에 있어야 해!';
  }

  /// 숫자를 한자어로 읽었을 때 받침이 있으면 '과', 없으면 '와'
  static String _andParticle(int number) =>
      const {2, 4, 5, 9, 12}.contains(number) ? '와' : '과';

  static int _displayHour(int hour) {
    final h = hour % 12;
    return h == 0 ? 12 : h;
  }
}

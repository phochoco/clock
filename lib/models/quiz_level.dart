import 'clock_time.dart';
import 'dart:math';

typedef RandomInt = int Function(int max);

/// 퀴즈 난이도 레벨
enum QuizLevel {
  level1, // 정각만 (분침 고정)
  level2, // 30분 추가
  level3, // 5분 단위
  level4, // 1분 단위
  level5, // 마의 구간 (시침이 다음 숫자 근접)
}

/// 아직 완료하지 않은 첫 레벨 (모두 완료했으면 마지막 레벨)
QuizLevel nextLevelToPlay(Set<int> completedLevels) {
  return QuizLevel.values.firstWhere(
    (level) => !completedLevels.contains(level.number),
    orElse: () => QuizLevel.level5,
  );
}

/// 보물섬 지도 순서대로 열린 레벨인지 (완료했거나 다음 차례까지)
bool isLevelOpen(QuizLevel level, Set<int> completedLevels) {
  return completedLevels.contains(level.number) ||
      level.index <= nextLevelToPlay(completedLevels).index;
}

extension QuizLevelExtension on QuizLevel {
  /// 레벨 이름
  String get name {
    switch (this) {
      case QuizLevel.level1:
        return '레벨 1: 정각';
      case QuizLevel.level2:
        return '레벨 2: 30분';
      case QuizLevel.level3:
        return '레벨 3: 5분 단위';
      case QuizLevel.level4:
        return '레벨 4: 1분 단위';
      case QuizLevel.level5:
        return '레벨 5: 마스터';
    }
  }

  /// 레벨 설명
  String get description {
    switch (this) {
      case QuizLevel.level1:
        return '정각부터 맞춰봐요';
      case QuizLevel.level2:
        return '30분도 배워볼까요?';
      case QuizLevel.level3:
        return '5분 단위로 읽어봐요';
      case QuizLevel.level4:
        return '정확한 시간을 맞춰봐요';
      case QuizLevel.level5:
        return '어려운 시간도 척척!';
    }
  }

  /// 레벨 번호
  int get number => index + 1;

  /// 다음 레벨
  QuizLevel? get next {
    if (this == QuizLevel.level5) return null;
    return QuizLevel.values[index + 1];
  }

  /// 이전 레벨
  QuizLevel? get previous {
    if (this == QuizLevel.level1) return null;
    return QuizLevel.values[index - 1];
  }
}

/// 문제 방식
enum QuizTask {
  /// 글로 된 시각을 보고 바늘 맞추기
  setHands,

  /// 시계를 보고 맞는 시각 고르기
  readClock,

  /// 디지털 시계를 보고 바늘 맞추기
  digitalSet,
}

/// 섬(레벨)마다 5문제의 방식 순서. 뒤 섬으로 갈수록 새로운 방식이 섞인다.
const Map<QuizLevel, List<QuizTask>> quizTaskPlan = {
  QuizLevel.level1: [
    QuizTask.setHands,
    QuizTask.setHands,
    QuizTask.setHands,
    QuizTask.setHands,
    QuizTask.setHands,
  ],
  QuizLevel.level2: [
    QuizTask.setHands,
    QuizTask.readClock,
    QuizTask.setHands,
    QuizTask.readClock,
    QuizTask.setHands,
  ],
  QuizLevel.level3: [
    QuizTask.setHands,
    QuizTask.readClock,
    QuizTask.digitalSet,
    QuizTask.readClock,
    QuizTask.digitalSet,
  ],
  QuizLevel.level4: [
    QuizTask.digitalSet,
    QuizTask.readClock,
    QuizTask.setHands,
    QuizTask.readClock,
    QuizTask.digitalSet,
  ],
  QuizLevel.level5: [
    QuizTask.readClock,
    QuizTask.digitalSet,
    QuizTask.setHands,
    QuizTask.readClock,
    QuizTask.digitalSet,
  ],
};

/// n번째 문제(0부터)의 방식
QuizTask quizTaskFor(QuizLevel level, int index) {
  final plan = quizTaskPlan[level]!;
  return plan[index.clamp(0, plan.length - 1)];
}

/// 황금성(마지막 섬)의 마지막 문제는 보스 문제
bool isBossQuestion(QuizLevel level, int index, int questionsPerLevel) =>
    level == QuizLevel.level5 && index == questionsPerLevel - 1;

/// 시계 읽기 문제의 보기 3개 (정답 1 + 아이들이 자주 헷갈리는 시각 2)
List<ClockTime> readClockOptions(QuizQuestion question, RandomInt randomInt) {
  final h = question.hour;
  final m = question.minute;
  ClockTime at(int hour, int minute) =>
      ClockTime(hour: (hour % 12 + 12) % 12, minute: (minute % 60 + 60) % 60);

  final candidates = switch (question.level) {
    QuizLevel.level1 => [at(h + 1, 0), at(h - 1, 0), at(h + 6, 0)],
    QuizLevel.level2 => [at(h, m + 30), at(h + 1, m), at(h - 1, m)],
    QuizLevel.level3 => [
      at(h, m + 5),
      at(h, m - 5),
      at(h, m + 10),
      at(h + 1, m),
    ],
    QuizLevel.level4 || QuizLevel.level5 => [
      at(h, m + 1),
      at(h, m - 1),
      at(h, m + 5),
      at(h + 1, m),
    ],
  };
  final correct = at(h, m);
  final pool = <ClockTime>[];
  for (final c in candidates) {
    final duplicate = pool.any((p) => p.hour == c.hour && p.minute == c.minute);
    final isCorrect = c.hour == correct.hour && c.minute == correct.minute;
    if (!duplicate && !isCorrect) pool.add(c);
  }
  final options = <ClockTime>[correct];
  while (options.length < 3 && pool.isNotEmpty) {
    options.add(pool.removeAt(randomInt(pool.length)));
  }
  // 정답 위치를 섞는다
  final answerSlot = randomInt(options.length);
  options
    ..removeAt(0)
    ..insert(answerSlot, correct);
  return options;
}

/// 시각을 "7시 30분" 꼴로
String clockTimeText(ClockTime time) {
  final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return time.minute == 0 ? '$h시' : '$h시 ${time.minute}분';
}

/// 디지털 시계 표기 "07:30"
String digitalTimeText(int hour, int minute) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// 바늘을 12시에서부터 돌리는 문제용 시각 (12시 정각과 앞뒤 1분은 시작 상태로도 정답이 되므로 뺀다)
QuizQuestion handsQuestion(QuizLevel level) =>
    QuizQuestionGenerator().next(level, avoid: const {0, 1, 719});

/// 바늘 문제의 시계 시작 시각
final handsStartTime = ClockTime(hour: 12, minute: 0);

/// 퀴즈 문제
class QuizQuestion {
  final int hour;
  final int minute;
  final QuizLevel level;

  QuizQuestion({required this.hour, required this.minute, required this.level});

  /// 레벨에 맞는 랜덤 문제 생성
  factory QuizQuestion.random(QuizLevel level, {RandomInt? randomInt}) {
    return QuizQuestionGenerator(randomInt: randomInt).next(level);
  }

  bool isSameTime(QuizQuestion other) {
    return hour == other.hour && minute == other.minute;
  }

  /// 정답 텍스트
  String get answerText {
    final h = hour == 0 ? 12 : hour;
    if (minute == 0) {
      return '$h시';
    }
    return '$h시 $minute분';
  }
}

class QuizQuestionGenerator {
  QuizQuestionGenerator({RandomInt? randomInt})
    : _randomInt = randomInt ?? Random().nextInt;

  final RandomInt _randomInt;

  /// [avoid]: 이미 낸 시각 등 피할 시각 (시×60+분, 12시는 0)
  QuizQuestion next(
    QuizLevel level, {
    QuizQuestion? previous,
    Set<int> avoid = const {},
  }) {
    QuizQuestion question;
    var attempts = 0;

    bool rejected(QuizQuestion q) =>
        (previous != null && q.isSameTime(previous)) ||
        avoid.contains((q.hour % 12) * 60 + q.minute);

    do {
      question = _build(level);
      attempts++;
    } while (rejected(question) && attempts < 40);

    return question;
  }

  QuizQuestion _build(QuizLevel level) {
    final hour = _randomInt(12);
    int minute;

    switch (level) {
      case QuizLevel.level1:
        // 정각만
        minute = 0;
        break;
      case QuizLevel.level2:
        // 정각 또는 30분
        minute = _randomInt(2) * 30;
        break;
      case QuizLevel.level3:
        // 5분 단위
        minute = _randomInt(12) * 5;
        break;
      case QuizLevel.level4:
        // 1분 단위 (쉬운 범위)
        minute = _randomInt(60);
        break;
      case QuizLevel.level5:
        // 마의 구간 (50~59분)
        minute = 50 + _randomInt(10);
        break;
    }

    return QuizQuestion(hour: hour, minute: minute, level: level);
  }
}

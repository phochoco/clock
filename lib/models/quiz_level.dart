/// 퀴즈 난이도 레벨
enum QuizLevel {
  level1, // 정각만 (분침 고정)
  level2, // 30분 추가
  level3, // 5분 단위
  level4, // 1분 단위
  level5, // 마의 구간 (시침이 다음 숫자 근접)
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
        return '정각만 맞춰보세요!';
      case QuizLevel.level2:
        return '30분도 배워볼까요?';
      case QuizLevel.level3:
        return '5분 단위로 읽어보세요!';
      case QuizLevel.level4:
        return '정확한 시간을 맞춰보세요!';
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

/// 퀴즈 문제
class QuizQuestion {
  final int hour;
  final int minute;
  final QuizLevel level;
  
  QuizQuestion({
    required this.hour,
    required this.minute,
    required this.level,
  });
  
  /// 레벨에 맞는 랜덤 문제 생성
  factory QuizQuestion.random(QuizLevel level) {
    final random = DateTime.now().millisecondsSinceEpoch;
    int hour = (random % 12);
    int minute;
    
    switch (level) {
      case QuizLevel.level1:
        // 정각만
        minute = 0;
        break;
      case QuizLevel.level2:
        // 정각 또는 30분
        minute = (random % 2) * 30;
        break;
      case QuizLevel.level3:
        // 5분 단위
        minute = ((random % 12) * 5);
        break;
      case QuizLevel.level4:
        // 1분 단위 (쉬운 범위)
        minute = (random % 60);
        break;
      case QuizLevel.level5:
        // 마의 구간 (50~59분)
        minute = 50 + (random % 10);
        break;
    }
    
    return QuizQuestion(hour: hour, minute: minute, level: level);
  }
  
  /// 정답 텍스트
  String get answerText {
    final h = hour == 0 ? 12 : hour;
    return '$h시 $minute분';
  }
}

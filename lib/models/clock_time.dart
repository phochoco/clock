import 'dart:math';

/// 시계 시간 모델
/// 시침과 분침의 각도를 계산하고 관리
class ClockTime {
  final int hour;
  final int minute;
  final int second;
  
  ClockTime({
    required this.hour, 
    required this.minute,
    this.second = 0,
  }) : assert(hour >= 0 && hour < 24, 'Hour must be between 0 and 23'),
       assert(minute >= 0 && minute < 60, 'Minute must be between 0 and 59'),
       assert(second >= 0 && second < 60, 'Second must be between 0 and 59');
  
  /// 현재 시간으로 ClockTime 생성
  factory ClockTime.now() {
    final now = DateTime.now();
    int hour12 = now.hour % 12;
    if (hour12 == 0) hour12 = 12; // 0시 또는 12시는 12로 표시
    return ClockTime(
      hour: hour12, 
      minute: now.minute,
      second: now.second,
    );
  }
  
  /// 시침 각도 계산 (12시 기준 0도, 시계방향)
  /// 분침 위치에 따라 시침도 부드럽게 이동 (Geared Movement)
  double get hourAngle {
    final h = hour % 12; // 12시간 형식으로 변환
    return (h * 30.0) + (minute / 60.0 * 30.0);
  }
  
  /// 분침 각도 계산 (12시 기준 0도, 시계방향)
  double get minuteAngle {
    return minute * 6.0;
  }
  
  /// 초침 각도 계산 (12시 기준 0도, 시계방향)
  double get secondAngle {
    return second * 6.0;
  }
  
  /// 각도로부터 시간 생성 (역계산)
  /// 사용자가 시계를 조작할 때 사용
  factory ClockTime.fromAngles({
    required double hourAngle,
    required double minuteAngle,
  }) {
    // 분침 각도로부터 분 계산
    int minute = ((minuteAngle / 6.0).round()) % 60;
    
    // 시침 각도로부터 시간 계산
    // 분침의 영향을 제거하고 순수 시간만 추출
    double pureHourAngle = hourAngle - (minute / 60.0 * 30.0);
    int hour = ((pureHourAngle / 30.0).round()) % 12;
    
    // 음수 방지
    if (hour < 0) hour += 12;
    if (minute < 0) minute += 60;
    
    return ClockTime(hour: hour, minute: minute);
  }
  
  /// 분침 각도로부터 시간 생성 (분침만 조작할 때)
  /// Geared Movement: 분침 360도 = 60분 = 1시간, 시침 30도
  factory ClockTime.fromMinuteAngle(double minuteAngle) {
    // 분침 각도를 정규화 (0-360 범위)
    double normalizedMinuteAngle = minuteAngle % 360;
    if (normalizedMinuteAngle < 0) normalizedMinuteAngle += 360;
    
    // 분 계산: 각도 / 6 = 분 (360도 / 60분 = 6도/분)
    int minute = (normalizedMinuteAngle / 6.0).round() % 60;
    
    // 시간 계산: 분침이 몇 바퀴 돌았는지 계산
    // 한 바퀴(360도) = 1시간
    int hour = (minuteAngle / 360.0).floor() % 12;
    if (hour < 0) hour += 12;
    if (hour == 0) hour = 12; // 0시는 12시로 표시
    
    return ClockTime(hour: hour, minute: minute);
  }
  
  /// 오전/오후 판단
  bool get isAM => hour < 12;
  bool get isPM => hour >= 12;
  
  /// 12시간 형식 시간
  int get hour12 {
    final h = hour % 12;
    return h == 0 ? 12 : h;
  }
  
  /// 포맷된 시간 문자열 (HH:MM)
  String get formatted {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
  
  /// 포맷된 시간 문자열 (12시간 형식)
  String get formatted12 {
    final period = isAM ? '오전' : '오후';
    return '$period ${hour12}시 ${minute}분';
  }
  
  /// 시간 비교
  bool equals(ClockTime other) {
    return hour == other.hour && minute == other.minute;
  }
  
  /// 시간 차이 계산 (분 단위)
  int differenceInMinutes(ClockTime other) {
    return (hour * 60 + minute) - (other.hour * 60 + other.minute);
  }
  
  /// 복사본 생성
  ClockTime copyWith({int? hour, int? minute}) {
    return ClockTime(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
  
  @override
  String toString() => formatted;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClockTime && other.hour == hour && other.minute == minute;
  }
  
  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}

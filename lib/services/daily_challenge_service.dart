import 'package:shared_preferences/shared_preferences.dart';

/// 데일리 챌린지 서비스
/// 매일 한 번 도전 가능한 챌린지 관리
class DailyChallengeService {
  static const String _lastPlayDateKey = 'daily_challenge_last_play';
  static const String _streakKey = 'daily_challenge_streak';
  static const String _completedTodayKey = 'daily_challenge_completed';
  
  /// 오늘 날짜 문자열 (YYYY-MM-DD)
  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  
  /// 오늘 챌린지 완료 여부
  static Future<bool> isCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlay = prefs.getString(_lastPlayDateKey);
    final today = _getTodayString();
    
    return lastPlay == today && (prefs.getBool(_completedTodayKey) ?? false);
  }
  
  /// 챌린지 완료 처리
  static Future<void> completeChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final lastPlay = prefs.getString(_lastPlayDateKey);
    
    // 연속 출석 계산
    int streak = prefs.getInt(_streakKey) ?? 0;
    
    if (lastPlay != null) {
      final lastDate = DateTime.parse(lastPlay);
      final todayDate = DateTime.parse(today);
      final difference = todayDate.difference(lastDate).inDays;
      
      if (difference == 1) {
        // 연속
        streak++;
      } else if (difference > 1) {
        // 끊김
        streak = 1;
      }
    } else {
      streak = 1;
    }
    
    await prefs.setString(_lastPlayDateKey, today);
    await prefs.setInt(_streakKey, streak);
    await prefs.setBool(_completedTodayKey, true);
  }
  
  /// 현재 연속 출석 일수
  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }
  
  /// 다음 리셋까지 남은 시간 (초)
  static int getTimeUntilReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now).inSeconds;
  }
  
  /// 리셋 (테스트용)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastPlayDateKey);
    await prefs.remove(_completedTodayKey);
  }
}

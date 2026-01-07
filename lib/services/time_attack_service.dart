import 'package:shared_preferences/shared_preferences.dart';

/// 타임 어택 모드 서비스
/// 최고 기록 관리
class TimeAttackService {
  static const String _highScoreKey = 'time_attack_high_score';
  
  /// 최고 기록 가져오기
  static Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highScoreKey) ?? 0;
  }
  
  /// 최고 기록 저장
  static Future<void> saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHigh = await getHighScore();
    
    if (score > currentHigh) {
      await prefs.setInt(_highScoreKey, score);
    }
  }
  
  /// 최고 기록 초기화 (테스트용)
  static Future<void> resetHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_highScoreKey);
  }
}

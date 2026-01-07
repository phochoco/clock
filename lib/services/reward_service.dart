import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/reward.dart';

/// 보물 저장 및 관리 서비스
class RewardService {
  static const String _unlockedRewardsKey = 'unlocked_rewards';
  static const String _completedLevelsKey = 'completed_levels';
  static const String _totalStarsKey = 'total_stars';
  
  /// 획득한 보물 ID 목록 가져오기
  static Future<List<String>> getUnlockedRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_unlockedRewardsKey);
    if (jsonString == null) {
      // 기본 시계는 처음부터 해금
      return ['basic_clock'];
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.cast<String>();
  }
  
  /// 보물 획득
  static Future<void> unlockReward(String rewardId) async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedRewards = await getUnlockedRewards();
    
    if (!unlockedRewards.contains(rewardId)) {
      unlockedRewards.add(rewardId);
      await prefs.setString(_unlockedRewardsKey, json.encode(unlockedRewards));
    }
  }
  
  /// 완료한 레벨 목록 가져오기
  static Future<List<int>> getCompletedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_completedLevelsKey);
    if (jsonString == null) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.cast<int>();
  }
  
  /// 레벨 완료 기록
  static Future<void> completeLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    final completedLevels = await getCompletedLevels();
    
    if (!completedLevels.contains(level)) {
      completedLevels.add(level);
      await prefs.setString(_completedLevelsKey, json.encode(completedLevels));
    }
  }
  
  /// 특정 보물이 해금되었는지 확인
  static Future<bool> isRewardUnlocked(String rewardId) async {
    final unlockedRewards = await getUnlockedRewards();
    return unlockedRewards.contains(rewardId);
  }
  
  /// 획득한 보물 개수
  static Future<int> getUnlockedRewardCount() async {
    final unlockedRewards = await getUnlockedRewards();
    return unlockedRewards.length;
  }
  
  /// 완료한 레벨 개수
  static Future<int> getCompletedLevelCount() async {
    final completedLevels = await getCompletedLevels();
    return completedLevels.length;
  }
  
  // ===== 별 시스템 =====
  
  /// 총 별 개수 가져오기
  static Future<int> getTotalStars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalStarsKey) ?? 0;
  }
  
  /// 별 추가
  static Future<void> addStars(int stars) async {
    final prefs = await SharedPreferences.getInstance();
    final currentStars = await getTotalStars();
    await prefs.setInt(_totalStarsKey, currentStars + stars);
  }
  
  /// 별 차감 (구매 시 사용)
  static Future<bool> spendStars(int stars) async {
    final currentStars = await getTotalStars();
    if (currentStars < stars) {
      return false; // 별이 부족함
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalStarsKey, currentStars - stars);
    return true;
  }
  
  /// 별 초기화 (테스트용)
  static Future<void> resetStars() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalStarsKey, 0);
  }
}

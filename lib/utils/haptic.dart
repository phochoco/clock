import 'package:flutter/services.dart';

/// 햅틱 피드백 유틸리티
/// 시계 조작 시 촉각 피드백 제공
class HapticHelper {
  /// 가벼운 선택 피드백 (12, 3, 6, 9 지점)
  static void lightImpact() {
    HapticFeedback.selectionClick();
  }
  
  /// 중간 강도 피드백 (정각 도달)
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }
  
  /// 강한 피드백 (정답)
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }
  
  /// 진동 피드백 (오답)
  static void vibrate() {
    HapticFeedback.vibrate();
  }
}

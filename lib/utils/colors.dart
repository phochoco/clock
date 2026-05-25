import 'package:flutter/material.dart';

/// 세련되고 프리미엄한 앱 전체 색상 팔레트
class AppColors {
  // 메인 색상 - 시침/분침 구분 (명도/채도 조절로 고급스럽게)
  static const Color hourRed = Color(0xFFFF5252); // 시침 (Vivid Red)
  static const Color minuteBlue = Color(0xFF00B0FF); // 분침 (Vivid Blue)
  static const Color secondary = Color(
    0xFF8B5CF6,
  ); // Violet 500 (메모리 게임 등 보조 효과)

  // 프리미엄 다이내믹 배경 색상 (Mesh Gradient용)
  static const Color bgPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color bgSecondary = Color(0xFFEFF6FF); // Blue 50
  static const Color bgAccent1 = Color(0xFFE0E7FF); // Indigo 50
  static const Color bgAccent2 = Color(0xFFF3E8FF); // Purple 50

  // 야간/다크 테마용 다이내믹 배경 색상
  static const Color bgDarkPrimary = Color(0xFF0F172A); // Slate 900
  static const Color bgDarkSecondary = Color(0xFF1E1B4B); // Indigo 950
  static const Color bgDarkAccent1 = Color(0xFF312E81); // Indigo 800

  // UI 요소
  static const Color textDark = Color(0xFF1E293B); // Slate 800 (기본 텍스트)
  static const Color textLight = Color(0xFF64748B); // Slate 500 (보조 텍스트)
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200 (연한 테두리)
  static const Color borderDark = Color(0xFF334155); // Slate 700 (다크 모드 테두리)

  // 상태 색상
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500

  // 글래스모피즘 표면 색상
  static const Color glassWhite = Color(0x99FFFFFF); // 반투명 화이트 (60%)
  static const Color glassDark = Color(0x40000000); // 반투명 블랙 (25%)
}

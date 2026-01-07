import 'package:flutter/material.dart';

/// 파스텔톤 색상 팔레트
/// 아동 친화적이고 따뜻한 느낌의 색상 조합
class AppColors {
  // 메인 색상 - 시침/분침 구분
  static const Color hourRed = Color(0xFFFF6B6B);      // 시침 & 시간 숫자 (빨강)
  static const Color minuteBlue = Color(0xFF2196F3);   // 분침 & 분 눈금 (진한 파랑)
  
  // 배경 색상
  static const Color bgCream = Color(0xFFFFF9E6);      // 메인 배경 (크림)
  static const Color bgPeach = Color(0xFFFFE5B4);      // 서브 배경 (복숭아)
  static const Color clockFace = Color(0xFFFFFAF0);    // 시계 페이스 (아이보리)
  
  // 액센트 색상
  static const Color accentPink = Color(0xFFFFB6C1);   // 분홍
  static const Color accentMint = Color(0xFFB4E7CE);   // 민트
  static const Color accentLavender = Color(0xFFE6E6FA); // 라벤더
  static const Color accentYellow = Color(0xFFFFF59D); // 노란색
  
  // UI 요소
  static const Color textDark = Color(0xFF5D4E37);     // 진한 갈색 (텍스트)
  static const Color textLight = Color(0xFF8B7355);    // 연한 갈색 (보조 텍스트)
  static const Color border = Color(0xFFE8D5C4);       // 테두리
  
  // 상태 색상
  static const Color success = Color(0xFF81C784);      // 정답
  static const Color error = Color(0xFFE57373);        // 오답
  static const Color warning = Color(0xFFFFD54F);      // 경고
  
  // 그라데이션
  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFB3E5FC),  // 하늘색
      Color(0xFFE1F5FE),  // 연한 하늘색
    ],
  );
  
  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF303F9F),  // 진한 파랑
      Color(0xFF5C6BC0),  // 보라빛 파랑
    ],
  );
}

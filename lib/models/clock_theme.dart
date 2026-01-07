import 'package:flutter/material.dart';

/// 시계 테마 데이터 모델
class ClockTheme {
  final String id;
  final String name;
  final Color hourHandColor;
  final Color minuteHandColor;
  final Color secondHandColor;
  final Color backgroundColor;
  final Gradient? backgroundGradient;
  final bool isPremium; // 프리미엄 테마 여부
  final int starCost; // 별 가격 (프리미엄 테마만)
  
  const ClockTheme({
    required this.id,
    required this.name,
    required this.hourHandColor,
    required this.minuteHandColor,
    required this.secondHandColor,
    required this.backgroundColor,
    this.backgroundGradient,
    this.isPremium = false,
    this.starCost = 0,
  });
  
  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hourHandColor': hourHandColor.value,
      'minuteHandColor': minuteHandColor.value,
      'secondHandColor': secondHandColor.value,
      'backgroundColor': backgroundColor.value,
    };
  }
  
  /// JSON에서 생성
  factory ClockTheme.fromJson(Map<String, dynamic> json) {
    final themeId = json['id'] as String;
    // ID로 미리 정의된 테마 찾기
    return ClockThemeList.all.firstWhere(
      (theme) => theme.id == themeId,
      orElse: () => ClockThemeList.basic,
    );
  }
}

/// 사용 가능한 모든 시계 테마 목록
class ClockThemeList {
  /// 기본 시계 (현재 디자인)
  static const basic = ClockTheme(
    id: 'basic_clock',
    name: '기본 시계',
    hourHandColor: Color(0xFF666666),
    minuteHandColor: Color(0xFF00BCD4),
    secondHandColor: Color(0xFFFF5252),
    backgroundColor: Colors.white,
  );
  
  /// 무지개 시계
  static const rainbow = ClockTheme(
    id: 'rainbow_clock',
    name: '무지개 시계',
    hourHandColor: Color(0xFF9C27B0),
    minuteHandColor: Color(0xFFFF6B6B),
    secondHandColor: Color(0xFFFFD93D),
    backgroundColor: Color(0xFFFFF8E1),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFFFE5E5),
        Color(0xFFFFF8E1),
        Color(0xFFE8F5E9),
        Color(0xFFE3F2FD),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
  
  /// 별빛 시계
  static const star = ClockTheme(
    id: 'star_clock',
    name: '별빛 시계',
    hourHandColor: Color(0xFFFFD700),
    minuteHandColor: Color(0xFFC0C0C0),
    secondHandColor: Color(0xFFFFEB3B),
    backgroundColor: Color(0xFF1A237E),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFF1A237E),
        Color(0xFF283593),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );
  
  /// 꽃 시계
  static const flower = ClockTheme(
    id: 'flower_clock',
    name: '꽃 시계',
    hourHandColor: Color(0xFF4CAF50),
    minuteHandColor: Color(0xFFE91E63),
    secondHandColor: Color(0xFFFF5252),
    backgroundColor: Color(0xFFFCE4EC),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFFCE4EC),
        Color(0xFFF8BBD0),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
  
  /// 그림 시계
  static const art = ClockTheme(
    id: 'art_clock',
    name: '그림 시계',
    hourHandColor: Color(0xFF2196F3),
    minuteHandColor: Color(0xFFF44336),
    secondHandColor: Color(0xFFFFEB3B),
    backgroundColor: Color(0xFFFAFAFA),
  );
  
  /// 음악 시계
  static const music = ClockTheme(
    id: 'music_clock',
    name: '음악 시계',
    hourHandColor: Color(0xFF9C27B0),
    minuteHandColor: Color(0xFF2196F3),
    secondHandColor: Color(0xFFE91E63),
    backgroundColor: Color(0xFF212121),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFF212121),
        Color(0xFF424242),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
  
  // ===== 프리미엄 테마 =====
  
  /// 골든 시계 (프리미엄)
  static const golden = ClockTheme(
    id: 'golden_clock',
    name: '골든 시계',
    hourHandColor: Color(0xFFFFD700),
    minuteHandColor: Color(0xFFFFA500),
    secondHandColor: Color(0xFFFFE55C),
    backgroundColor: Color(0xFF2C1810),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFF2C1810),
        Color(0xFF3E2723),
        Color(0xFF4E342E),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    isPremium: true,
    starCost: 30,
  );
  
  /// 달빛 시계 (프리미엄)
  static const moonlight = ClockTheme(
    id: 'moonlight_clock',
    name: '달빛 시계',
    hourHandColor: Color(0xFFC0C0C0),
    minuteHandColor: Color(0xFFE0E0E0),
    secondHandColor: Color(0xFFFFFFFF),
    backgroundColor: Color(0xFF0D1B2A),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFF0D1B2A),
        Color(0xFF1B263B),
        Color(0xFF415A77),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    isPremium: true,
    starCost: 20,
  );
  
  /// 크리스탈 시계 (프리미엄)
  static const crystal = ClockTheme(
    id: 'crystal_clock',
    name: '크리스탈 시계',
    hourHandColor: Color(0xFF00BCD4),
    minuteHandColor: Color(0xFF9C27B0),
    secondHandColor: Color(0xFFE91E63),
    backgroundColor: Color(0xFFF5F5F5),
    backgroundGradient: LinearGradient(
      colors: [
        Color(0xFFE3F2FD),
        Color(0xFFF3E5F5),
        Color(0xFFFCE4EC),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    isPremium: true,
    starCost: 25,
  );
  
  /// 서커스 시계 (프리미엄)
  static const circus = ClockTheme(
    id: 'circus_clock',
    name: '서커스 시계',
    hourHandColor: Colors.black,
    minuteHandColor: Color(0xFF4ECDC4),
    secondHandColor: Color(0xFFFFE66D),
    backgroundColor: Colors.white,
    backgroundGradient: null,
    isPremium: true,
    starCost: 15,
  );
  
  static const List<ClockTheme> all = [
    basic,
    rainbow,
    star,
    flower,
    art,
    music,
    // 프리미엄 테마
    golden,
    moonlight,
    crystal,
    circus,
  ];
  
  /// 무료 테마만 가져오기
  static List<ClockTheme> get freeThemes => all.where((t) => !t.isPremium).toList();
  
  /// 프리미엄 테마만 가져오기
  static List<ClockTheme> get premiumThemes => all.where((t) => t.isPremium).toList();
  
  /// ID로 테마 찾기
  static ClockTheme getThemeById(String id) {
    return all.firstWhere(
      (theme) => theme.id == id,
      orElse: () => basic,
    );
  }
}

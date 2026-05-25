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
  final String? backgroundImage; // 추가된 배경 이미지 경로 프로퍼티
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
    this.backgroundImage,
    this.isPremium = false,
    this.starCost = 0,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hourHandColor': hourHandColor.toARGB32(),
      'minuteHandColor': minuteHandColor.toARGB32(),
      'secondHandColor': secondHandColor.toARGB32(),
      'backgroundColor': backgroundColor.toARGB32(),
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
      colors: [Color(0xFF1A237E), Color(0xFF283593)],
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
      colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
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
      colors: [Color(0xFF212121), Color(0xFF424242)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ===== 프리미엄 테마 =====

  /// 골든 시계 (프리미엄)
  static const golden = ClockTheme(
    id: 'golden_clock',
    name: '골든 시계',
    hourHandColor: Color(0xFFD4AF37), // 메탈릭 골드
    minuteHandColor: Color(0xFFF3E5AB), // 밝은 금색
    secondHandColor: Color(0xFFFF0000), // 클래식 레드 초침
    backgroundColor: Color(0xFF1A1A1A),
    backgroundGradient: null,
    backgroundImage: 'assets/images/themes/golden_bg.jpg',
    isPremium: true,
    starCost: 200,
  );

  /// 달빛 시계 (프리미엄)
  static const moonlight = ClockTheme(
    id: 'moonlight_clock',
    name: '달빛 시계',
    hourHandColor: Color(0xFFB0BEC5), // 은은한 은색
    minuteHandColor: Color(0xFFECEFF1), // 밝은 은색
    secondHandColor: Color(0xFF64B5F6), // 신비로운 푸른빛
    backgroundColor: Color(0xFF0F172A), // 아주 깊은 밤하늘
    backgroundGradient: null,
    backgroundImage: 'assets/images/themes/moonlight_bg.jpg',
    isPremium: true,
    starCost: 200,
  );

  /// 크리스탈 시계 (프리미엄)
  static const crystal = ClockTheme(
    id: 'crystal_clock',
    name: '크리스탈 시계',
    hourHandColor: Color(0xFFE0F7FA), // 얼음색
    minuteHandColor: Colors.white,
    secondHandColor: Color(0xFFB39DDB), // 보라빛 반사광
    backgroundColor: Color(0xFFF3E5F5),
    backgroundGradient: null,
    backgroundImage: 'assets/images/themes/crystal_bg.jpg',
    isPremium: true,
    starCost: 200,
  );

  /// 서커스 시계 (프리미엄)
  static const circus = ClockTheme(
    id: 'circus_clock',
    name: '서커스 시계',
    hourHandColor: Colors.white,
    minuteHandColor: Color(0xFFFFD54F),
    secondHandColor: Color(0xFFFF5252),
    backgroundColor: Colors.black,
    backgroundGradient: null,
    backgroundImage: 'assets/images/themes/circus_bg.jpg',
    isPremium: true,
    starCost: 200,
  );

  /// 공주 시계 (프리미엄)
  static const princess = ClockTheme(
    id: 'princess_clock',
    name: '공주 시계',
    hourHandColor: Color(0xFFFF4081), // 핑크색 계열
    minuteHandColor: Color(0xFFFF80AB),
    secondHandColor: Color(0xFFF48FB1),
    backgroundColor: Colors.black,
    backgroundGradient: null,
    backgroundImage: 'assets/images/themes/princess_bg.jpg',
    isPremium: true,
    starCost: 200,
  );

  /// 경찰관 시계 (프리미엄)
  static const police = ClockTheme(
    id: 'police_clock',
    name: '경찰관 시계',
    hourHandColor: Color(0xFFD4AF37), // 뱃지 골드
    minuteHandColor: Color(0xFFE0E0E0), // 메탈 실버
    secondHandColor: Color(0xFFE53935), // 경찰 사이렌 레드
    backgroundColor: Colors.black,
    backgroundGradient: null,
    backgroundImage: 'assets/images/themes/police_bg.jpg',
    isPremium: true,
    starCost: 200,
  );

  /// 공룡 시계 (프리미엄)
  static const dinosaur = ClockTheme(
    id: 'dinosaur_clock',
    name: '공룡 시계',
    hourHandColor: Color(0xFF5D4037), // 나무 화석 갈색
    minuteHandColor: Color(0xFF8D6E63), // 뼈다귀 상아색
    secondHandColor: Color(0xFF388E3C), // 정글 잎사귀 녹색
    backgroundColor: Colors.black,
    backgroundGradient: null,
    backgroundImage: 'assets/images/themes/dinosaur_bg.jpg',
    isPremium: true,
    starCost: 200,
  );

  /// 우주선 시계 (프리미엄)
  static const spaceship = ClockTheme(
    id: 'spaceship_clock',
    name: '우주선 시계',
    hourHandColor: Color(0xFFBDBDBD), // 메탈 실버
    minuteHandColor: Color(0xFFE0E0E0), // 밝은 은색
    secondHandColor: Color(0xFFFF3D00), // 진한 불꽃 오렌지
    backgroundColor: Colors.black,
    backgroundGradient: null,
    backgroundImage: 'assets/images/themes/spaceship_bg.jpg',
    isPremium: true,
    starCost: 200,
  );

  /// 사탕 시계 (프리미엄)
  static const candy = ClockTheme(
    id: 'candy_clock',
    name: '사탕 시계',
    hourHandColor: Color(0xFF9C27B0), // 딥 퍼플
    minuteHandColor: Color(0xFFCE93D8), // 라이트 라일락
    secondHandColor: Color(0xFF00BCD4), // 팝핑 캔디 시안
    backgroundColor: Color(0xFFF3E5F5),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFFF8BBD0), Color(0xFFE1BEE7), Color(0xFFB2EBF2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundImage: 'assets/images/themes/candy_bg.jpg',
    isPremium: true,
    starCost: 200,
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
    princess,
    police,
    dinosaur,
    spaceship,
    candy,
  ];

  /// 무료 테마만 가져오기
  static List<ClockTheme> get freeThemes =>
      all.where((t) => !t.isPremium).toList();

  /// 프리미엄 테마만 가져오기
  static List<ClockTheme> get premiumThemes =>
      all.where((t) => t.isPremium).toList();

  /// ID로 테마 찾기
  static ClockTheme getThemeById(String id) {
    return all.firstWhere((theme) => theme.id == id, orElse: () => basic);
  }
}

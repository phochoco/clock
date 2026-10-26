import 'package:flutter/material.dart';

/// 시계 테두리 그림(assets/images/frames/<테마 ID>.webp) 안의 빈 시계판 자리
///
/// 시계판은 테두리 그림 아래에 그리고, 숫자와 바늘은 그 위에 그린다.
/// 값은 그림 크기에 대한 비율(0~1)이다.
class ClockFaceArt {
  const ClockFaceArt({
    required this.cx,
    required this.cy,
    required this.r,
    required this.faceColor,
    required this.dark,
  });

  /// 시계판 중심 (그림 너비·높이에 대한 비율)
  final double cx;
  final double cy;

  /// 시계판 반지름 (그림 너비에 대한 비율)
  final double r;

  /// 시계판 바탕색
  final Color faceColor;

  /// 어두운 시계판이면 숫자를 밝게 그린다
  final bool dark;

  /// 시계판 자리가 비어 있는 테두리 그림
  String assetFor(String themeId) => 'assets/images/frames/$themeId.webp';

  static ClockFaceArt? of(String? themeId) => byThemeId[themeId];

  static const Map<String, ClockFaceArt> byThemeId = {
    'basic_clock': ClockFaceArt(
      cx: 0.4996,
      cy: 0.4961,
      r: 0.3629,
      faceColor: Color(0xFFFCF1DC),
      dark: false,
    ),
    'rainbow_clock': ClockFaceArt(
      cx: 0.4999,
      cy: 0.5106,
      r: 0.2798,
      faceColor: Color(0xFFFCF1DB),
      dark: false,
    ),
    'star_clock': ClockFaceArt(
      cx: 0.4994,
      cy: 0.5389,
      r: 0.378,
      faceColor: Color(0xFF1C347B),
      dark: true,
    ),
    'flower_clock': ClockFaceArt(
      cx: 0.5001,
      cy: 0.5007,
      r: 0.3006,
      faceColor: Color(0xFFFDF2DE),
      dark: false,
    ),
    'art_clock': ClockFaceArt(
      cx: 0.4998,
      cy: 0.497,
      r: 0.3353,
      faceColor: Color(0xFFFCECD2),
      dark: false,
    ),
    'music_clock': ClockFaceArt(
      cx: 0.5001,
      cy: 0.5043,
      r: 0.3235,
      faceColor: Color(0xFFFCECD4),
      dark: false,
    ),
    'golden_clock': ClockFaceArt(
      cx: 0.4996,
      cy: 0.4972,
      r: 0.3272,
      faceColor: Color(0xFFFDF2DF),
      dark: false,
    ),
    'moonlight_clock': ClockFaceArt(
      cx: 0.5452,
      cy: 0.4921,
      r: 0.3336,
      faceColor: Color(0xFF41256E),
      dark: true,
    ),
    'crystal_clock': ClockFaceArt(
      cx: 0.4993,
      cy: 0.4937,
      r: 0.3292,
      faceColor: Color(0xFFDCE7FB),
      dark: false,
    ),
    'circus_clock': ClockFaceArt(
      cx: 0.4987,
      cy: 0.6168,
      r: 0.306,
      faceColor: Color(0xFFFCEBD1),
      dark: false,
    ),
    'princess_clock': ClockFaceArt(
      cx: 0.4996,
      cy: 0.5515,
      r: 0.3391,
      faceColor: Color(0xFFFCDFE1),
      dark: false,
    ),
    'police_clock': ClockFaceArt(
      cx: 0.4996,
      cy: 0.5444,
      r: 0.3499,
      faceColor: Color(0xFFFDF1DC),
      dark: false,
    ),
    'dinosaur_clock': ClockFaceArt(
      cx: 0.4647,
      cy: 0.6065,
      r: 0.29,
      faceColor: Color(0xFFFCEDD2),
      dark: false,
    ),
    'spaceship_clock': ClockFaceArt(
      cx: 0.4997,
      cy: 0.525,
      r: 0.2972,
      faceColor: Color(0xFFFCEDD3),
      dark: false,
    ),
    'candy_clock': ClockFaceArt(
      cx: 0.4986,
      cy: 0.4915,
      r: 0.3105,
      faceColor: Color(0xFFFCEDD5),
      dark: false,
    ),
  };
}

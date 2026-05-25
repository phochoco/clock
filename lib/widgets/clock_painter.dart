import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/clock_theme.dart';

/// 아날로그 시계 페인터
/// CustomPainter를 사용한 고성능 시계 렌더링
class ClockPainter extends CustomPainter {
  final double hourAngle;
  final double minuteAngle;
  final double secondAngle;
  final bool showGuideline;
  final bool showMinuteNumbers;
  final ClockTheme? theme;
  final double flickerValue; // 깜빡임 애니메이션 값 (0.3 ~ 1.0)
  final ui.Image? backgroundImage; // 추가: 실제 이미지 에셋

  ClockPainter({
    required this.hourAngle,
    required this.minuteAngle,
    required this.secondAngle,
    this.showGuideline = false,
    this.showMinuteNumbers = false,
    this.theme,
    this.flickerValue = 1.0, // 기본값
    this.backgroundImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // 이미지가 있으면 테두리 두께(8)를 제외하고 가득 채움, 없으면 기존처럼 0.85 비율
    final baseRadius = min(size.width, size.height) / 2;
    final radius = backgroundImage != null ? baseRadius - 8 : baseRadius * 0.85;

    // 1. 시계 배경
    _drawClockFace(canvas, center, radius);

    // 2. 테마별 장식 (배경 위에, 시계 요소 아래)
    // 이미지가 존재하면 무거운 캔버스 드로잉 대신 가벼운 파티클 이펙트만 그립니다.
    if (backgroundImage == null) {
      _drawThemeDecoration(canvas, center, radius);
    } else {
      _drawPremiumImageEffects(canvas, center, radius);
    }

    // 3. 가이드라인 (부채꼴 영역)
    if (showGuideline) {
      _drawGuideline(canvas, center, radius);
    }

    // 4. 시간 숫자 (1-12)
    // 커스텀 이미지여도 숫자는 그려줘야 함
    _drawHourNumbers(canvas, center, radius);

    // 5. 분 눈금
    _drawMinuteTicks(canvas, center, radius);

    // 6. 분 숫자 (선택적)
    if (showMinuteNumbers) {
      _drawMinuteNumbers(canvas, center, radius);
    }

    // 7. 시침
    _drawHourHand(canvas, center, radius);

    // 8. 분침
    _drawMinuteHand(canvas, center, radius);

    // 9. 초침
    _drawSecondHand(canvas, center, radius);

    // 10. 중심점
    _drawCenter(canvas, center);
  }

  /// 시계 배경 그리기
  void _drawClockFace(Canvas canvas, Offset center, double radius) {
    // 1. 공통 배경 (테마별 색상)
    Color bgColor;
    switch (theme?.id) {
      case 'star_clock':
      case 'moonlight_clock':
        bgColor = Color(0xFF1A1A2E); // 깊은 밤하늘
        break;
      case 'golden_clock':
        bgColor = Color(0xFF2C2C2C); // 어두운 차콜 (골드 대비)
        break;
      case 'flower_clock':
        bgColor = Color(0xFFF9FBE7); // 연한 라임/크림 배경
        break;
      case 'art_clock':
        bgColor = Color(0xFFFFF7E6); // 캔버스 종이 색상
        break;
      case 'crystal_clock':
        bgColor = Color(0xFFE0F7FA).withValues(alpha: 0.5); // 얼음/유리 느낌
        break;
      case 'music_clock':
        bgColor = Color(0xFF121212); // 바이닐 레코드판 블랙
        break;
      case 'rainbow_clock':
        bgColor = Color(0xFF22223B); // 무지개가 돋보이는 짙은 네이비
        break;
      case 'circus_clock':
        bgColor = Color(0xFFFFF3E0); // 따뜻한 연주황 텐트 배경
        break;
      case 'princess_clock':
        bgColor = Color(0xFFFCE4EC); // 파스텔 핑크
        break;
      case 'police_clock':
        bgColor = Color(0xFFE3F2FD); // 옅은 스카이블루
        break;
      case 'dinosaur_clock':
        bgColor = Color(0xFFE8F5E9); // 파스텔 그린
        break;
      case 'spaceship_clock':
        bgColor = Color(0xFF1C1C28); // 다크 네이비 우주색
        break;
      case 'candy_clock':
        bgColor = Color(0xFFFFF0F5); // 달콤한 연분홍
        break;
      default:
        bgColor = Colors.white; // 기본 화이트
        break;
    }

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;

    // 시계판 배경 칠하기
    if (backgroundImage != null) {
      // 이미지가 있으면 원형으로 클리핑하여 이미지를 그립니다.
      canvas.save();
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.clipPath(Path()..addOval(rect));

      // 이미지를 꽉 차게 그리기 위해 소스/목적지 영역 계산
      final src = Rect.fromLTWH(
        0,
        0,
        backgroundImage!.width.toDouble(),
        backgroundImage!.height.toDouble(),
      );
      final dst = rect;

      canvas.drawImageRect(backgroundImage!, src, dst, Paint());
      canvas.restore();
    } else {
      // 이미지가 없으면 기본 색상/그라디언트 칠하기
      if (theme?.backgroundGradient != null) {
        bgPaint.shader = theme!.backgroundGradient!.createShader(
          Rect.fromCircle(center: center, radius: radius),
        );
      }
      canvas.drawCircle(center, radius, bgPaint);

      // 2. 테마별 베젤(테두리) 디테일 (이미지 미사용 시에만 적용)
      if (theme?.id == 'crystal_clock') {
        final borderPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12;

        final highlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;

        canvas.drawCircle(center, radius, borderPaint);
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -pi,
          pi / 2,
          false,
          highlightPaint,
        );
      } else if (theme?.id == 'moonlight_clock' || theme?.id == 'star_clock') {
        final borderPaint = Paint()
          ..color = Colors.indigoAccent.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, 8);

        final innerBorder = Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(center, radius, borderPaint);
        canvas.drawCircle(center, radius - 4, innerBorder);
      } else if (theme?.id == 'golden_clock') {
        final borderPaint = Paint()
          ..color = Color(0xFFFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14;

        final innerShadow = Paint()
          ..color = Colors.black45
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawCircle(center, radius, borderPaint);
        canvas.drawCircle(center, radius - 7, innerShadow);
      } else if (theme?.id == 'music_clock') {
        for (double r = radius; r > radius * 0.3; r -= 10) {
          canvas.drawCircle(
            center,
            r,
            Paint()
              ..color = Colors.white10
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = Colors.grey[800]!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8,
        );
      } else if (theme?.id == 'basic_clock') {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = AppColors.borderLight
            ..style = PaintingStyle.stroke
            ..strokeWidth = 12,
        );
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color =
                theme?.hourHandColor.withValues(alpha: 0.2) ??
                Colors.blueAccent.withValues(alpha: 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      } else if (theme?.id == 'princess_clock') {
        final borderPaint = Paint()
          ..color = Color(0xFFF48FB1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6;
        canvas.drawCircle(center, radius, borderPaint);
      } else if (theme?.id == 'police_clock') {
        final badgePaint = Paint()
          ..color = Color(0xFF1565C0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14;
        canvas.drawCircle(center, radius, badgePaint);
      } else {
        final borderPaint = Paint()
          ..color = AppColors.borderLight
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10;
        canvas.drawCircle(center, radius, borderPaint);
      }
    }
  }

  /// 테마별 장식 그리기
  void _drawThemeDecoration(Canvas canvas, Offset center, double radius) {
    switch (theme?.id) {
      case 'star_clock':
        _drawStarPattern(canvas, center, radius);
        break;
      case 'rainbow_clock':
        _drawRainbowPattern(canvas, center, radius);
        break;
      case 'flower_clock':
        _drawFlowerPattern(canvas, center, radius);
        break;
      case 'art_clock':
        _drawArtPattern(canvas, center, radius);
        break;
      case 'music_clock':
        _drawMusicPattern(canvas, center, radius);
        break;
      // 프리미엄 테마
      case 'golden_clock':
        _drawGoldenPattern(canvas, center, radius);
        break;
      case 'moonlight_clock':
        _drawMoonlightPattern(canvas, center, radius);
        break;
      case 'crystal_clock':
        _drawCrystalPattern(canvas, center, radius);
        break;
      case 'circus_clock':
        _drawCircusPattern(canvas, center, radius);
        break;
      case 'princess_clock':
        _drawPrincessPattern(canvas, center, radius);
        break;
      case 'police_clock':
        _drawPolicePattern(canvas, center, radius);
        break;
      case 'dinosaur_clock':
        _drawDinosaurPattern(canvas, center, radius);
        break;
      case 'spaceship_clock':
        _drawSpaceshipPattern(canvas, center, radius);
        break;
      case 'candy_clock':
        _drawCandyPattern(canvas, center, radius);
        break;
      default:
        // 기본 시계는 장식 없음
        break;
    }
  }

  /// 별빛 시계: 별 패턴
  void _drawStarPattern(Canvas canvas, Offset center, double radius) {
    final random = Random(42); // 고정 시드로 일관된 패턴

    // 더 많은 별 (50개)
    for (int i = 0; i < 50; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * radius * 0.9;
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);

      final starSize = random.nextDouble() * 6 + 2; // 2-8 크기
      final opacity = random.nextDouble() * 0.4 + 0.5; // 0.5-0.9

      // 별 색상 (흰색 또는 노란색)
      final starColor = random.nextDouble() > 0.7
          ? Color(0xFFFFD700).withValues(alpha: opacity) // 금색
          : Colors.white.withValues(alpha: opacity);

      // 5각 별 그리기
      _drawStar(canvas, Offset(x, y), starSize, starColor);
    }
  }

  /// 5각 별 그리기
  void _drawStar(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final outerRadius = size;
    final innerRadius = size * 0.4;

    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * pi / 180;

      if (i == 0) {
        path.moveTo(
          center.dx + outerRadius * cos(outerAngle),
          center.dy + outerRadius * sin(outerAngle),
        );
      } else {
        path.lineTo(
          center.dx + outerRadius * cos(outerAngle),
          center.dy + outerRadius * sin(outerAngle),
        );
      }

      path.lineTo(
        center.dx + innerRadius * cos(innerAngle),
        center.dy + innerRadius * sin(innerAngle),
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  /// 무지개 시계: 무지개 아치
  void _drawRainbowPattern(Canvas canvas, Offset center, double radius) {
    final colors = [
      Color(0xFFFF0000), // 빨강
      Color(0xFFFF7F00), // 주황
      Color(0xFFFFFF00), // 노랑
      Color(0xFF00FF00), // 초록
      Color(0xFF0000FF), // 파랑
      Color(0xFF4B0082), // 남색
      Color(0xFF9400D3), // 보라
    ];

    // 무지개 아치 (더 크고 선명하게)
    for (int i = 0; i < colors.length; i++) {
      final arcRadius = radius * 0.25 + i * 5;
      final arcPaint = Paint()
        ..color = colors[i].withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;

      canvas.drawCircle(center, arcRadius, arcPaint);
    }

    // 작은 하트와 별 추가
    final random = Random(789);
    for (int i = 0; i < 8; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * radius * 0.7;
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);

      final heartPaint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      // 작은 하트
      canvas.drawCircle(Offset(x, y), 3, heartPaint);
    }
  }

  /// 꽃 시계: 꽃잎 패턴
  void _drawFlowerPattern(Canvas canvas, Offset center, double radius) {
    // 숫자 사이에 큰 꽃들 (12개, 15도씩 오프셋)
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 + 15 - 90) * pi / 180; // 15도 오프셋으로 숫자 사이에 배치
      final x = center.dx + radius * 0.8 * cos(angle);
      final y = center.dy + radius * 0.8 * sin(angle);

      _drawFlower(canvas, Offset(x, y), 7);
    }

    // 중심 근처에 작은 꽃들
    final random = Random(321);
    for (int i = 0; i < 12; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * radius * 0.5; // 중심 근처에만
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);

      _drawFlower(canvas, Offset(x, y), 4);
    }
  }

  /// 5개 꽃잎 꽃 그리기
  void _drawFlower(Canvas canvas, Offset center, double size) {
    // 5개 꽃잎 (중심 주변에 원형으로)
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * pi / 180;
      final x = center.dx + size * 0.5 * cos(angle);
      final y = center.dy + size * 0.5 * sin(angle);

      // 꽃잎 (원형)
      final petalPaint2 = Paint()
        ..color = Color(0xFFFFB6C1).withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), size * 0.6, petalPaint2);
    }

    // 꽃 중심 (노란색)
    final centerPaint = Paint()
      ..color = Color(0xFFFFD700).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size * 0.5, centerPaint);
  }

  /// 그림 시계: 붓터치 효과
  void _drawArtPattern(Canvas canvas, Offset center, double radius) {
    final random = Random(123);
    final colors = [
      Color(0xFF2196F3), // 파란색
      Color(0xFFF44336), // 빨간색
      Color(0xFFFFEB3B), // 노란색
      Color(0xFF4CAF50), // 초록색
      Color(0xFF9C27B0), // 보라색
      Color(0xFFFF9800), // 주황색
    ];

    // 큰 붓터치 (30개)
    for (int i = 0; i < 30; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * radius * 0.8;
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);

      final brushSize = random.nextDouble() * 25 + 15; // 15-40 크기
      final opacity = random.nextDouble() * 0.2 + 0.2; // 0.2-0.4

      final brushPaint = Paint()
        ..color = colors[random.nextInt(colors.length)].withValues(
          alpha: opacity,
        )
        ..style = PaintingStyle.fill;

      // 붓터치 (타원)
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * 2 * pi);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: brushSize,
          height: brushSize * 0.4,
        ),
        brushPaint,
      );
      canvas.restore();
    }

    // 물감 튀김 효과 (작은 원)
    for (int i = 0; i < 20; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * radius * 0.9;
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);

      final splatterSize = random.nextDouble() * 4 + 2;
      final splatterPaint = Paint()
        ..color = colors[random.nextInt(colors.length)].withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), splatterSize, splatterPaint);
    }
  }

  /// 음악 시계: 음표 패턴
  void _drawMusicPattern(Canvas canvas, Offset center, double radius) {
    final random = Random(456);

    // 오선지 (5줄)
    for (int i = 0; i < 5; i++) {
      final y = center.dy - radius * 0.4 + i * 15;
      final linePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = 1.5;

      canvas.drawLine(
        Offset(center.dx - radius * 0.7, y),
        Offset(center.dx + radius * 0.7, y),
        linePaint,
      );
    }

    // 큰 음표들 (30개)
    for (int i = 0; i < 30; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * radius * 0.85;
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);

      final noteSize = random.nextDouble() * 6 + 4; // 4-10 크기
      final opacity = random.nextDouble() * 0.3 + 0.3; // 0.3-0.6

      final notePaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // 음표 머리 (타원)
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-0.3);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: noteSize,
          height: noteSize * 0.7,
        ),
        notePaint,
      );
      canvas.restore();

      // 음표 줄기
      final stemPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..strokeWidth = 1.5;

      canvas.drawLine(
        Offset(x + noteSize * 0.4, y),
        Offset(x + noteSize * 0.4, y - noteSize * 2.5),
        stemPaint,
      );
    }

    // 작은 음표 기호 (♪, ♫)
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < 10; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * radius * 0.7;
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);

      textPainter.text = TextSpan(
        text: i % 2 == 0 ? '♪' : '♫',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 20,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  /// 가이드라인 (현재 시침이 가리키는 시간 구간)
  void _drawGuideline(Canvas canvas, Offset center, double radius) {
    // hourAngle을 직접 사용 (모듈로 연산 제거)
    // hourAngle이 계속 증가하더라도 그리기는 정상적으로 작동
    final startAngle = (hourAngle - 90) * pi / 180;
    final sweepAngle = 30 * pi / 180; // 1시간 = 30도

    final guidelinePaint = Paint()
      ..color = AppColors.hourRed.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius * 0.7),
        startAngle,
        sweepAngle,
        false,
      )
      ..close();

    canvas.drawPath(path, guidelinePaint);
  }

  /// 시간 숫자 그리기 (1-12)
  void _drawHourNumbers(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // 시간 숫자 (12개) - 테마의 시침 색상 사용
    Color numberColor = theme?.hourHandColor ?? AppColors.hourRed;

    // 테마별 커스텀 스타일링
    double fontSize = 24;
    FontWeight fontWeight = FontWeight.bold;
    List<Shadow>? shadows;

    if (theme?.id == 'star_clock') {
      numberColor = Color(0xFFFFD700); // 금색
      shadows = [
        Shadow(
          color: Color(0xFFFFD700).withValues(alpha: 0.8),
          blurRadius: 8 * flickerValue,
        ),
      ]; // 네온 효과
    } else if (theme?.id == 'music_clock') {
      numberColor = Colors.white;
      shadows = [Shadow(color: Colors.blueAccent, blurRadius: 4)];
    } else if (theme?.id == 'golden_clock') {
      numberColor = Color(0xFFFFD700);
      fontWeight = FontWeight.w900;
      shadows = [
        Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
        Shadow(color: Colors.white, offset: Offset(-1, -1), blurRadius: 1),
      ];
    } else if (theme?.id == 'crystal_clock') {
      numberColor = Colors.white;
      fontWeight = FontWeight.w300;
      fontSize = 28;
      shadows = [
        Shadow(
          color: Colors.purpleAccent.withValues(alpha: 0.5),
          blurRadius: 10 * flickerValue,
        ),
      ];
    } else if (theme?.id == 'princess_clock') {
      numberColor = Colors.white;
      fontWeight = FontWeight.w900;
      shadows = [
        Shadow(color: Color(0xFFD81B60), blurRadius: 4),
        Shadow(color: Colors.black54, offset: Offset(1, 1), blurRadius: 2),
      ];
    } else if (theme?.id == 'police_clock') {
      numberColor = Colors.white;
      fontWeight = FontWeight.w900;
      shadows = [
        Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 3),
        Shadow(color: Color(0xFF0D47A1), blurRadius: 8),
      ];
    } else if (theme?.id == 'dinosaur_clock') {
      numberColor = Color(0xFFFFF59D); // 연한 노란색 (뼈 느낌)
      fontWeight = FontWeight.w900;
      shadows = [
        Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 4),
      ];
    } else if (theme?.id == 'spaceship_clock') {
      numberColor = Colors.white;
      fontWeight = FontWeight.w800;
      shadows = [
        Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
        Shadow(color: Color(0xFF00E5FF), blurRadius: 8 * flickerValue),
      ];
    } else if (theme?.id == 'moonlight_clock') {
      numberColor = Color(0xFFECEFF1); // 밝은 은색
      fontWeight = FontWeight.w800;
      shadows = [
        Shadow(color: Colors.black87, offset: Offset(1, 1), blurRadius: 4),
        Shadow(color: Colors.blueAccent.withValues(alpha: 0.5), blurRadius: 6),
      ];
    } else if (theme?.id == 'circus_clock') {
      numberColor = Colors.white;
      fontWeight = FontWeight.w900;
      shadows = [
        Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 3),
      ];
    } else if (theme?.id == 'candy_clock') {
      numberColor = Colors.white;
      fontWeight = FontWeight.w900;
      shadows = [
        Shadow(color: Color(0xFFE91E63).withValues(alpha: 0.5), blurRadius: 6),
      ];
    }

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      final x = center.dx + radius * 0.75 * cos(angle);
      final y = center.dy + radius * 0.75 * sin(angle);

      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(
          color: numberColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
          shadows: shadows,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  /// 분 눈금 그리기
  void _drawMinuteTicks(Canvas canvas, Offset center, double radius) {
    for (int i = 0; i < 60; i++) {
      final angle = (i * 6 - 90) * pi / 180;
      final isHourMark = i % 5 == 0;

      final tickPaint = Paint()
        ..color = isHourMark
            ? AppColors.textDark
            : AppColors.minuteBlue.withValues(alpha: 0.5)
        ..strokeWidth = isHourMark ? 3 : 1.5
        ..strokeCap = StrokeCap.round;

      final startRadius = isHourMark ? radius * 0.88 : radius * 0.92;
      final endRadius = radius * 0.96;

      final start = Offset(
        center.dx + startRadius * cos(angle),
        center.dy + startRadius * sin(angle),
      );

      final end = Offset(
        center.dx + endRadius * cos(angle),
        center.dy + endRadius * sin(angle),
      );

      canvas.drawLine(start, end, tickPaint);
    }
  }

  /// 분 숫자 그리기 (0, 5, 10, 15, ...)
  void _drawMinuteNumbers(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < 12; i++) {
      final minute = i * 5;
      final angle = (i * 30 - 90) * pi / 180;
      final x = center.dx + radius * 0.6 * cos(angle);
      final y = center.dy + radius * 0.6 * sin(angle);

      textPainter.text = TextSpan(
        text: '$minute',
        style: TextStyle(
          color: AppColors.minuteBlue,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  /// 시침 그리기
  void _drawHourHand(Canvas canvas, Offset center, double radius) {
    // 12시(0도)에서 위쪽(-y)을 향해 그리므로 -90도 보정은 필요 없음
    final angle = hourAngle * pi / 180;
    final handLength = radius * 0.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    if (theme?.id == 'music_clock') {
      // 음악 테마: 마이크 모양 시침
      final paint = Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(-4, -handLength + 10)
        ..lineTo(4, -handLength + 10)
        ..lineTo(6, 10)
        ..lineTo(-6, 10)
        ..close();
      canvas.drawPath(path, paint);

      // 마이크 헤드
      canvas.drawCircle(
        Offset(0, -handLength),
        12,
        Paint()..color = theme!.hourHandColor,
      );
      canvas.drawCircle(
        Offset(0, -handLength),
        12,
        Paint()
          ..color = Colors.grey[800]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else if (theme?.id == 'crystal_clock') {
      // 크리스탈 테마: 다각 기둥 (Glassmorphism)
      final path = Path()
        ..moveTo(0, -handLength - 10)
        ..lineTo(8, -handLength * 0.2)
        ..lineTo(0, 15)
        ..lineTo(-8, -handLength * 0.2)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = theme!.hourHandColor.withValues(alpha: 0.7)
          ..style = PaintingStyle.fill,
      );

      // 입체감 (Highlight)
      final highlightPath = Path()
        ..moveTo(0, -handLength - 10)
        ..lineTo(0, 15)
        ..lineTo(-8, -handLength * 0.2)
        ..close();
      canvas.drawPath(
        highlightPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.fill,
      );
    } else if (theme?.id == 'golden_clock') {
      // 골든 테마: 고전적인 화살촉 시침
      final paint = Paint()
        ..color = theme!.hourHandColor
        ..style = PaintingStyle.fill
        ..strokeJoin = StrokeJoin.round;

      final path = Path()
        ..moveTo(0, -handLength - 5)
        ..lineTo(10, -handLength + 20)
        ..lineTo(4, -handLength + 20)
        ..lineTo(6, 15)
        ..lineTo(-6, 15)
        ..lineTo(-4, -handLength + 20)
        ..lineTo(-10, -handLength + 20)
        ..close();

      // Drop Shadow
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black38
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(path, paint);
    } else if (theme?.id == 'basic_clock') {
      final paint = Paint()
        ..color = theme!.hourHandColor
        ..strokeWidth =
            14 // 어린이를 위해 매우 두껍게
        ..strokeCap = StrokeCap.round;

      // 시침 테두리 (구분감 입히기)
      canvas.drawLine(
        Offset(0, 4),
        Offset(0, -handLength + 2),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(2, 2),
        Offset(2, -handLength + 2),
        Paint()
          ..color = Colors.black26
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawLine(Offset.zero, Offset(0, -handLength), paint);
    } else if (theme?.id == 'rainbow_clock') {
      final paint = Paint()
        ..color = theme!.hourHandColor.withValues(alpha: 0.9)
        ..strokeWidth =
            16 // 매우 굵게
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, 4);
      canvas.drawLine(Offset.zero, Offset(0, -handLength), paint);
    } else if (theme?.id == 'star_clock') {
      final path = Path()
        ..moveTo(-8, 0)
        ..lineTo(0, -handLength)
        ..lineTo(8, 0)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = theme!.hourHandColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, 3),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else if (theme?.id == 'flower_clock') {
      final path = Path()
        ..moveTo(0, 15)
        ..cubicTo(
          -25,
          -handLength * 0.3,
          -20,
          -handLength * 0.8,
          0,
          -handLength,
        )
        ..cubicTo(20, -handLength * 0.8, 25, -handLength * 0.3, 0, 15);
      canvas.drawPath(
        path,
        Paint()
          ..color = Color(0xFF66BB6A).withValues(alpha: 0.9)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.green[800]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawLine(
        Offset(0, 5),
        Offset(0, -handLength + 10),
        Paint()
          ..color = Colors.green[100]!.withValues(alpha: 0.6)
          ..strokeWidth = 1.5,
      );
    } else if (theme?.id == 'art_clock') {
      final paint = Paint()
        ..color = theme!.hourHandColor.withValues(alpha: 0.8)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset.zero, Offset(0, -handLength + 5), paint);
      canvas.drawCircle(
        Offset(0, -handLength),
        8,
        Paint()..color = theme!.hourHandColor.withValues(alpha: 0.6),
      );
    } else if (theme?.id == 'moonlight_clock') {
      final path = Path()
        ..moveTo(-8, 0)
        ..quadraticBezierTo(-12, -handLength * 0.5, 0, -handLength)
        ..quadraticBezierTo(12, -handLength * 0.5, 8, 0)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Color(0xFFC0C0C0)
          ..style = PaintingStyle.fill,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -handLength * 0.4),
          width: 4,
          height: handLength * 0.3,
        ),
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.fill,
      );
    } else if (theme?.id == 'circus_clock') {
      final paint = Paint()
        ..color = Colors.redAccent
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset.zero, Offset(0, -handLength), paint);
      for (double i = 10; i < handLength - 10; i += 20) {
        canvas.drawLine(
          Offset(-7, -i),
          Offset(7, -i),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 6,
        );
      }
    } else if (theme?.id == 'police_clock') {
      // 경찰관: 두껍고 단단한 네이비/골드 철퇴 모양
      final path = Path()
        ..moveTo(0, -handLength)
        ..lineTo(8, -handLength + 15)
        ..lineTo(5, 0)
        ..lineTo(-5, 0)
        ..lineTo(-8, -handLength + 15)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black45
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Color(0xFF152238)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Color(0xFFFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else if (theme?.id == 'dinosaur_clock') {
      // 공룡: 거친 뼈다귀 모양
      final path = Path()
        ..moveTo(0, 5)
        ..lineTo(6, -handLength * 0.3)
        ..quadraticBezierTo(10, -handLength * 0.5, 4, -handLength * 0.8)
        ..quadraticBezierTo(12, -handLength * 0.9, 0, -handLength)
        ..quadraticBezierTo(-12, -handLength * 0.9, -4, -handLength * 0.8)
        ..quadraticBezierTo(-10, -handLength * 0.5, -6, -handLength * 0.3)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black45
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Color(0xFFD7CCC8)
          ..style = PaintingStyle.fill,
      );
    } else if (theme?.id == 'spaceship_clock') {
      // 우주선: 로켓 바디 모양 (시침)
      final path = Path()
        ..moveTo(0, -handLength)
        ..lineTo(10, -handLength + 20)
        ..lineTo(8, 5)
        ..lineTo(-8, 5)
        ..lineTo(-10, -handLength + 20)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10),
      ); // 글로우
      canvas.drawPath(
        path,
        Paint()
          ..color = Color(0xFFECEFF1)
          ..style = PaintingStyle.fill,
      );
      canvas.drawLine(
        Offset(0, -handLength + 10),
        Offset(0, 0),
        Paint()
          ..color = Colors.redAccent
          ..strokeWidth = 2,
      );
    } else if (theme?.id == 'princess_clock') {
      // 공주: 레이스 화려한 요술봉
      final path = Path()
        ..moveTo(0, -handLength)
        ..quadraticBezierTo(15, -handLength * 0.5, 4, 0)
        ..lineTo(-4, 0)
        ..quadraticBezierTo(-15, -handLength * 0.5, 0, -handLength)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Color(0xFFF8BBD0)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      // 요술봉 끝 하트
      canvas.drawCircle(
        Offset(0, -handLength),
        6,
        Paint()..color = Color(0xFFE91E63),
      );
    } else {
      // 기본 시침 (둥근 막대)
      final paint = Paint()
        ..color = theme?.hourHandColor ?? AppColors.textDark
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;

      // Drop Shadow
      canvas.drawLine(
        Offset(2, 2),
        Offset(2, -handLength + 2),
        Paint()
          ..color = Colors.black26
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawLine(Offset.zero, Offset(0, -handLength), paint);
    }

    canvas.restore();
  }

  /// 분침 그리기
  void _drawMinuteHand(Canvas canvas, Offset center, double radius) {
    // 12시(0도)에서 위쪽(-y)을 향해 그리므로 -90도 보정은 필요 없음
    final angle = minuteAngle * pi / 180;
    final handLength = radius * 0.75;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    if (theme?.id == 'music_clock') {
      // 음악 테마: 일렉기타 넥 느낌
      final paint = Paint()
        ..color = theme!.minuteHandColor
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(-3, -handLength)
        ..lineTo(3, -handLength)
        ..lineTo(4, 15)
        ..lineTo(-4, 15)
        ..close();
      canvas.drawPath(path, paint);

      // 기타 줄 표현
      final stringPaint = Paint()
        ..color = Colors.white54
        ..strokeWidth = 1;
      canvas.drawLine(Offset(-1, -handLength), Offset(-1, 10), stringPaint);
      canvas.drawLine(Offset(1, -handLength), Offset(1, 10), stringPaint);
    } else if (theme?.id == 'crystal_clock') {
      // 크리스탈 테마: 얇고 긴 다각 기둥
      final path = Path()
        ..moveTo(0, -handLength - 15)
        ..lineTo(6, -handLength * 0.2)
        ..lineTo(0, 15)
        ..lineTo(-6, -handLength * 0.2)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = theme!.minuteHandColor.withValues(alpha: 0.7)
          ..style = PaintingStyle.fill,
      );

      final highlightPath = Path()
        ..moveTo(0, -handLength - 15)
        ..lineTo(0, 15)
        ..lineTo(-6, -handLength * 0.2)
        ..close();
      canvas.drawPath(
        highlightPath,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill,
      );
    } else if (theme?.id == 'golden_clock') {
      // 골든 테마: 긴 검 모양 분침
      final paint = Paint()
        ..color = theme!.minuteHandColor
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(0, -handLength - 10)
        ..lineTo(8, -handLength + 30)
        ..lineTo(4, 15)
        ..lineTo(-4, 15)
        ..lineTo(-8, -handLength + 30)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black38
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(path, paint);
    } else if (theme?.id == 'basic_clock') {
      // 분침은 시침보다 얇지만 길게
      final paint = Paint()
        ..color = theme!.minuteHandColor
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(0, 4),
        Offset(0, -handLength),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(2, 2),
        Offset(2, -handLength),
        Paint()
          ..color = Colors.black26
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawLine(Offset.zero, Offset(0, -handLength), paint);
    } else if (theme?.id == 'rainbow_clock') {
      final paint = Paint()
        ..color = theme!.minuteHandColor.withValues(alpha: 0.9)
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, 4);
      canvas.drawLine(Offset.zero, Offset(0, -handLength), paint);
    } else if (theme?.id == 'star_clock') {
      final path = Path()
        ..moveTo(-5, 0)
        ..lineTo(0, -handLength)
        ..lineTo(5, 0)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = theme!.minuteHandColor.withValues(alpha: 0.7)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, 3),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    } else if (theme?.id == 'flower_clock') {
      final path = Path()
        ..moveTo(0, 10)
        ..cubicTo(-12, -handLength * 0.2, -8, -handLength * 0.9, 0, -handLength)
        ..cubicTo(8, -handLength * 0.9, 12, -handLength * 0.2, 0, 10);
      canvas.drawPath(
        path,
        Paint()
          ..color = Color(0xFFF48FB1).withValues(alpha: 0.9)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.pink[800]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    } else if (theme?.id == 'art_clock') {
      canvas.drawLine(
        Offset.zero,
        Offset(0, -handLength),
        Paint()
          ..color = theme!.minuteHandColor.withValues(alpha: 0.8)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1),
      );
    } else if (theme?.id == 'moonlight_clock') {
      final path = Path()
        ..moveTo(-5, 0)
        ..lineTo(0, -handLength)
        ..lineTo(5, 0)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Color(0xFFE0E0E0)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(0, -handLength * 0.7),
        3,
        Paint()..color = Colors.indigo[900]!,
      );
    } else if (theme?.id == 'circus_clock') {
      final paint = Paint()
        ..color = Colors.blueAccent
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset.zero, Offset(0, -handLength), paint);
      for (double i = 10; i < handLength - 10; i += 20) {
        canvas.drawLine(
          Offset(-5, -i),
          Offset(5, -i),
          Paint()
            ..color = Colors.yellowAccent
            ..strokeWidth = 6,
        );
      }
    } else if (theme?.id == 'police_clock') {
      // 경찰관: 얇고 긴 메탈/블루 곤봉 모양 분침
      final path = Path()
        ..moveTo(0, -handLength - 5)
        ..lineTo(6, -handLength + 20)
        ..lineTo(3, 0)
        ..lineTo(-3, 0)
        ..lineTo(-6, -handLength + 20)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black45
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = theme!.minuteHandColor
          ..style = PaintingStyle.fill,
      );
      canvas.drawLine(
        Offset(0, -handLength + 20),
        Offset(0, 0),
        Paint()
          ..color = Color(0xFF1565C0)
          ..strokeWidth = 2,
      );
    } else if (theme?.id == 'dinosaur_clock') {
      // 공룡: 날카로운 이빨/초식공룡 꼬리 모양 분침
      final path = Path()
        ..moveTo(0, -handLength)
        ..quadraticBezierTo(8, -handLength * 0.5, 4, 0)
        ..lineTo(-4, 0)
        ..quadraticBezierTo(-8, -handLength * 0.5, 0, -handLength)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black45
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = theme!.minuteHandColor
          ..style = PaintingStyle.fill,
      );
    } else if (theme?.id == 'spaceship_clock') {
      // 우주선: 레이저빔/플라즈마 형태의 얇은 분침
      final path = Path()
        ..moveTo(0, -handLength - 10)
        ..lineTo(4, -handLength * 0.2)
        ..lineTo(0, 5)
        ..lineTo(-4, -handLength * 0.2)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = theme!.minuteHandColor.withValues(alpha: 0.9)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, 5),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
    } else if (theme?.id == 'princess_clock') {
      // 공주: 얇고 우아한 레이스 리본 바늘
      final path = Path()
        ..moveTo(0, -handLength)
        ..quadraticBezierTo(8, -handLength * 0.6, 2, 0)
        ..lineTo(-2, 0)
        ..quadraticBezierTo(-8, -handLength * 0.6, 0, -handLength)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = theme!.minuteHandColor
          ..style = PaintingStyle.fill,
      );
      // 중심에 작은 보석 장식
      for (double i = 0.2; i < 0.9; i += 0.3) {
        canvas.drawCircle(
          Offset(0, -handLength * i),
          2,
          Paint()..color = Colors.white,
        );
      }
    } else {
      // 기본 분침
      final paint = Paint()
        ..color = theme?.minuteHandColor ?? AppColors.minuteBlue
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(2, 2),
        Offset(2, -handLength + 2),
        Paint()
          ..color = Colors.black26
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawLine(Offset.zero, Offset(0, -handLength), paint);
    }

    canvas.restore();
  }

  /// 초침 그리기
  void _drawSecondHand(Canvas canvas, Offset center, double radius) {
    // 12시(0도)에서 위쪽(-y)을 향해 그리므로 -90도 보정은 필요 없음
    final angle = secondAngle * pi / 180;
    final handLength = radius * 0.85;
    final tailLength = radius * 0.2; // 초침 반대쪽 꼬리

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final color = theme?.secondHandColor ?? Color(0xFFFF5252);

    if (theme?.id == 'music_clock') {
      // 음악 테마: 지휘봉
      final paint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(0, tailLength), Offset(0, -handLength), paint);

      // 손잡이 부분
      canvas.drawLine(
        Offset(0, tailLength),
        Offset(0, tailLength - 20),
        Paint()
          ..color = color
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    } else if (theme?.id == 'star_clock') {
      // 별빛 테마: 끝에 빛나는 별이 달린 초침
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(0, tailLength),
        Offset(0, -handLength + 10),
        paint,
      );

      // 끝의 별
      canvas.save();
      canvas.translate(0, -handLength);
      // 자체 회전
      canvas.rotate(-angle + flickerValue * 2 * pi);
      _drawStar(canvas, Offset.zero, 6, color);
      canvas.restore();
    } else if (theme?.id == 'basic_clock') {
      canvas.drawLine(
        Offset(0, tailLength),
        Offset(0, -handLength),
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    } else if (theme?.id == 'rainbow_clock') {
      canvas.drawLine(
        Offset(0, tailLength),
        Offset(0, -handLength),
        Paint()
          ..color = color.withValues(alpha: 0.9)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, 3),
      );
    } else if (theme?.id == 'flower_clock') {
      canvas.drawLine(
        Offset(0, tailLength),
        Offset(0, -handLength + 10),
        Paint()
          ..color = Colors.lightGreen
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      _drawFlower(canvas, Offset(0, -handLength), 4);
    } else if (theme?.id == 'art_clock') {
      canvas.drawLine(
        Offset(0, tailLength),
        Offset(0, -handLength),
        Paint()
          ..color = color.withValues(alpha: 0.7)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.square,
      );
      canvas.drawCircle(
        Offset(0, -handLength),
        5,
        Paint()..color = color.withValues(alpha: 0.8),
      );
    } else if (theme?.id == 'golden_clock' || theme?.id == 'crystal_clock') {
      canvas.drawLine(
        Offset(0, tailLength),
        Offset(0, -handLength),
        Paint()
          ..color = color
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        Offset(0, -handLength + 20),
        5,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    } else if (theme?.id == 'moonlight_clock') {
      canvas.drawLine(
        Offset(0, tailLength),
        Offset(0, -handLength + 8),
        Paint()
          ..color = Colors.yellow[300]!
          ..strokeWidth = 1.5,
      );
      _drawStar(canvas, Offset(0, -handLength), 5, Colors.yellow[300]!);
    } else if (theme?.id == 'circus_clock') {
      canvas.drawLine(
        Offset(0, tailLength),
        Offset(0, -handLength + 10),
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
        Offset(0, -handLength),
        8,
        Paint()..color = Colors.pinkAccent,
      );
    } else if (theme?.id == 'police_clock') {
      // 경찰관: 사이렌 레드 얇은 초침 + 끝에 삐뽀삐뽀 경광등 느낌
      canvas.drawLine(
        Offset(0, tailLength),
        Offset(0, -handLength + 12),
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, -handLength + 5),
            width: 8,
            height: 12,
          ),
          Radius.circular(3),
        ),
        Paint()..color = Color(0xFFE53935),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, -handLength + 5),
            width: 8,
            height: 12,
          ),
          Radius.circular(3),
        ),
        Paint()
          ..color = Colors.blueAccent.withValues(alpha: 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, 3 * flickerValue),
      );
    } else if (theme?.id == 'dinosaur_clock') {
      // 공룡: 풀잎 모양 또는 작은 화석뼈
      canvas.drawLine(
        Offset(0, tailLength),
        Offset(0, -handLength + 8),
        Paint()
          ..color = color
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.square,
      );
      // 끝부분 작은 잎사귀
      final path = Path()
        ..moveTo(0, -handLength - 5)
        ..quadraticBezierTo(5, -handLength + 5, 0, -handLength + 15)
        ..quadraticBezierTo(-5, -handLength + 5, 0, -handLength - 5)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    } else if (theme?.id == 'spaceship_clock') {
      // 우주선: 불꽃 오렌지 레이저
      canvas.drawLine(
        Offset(0, tailLength),
        Offset(0, -handLength),
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, 2),
      );
      // 뒤쪽 추진체 불꽃 연출
      canvas.drawCircle(
        Offset(0, tailLength),
        3,
        Paint()
          ..color = Colors.yellowAccent
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, 4 * flickerValue),
      );
    } else if (theme?.id == 'princess_clock') {
      // 공주: 얇은 핑크 선과 별모양 또는 작은 크리스탈 끝
      canvas.drawLine(
        Offset(0, tailLength),
        Offset(0, -handLength + 8),
        Paint()
          ..color = color
          ..strokeWidth = 1.5,
      );
      _drawStar(canvas, Offset(0, -handLength), 4, color);
    } else {
      // 기본 초침 (꼬리 포함, Drop Shadow)
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(1, tailLength + 1),
        Offset(1, -handLength + 1),
        Paint()
          ..color = Colors.black26
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1),
      );
      canvas.drawLine(Offset(0, tailLength), Offset(0, -handLength), paint);

      // 초침 중심 액센트 원
      canvas.drawCircle(Offset.zero, 3, Paint()..color = color);
    }

    canvas.restore();
  }

  void _drawCenter(Canvas canvas, Offset center) {
    if (theme?.id == 'moonlight_clock') {
      canvas.drawCircle(
        center,
        14,
        Paint()
          ..color = Colors.yellow[100]!.withValues(alpha: 0.5)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(center, 10, Paint()..color = Colors.yellow[100]!);
      canvas.drawCircle(center, 8, Paint()..color = Colors.white);
      return;
    } else if (theme?.id == 'golden_clock') {
      canvas.drawCircle(center, 12, Paint()..color = Color(0xFFB8860B));
      canvas.drawCircle(center, 8, Paint()..color = Color(0xFFFFD700));
      canvas.drawLine(
        Offset(center.dx - 6, center.dy),
        Offset(center.dx + 6, center.dy),
        Paint()
          ..color = Colors.black54
          ..strokeWidth = 2,
      );
      return;
    } else if (theme?.id == 'flower_clock') {
      canvas.drawCircle(center, 14, Paint()..color = Color(0xFFFBC02D));
      canvas.drawCircle(center, 6, Paint()..color = Color(0xFFFFF59D));
      return;
    } else if (theme?.id == 'crystal_clock') {
      final path = Path()
        ..moveTo(center.dx, center.dy - 12)
        ..lineTo(center.dx + 12, center.dy)
        ..lineTo(center.dx, center.dy + 12)
        ..lineTo(center.dx - 12, center.dy)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
      return;
    } else if (theme?.id == 'rainbow_clock') {
      canvas.drawCircle(
        center,
        12,
        Paint()
          ..color = Colors.white
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, 4),
      );
      canvas.drawCircle(center, 8, Paint()..color = Colors.black);
      return;
    } else if (theme?.id == 'art_clock') {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 24, height: 18),
        Paint()..color = Colors.brown[700]!,
      );
      return;
    }

    final centerPaint = Paint()
      ..color = AppColors.textDark
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 10, centerPaint);

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 4, innerPaint);
  }

  // ===== 프리미엄 테마 패턴 =====

  /// 골든 시계: 금색 반짝임
  void _drawGoldenPattern(Canvas canvas, Offset center, double radius) {
    final random = Random(777);

    // 금색 반짝임 다이아몬드 (50개) - 깜빡임 적용
    for (int i = 0; i < 50; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * radius * 0.85;
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);

      final sparkleSize = random.nextDouble() * 5 + 2;

      // 각 다이아몬드마다 다른 깜빡임 오프셋
      final flickerOffset = (i % 3) * 0.2;
      final adjustedFlicker = ((flickerValue + flickerOffset) % 1.0).clamp(
        0.3,
        1.0,
      );

      final sparklePaint = Paint()
        ..color = Color(
          0xFFFFD700,
        ).withValues(alpha: (random.nextDouble() * 0.5 + 0.3) * adjustedFlicker)
        ..style = PaintingStyle.fill;

      // 다이아몬드 모양 반짝임
      final path = Path();
      path.moveTo(x, y - sparkleSize);
      path.lineTo(x + sparkleSize * 0.5, y);
      path.lineTo(x, y + sparkleSize);
      path.lineTo(x - sparkleSize * 0.5, y);
      path.close();

      canvas.drawPath(path, sparklePaint);
    }
  }

  /// 달빛 시계: 은색 별과 달
  void _drawMoonlightPattern(Canvas canvas, Offset center, double radius) {
    final random = Random(888);

    // 큰 달 (오른쪽 상단)
    final moonX = center.dx + radius * 0.6;
    final moonY = center.dy - radius * 0.6;

    final moonPaint = Paint()
      ..color = Color(0xFFE0E0E0).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(moonX, moonY), 25, moonPaint);

    // 달 크레이터
    final craterPaint = Paint()
      ..color = Color(0xFFC0C0C0).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(moonX - 5, moonY - 3), 4, craterPaint);
    canvas.drawCircle(Offset(moonX + 7, moonY + 5), 3, craterPaint);

    // 은색 별들 (60개로 증가) - 깜빡임 효과
    for (int i = 0; i < 60; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * radius * 0.85;
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);

      final starSize = random.nextDouble() * 4 + 2; // 크기 증가 (1-4 -> 2-6)

      // 각 별마다 다른 깜빡임 오프셋 (더 자연스러운 효과)
      final flickerOffset = (i % 3) * 0.2;
      final adjustedFlicker = ((flickerValue + flickerOffset) % 1.0).clamp(
        0.3,
        1.0,
      );

      _drawStar(
        canvas,
        Offset(x, y),
        starSize,
        Color(0xFFFFD700).withValues(
          alpha: (random.nextDouble() * 0.3 + 0.4) * adjustedFlicker,
        ), // 노란색 별
      );
    }
  }

  /// 크리스탈 시계: 프리즘 효과
  void _drawCrystalPattern(Canvas canvas, Offset center, double radius) {
    final random = Random(999);
    final colors = [
      Color(0xFF00BCD4),
      Color(0xFF9C27B0),
      Color(0xFFE91E63),
      Color(0xFF4CAF50),
    ];

    // 크리스탈 조각들 (40개) - 깜빡임 적용
    for (int i = 0; i < 40; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final distance = random.nextDouble() * radius * 0.8;
      final x = center.dx + distance * cos(angle);
      final y = center.dy + distance * sin(angle);

      final size = random.nextDouble() * 10 + 5;
      final rotation = random.nextDouble() * 2 * pi;

      // 각 크리스탈마다 다른 깜빡임 오프셋
      final flickerOffset = (i % 4) * 0.25;
      final adjustedFlicker = ((flickerValue + flickerOffset) % 1.0).clamp(
        0.4,
        1.0,
      );

      final crystalPaint = Paint()
        ..color = colors[random.nextInt(colors.length)].withValues(
          alpha: 0.4 * adjustedFlicker,
        )
        ..style = PaintingStyle.fill;

      // 삼각형 크리스탈
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final path = Path();
      path.moveTo(0, -size);
      path.lineTo(size * 0.866, size * 0.5);
      path.lineTo(-size * 0.866, size * 0.5);
      path.close();

      canvas.drawPath(path, crystalPaint);
      canvas.restore();
    }
  }

  /// 서커스 시계: 다양한 모양의 풍선들과 회전목마
  void _drawCircusPattern(Canvas canvas, Offset center, double radius) {
    // 1. 풍선들 (13개) - 무지개 7개 + 하트 3개 + 별 2개 + 강아지 1개
    final random = Random(777);
    final balloonColors = [
      Color(0xFFFF6B6B), // 빨강
      Color(0xFFFF7F00), // 주황
      Color(0xFFFFFF00), // 노랑
      Color(0xFF00FF00), // 초록
      Color(0xFF0000FF), // 파랑
      Color(0xFF4B0082), // 남색
      Color(0xFF9400D3), // 보라
    ];

    final usedPositions = <Offset>[];

    // 무지개 풍선 7개
    for (int i = 0; i < 7; i++) {
      Offset position;
      bool tooClose;
      int attempts = 0;

      do {
        final angle = random.nextDouble() * 2 * pi;
        final distance = radius * (0.15 + random.nextDouble() * 0.35);
        position = Offset(
          center.dx + distance * cos(angle),
          center.dy + distance * sin(angle),
        );

        tooClose = usedPositions.any(
          (p) =>
              (p.dx - position.dx).abs() < 20 &&
              (p.dy - position.dy).abs() < 20,
        );

        attempts++;
      } while (tooClose && attempts < 30);

      usedPositions.add(position);

      final balloonSize = 8.0 + random.nextDouble() * 8.0;
      final floatOffset = sin(flickerValue * 2 * pi + i * 0.5) * 5;
      final adjustedPosition = Offset(position.dx, position.dy + floatOffset);

      _drawRoundBalloon(
        canvas,
        adjustedPosition,
        balloonSize,
        balloonColors[i],
      );
    }

    // 하트 풍선 3개
    for (int i = 0; i < 3; i++) {
      Offset position;
      bool tooClose;
      int attempts = 0;

      do {
        final angle = random.nextDouble() * 2 * pi;
        final distance = radius * (0.15 + random.nextDouble() * 0.35);
        position = Offset(
          center.dx + distance * cos(angle),
          center.dy + distance * sin(angle),
        );

        tooClose = usedPositions.any(
          (p) =>
              (p.dx - position.dx).abs() < 20 &&
              (p.dy - position.dy).abs() < 20,
        );

        attempts++;
      } while (tooClose && attempts < 30);

      usedPositions.add(position);

      final balloonSize = 10.0 + random.nextDouble() * 6.0;
      final floatOffset = sin(flickerValue * 2 * pi + (i + 7) * 0.5) * 5;
      final adjustedPosition = Offset(position.dx, position.dy + floatOffset);

      _drawHeartBalloon(
        canvas,
        adjustedPosition,
        balloonSize,
        Color(0xFFFF69B4),
      );
    }

    // 별 풍선 2개
    for (int i = 0; i < 2; i++) {
      Offset position;
      bool tooClose;
      int attempts = 0;

      do {
        final angle = random.nextDouble() * 2 * pi;
        final distance = radius * (0.15 + random.nextDouble() * 0.35);
        position = Offset(
          center.dx + distance * cos(angle),
          center.dy + distance * sin(angle),
        );

        tooClose = usedPositions.any(
          (p) =>
              (p.dx - position.dx).abs() < 20 &&
              (p.dy - position.dy).abs() < 20,
        );

        attempts++;
      } while (tooClose && attempts < 30);

      usedPositions.add(position);

      final balloonSize = 10.0 + random.nextDouble() * 6.0;
      final floatOffset = sin(flickerValue * 2 * pi + (i + 10) * 0.5) * 5;
      final adjustedPosition = Offset(position.dx, position.dy + floatOffset);

      _drawStarBalloon(
        canvas,
        adjustedPosition,
        balloonSize,
        Color(0xFFFFD700),
      );
    }

    // 강아지 풍선 1개
    Offset position;
    bool tooClose;
    int attempts = 0;

    do {
      final angle = random.nextDouble() * 2 * pi;
      final distance = radius * (0.15 + random.nextDouble() * 0.35);
      position = Offset(
        center.dx + distance * cos(angle),
        center.dy + distance * sin(angle),
      );

      tooClose = usedPositions.any(
        (p) =>
            (p.dx - position.dx).abs() < 25 && (p.dy - position.dy).abs() < 25,
      );

      attempts++;
    } while (tooClose && attempts < 30);

    final balloonSize = 14.0;
    final floatOffset = sin(flickerValue * 2 * pi + 12 * 0.5) * 5;
    final adjustedPosition = Offset(position.dx, position.dy + floatOffset);

    _drawDogBalloon(canvas, adjustedPosition, balloonSize, Color(0xFFFFAA66));

    // 2. 회전목마 (하단, 더 작게)
    final carouselY = center.dy + radius * 0.55;
    final carouselRadius = radius * 0.15;

    // 회전목마 지붕 (삼각형)
    final roofPaint = Paint()
      ..color = Color(0xFFFF6B6B).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final roofPath = Path();
    roofPath.moveTo(center.dx, carouselY - carouselRadius * 1.8);
    roofPath.lineTo(
      center.dx - carouselRadius * 1.5,
      carouselY - carouselRadius * 0.2,
    );
    roofPath.lineTo(
      center.dx + carouselRadius * 1.5,
      carouselY - carouselRadius * 0.2,
    );
    roofPath.close();

    canvas.drawPath(roofPath, roofPaint);

    // 지붕 테두리
    final roofBorderPaint = Paint()
      ..color = Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(roofPath, roofBorderPaint);

    // 지붕 꼭대기 별
    _drawStar(
      canvas,
      Offset(center.dx, carouselY - carouselRadius * 2.0),
      5,
      Color(0xFFFFD700),
    );

    // 회전목마 플랫폼
    final platformPaint = Paint()
      ..color = Color(0xFFFFD700).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, carouselY),
        width: carouselRadius * 3,
        height: carouselRadius * 0.6,
      ),
      platformPaint,
    );

    // 회전목마 말들 (4마리) - 회전 애니메이션
    final horseColors = [
      Color(0xFFFF6B6B), // 빨강
      Color(0xFF4D96FF), // 파랑
      Color(0xFFFFD93D), // 노랑
      Color(0xFFB565D8), // 보라
    ];

    for (int i = 0; i < 4; i++) {
      // flickerValue를 회전 각도로 사용
      final rotationAngle = flickerValue * 2 * pi;
      final angle = (i / 4) * 2 * pi + rotationAngle;

      final horseX = center.dx + carouselRadius * 1.2 * cos(angle);
      final horseY =
          carouselY -
          carouselRadius * 0.3 +
          carouselRadius * 1.2 * sin(angle) * 0.2;

      // 원근감 (뒤쪽 말은 작게)
      final depth = sin(angle);
      final scale = 0.6 + 0.4 * ((depth + 1) / 2);
      final horseSize = 8.0 * scale;

      // 뒤쪽 말 먼저 그리기
      if (depth < 0) {
        _drawHorse(
          canvas,
          Offset(horseX, horseY),
          horseSize,
          horseColors[i],
          carouselY,
          rotationAngle + i,
        );
      }
    }

    // 앞쪽 말 나중에 그리기 (겹침 효과)
    for (int i = 0; i < 4; i++) {
      final rotationAngle = flickerValue * 2 * pi;
      final angle = (i / 4) * 2 * pi + rotationAngle;

      final horseX = center.dx + carouselRadius * 1.2 * cos(angle);
      final horseY =
          carouselY -
          carouselRadius * 0.3 +
          carouselRadius * 1.2 * sin(angle) * 0.2;

      final depth = sin(angle);
      final scale = 0.6 + 0.4 * ((depth + 1) / 2);
      final horseSize = 8.0 * scale;

      if (depth >= 0) {
        _drawHorse(
          canvas,
          Offset(horseX, horseY),
          horseSize,
          horseColors[i],
          carouselY,
          rotationAngle + i,
        );
      }
    }
  }

  // 회전목마 말 그리기 헬퍼 함수
  void _drawHorse(
    Canvas canvas,
    Offset position,
    double size,
    Color color,
    double carouselY,
    double bobAngle,
  ) {
    final horsePaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    // 위아래 움직임
    final bobOffset = sin(bobAngle * 2) * 3;
    final adjustedY = position.dy + bobOffset;

    // 말 몸통 (둥근 사각형)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(position.dx, adjustedY),
        width: size * 1.2,
        height: size * 1.0,
      ),
      Radius.circular(size * 0.3),
    );
    canvas.drawRRect(bodyRect, horsePaint);

    // 말 머리 (원)
    canvas.drawCircle(
      Offset(position.dx + size * 0.5, adjustedY - size * 0.3),
      size * 0.4,
      horsePaint,
    );

    // 귀 (2개 작은 삼각형)
    final earPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    // 왼쪽 귀
    final leftEarPath = Path();
    leftEarPath.moveTo(position.dx + size * 0.35, adjustedY - size * 0.6);
    leftEarPath.lineTo(position.dx + size * 0.25, adjustedY - size * 0.8);
    leftEarPath.lineTo(position.dx + size * 0.4, adjustedY - size * 0.65);
    leftEarPath.close();
    canvas.drawPath(leftEarPath, earPaint);

    // 오른쪽 귀
    final rightEarPath = Path();
    rightEarPath.moveTo(position.dx + size * 0.55, adjustedY - size * 0.6);
    rightEarPath.lineTo(position.dx + size * 0.65, adjustedY - size * 0.8);
    rightEarPath.lineTo(position.dx + size * 0.5, adjustedY - size * 0.65);
    rightEarPath.close();
    canvas.drawPath(rightEarPath, earPaint);

    // 눈 (작은 점)
    final eyePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(position.dx + size * 0.6, adjustedY - size * 0.35),
      size * 0.08,
      eyePaint,
    );

    // 다리 (4개 - 짧은 선)
    final legPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = size * 0.2
      ..strokeCap = StrokeCap.round;

    // 앞다리 2개
    canvas.drawLine(
      Offset(position.dx + size * 0.2, adjustedY + size * 0.4),
      Offset(position.dx + size * 0.2, adjustedY + size * 0.9),
      legPaint,
    );
    canvas.drawLine(
      Offset(position.dx + size * 0.4, adjustedY + size * 0.4),
      Offset(position.dx + size * 0.4, adjustedY + size * 0.9),
      legPaint,
    );

    // 뒷다리 2개
    canvas.drawLine(
      Offset(position.dx - size * 0.2, adjustedY + size * 0.4),
      Offset(position.dx - size * 0.2, adjustedY + size * 0.9),
      legPaint,
    );
    canvas.drawLine(
      Offset(position.dx - size * 0.4, adjustedY + size * 0.4),
      Offset(position.dx - size * 0.4, adjustedY + size * 0.9),
      legPaint,
    );

    // 꼬리 (간단한 곡선)
    final tailPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = size * 0.15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final tailPath = Path();
    tailPath.moveTo(position.dx - size * 0.6, adjustedY);
    tailPath.quadraticBezierTo(
      position.dx - size * 0.8,
      adjustedY - size * 0.2,
      position.dx - size * 0.7,
      adjustedY + size * 0.3,
    );
    canvas.drawPath(tailPath, tailPaint);

    // 막대 (금색)
    final polePaint = Paint()
      ..color = Color(0xFFFFD700).withValues(alpha: 0.7)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(position.dx, carouselY - size * 2.5),
      Offset(position.dx, adjustedY - size * 0.3),
      polePaint,
    );
  }

  // 둥근 풍선 그리기
  void _drawRoundBalloon(
    Canvas canvas,
    Offset position,
    double size,
    Color color,
  ) {
    final balloonPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(center: position, width: size, height: size * 1.3),
      balloonPaint,
    );

    // 하이라이트
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(position.dx - size * 0.15, position.dy - size * 0.2),
        width: size * 0.3,
        height: size * 0.4,
      ),
      highlightPaint,
    );

    // 줄
    final stringPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(position.dx, position.dy + size * 0.65),
      Offset(position.dx, position.dy + size * 0.65 + 10),
      stringPaint,
    );
  }

  // 하트 풍선 그리기
  void _drawHeartBalloon(
    Canvas canvas,
    Offset position,
    double size,
    Color color,
  ) {
    final heartPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(position.dx, position.dy + size * 0.3);
    path.cubicTo(
      position.dx - size * 0.6,
      position.dy - size * 0.2,
      position.dx - size * 0.6,
      position.dy - size * 0.7,
      position.dx,
      position.dy - size * 0.4,
    );
    path.cubicTo(
      position.dx + size * 0.6,
      position.dy - size * 0.7,
      position.dx + size * 0.6,
      position.dy - size * 0.2,
      position.dx,
      position.dy + size * 0.3,
    );

    canvas.drawPath(path, heartPaint);

    // 줄
    final stringPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(position.dx, position.dy + size * 0.4),
      Offset(position.dx, position.dy + size * 0.4 + 10),
      stringPaint,
    );
  }

  // 별 풍선 그리기
  void _drawStarBalloon(
    Canvas canvas,
    Offset position,
    double size,
    Color color,
  ) {
    _drawStar(canvas, position, size, color.withValues(alpha: 0.85));

    // 줄
    final stringPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(position.dx, position.dy + size),
      Offset(position.dx, position.dy + size + 10),
      stringPaint,
    );
  }

  // 강아지 풍선 그리기
  void _drawDogBalloon(
    Canvas canvas,
    Offset position,
    double size,
    Color color,
  ) {
    final dogPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // 얼굴 (원)
    canvas.drawCircle(position, size * 0.6, dogPaint);

    // 귀 2개 (타원)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(position.dx - size * 0.5, position.dy - size * 0.4),
        width: size * 0.4,
        height: size * 0.7,
      ),
      dogPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(position.dx + size * 0.5, position.dy - size * 0.4),
        width: size * 0.4,
        height: size * 0.7,
      ),
      dogPaint,
    );

    // 코 (작은 원)
    final nosePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(position.dx, position.dy + size * 0.1),
      size * 0.15,
      nosePaint,
    );

    // 눈 2개
    canvas.drawCircle(
      Offset(position.dx - size * 0.25, position.dy - size * 0.1),
      size * 0.1,
      nosePaint,
    );
    canvas.drawCircle(
      Offset(position.dx + size * 0.25, position.dy - size * 0.1),
      size * 0.1,
      nosePaint,
    );

    // 줄
    final stringPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(position.dx, position.dy + size * 0.7),
      Offset(position.dx, position.dy + size * 0.7 + 10),
      stringPaint,
    );
  }

  /// 공주 시계 (Princess) 장식: 핑크 파스텔 티아라 렌더링 및 반짝이는 스파클 파티클
  void _drawPrincessPattern(Canvas canvas, Offset center, double radius) {
    // 1. 티아라 베젤 장식
    final tiaraPaint = Paint()
      ..color =
          Color(0xFFFF80AB) // 핑크 메인
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 4);

    final tiaraPath = Path();
    // 상단 12시 방향 왕관
    tiaraPath.moveTo(center.dx - 30, center.dy - radius - 10);
    tiaraPath.lineTo(center.dx - 15, center.dy - radius + 5);
    tiaraPath.lineTo(center.dx, center.dy - radius - 20); // 중앙 뿔
    tiaraPath.lineTo(center.dx + 15, center.dy - radius + 5);
    tiaraPath.lineTo(center.dx + 30, center.dy - radius - 10);
    canvas.drawPath(tiaraPath, tiaraPaint);

    final gemPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.solid, 4 * flickerValue);

    // 중앙 다이아몬드 보석을 Path로 그립니다.
    void drawDiamondShape(
      Canvas c,
      double x,
      double y,
      double width,
      double height,
      Paint p,
    ) {
      final path = Path()
        ..moveTo(x, y - height / 2)
        ..lineTo(x + width / 2, y)
        ..lineTo(x, y + height / 2)
        ..lineTo(x - width / 2, y)
        ..close();
      c.drawPath(path, p);
    }

    drawDiamondShape(
      canvas,
      center.dx,
      center.dy - radius - 25,
      24,
      24,
      Paint()
        ..color = Color(0xFFF06292)
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, 8 * flickerValue),
    );
    drawDiamondShape(
      canvas,
      center.dx,
      center.dy - radius - 25,
      12,
      12,
      gemPaint,
    );

    // 2. 블링블링 보석 흩뿌리기 (배경 파티클)
    final random = Random(42);
    for (int i = 0; i < 20; i++) {
      final r = random.nextDouble() * radius * 0.85;
      final theta = random.nextDouble() * 2 * pi;
      final x = center.dx + r * cos(theta);
      final y = center.dy + r * sin(theta);

      // 반짝임 강도 계산
      final size = 2 + random.nextDouble() * 3;
      final alpha = (0.3 + 0.7 * sin(flickerValue * pi * 4 + i)).clamp(
        0.1,
        1.0,
      );

      final starPaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), size, starPaint);
      // 빛 갈라짐 십자가 모양
      canvas.drawLine(
        Offset(x - size * 2, y),
        Offset(x + size * 2, y),
        starPaint..strokeWidth = 1,
      );
      canvas.drawLine(
        Offset(x, y - size * 2),
        Offset(x, y + size * 2),
        starPaint..strokeWidth = 1,
      );
    }
  }

  /// 경찰관 시계 (Police) 장식: 경찰차 경광등 및 뱃지 방패 베젤
  void _drawPolicePattern(Canvas canvas, Offset center, double radius) {
    // 1. 방패 (Badge) 다각형 장식 라인 (배경 위에 그리기)
    final badgeOutline = Path();
    badgeOutline.moveTo(center.dx, center.dy - radius + 10);
    badgeOutline.lineTo(center.dx + radius * 0.7, center.dy - radius * 0.5);
    badgeOutline.lineTo(center.dx + radius * 0.6, center.dy + radius * 0.6);
    badgeOutline.lineTo(center.dx, center.dy + radius - 10);
    badgeOutline.lineTo(center.dx - radius * 0.6, center.dy + radius * 0.6);
    badgeOutline.lineTo(center.dx - radius * 0.7, center.dy - radius * 0.5);
    badgeOutline.close();

    canvas.drawPath(
      badgeOutline,
      Paint()
        ..color = Color(0xFFFFD54F).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // 2. 좌우 경찰차 사이렌 (경광등 점멸)
    // 플리커 값(0.3~1.0)에 따라 좌파랑, 우빨강 점멸 토글링
    bool isRedTurn = sin(flickerValue * pi * 8) > 0;

    // 왼쪽 파란불
    final blueLight = Paint()
      ..color = Color(0xFF1E88E5).withValues(alpha: isRedTurn ? 0.2 : 0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isRedTurn ? 4 : 20);

    // 오른쪽 빨간불
    final redLight = Paint()
      ..color = Color(0xFFE53935).withValues(alpha: isRedTurn ? 0.8 : 0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isRedTurn ? 20 : 4);

    // 빛샘 효과
    canvas.drawCircle(
      Offset(center.dx - radius + 20, center.dy - radius * 0.5),
      25,
      blueLight,
    );
    canvas.drawCircle(
      Offset(center.dx + radius - 20, center.dy - radius * 0.5),
      25,
      redLight,
    );
  }

  /// 공룡 시계 (Dinosaur) 장식: 발자국 패턴 및 뼈다귀 모양 디테일 (추후 바늘에 적용, 여기서는 잎사귀 배경)
  void _drawDinosaurPattern(Canvas canvas, Offset center, double radius) {
    // 쥐라기 잎사귀 패턴 (간단한 타원 조합)
    final leafPaint = Paint()
      ..color = Color(0xFF81C784).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 + 45) * pi / 180;
      final x = center.dx + radius * 0.6 * cos(angle);
      final y = center.dy + radius * 0.6 * sin(angle);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 40, height: 15),
        leafPaint,
      );
      canvas.restore();
    }
  }

  /// 우주선 시계 (Spaceship) 장식: 은하수 배경과 로켓 부스터 효과
  void _drawSpaceshipPattern(Canvas canvas, Offset center, double radius) {
    // 은하수 파티클
    final random = Random(101);
    for (int i = 0; i < 30; i++) {
      final r = random.nextDouble() * radius;
      final theta = random.nextDouble() * 2 * pi;
      final x = center.dx + r * cos(theta);
      final y = center.dy + r * sin(theta);

      final alpha = (0.2 + 0.8 * random.nextDouble() * flickerValue).clamp(
        0.1,
        1.0,
      );
      canvas.drawCircle(
        Offset(x, y),
        1.5 + random.nextDouble() * 2,
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: alpha)
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, 2),
      );
    }

    // 외곽 레이더 그리드
    canvas.drawCircle(
      center,
      radius * 0.85,
      Paint()
        ..color = Color(0xFF00E5FF).withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  /// 사탕 시계 (Candy) 장식: 소용돌이 페퍼민트 무늬와 젤리 파티클
  void _drawCandyPattern(Canvas canvas, Offset center, double radius) {
    // 테두리에 동그란 알사탕 장식
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * pi / 180;
      final x = center.dx + radius * 0.95 * cos(angle);
      final y = center.dy + radius * 0.95 * sin(angle);

      Color candyColor = i % 3 == 0
          ? Colors.pinkAccent
          : (i % 3 == 1 ? Colors.cyanAccent : Colors.yellowAccent);

      final p = Paint()
        ..color = candyColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 8, p);

      // 알사탕 빤짝이 하이라이트
      canvas.drawArc(
        Rect.fromCircle(center: Offset(x - 2, y - 2), radius: 4),
        pi,
        pi / 2,
        false,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  /// 원본 배경 이미지가 있는 프리미엄 테마 위에 겹칠 동적인 라이트/파티클 효과
  void _drawPremiumImageEffects(Canvas canvas, Offset center, double radius) {
    if (theme?.id == 'golden_clock') {
      _drawGoldenPattern(canvas, center, radius); // 골드는 기존 패턴(반짝이) 그대로 사용
    } else if (theme?.id == 'moonlight_clock') {
      // 은은한 별빛과 반딧불이 효과
      final random = Random(42);
      for (int i = 0; i < 20; i++) {
        final angle = random.nextDouble() * 2 * pi;
        final distance = random.nextDouble() * radius * 0.9;
        final x = center.dx + distance * cos(angle);
        final y = center.dy + distance * sin(angle);

        // 깜빡임 효과 부드럽게
        final alpha = (sin(flickerValue * 2 * pi + i) * 0.5 + 0.5) * 0.8;
        canvas.drawCircle(
          Offset(x, y),
          random.nextDouble() * 2 + 1,
          Paint()
            ..color = Colors.white.withValues(alpha: alpha.clamp(0.1, 1.0))
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    } else if (theme?.id == 'crystal_clock') {
      // 기존 크리스탈 패턴이 두꺼운 선을 그리므로 얇게 반짝이만
      final random = Random(123);
      for (int i = 0; i < 15; i++) {
        final angle = random.nextDouble() * 2 * pi;
        final distance = random.nextDouble() * radius * 0.8;
        final x = center.dx + distance * cos(angle);
        final y = center.dy + distance * sin(angle);

        final alpha = (sin(flickerValue * pi + i * 0.5) * 0.5 + 0.5) * 0.8;
        _drawStar(
          canvas,
          Offset(x, y),
          4,
          Colors.cyanAccent.withValues(alpha: alpha.clamp(0.1, 1.0)),
        );
      }
    } else if (theme?.id == 'circus_clock') {
      // 화려한 금빛 종이조각(컨페티) 흩날림
      final random = Random(99);
      for (int i = 0; i < 25; i++) {
        final angle = random.nextDouble() * 2 * pi;
        final distance = random.nextDouble() * radius * 0.85;
        // 위아래로 살짝 떨어지는 효과
        final drop = (flickerValue * 20 + i * 5) % 40 - 20;
        final x = center.dx + distance * cos(angle);
        final y = center.dy + distance * sin(angle) + drop;

        final colors = [Colors.amber, Colors.pinkAccent, Colors.cyanAccent];
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(flickerValue * pi * 2 + i); // 회전 이펙트
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: 3, height: 6),
          Paint()
            ..color = colors[i % 3]
            ..style = PaintingStyle.fill,
        );
        canvas.restore();
      }
    } else if (theme?.id == 'princess_clock') {
      // 핑크빛 반짝임과 작은 별들
      final random = Random(1004);
      for (int i = 0; i < 20; i++) {
        final angle = random.nextDouble() * 2 * pi;
        final distance =
            radius * 0.2 + random.nextDouble() * radius * 0.7; // 중앙은 비워둠
        final x = center.dx + distance * cos(angle);
        final y = center.dy + distance * sin(angle);

        final alpha = (sin(flickerValue * pi * 1.5 + i) * 0.5 + 0.5).clamp(
          0.2,
          0.9,
        );
        _drawStar(
          canvas,
          Offset(x, y),
          6,
          Color(0xFFF48FB1).withValues(alpha: alpha),
        );
      }
    } else if (theme?.id == 'police_clock') {
      // 가장자리 경광등 효과 (은은한 빨강/파랑 빛 바운딩)
      final rect = Rect.fromCircle(center: center, radius: radius);
      final redPaint = Paint()
        ..color = Colors.red.withValues(alpha: 0.15 * flickerValue)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20);
      final bluePaint = Paint()
        ..color = Colors.blue.withValues(alpha: 0.15 * (1.0 - flickerValue))
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20);

      canvas.drawArc(rect, -pi / 2, pi, true, redPaint);
      canvas.drawArc(rect, pi / 2, pi, true, bluePaint);
    } else if (theme?.id == 'dinosaur_clock') {
      // 정글의 흩날리는 나뭇잎/포자
      final random = Random(88);
      for (int i = 0; i < 15; i++) {
        final angle = random.nextDouble() * 2 * pi;
        final distance = random.nextDouble() * radius * 0.9;
        final x =
            center.dx +
            distance * cos(angle) +
            sin(flickerValue * pi * 2 + i) * 5;
        final y =
            center.dy +
            distance * sin(angle) +
            cos(flickerValue * pi * 2 + i) * 5;

        canvas.drawCircle(
          Offset(x, y),
          random.nextDouble() * 2 + 1.5,
          Paint()..color = Colors.lightGreenAccent.withValues(alpha: 0.6),
        );
      }
    } else if (theme?.id == 'spaceship_clock') {
      // 기존 은하수 재활용하면서 추가 레이저/먼지 효과
      _drawSpaceshipPattern(canvas, center, radius);
    }
  }

  @override
  bool shouldRepaint(ClockPainter oldDelegate) {
    return hourAngle != oldDelegate.hourAngle ||
        minuteAngle != oldDelegate.minuteAngle ||
        secondAngle != oldDelegate.secondAngle ||
        showGuideline != oldDelegate.showGuideline ||
        showMinuteNumbers != oldDelegate.showMinuteNumbers ||
        theme != oldDelegate.theme ||
        flickerValue != oldDelegate.flickerValue ||
        backgroundImage != oldDelegate.backgroundImage;
  }
}

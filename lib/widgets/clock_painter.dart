import 'dart:math';
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
  
  ClockPainter({
    required this.hourAngle,
    required this.minuteAngle,
    required this.secondAngle,
    this.showGuideline = false,
    this.showMinuteNumbers = false,
    this.theme,
    this.flickerValue = 1.0, // 기본값
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.85;
    
    // 1. 시계 배경
    _drawClockFace(canvas, center, radius);
    
    // 2. 테마별 장식 (배경 위에, 시계 요소 아래)
    _drawThemeDecoration(canvas, center, radius);
    
    // 3. 가이드라인 (부채꼴 영역)
    if (showGuideline) {
      _drawGuideline(canvas, center, radius);
    }
    
    // 4. 시간 숫자 (1-12)
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
    // 외곽 테두리
    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, borderPaint);
    
    // 시계 페이스는 AnalogClock 위젯의 Container에서 그려짐
    // 여기서는 추가 배경을 그리지 않음
  }
  
  /// 테마별 장식 그리기
  void _drawThemeDecoration(Canvas canvas, Offset center, double radius) {
    print('Drawing theme decoration for: ${theme?.id}');
    
    switch (theme?.id) {
      case 'star_clock':
        print('Drawing star pattern!');
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
      default:
        // 기본 시계는 장식 없음
        print('No decoration for basic clock');
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
          ? Color(0xFFFFD700).withOpacity(opacity) // 금색
          : Colors.white.withOpacity(opacity);
      
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
        ..color = colors[i].withOpacity(0.4)
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
        ..color = colors[i % colors.length].withOpacity(0.3)
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
    final petalPaint = Paint()
      ..color = Color(0xFFFFB6C1).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    // 5개 꽃잎 (중심 주변에 원형으로)
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * pi / 180;
      final x = center.dx + size * 0.5 * cos(angle);
      final y = center.dy + size * 0.5 * sin(angle);
      
      // 꽃잎 (원형)
      final petalPaint2 = Paint()
        ..color = Color(0xFFFFB6C1).withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(x, y), size * 0.6, petalPaint2);
    }
    
    // 꽃 중심 (노란색)
    final centerPaint = Paint()
      ..color = Color(0xFFFFD700).withOpacity(0.9)
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
        ..color = colors[random.nextInt(colors.length)].withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      // 붓터치 (타원)
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * 2 * pi);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: brushSize, height: brushSize * 0.4),
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
        ..color = colors[random.nextInt(colors.length)].withOpacity(0.4)
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
        ..color = Colors.white.withOpacity(0.15)
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
        ..color = Colors.white.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      // 음표 머리 (타원)
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-0.3);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: noteSize, height: noteSize * 0.7),
        notePaint,
      );
      canvas.restore();
      
      // 음표 줄기
      final stemPaint = Paint()
        ..color = Colors.white.withOpacity(opacity)
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
          color: Colors.white.withOpacity(0.4),
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
      ..color = AppColors.hourRed.withOpacity(0.1)
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
    if (theme?.id == 'star_clock') {
      numberColor = Color(0xFFFFD700); // 금색
    } else if (theme?.id == 'music_clock') {
      numberColor = Colors.white;
    }
    
    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      final x = center.dx + radius * 0.75 * cos(angle);
      final y = center.dy + radius * 0.75 * sin(angle);
      
      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(
          color: numberColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
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
        ..color = isHourMark ? AppColors.textDark : AppColors.minuteBlue.withOpacity(0.5)
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
    final angle = (hourAngle - 90) * pi / 180;
    final handLength = radius * 0.5;
    
    final paint = Paint()
      ..color = theme?.hourHandColor ?? AppColors.textDark
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    final handEnd = Offset(
      center.dx + handLength * cos(angle),
      center.dy + handLength * sin(angle),
    );
    
    canvas.drawLine(center, handEnd, paint);
  }
  
  /// 분침 그리기
  void _drawMinuteHand(Canvas canvas, Offset center, double radius) {
    final angle = (minuteAngle - 90) * pi / 180;
    final handLength = radius * 0.75;
    
    final paint = Paint()
      ..color = theme?.minuteHandColor ?? AppColors.minuteBlue
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    
    final handEnd = Offset(
      center.dx + handLength * cos(angle),
      center.dy + handLength * sin(angle),
    );
    
    canvas.drawLine(center, handEnd, paint);
  }
  
  /// 초침 그리기
  void _drawSecondHand(Canvas canvas, Offset center, double radius) {
    final angle = (secondAngle - 90) * pi / 180;
    final handLength = radius * 0.85;
    
    final paint = Paint()
      ..color = theme?.secondHandColor ?? Color(0xFFFF5252)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    
    final handEnd = Offset(
      center.dx + handLength * cos(angle),
      center.dy + handLength * sin(angle),
    );
    
    canvas.drawLine(center, handEnd, paint);
  }
  
  /// 중심점 그리기
  void _drawCenter(Canvas canvas, Offset center) {
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
      final adjustedFlicker = ((flickerValue + flickerOffset) % 1.0).clamp(0.3, 1.0);
      
      final sparklePaint = Paint()
        ..color = Color(0xFFFFD700).withOpacity((random.nextDouble() * 0.5 + 0.3) * adjustedFlicker)
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
      ..color = Color(0xFFE0E0E0).withOpacity(0.4)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(moonX, moonY), 25, moonPaint);
    
    // 달 크레이터
    final craterPaint = Paint()
      ..color = Color(0xFFC0C0C0).withOpacity(0.3)
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
      final adjustedFlicker = ((flickerValue + flickerOffset) % 1.0).clamp(0.3, 1.0);
      
      _drawStar(
        canvas,
        Offset(x, y),
        starSize,
        Color(0xFFFFD700).withOpacity((random.nextDouble() * 0.3 + 0.4) * adjustedFlicker), // 노란색 별
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
      final adjustedFlicker = ((flickerValue + flickerOffset) % 1.0).clamp(0.4, 1.0);
      
      final crystalPaint = Paint()
        ..color = colors[random.nextInt(colors.length)].withOpacity(0.4 * adjustedFlicker)
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
        
        tooClose = usedPositions.any((p) => 
          (p.dx - position.dx).abs() < 20 && (p.dy - position.dy).abs() < 20
        );
        
        attempts++;
      } while (tooClose && attempts < 30);
      
      usedPositions.add(position);
      
      final balloonSize = 8.0 + random.nextDouble() * 8.0;
      final floatOffset = sin(flickerValue * 2 * pi + i * 0.5) * 5;
      final adjustedPosition = Offset(position.dx, position.dy + floatOffset);
      
      _drawRoundBalloon(canvas, adjustedPosition, balloonSize, balloonColors[i]);
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
        
        tooClose = usedPositions.any((p) => 
          (p.dx - position.dx).abs() < 20 && (p.dy - position.dy).abs() < 20
        );
        
        attempts++;
      } while (tooClose && attempts < 30);
      
      usedPositions.add(position);
      
      final balloonSize = 10.0 + random.nextDouble() * 6.0;
      final floatOffset = sin(flickerValue * 2 * pi + (i + 7) * 0.5) * 5;
      final adjustedPosition = Offset(position.dx, position.dy + floatOffset);
      
      _drawHeartBalloon(canvas, adjustedPosition, balloonSize, Color(0xFFFF69B4));
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
        
        tooClose = usedPositions.any((p) => 
          (p.dx - position.dx).abs() < 20 && (p.dy - position.dy).abs() < 20
        );
        
        attempts++;
      } while (tooClose && attempts < 30);
      
      usedPositions.add(position);
      
      final balloonSize = 10.0 + random.nextDouble() * 6.0;
      final floatOffset = sin(flickerValue * 2 * pi + (i + 10) * 0.5) * 5;
      final adjustedPosition = Offset(position.dx, position.dy + floatOffset);
      
      _drawStarBalloon(canvas, adjustedPosition, balloonSize, Color(0xFFFFD700));
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
      
      tooClose = usedPositions.any((p) => 
        (p.dx - position.dx).abs() < 25 && (p.dy - position.dy).abs() < 25
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
      ..color = Color(0xFFFF6B6B).withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    final roofPath = Path();
    roofPath.moveTo(center.dx, carouselY - carouselRadius * 1.8);
    roofPath.lineTo(center.dx - carouselRadius * 1.5, carouselY - carouselRadius * 0.2);
    roofPath.lineTo(center.dx + carouselRadius * 1.5, carouselY - carouselRadius * 0.2);
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
      ..color = Color(0xFFFFD700).withOpacity(0.9)
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
      final horseY = carouselY - carouselRadius * 0.3 + carouselRadius * 1.2 * sin(angle) * 0.2;
      
      // 원근감 (뒤쪽 말은 작게)
      final depth = sin(angle);
      final scale = 0.6 + 0.4 * ((depth + 1) / 2);
      final horseSize = 8.0 * scale;
      
      // 뒤쪽 말 먼저 그리기
      if (depth < 0) {
        _drawHorse(canvas, Offset(horseX, horseY), horseSize, horseColors[i], carouselY, rotationAngle + i);
      }
    }
    
    // 앞쪽 말 나중에 그리기 (겹침 효과)
    for (int i = 0; i < 4; i++) {
      final rotationAngle = flickerValue * 2 * pi;
      final angle = (i / 4) * 2 * pi + rotationAngle;
      
      final horseX = center.dx + carouselRadius * 1.2 * cos(angle);
      final horseY = carouselY - carouselRadius * 0.3 + carouselRadius * 1.2 * sin(angle) * 0.2;
      
      final depth = sin(angle);
      final scale = 0.6 + 0.4 * ((depth + 1) / 2);
      final horseSize = 8.0 * scale;
      
      if (depth >= 0) {
        _drawHorse(canvas, Offset(horseX, horseY), horseSize, horseColors[i], carouselY, rotationAngle + i);
      }
    }
  }
  
  // 회전목마 말 그리기 헬퍼 함수
  void _drawHorse(Canvas canvas, Offset position, double size, Color color, double carouselY, double bobAngle) {
    final horsePaint = Paint()
      ..color = color.withOpacity(0.9)
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
      ..color = color.withOpacity(0.9)
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
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(position.dx + size * 0.6, adjustedY - size * 0.35),
      size * 0.08,
      eyePaint,
    );
    
    // 다리 (4개 - 짧은 선)
    final legPaint = Paint()
      ..color = color.withOpacity(0.9)
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
      ..color = color.withOpacity(0.7)
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
      ..color = Color(0xFFFFD700).withOpacity(0.7)
      ..strokeWidth = 1.5;
    
    canvas.drawLine(
      Offset(position.dx, carouselY - size * 2.5),
      Offset(position.dx, adjustedY - size * 0.3),
      polePaint,
    );
  }
  
  // 둥근 풍선 그리기
  void _drawRoundBalloon(Canvas canvas, Offset position, double size, Color color) {
    final balloonPaint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    
    canvas.drawOval(
      Rect.fromCenter(center: position, width: size, height: size * 1.3),
      balloonPaint,
    );
    
    // 하이라이트
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
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
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(position.dx, position.dy + size * 0.65),
      Offset(position.dx, position.dy + size * 0.65 + 10),
      stringPaint,
    );
  }
  
  // 하트 풍선 그리기
  void _drawHeartBalloon(Canvas canvas, Offset position, double size, Color color) {
    final heartPaint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(position.dx, position.dy + size * 0.3);
    path.cubicTo(
      position.dx - size * 0.6, position.dy - size * 0.2,
      position.dx - size * 0.6, position.dy - size * 0.7,
      position.dx, position.dy - size * 0.4,
    );
    path.cubicTo(
      position.dx + size * 0.6, position.dy - size * 0.7,
      position.dx + size * 0.6, position.dy - size * 0.2,
      position.dx, position.dy + size * 0.3,
    );
    
    canvas.drawPath(path, heartPaint);
    
    // 줄
    final stringPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(position.dx, position.dy + size * 0.4),
      Offset(position.dx, position.dy + size * 0.4 + 10),
      stringPaint,
    );
  }
  
  // 별 풍선 그리기
  void _drawStarBalloon(Canvas canvas, Offset position, double size, Color color) {
    _drawStar(canvas, position, size, color.withOpacity(0.85));
    
    // 줄
    final stringPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(position.dx, position.dy + size),
      Offset(position.dx, position.dy + size + 10),
      stringPaint,
    );
  }
  
  // 강아지 풍선 그리기
  void _drawDogBalloon(Canvas canvas, Offset position, double size, Color color) {
    final dogPaint = Paint()
      ..color = color.withOpacity(0.85)
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
      ..color = Colors.black.withOpacity(0.7)
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
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1;
    
    canvas.drawLine(
      Offset(position.dx, position.dy + size * 0.7),
      Offset(position.dx, position.dy + size * 0.7 + 10),
      stringPaint,
    );
  }
  
  @override
  bool shouldRepaint(ClockPainter oldDelegate) {
    return hourAngle != oldDelegate.hourAngle ||
           minuteAngle != oldDelegate.minuteAngle ||
           secondAngle != oldDelegate.secondAngle ||
           showGuideline != oldDelegate.showGuideline ||
           showMinuteNumbers != oldDelegate.showMinuteNumbers ||
           theme != oldDelegate.theme;
  }
}

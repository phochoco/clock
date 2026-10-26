import 'dart:math';
import 'package:flutter/material.dart';
import '../models/clock_face_art.dart';
import '../utils/colors.dart';

/// 시계 테두리 일러스트와 함께 쓰는 시계판·바늘 페인터
///
/// 그리는 순서: [ClockLayer.face] 시계판 → (테두리 그림) → [ClockLayer.dial] 눈금·숫자·바늘.
/// 시계판은 테두리 안쪽 가장자리 밑으로 살짝 들어가게 그려서 경계가 깔끔하다.
/// 시침은 빨강, 분침은 파랑으로 모든 시계에서 같다.
enum ClockLayer { face, dial }

class IllustratedClockPainter extends CustomPainter {
  IllustratedClockPainter({
    required this.layer,
    required this.art,
    required this.faceRadius,
    this.hourAngle = 0,
    this.minuteAngle = 0,
    this.secondAngle = 0,
    this.showGuideline = false,
    this.showMinuteNumbers = false,
  });

  final ClockLayer layer;
  final ClockFaceArt art;
  final double faceRadius;
  final double hourAngle;
  final double minuteAngle;
  final double secondAngle;
  final bool showGuideline;
  final bool showMinuteNumbers;

  static const _hourColor = Color(0xFFFF5A5F);
  static const _minuteColor = Color(0xFF2F9BFF);

  Color get _ink => art.dark ? Color(0xFFFFF3D6) : Color(0xFF4A2E17);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = faceRadius;

    if (layer == ClockLayer.face) {
      _drawFace(canvas, center, r);
      return;
    }

    if (showGuideline) _drawGuideline(canvas, center, r);
    _drawTicks(canvas, center, r);
    _drawHourNumbers(canvas, center, r);
    if (showMinuteNumbers) _drawMinuteNumbers(canvas, center, r);
    _drawHand(
      canvas,
      center,
      angle: hourAngle,
      length: r * 0.5,
      width: r * 0.13,
      color: _hourColor,
    );
    _drawHand(
      canvas,
      center,
      angle: minuteAngle,
      length: r * 0.78,
      width: r * 0.095,
      color: _minuteColor,
    );
    _drawSecondHand(canvas, center, r);
    _drawCenterCap(canvas, center, r);
  }

  void _drawFace(Canvas canvas, Offset center, double r) {
    final base = art.faceColor;
    final edge = Color.lerp(base, Colors.black, art.dark ? 0.25 : 0.07)!;
    final glow = Color.lerp(base, Colors.white, art.dark ? 0.08 : 0.45)!;
    // 테두리 그림 안쪽 가장자리 밑으로 들어가도록 조금 크게
    final rect = Rect.fromCircle(center: center, radius: r * 1.06);
    canvas.drawCircle(
      center,
      r * 1.06,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(-0.25, -0.35),
          radius: 0.95,
          colors: [glow, base, edge],
          stops: [0, 0.6, 1],
        ).createShader(rect),
    );
  }

  void _drawGuideline(Canvas canvas, Offset center, double r) {
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: r * 0.86),
        (hourAngle - 90) * pi / 180,
        30 * pi / 180,
        false,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = _hourColor.withValues(alpha: 0.14));
  }

  void _drawTicks(Canvas canvas, Offset center, double r) {
    final minuteDot = Paint()
      ..color = (art.dark ? Colors.white : _minuteColor).withValues(
        alpha: art.dark ? 0.55 : 0.45,
      );
    final hourBar = Paint()
      ..color = _ink
      ..strokeWidth = r * 0.035
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 60; i++) {
      final angle = (i * 6 - 90) * pi / 180;
      final dir = Offset(cos(angle), sin(angle));
      if (i % 5 == 0) {
        canvas.drawLine(
          center + dir * (r * 0.84),
          center + dir * (r * 0.93),
          hourBar,
        );
      } else {
        canvas.drawCircle(center + dir * (r * 0.9), r * 0.014, minuteDot);
      }
    }
  }

  void _drawHourNumbers(Canvas canvas, Offset center, double r) {
    for (var hour = 1; hour <= 12; hour++) {
      final angle = (hour * 30 - 90) * pi / 180;
      _paintText(
        canvas,
        '$hour',
        center + Offset(cos(angle), sin(angle)) * (r * 0.68),
        TextStyle(
          fontSize: r * 0.2,
          fontWeight: FontWeight.w900,
          color: _ink,
          height: 1,
          letterSpacing: -0.5,
        ),
      );
    }
  }

  void _drawMinuteNumbers(Canvas canvas, Offset center, double r) {
    for (var i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      _paintText(
        canvas,
        '${i * 5}',
        center + Offset(cos(angle), sin(angle)) * (r * 0.47),
        TextStyle(
          fontSize: r * 0.085,
          fontWeight: FontWeight.w800,
          color: art.dark ? Color(0xFF8FE3FF) : _minuteColor,
          height: 1,
        ),
      );
    }
  }

  /// 중심에서 넓고 끝으로 갈수록 가늘어지는 둥근 바늘
  void _drawHand(
    Canvas canvas,
    Offset center, {
    required double angle,
    required double length,
    required double width,
    required Color color,
  }) {
    final half = width / 2;
    final tip = half * 0.45;
    final tail = width * 0.9;
    final path = Path()
      ..moveTo(-half, 0)
      ..lineTo(-tip, -length + tip)
      ..arcToPoint(Offset(tip, -length + tip), radius: Radius.circular(tip))
      ..lineTo(half, 0)
      ..lineTo(half * 0.7, tail)
      ..arcToPoint(
        Offset(-half * 0.7, tail),
        radius: Radius.circular(half * 0.7),
      )
      ..close();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle * pi / 180);
    canvas.drawPath(
      path.shift(Offset(2, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: [Color.lerp(color, Colors.white, 0.25)!, color],
        ).createShader(Rect.fromLTRB(-half, -length, half, tail)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, width * 0.12)
        ..strokeJoin = StrokeJoin.round
        ..color = Color.lerp(color, Colors.black, 0.4)!,
    );
    canvas.restore();
  }

  void _drawSecondHand(Canvas canvas, Offset center, double r) {
    final angle = (secondAngle - 90) * pi / 180;
    final dir = Offset(cos(angle), sin(angle));
    final paint = Paint()
      ..color = AppColors.treasureOrange
      ..strokeWidth = max(1.3, r * 0.014)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center - dir * (r * 0.14),
      center + dir * (r * 0.82),
      paint,
    );
    canvas.drawCircle(center - dir * (r * 0.14), r * 0.03, paint);
  }

  void _drawCenterCap(Canvas canvas, Offset center, double r) {
    canvas.drawCircle(center, r * 0.085, Paint()..color = Color(0xFF4A2E17));
    canvas.drawCircle(
      center,
      r * 0.06,
      Paint()
        ..shader = RadialGradient(
          colors: [Color(0xFFFFF1A8), AppColors.mapStar],
        ).createShader(Rect.fromCircle(center: center, radius: r * 0.06)),
    );
  }

  void _paintText(Canvas canvas, String text, Offset at, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(IllustratedClockPainter old) =>
      old.hourAngle != hourAngle ||
      old.minuteAngle != minuteAngle ||
      old.secondAngle != secondAngle ||
      old.showGuideline != showGuideline ||
      old.showMinuteNumbers != showMinuteNumbers ||
      old.faceRadius != faceRadius ||
      old.art != art ||
      old.layer != layer;
}

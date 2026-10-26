import 'dart:math';
import 'package:flutter/material.dart';

/// 시계판 안에서 테마별로 계속 움직이는 작은 장식
///
/// 시계판 위, 테두리 그림과 숫자 아래에 그린다. 숫자가 잘 보이도록 옅게 그리고
/// 시계판 원 밖으로 나가지 않게 자른다. [t]는 0→1로 반복되는 시간이다.
class ClockAmbientPainter extends CustomPainter {
  ClockAmbientPainter({
    required this.themeId,
    required this.faceRadius,
    required this.t,
  });

  final String themeId;
  final double faceRadius;
  final double t;

  static const _particles = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = faceRadius;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));

    switch (themeId) {
      case 'star_clock':
        _twinkles(canvas, c, r, [Color(0xFFFFE08A), Colors.white], 0.9);
      case 'moonlight_clock':
        _twinkles(canvas, c, r, [Colors.white, Color(0xFFD8C8FF)], 0.8);
        _shootingStar(canvas, c, r);
      case 'golden_clock':
        _twinkles(canvas, c, r, [Color(0xFFFFD54F)], 0.55);
      case 'rainbow_clock':
        _twinkles(canvas, c, r, _rainbow, 0.45);
      case 'crystal_clock':
        _falling(canvas, c, r, [Colors.white], speed: 0.6, shape: _Shape.snow);
      case 'flower_clock':
        _falling(
          canvas,
          c,
          r,
          [Color(0xFFFF9EC4), Color(0xFFFFC2DA)],
          speed: 0.5,
          shape: _Shape.petal,
        );
      case 'circus_clock':
        _falling(canvas, c, r, _rainbow, speed: 0.8, shape: _Shape.confetti);
      case 'candy_clock':
        _falling(canvas, c, r, _rainbow, speed: 0.55, shape: _Shape.sprinkle);
      case 'dinosaur_clock':
        _falling(
          canvas,
          c,
          r,
          [Color(0xFF7CC66B), Color(0xFFA5D86E)],
          speed: 0.4,
          shape: _Shape.petal,
        );
      case 'princess_clock':
        _rising(canvas, c, r, [Color(0xFFFF7FAF), Color(0xFFFFB3CF)], '♥');
      case 'music_clock':
        _rising(canvas, c, r, [
          Color(0xFF7E57C2),
          Color(0xFF2F9BFF),
          Color(0xFFFF5A5F),
        ], '♪');
      case 'art_clock':
        _bobbingDots(canvas, c, r);
      case 'spaceship_clock':
        _warp(canvas, c, r);
      case 'police_clock':
        _siren(canvas, c, r);
    }
    canvas.restore();
  }

  static const _rainbow = [
    Color(0xFFFF6B6B),
    Color(0xFFFFB74D),
    Color(0xFFFFE066),
    Color(0xFF7CD67C),
    Color(0xFF5AB4FF),
    Color(0xFFB388FF),
  ];

  /// 입자마다 고정된 위치·박자 (매 프레임 같은 값이 나오도록 시드 고정)
  double _rand(int i, int salt) {
    final x = sin(i * 12.9898 + salt * 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  Offset _spot(Offset c, double r, int i) {
    final angle = _rand(i, 1) * 2 * pi;
    final dist = sqrt(_rand(i, 2)) * r * 0.88;
    return c + Offset(cos(angle), sin(angle)) * dist;
  }

  void _twinkles(
    Canvas canvas,
    Offset c,
    double r,
    List<Color> colors,
    double strength,
  ) {
    for (var i = 0; i < _particles; i++) {
      final phase = (t * 2 + _rand(i, 3)) % 1.0;
      final glow = pow(sin(phase * pi), 3).toDouble();
      if (glow < 0.05) continue;
      final p = _spot(c, r, i);
      final s = r * (0.025 + 0.03 * _rand(i, 4)) * (0.6 + 0.4 * glow);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: strength * glow);
      _sparkle(canvas, p, s, paint);
    }
  }

  void _sparkle(Canvas canvas, Offset p, double s, Paint paint) {
    final path = Path()
      ..moveTo(p.dx, p.dy - s * 2)
      ..quadraticBezierTo(p.dx, p.dy, p.dx + s * 2, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + s * 2)
      ..quadraticBezierTo(p.dx, p.dy, p.dx - s * 2, p.dy)
      ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - s * 2);
    canvas.drawPath(path, paint);
  }

  void _shootingStar(Canvas canvas, Offset c, double r) {
    final phase = (t * 1.5) % 1.0;
    if (phase > 0.3) return;
    final k = phase / 0.3;
    final start = c + Offset(-r * 0.9, -r * 0.6);
    final head = start + Offset(r * 1.6, r * 0.7) * k;
    final tail = head - Offset(r * 0.35, r * 0.15);
    canvas.drawLine(
      tail,
      head,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.9 * (1 - k)),
          ],
        ).createShader(Rect.fromPoints(tail, head))
        ..strokeWidth = r * 0.02
        ..strokeCap = StrokeCap.round,
    );
  }

  void _falling(
    Canvas canvas,
    Offset c,
    double r,
    List<Color> colors, {
    required double speed,
    required _Shape shape,
  }) {
    for (var i = 0; i < _particles; i++) {
      final y = ((t * speed * 2 + _rand(i, 5)) % 1.0) * 2.2 - 1.1;
      final x =
          (_rand(i, 6) * 2 - 1) * 0.9 +
          sin((t * 2 + _rand(i, 7)) * 2 * pi) * 0.06;
      final p = c + Offset(x * r, y * r);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 0.55);
      final s = r * (0.025 + 0.02 * _rand(i, 8));
      final spin = (t * 4 + _rand(i, 9)) * 2 * pi;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(spin);
      switch (shape) {
        case _Shape.snow:
          _sparkle(canvas, Offset.zero, s * 0.8, paint);
          canvas.drawCircle(Offset.zero, s * 0.5, paint);
        case _Shape.petal:
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset.zero,
              width: s * 2.4,
              height: s * 1.3,
            ),
            paint,
          );
        case _Shape.confetti:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: s * 2, height: s * 1.1),
            paint,
          );
        case _Shape.sprinkle:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: s * 2.6,
                height: s * 0.9,
              ),
              Radius.circular(s),
            ),
            paint,
          );
      }
      canvas.restore();
    }
  }

  void _rising(
    Canvas canvas,
    Offset c,
    double r,
    List<Color> colors,
    String glyph,
  ) {
    for (var i = 0; i < 8; i++) {
      final k = (t * 0.9 + _rand(i, 10)) % 1.0;
      final y = 1.0 - k * 2.0;
      final x = (_rand(i, 11) * 2 - 1) * 0.75 + sin(k * 2 * pi + i) * 0.08;
      final alpha = sin(k * pi) * 0.5;
      final painter = TextPainter(
        text: TextSpan(
          text: glyph,
          style: TextStyle(
            fontSize: r * (0.12 + 0.06 * _rand(i, 12)),
            color: colors[i % colors.length].withValues(alpha: alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        c +
            Offset(x * r, y * r) -
            Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  void _bobbingDots(Canvas canvas, Offset c, double r) {
    for (var i = 0; i < 10; i++) {
      final p =
          _spot(c, r, i) +
          Offset(0, sin((t * 2 + _rand(i, 13)) * 2 * pi) * r * 0.04);
      canvas.drawCircle(
        p,
        r * (0.03 + 0.03 * _rand(i, 14)),
        Paint()..color = _rainbow[i % _rainbow.length].withValues(alpha: 0.35),
      );
    }
  }

  void _warp(Canvas canvas, Offset c, double r) {
    for (var i = 0; i < 18; i++) {
      final angle = _rand(i, 15) * 2 * pi;
      final k = (t * 1.6 + _rand(i, 16)) % 1.0;
      final dir = Offset(cos(angle), sin(angle));
      final from = c + dir * (r * (0.15 + k * 0.85));
      final to = from + dir * (r * 0.08 * k);
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = Color(0xFF9FD8FF).withValues(alpha: 0.6 * k)
          ..strokeWidth = r * 0.015
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _siren(Canvas canvas, Offset c, double r) {
    final red = (sin(t * 8 * pi) * 0.5 + 0.5);
    for (final (color, side, a) in [
      (Color(0xFFFF4D4D), -1.0, red),
      (Color(0xFF3D8BFF), 1.0, 1 - red),
    ]) {
      final p = c + Offset(side * r * 0.75, -r * 0.75);
      canvas.drawCircle(
        p,
        r * 0.6,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.28 * a),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: p, radius: r * 0.6)),
      );
    }
  }

  @override
  bool shouldRepaint(ClockAmbientPainter old) =>
      old.t != t || old.themeId != themeId || old.faceRadius != faceRadius;
}

enum _Shape { snow, petal, confetti, sprinkle }

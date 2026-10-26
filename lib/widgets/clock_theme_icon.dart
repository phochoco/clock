import 'package:flutter/material.dart';
import '../models/clock_theme.dart';

/// 시계 테마의 일러스트 아이콘 (assets/images/clocks/<테마 ID>.png)
/// 잠긴 시계는 흑백으로 흐리게 보여준다
class ClockThemeIcon extends StatelessWidget {
  const ClockThemeIcon({
    super.key,
    required this.theme,
    this.size = 88,
    this.locked = false,
  });

  final ClockTheme theme;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    Widget icon = Image.asset(
      'assets/images/clocks/${theme.id}.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          gradient: theme.backgroundGradient,
          shape: BoxShape.circle,
        ),
      ),
    );
    if (locked) {
      icon = Opacity(
        opacity: 0.55,
        child: ColorFiltered(colorFilter: _grayscale, child: icon),
      );
    }
    return icon;
  }

  static const _grayscale = ColorFilter.matrix([
    0.33, 0.5, 0.17, 0, 0, //
    0.33, 0.5, 0.17, 0, 0, //
    0.33, 0.5, 0.17, 0, 0, //
    0, 0, 0, 1, 0,
  ]);
}

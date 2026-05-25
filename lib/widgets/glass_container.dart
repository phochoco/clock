import 'dart:ui';
import 'package:flutter/material.dart';

/// 앱 전반에 걸쳐 사용되는 재사용 가능한 글래스모피즘(유리 질감) 컨테이너
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final bool isDark; // 다크 모드 표면 여부
  final double blurRadius; // 블러 강도
  final double opacity; // 배경 투명도

  const GlassContainer({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(24.0),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.isDark = false,
    this.blurRadius = 20.0,
    this.opacity = 0.2, // 20% 투명도가 가장 유리스러움
  });

  @override
  Widget build(BuildContext context) {
    // 배경 테두리와 색상
    final Color bgColor = isDark ? Colors.black : Colors.white;
    final Color borderColor = (isDark ? Colors.white : Colors.white).withValues(
      alpha: isDark ? 0.1 : 0.4,
    );

    Widget container = Container(
      width: width == double.infinity ? null : width,
      height: height == double.infinity ? null : height,
      margin: margin,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }

    return container;
  }
}

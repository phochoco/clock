import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// 앱 전반에 걸쳐 사용되는 카드 컨테이너
/// 보물섬 바다 배경 위에서도 잘 읽히도록 모래색 판에 나무 테두리를 두른다
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final bool isDark; // 다크 모드 표면 여부
  final double blurRadius; // (이전 글래스 스타일 호환용)
  final double opacity; // (이전 글래스 스타일 호환용)

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
    this.opacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      width: width == double.infinity ? null : width,
      height: height == double.infinity ? null : height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.watchSurface : AppColors.mapSand,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.woodLight, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDark.withValues(alpha: 0.3),
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }

    return container;
  }
}

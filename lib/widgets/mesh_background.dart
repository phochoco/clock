import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// 앱 전경에 깔리는 동적 메쉬(Mesh) 그라데이션 배경
/// 시간이 지남에 따라 천천히 움직이도록 구현할 수 있으나 성능을 위해 우선 정적/미세 애니메이션만 적용
class MeshBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const MeshBackground({super.key, required this.child, this.isDark = false});

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 매우 느린 호흡 애니메이션
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseGradient = widget.isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.watchBlack,
              AppColors.bgDarkPrimary,
              AppColors.watchSurface,
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgPrimary,
              AppColors.bgSecondary,
              AppColors.bgPrimary,
            ],
          );

    return Stack(
      children: [
        Container(decoration: BoxDecoration(gradient: baseGradient)),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: widget.isDark ? 0.16 : 0.22,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: widget.isDark ? 0.05 : 0.55),
                    Colors.transparent,
                    (widget.isDark ? AppColors.appleBlue : AppColors.bgAccent1)
                        .withValues(alpha: 0.08 + (_controller.value * 0.04)),
                  ],
                  stops: const [0, 0.48, 1],
                ),
              ),
            ),
          ),
        ),

        // 실제 컨텐츠
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

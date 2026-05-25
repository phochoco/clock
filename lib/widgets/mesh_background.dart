import 'dart:math';
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
    return Stack(
      children: [
        // 1. 기본 배경색
        Container(
          color: widget.isDark ? AppColors.bgDarkPrimary : AppColors.bgPrimary,
        ),

        // 2. 움직이는 그라데이션 오로라 1
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned(
              top: -100 + (_controller.value * 50),
              left: -50 + (sin(_controller.value * pi) * 50),
              child: _buildBlurOrb(
                widget.isDark
                    ? AppColors.bgDarkSecondary
                    : AppColors.bgSecondary,
                300,
              ),
            );
          },
        ),

        // 3. 움직이는 그라데이션 오로라 2
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Positioned(
              bottom: -50 - (_controller.value * 30),
              right: -100 + (cos(_controller.value * pi) * 60),
              child: _buildBlurOrb(
                widget.isDark ? AppColors.bgDarkAccent1 : AppColors.bgAccent1,
                350,
              ),
            );
          },
        ),

        // 4. 움직이는 그라데이션 오로라 3
        if (!widget.isDark)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                right: -50 - (_controller.value * 20),
                child: _buildBlurOrb(AppColors.bgAccent2, 250),
              );
            },
          ),

        // 실제 컨텐츠
        Positioned.fill(child: widget.child),
      ],
    );
  }

  Widget _buildBlurOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 100, // 부드럽게 퍼지는 효과
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }
}

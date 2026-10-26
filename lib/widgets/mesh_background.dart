import 'package:flutter/material.dart';
import 'island_ui.dart';

/// 화면 공통 배경
/// 보물섬 리디자인 이후 모든 화면이 같은 바다 배경을 쓴다
class MeshBackground extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const MeshBackground({super.key, required this.child, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return IslandSeaBackground(child: child);
  }
}

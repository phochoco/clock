import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/quiz_level.dart';
import '../utils/colors.dart';

/// 보물섬 지도 위 섬 하나 (퀴즈 레벨 하나에 대응)
class TreasureIsland {
  const TreasureIsland({
    required this.level,
    required this.name,
    required this.asset,
    required this.background,
    required this.badgeColor,
    required this.position,
  });

  final QuizLevel level;
  final String name;
  final String asset;

  /// 이 섬의 퀴즈 화면 배경
  final String background;
  final Color badgeColor;

  /// 지도 영역 안에서의 상대 위치 (0~1)
  final Offset position;

  static const all = [
    TreasureIsland(
      level: QuizLevel.level1,
      name: '야자수 해변',
      asset: 'assets/images/map/island_1.png',
      background: 'assets/images/islands/bg_1.jpg',
      badgeColor: Color(0xFFF0457A),
      position: Offset(0.27, 0.85),
    ),
    TreasureIsland(
      level: QuizLevel.level2,
      name: '버섯 숲',
      asset: 'assets/images/map/island_2.png',
      background: 'assets/images/islands/bg_2.jpg',
      badgeColor: Color(0xFF2FB344),
      position: Offset(0.72, 0.67),
    ),
    TreasureIsland(
      level: QuizLevel.level3,
      name: '화산섬',
      asset: 'assets/images/map/island_3.png',
      background: 'assets/images/islands/bg_3.jpg',
      badgeColor: Color(0xFFFF8A00),
      position: Offset(0.30, 0.48),
    ),
    TreasureIsland(
      level: QuizLevel.level4,
      name: '얼음섬',
      asset: 'assets/images/map/island_4.png',
      background: 'assets/images/islands/bg_4.jpg',
      badgeColor: Color(0xFF3B6FE0),
      position: Offset(0.70, 0.30),
    ),
    TreasureIsland(
      level: QuizLevel.level5,
      name: '황금성',
      asset: 'assets/images/map/island_5.png',
      background: 'assets/images/islands/bg_5.jpg',
      badgeColor: Color(0xFF8B4FD8),
      position: Offset(0.34, 0.12),
    ),
  ];

  static TreasureIsland of(QuizLevel level) => all[level.index];
}

enum IslandState { completed, current, locked }

/// 섬 5개와 뱃길, 현재 위치의 해적선을 그리는 지도
class TreasureMap extends StatefulWidget {
  const TreasureMap({
    super.key,
    required this.completedLevels,
    required this.currentLevel,
    required this.onIslandTap,
  });

  final Set<int> completedLevels;
  final QuizLevel currentLevel;
  final void Function(TreasureIsland island, IslandState state) onIslandTap;

  @override
  State<TreasureMap> createState() => _TreasureMapState();
}

class _TreasureMapState extends State<TreasureMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(vsync: this, duration: Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  IslandState _stateOf(TreasureIsland island) {
    if (widget.completedLevels.contains(island.level.number)) {
      return IslandState.completed;
    }
    if (island.level.index <= widget.currentLevel.index) {
      return IslandState.current;
    }
    return IslandState.locked;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final islandSize = math.min(size.width * 0.40, size.height * 0.27);
        final centers = TreasureIsland.all
            .map(
              (i) => Offset(
                i.position.dx * size.width,
                i.position.dy * size.height,
              ),
            )
            .toList();
        final ship = TreasureIsland.of(widget.currentLevel);
        final shipCenter = centers[ship.level.index];
        final shipOnRight = ship.position.dx < 0.5;

        return AnimatedBuilder(
          animation: _wave,
          builder: (context, _) {
            final t = _wave.value * math.pi * 2;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RoutePainter(
                      points: centers,
                      reachedIndex: widget.currentLevel.index,
                    ),
                  ),
                ),
                for (final island in TreasureIsland.all)
                  Positioned(
                    left: centers[island.level.index].dx - islandSize / 2,
                    top: centers[island.level.index].dy - islandSize / 2,
                    width: islandSize,
                    height: islandSize,
                    child: _IslandView(
                      island: island,
                      state: _stateOf(island),
                      pulse: math.sin(t),
                      onTap: () => widget.onIslandTap(island, _stateOf(island)),
                    ),
                  ),
                // 지금 탐험 중인 섬 옆에 정박한 해적선
                Positioned(
                  left:
                      shipCenter.dx +
                      (shipOnRight ? islandSize * 0.32 : -islandSize * 0.82),
                  top: shipCenter.dy + islandSize * 0.1 + math.sin(t) * 3,
                  width: islandSize * 0.5,
                  child: IgnorePointer(
                    child: Transform.rotate(
                      angle: math.sin(t + 1) * 0.04,
                      child: Transform.flip(
                        flipX: !shipOnRight,
                        child: Image.asset(
                          'assets/images/map/ship.png',
                          errorBuilder: (_, _, _) => SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _IslandView extends StatelessWidget {
  const _IslandView({
    required this.island,
    required this.state,
    required this.pulse,
    required this.onTap,
  });

  final TreasureIsland island;
  final IslandState state;
  final double pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLocked = state == IslandState.locked;
    final isCurrent = state == IslandState.current;
    final stateLabel = switch (state) {
      IslandState.completed => '탐험 완료',
      IslandState.current => '지금 탐험할 섬',
      IslandState.locked => '아직 잠겨 있음',
    };

    Widget image = Image.asset(
      island.asset,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Container(
        decoration: BoxDecoration(
          color: AppColors.mapSand,
          shape: BoxShape.circle,
        ),
      ),
    );
    if (isLocked) {
      image = Opacity(
        opacity: 0.92,
        child: ColorFiltered(colorFilter: _desaturate, child: image),
      );
    }

    return Semantics(
      button: true,
      label:
          '${island.level.number}번 ${island.name}, ${island.level.description}, $stateLabel',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Transform.scale(
          scale: isCurrent ? 1.04 + pulse * 0.025 : 1.0,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (isCurrent)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.mapGlow.withValues(alpha: 0.75),
                          AppColors.mapGlow.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned.fill(child: image),
              if (isLocked) ..._buildFog(),
              if (isLocked)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.mapLock,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              Positioned(
                left: 0,
                top: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NumberBadge(
                      number: island.level.number,
                      color: isLocked ? AppColors.mapLock : island.badgeColor,
                    ),
                    if (state == IslandState.completed) ...[
                      SizedBox(height: 2),
                      _StarRow(),
                    ],
                  ],
                ),
              ),
              Positioned(
                bottom: -6,
                child: _NameTag(name: island.name, dimmed: isLocked),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 잠긴 섬을 덮는 안개
  List<Widget> _buildFog() {
    return [
      for (final offset in [
        Offset(-0.22, 0.05),
        Offset(0.2, -0.08),
        Offset(0.05, 0.22),
      ])
        Align(
          alignment: Alignment(offset.dx * 2, offset.dy * 2),
          child: FractionallySizedBox(
            widthFactor: 0.45,
            heightFactor: 0.22,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.45),
                    blurRadius: 18,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  static const _desaturate = ColorFilter.matrix([
    0.75, 0.20, 0.05, 0, 12, //
    0.12, 0.80, 0.08, 0, 12, //
    0.12, 0.25, 0.63, 0, 20, //
    0, 0, 0, 1, 0,
  ]);
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number, required this.color});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            Icons.star_rounded,
            size: 18,
            color: AppColors.mapStar,
            shadows: [Shadow(color: AppColors.woodDark, blurRadius: 2)],
          ),
      ],
    );
  }
}

class _NameTag extends StatelessWidget {
  const _NameTag({required this.name, required this.dimmed});

  final String name;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: (dimmed ? Colors.white : AppColors.mapSand).withValues(
          alpha: dimmed ? 0.7 : 0.95,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.woodLight, width: 1.5),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: dimmed ? AppColors.textLight : AppColors.woodDark,
        ),
      ),
    );
  }
}

/// 섬과 섬을 잇는 점선 뱃길
class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.points, required this.reachedIndex});

  final List<Offset> points;
  final int reachedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final mid = Offset.lerp(a, b, 0.5)!;
      final normal = Offset(-(b.dy - a.dy), b.dx - a.dx) / (b - a).distance;
      final control = mid + normal * 28 * (i.isEven ? 1 : -1);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(control.dx, control.dy, b.dx, b.dy);

      final reached = i < reachedIndex;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: reached ? 0.95 : 0.45)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (final metric in path.computeMetrics()) {
        var d = 0.0;
        while (d < metric.length) {
          canvas.drawPath(metric.extractPath(d, d + 8), paint);
          d += 18;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.reachedIndex != reachedIndex || old.points != points;
}

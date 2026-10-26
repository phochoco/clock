import 'package:flutter/material.dart';
import '../utils/korean_text.dart';
import '../utils/colors.dart';

/// 보물섬 화면들이 함께 쓰는 공통 위젯 (배경, 째깍이, 말풍선, 버튼)

/// 바다 배경 (이미지가 없으면 바다색 그라데이션)
class IslandSeaBackground extends StatelessWidget {
  const IslandSeaBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/map/sea_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, _, _) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.mapSea, AppColors.mapSeaDeep],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

enum MascotPose { wave, cheer, think, point, treasure, sleep }

/// 마스코트 앵무새 째깍이 (둥실거리는 움직임 + 포즈 전환)
class Jjakkagi extends StatefulWidget {
  const Jjakkagi({
    super.key,
    required this.pose,
    this.height = 100,
    this.onTap,
  });

  final MascotPose pose;
  final double height;
  final VoidCallback? onTap;

  @override
  State<Jjakkagi> createState() => _JjakkagiState();
}

class _JjakkagiState extends State<Jjakkagi>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(vsync: this, duration: Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _bob,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -4 * Curves.easeInOut.transform(_bob.value)),
          child: child,
        ),
        child: SizedBox(
          height: widget.height,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.bottomLeft,
              children: [...previous, ?current],
            ),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: child,
            ),
            child: Image.asset(
              'assets/images/mascot/${widget.pose.name}.png',
              key: ValueKey(widget.pose),
              height: widget.height,
              fit: BoxFit.contain,
              semanticLabel: '앵무새 째깍이',
              errorBuilder: (_, _, _) => SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class IslandSpeechBubble extends StatelessWidget {
  const IslandSpeechBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(text),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text.keepWords,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.woodDark,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

/// 모래색 원형 아이콘 버튼 (뒤로 가기, 보호자 안내 등)
class SandIconButton extends StatelessWidget {
  const SandIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
      ),
      icon: Icon(icon, color: AppColors.woodDark, size: 22),
    );
  }
}

/// 아래로 두꺼운 그림자가 있는 큰 버튼. onTap이 null이면 비활성
class ChunkyButton extends StatelessWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.topColor = AppColors.treasureOrange,
    this.bottomColor = AppColors.treasureOrangeDeep,
    this.textColor = Colors.white,
    this.height = 64,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color topColor;
  final Color bottomColor;
  final Color textColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 200),
          opacity: enabled ? 1 : 0.75,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: enabled
                    ? [topColor, bottomColor]
                    : [AppColors.mapSand, AppColors.woodLight],
              ),
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.woodDark.withValues(alpha: 0.45),
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: textColor, size: 30),
                  SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 모래색 이름표 (화면 제목)
class IslandTitleChip extends StatelessWidget {
  const IslandTitleChip({super.key, required this.title, this.leading});

  final String title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(leading == null ? 16 : 6, 6, 16, 6),
      decoration: BoxDecoration(
        color: AppColors.mapSand,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.woodLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, SizedBox(width: 6)],
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.woodDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 뒤로 가기 + 가운데 이름표 + 오른쪽 자리로 된 상단 바
class IslandTopBar extends StatelessWidget {
  const IslandTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          SandIconButton(
            tooltip: '뒤로 가기',
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Center(
              child: IslandTitleChip(title: title, leading: leading),
            ),
          ),
          SizedBox(width: 8),
          trailing ?? SizedBox(width: 48),
        ],
      ),
    );
  }
}

/// Scaffold.appBar 자리에 쓰는 보물섬 상단 바
PreferredSizeWidget islandAppBar(String title) {
  return PreferredSize(
    preferredSize: Size.fromHeight(64),
    child: SafeArea(bottom: false, child: IslandTopBar(title: title)),
  );
}

/// 모래색 판 위에 그림·제목·내용·버튼을 담는 보물섬 대화상자
class IslandDialog extends StatelessWidget {
  const IslandDialog({
    super.key,
    this.top,
    required this.title,
    this.message,
    this.body,
    this.titleColor = AppColors.woodDark,
    required this.actions,
  });

  final Widget? top;
  final String title;
  final String? message;
  final Widget? body;
  final Color titleColor;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.mapSand,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.woodLight, width: 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (top != null) ...[top!, SizedBox(height: 8)],
            Text(
              title.keepWords,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: titleColor,
              ),
            ),
            if (message != null) ...[
              SizedBox(height: 8),
              Text(
                message!.keepWords,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.woodDark,
                  height: 1.45,
                ),
              ),
            ],
            if (body != null) ...[SizedBox(height: 12), body!],
            SizedBox(height: 18),
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) SizedBox(height: 10),
              actions[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// 대화상자 아래쪽 보조 버튼 (닫기, 나중에 등)
class SandChunkyButton extends StatelessWidget {
  const SandChunkyButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      label: label,
      height: 52,
      topColor: Colors.white,
      bottomColor: Color(0xFFF3DDAF),
      textColor: AppColors.woodDark,
      onTap: onTap,
    );
  }
}

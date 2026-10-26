import 'package:flutter/material.dart';
import '../models/quiz_level.dart';
import '../services/reward_service.dart';
import '../services/tts_service.dart';
import '../utils/colors.dart';
import '../widgets/island_ui.dart';
import '../widgets/treasure_map.dart';
import 'playground_screen.dart';
import 'game_mode_screen.dart';
import 'quiz_screen.dart';
import 'reward_screen.dart';

/// 메인 로비 화면
/// 보물섬 지도에서 레벨(섬)을 고르고, 놀이 모드·내 시계들·바늘 연습으로 이동
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  QuizLevel _recommendedLevel = QuizLevel.level1;
  Set<int> _completedLevels = {};
  var _totalStars = 0;
  String? _mascotLine;

  bool get _allLevelsComplete =>
      _completedLevels.length >= QuizLevel.values.length;

  @override
  void initState() {
    super.initState();
    _loadPracticeProgress();
  }

  Future<void> _loadPracticeProgress() async {
    final completedLevels = await RewardService.getCompletedLevels();
    final totalStars = await RewardService.getTotalStars();
    final nextLevel = nextLevelToPlay(completedLevels.toSet());

    if (!mounted) return;
    setState(() {
      _recommendedLevel = nextLevel;
      _completedLevels = completedLevels.toSet();
      _totalStars = totalStars;
      _mascotLine = null;
    });
  }

  String get _defaultMascotLine {
    if (_allLevelsComplete) return '모든 섬을 탐험했어! 다시 가 볼까?';
    if (_completedLevels.isEmpty) return '함께 보물섬으로 떠나자!';
    return '${TreasureIsland.of(_recommendedLevel).name}으로 떠나자!';
  }

  void _say(String line) {
    setState(() => _mascotLine = line);
    TtsService.speak(line);
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    _loadPracticeProgress();
  }

  void _onIslandTap(TreasureIsland island, IslandState state) {
    if (state == IslandState.locked) {
      final previous = TreasureIsland.of(island.level.previous!);
      _say('${previous.name}부터 탐험해 줘!');
      return;
    }
    _open(QuizScreen(initialLevel: island.level));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mapSea,
      body: IslandSeaBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: TreasureMap(
                    completedLevels: _completedLevels,
                    currentLevel: _recommendedLevel,
                    onIslandTap: _onIslandTap,
                  ),
                ),
              ),
              _buildMascotRow(),
              _buildBottomBar(),
              SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SandIconButton(
                tooltip: '보호자 안내',
                icon: Icons.shield_outlined,
                onPressed: _showGuardianInfoDialog,
              ),
            ),
          ),
          Expanded(child: Center(child: _WoodenLogo())),
          SizedBox(
            width: 84,
            child: Align(
              alignment: Alignment.centerRight,
              child: _StarCounter(stars: _totalStars),
            ),
          ),
        ],
      ),
    );
  }

  void _showGuardianInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.appleBlue),
            SizedBox(width: 8),
            Text('보호자 안내'),
          ],
        ),
        content: Text(
          '학습 기록과 별, 선택한 시계는 기기에만 저장됩니다.\n\n'
          '광고, 계정 가입, 외부 전송 없이 사용할 수 있습니다.\n\n'
          '문의: yeajunss@naver.com',
          style: TextStyle(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotRow() {
    return SizedBox(
      height: 104,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Jjakkagi(
              pose: MascotPose.wave,
              onTap: () => _say(_defaultMascotLine),
            ),
            SizedBox(width: 4),
            Flexible(
              child: Padding(
                padding: EdgeInsets.only(bottom: 44),
                child: IslandSpeechBubble(
                  text: _mascotLine ?? _defaultMascotLine,
                ),
              ),
            ),
            SizedBox(width: 8),
            Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: _RoundMenuButton(
                icon: Icons.schedule_rounded,
                label: '바늘 연습',
                color: AppColors.appleBlue,
                onTap: () => _open(PlaygroundScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final level = _recommendedLevel;
    final subtitle = _allLevelsComplete
        ? '어려운 시간도 다시 연습해요'
        : '${level.number}번 섬 · ${level.description}';

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          _RoundMenuButton(
            icon: Icons.inventory_2_rounded,
            label: '내 시계들',
            color: AppColors.wood,
            onTap: () => _open(RewardScreen()),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _StartButton(
              title: _allLevelsComplete ? '복습하기' : '시작하기',
              subtitle: subtitle,
              onTap: () => _open(QuizScreen(initialLevel: level)),
            ),
          ),
          SizedBox(width: 12),
          _RoundMenuButton(
            icon: Icons.explore_rounded,
            label: '놀이 모드',
            color: AppColors.appleRed,
            onTap: () => _open(GameModeScreen()),
          ),
        ],
      ),
    );
  }
}

/// 나무 간판 모양의 앱 로고
class _WoodenLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18, 8, 18, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.woodLight, AppColors.wood],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.woodDark, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OutlinedText('째깍', size: 24, fill: AppColors.mapGlow),
          _OutlinedText('보물섬', size: 30, fill: Color(0xFF8FE3FF)),
        ],
      ),
    );
  }
}

class _OutlinedText extends StatelessWidget {
  const _OutlinedText(this.text, {required this.size, required this.fill});

  final String text;
  final double size;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      height: 1.1,
      letterSpacing: 1,
    );
    return Stack(
      children: [
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..strokeJoin = StrokeJoin.round
              ..color = AppColors.woodDark,
          ),
        ),
        Text(text, style: style.copyWith(color: fill)),
      ],
    );
  }
}

class _StarCounter extends StatelessWidget {
  const _StarCounter({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '모은 별 $stars개',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(6, 4, 12, 4),
        decoration: BoxDecoration(
          color: AppColors.mapSand,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.woodLight, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, color: AppColors.mapStar, size: 24),
            SizedBox(width: 2),
            Text(
              '$stars',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.woodDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundMenuButton extends StatelessWidget {
  const _RoundMenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.mapSand,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.woodLight, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(color: AppColors.woodDark, blurRadius: 3),
                  Shadow(color: AppColors.woodDark, blurRadius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 76,
          padding: EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.treasureOrange, AppColors.treasureOrangeDeep],
            ),
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.woodDark.withValues(alpha: 0.45),
                blurRadius: 0,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
              SizedBox(width: 2),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

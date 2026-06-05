import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/clock_theme.dart';
import '../models/clock_time.dart';
import '../models/quiz_level.dart';
import '../services/reward_service.dart';
import '../utils/colors.dart';
import '../widgets/analog_clock.dart';
import '../widgets/glass_container.dart';
import '../widgets/mesh_background.dart';
import 'playground_screen.dart';
import 'game_mode_screen.dart';
import 'quiz_screen.dart';
import 'reward_screen.dart';

/// 메인 로비 화면
/// 학습 모드, 퀴즈 모드, 보상방 진입점
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;
  QuizLevel _recommendedLevel = QuizLevel.level1;
  var _completedLevelCount = 0;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 8),
    )..repeat();
    _loadPracticeProgress();
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  Future<void> _loadPracticeProgress() async {
    final completedLevels = await RewardService.getCompletedLevels();
    final nextLevel = QuizLevel.values.firstWhere(
      (level) => !completedLevels.contains(level.number),
      orElse: () => QuizLevel.level5,
    );

    if (!mounted) return;
    setState(() {
      _recommendedLevel = nextLevel;
      _completedLevelCount = completedLevels.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildGuardianInfoButton(),
                SizedBox(height: 8),

                _buildTitle(),
                SizedBox(height: 18),

                _buildDailyPracticeCard(context),
                SizedBox(height: 14),
                _buildMainGlassButton(
                  context,
                  icon: Icons.schedule_rounded,
                  label: '바늘 움직여 보기',
                  subtitle: '짧은 바늘과 긴 바늘을 살펴봐요',
                  color: AppColors.appleBlue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaygroundScreen(),
                      ),
                    );
                  },
                ),

                SizedBox(height: 14),

                _buildMainGlassButton(
                  context,
                  icon: Icons.bolt_rounded,
                  label: '놀이 모드',
                  subtitle: '이야기와 도전으로 시간을 익혀요',
                  color: AppColors.appleRed,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GameModeScreen()),
                    );
                  },
                ),

                SizedBox(height: 14),

                _buildMainGlassButton(
                  context,
                  icon: Icons.grid_view_rounded,
                  label: '내 시계들',
                  subtitle: '모은 시계를 살펴봐요',
                  color: AppColors.appleYellow,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RewardScreen()),
                    );
                  },
                ),

                SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuardianInfoButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          tooltip: '보호자 안내',
          icon: Icon(
            Icons.shield_outlined,
            color: AppColors.textLight,
            size: 24,
          ),
          onPressed: _showGuardianInfoDialog,
        ),
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

  Widget _buildTitle() {
    return Column(
      children: [
        SizedBox(height: 8),
        Text(
          '오늘의 연습',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: AppColors.textLight,
          ),
        ),
        SizedBox(height: 10),

        Text(
          '째깍',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            color: AppColors.textDark,
          ),
        ),

        SizedBox(height: 10),

        Text(
          '바늘을 맞춰 시간을 익혀요.',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            color: AppColors.textLight,
          ),
        ),
        SizedBox(height: 26),
        _buildAnimatedTitleIcon(),
      ],
    );
  }

  Widget _buildAnimatedTitleIcon() {
    return AnimatedBuilder(
      animation: _motionController,
      builder: (context, child) {
        final t = _motionController.value;
        return Transform.scale(
          scale: 1 + math.sin(t * math.pi * 2) * 0.012,
          child: SizedBox(
            width: 240,
            height: 240,
            child: AnalogClock(
              initialTime: ClockTime(hour: 10, minute: 10),
              interactive: false,
              showGuideline: false,
              showMinuteNumbers: false,
              notifyInitialTime: false,
              theme: ClockThemeList.basic,
            ),
          ),
        );
      },
    );
  }

  double _cardWidth(BuildContext context) {
    return math.min(MediaQuery.of(context).size.width - 40, 360.0);
  }

  Widget _buildDailyPracticeCard(BuildContext context) {
    final allLevelsComplete = _completedLevelCount >= QuizLevel.values.length;
    final title = allLevelsComplete
        ? '마스터 복습하기'
        : '레벨 ${_recommendedLevel.number} 이어 하기';
    final subtitle = allLevelsComplete
        ? '어려운 시간도 다시 연습해요'
        : '${_recommendedLevel.description} 문제 5개';

    return GlassContainer(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(initialLevel: _recommendedLevel),
          ),
        );
        _loadPracticeProgress();
      },
      width: _cardWidth(context),
      height: 88,
      padding: EdgeInsets.symmetric(horizontal: 18),
      borderRadius: 28,
      opacity: 0.84,
      blurRadius: 18,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.appleBlue.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: AppColors.appleBlue,
              size: 32,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.appleBlue,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildMainGlassButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      onTap: onTap,
      width: _cardWidth(context),
      height: 76,
      padding: EdgeInsets.symmetric(horizontal: 18),
      borderRadius: 28,
      opacity: 0.76,
      blurRadius: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textLight.withValues(alpha: 0.72),
            size: 26,
          ),
        ],
      ),
    );
  }
}

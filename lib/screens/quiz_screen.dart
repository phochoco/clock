import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/clock_time.dart';
import '../models/quiz_level.dart';
import '../models/quiz_session.dart';
import '../models/reward.dart';
import '../models/clock_theme.dart';
import '../services/reward_service.dart';
import '../services/theme_service.dart';
import '../services/tts_service.dart';
import '../services/voice_lines.dart';
import '../utils/clock_hint.dart';
import '../utils/korean_text.dart';
import '../utils/colors.dart';
import '../utils/haptic.dart';
import '../widgets/analog_clock.dart';
import '../widgets/island_ui.dart';
import '../widgets/treasure_map.dart';

/// 퀴즈 모드 화면
/// 보물섬 지도의 섬(레벨)마다 5문제씩 시계를 맞추는 탐험
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.initialLevel = QuizLevel.level1});

  final QuizLevel initialLevel;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int questionsPerLevel = 5; // 레벨당 문제 수
  static const _idleLine = VoiceLines.quizIdle;

  late final QuizSession _session;
  var _isSavingAnswer = false;
  var _questionToken = 0;
  final GlobalKey<AnalogClockState> _clockKey = GlobalKey();

  // 선택된 테마
  ClockTheme _selectedTheme = ClockThemeList.basic;

  // 지도와 같은 잠금 기준
  Set<int> _completedLevels = {};

  // 째깍이 반응
  MascotPose _mascotPose = MascotPose.point;
  String _mascotLine = _idleLine;

  TreasureIsland get _island => TreasureIsland.of(_session.currentLevel);

  @override
  void initState() {
    super.initState();
    _session = QuizSession(questionsPerLevel: questionsPerLevel);
    _session.start(level: widget.initialLevel);
    _loadTheme();
    _loadCompletedLevels();
    _initTts();
    _speakCurrentQuestion();
  }

  Future<void> _initTts() async {
    await TtsService.initialize();
  }

  @override
  void dispose() {
    TtsService.stop();
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final theme = await ThemeService.getSelectedTheme();
    if (!mounted) return;
    setState(() {
      _selectedTheme = theme;
    });
  }

  Future<void> _loadCompletedLevels() async {
    final completed = await RewardService.getCompletedLevels();
    if (!mounted) return;
    setState(() => _completedLevels = completed.toSet());
  }

  bool _isOpen(QuizLevel level) =>
      level == widget.initialLevel || isLevelOpen(level, _completedLevels);

  void _setMascot(MascotPose pose, String line) {
    setState(() {
      _mascotPose = pose;
      _mascotLine = line;
    });
  }

  void _speakCurrentQuestion() {
    final question = _session.currentQuestion;
    if (question == null) return;
    final token = ++_questionToken;
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted && token == _questionToken) {
        TtsService.speak(VoiceLines.quizQuestion(question));
      }
    });
  }

  void _resetClock() {
    _clockKey.currentState?.setTime(ClockTime(hour: 12, minute: 0));
  }

  void _nextQuestion() {
    setState(() {
      _session.nextQuestion();
      _resetClock();
      _mascotPose = MascotPose.point;
      _mascotLine = _idleLine;
    });
    _speakCurrentQuestion();
  }

  void _switchLevel(QuizLevel level) {
    if (!_isOpen(level)) {
      final previous = TreasureIsland.of(level.previous!);
      HapticHelper.vibrate();
      _setMascot(MascotPose.think, VoiceLines.exploreFirst(previous.name));
      TtsService.speak(_mascotLine);
      return;
    }
    setState(() {
      _session.switchLevel(level);
      _resetClock();
      _mascotPose = MascotPose.point;
      _mascotLine = VoiceLines.arrivedAt(TreasureIsland.of(level).name);
    });
    _speakCurrentQuestion();
  }

  void _retryQuestion() {
    setState(() {
      _session.retryQuestion();
      _resetClock();
      _mascotPose = MascotPose.point;
      _mascotLine = _idleLine;
    });
  }

  Future<void> _checkAnswer() async {
    final question = _session.currentQuestion;
    final answer = _session.userAnswer;
    if (_isSavingAnswer || answer == null || question == null) {
      return;
    }

    final result = _session.answer(answer);
    setState(() => _isSavingAnswer = result.isCorrect);

    if (result.isCorrect) {
      _setMascot(
        MascotPose.cheer,
        VoiceLines.correct(
          result.earnedStars,
          _session.showCombo ? _session.comboMessage : '',
        ),
      );
      TtsService.speak(_mascotLine);
      await RewardService.addStars(result.earnedStars);
      HapticHelper.heavyImpact();
    } else {
      final hint = ClockHint.forAnswer(
        answer,
        ClockTime(hour: question.hour, minute: question.minute),
      );
      _setMascot(MascotPose.think, hint);
      TtsService.speak(hint);
      HapticHelper.vibrate();
    }

    if (!mounted) return;
    setState(() => _isSavingAnswer = false);
  }

  void _showLevelCompleteDialog() async {
    final level = _session.currentLevel;
    final island = _island;
    final score = _session.score;

    // 레벨 완료 기록 (처음 깬 섬이면 첫 탐험 보너스)
    final firstClear = await RewardService.completeLevel(level.number);
    if (firstClear) {
      await RewardService.addStars(RewardService.firstClearBonusStars);
    }

    // 완벽한 클리어 보너스 (5/5 정답)
    if (score == questionsPerLevel) {
      await RewardService.addStars(3); // 보너스 별 3개
    }

    // 보물 획득
    final reward = RewardList.getRewardForLevel(level.number);
    if (reward != null) {
      await RewardService.unlockReward(reward.id);
    }

    if (!mounted) return;
    setState(() {
      _completedLevels = {..._completedLevels, level.number};
      _mascotPose = MascotPose.treasure;
    });

    final nextLevel = level.next;
    final title = nextLevel == null
        ? VoiceLines.allIslandsComplete
        : VoiceLines.islandComplete(island.name);
    TtsService.speak(title);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TreasureDialog(
        title: title,
        message: nextLevel == null
            ? '레벨 1부터 레벨 5까지\n모두 성공하였습니다!'
            : '$questionsPerLevel문제 중 $score문제를 맞췄어요!',
        score: score,
        total: questionsPerLevel,
        bonuses: [
          if (firstClear) '첫 탐험 보너스 별 ${RewardService.firstClearBonusStars}개',
          if (score == questionsPerLevel) '만점 보너스 별 3개',
        ],
        reward: reward,
        badgeColor: island.badgeColor,
        actions: nextLevel == null
            ? [
                ChunkyButton(
                  label: '지도로 돌아가기',
                  icon: Icons.map_rounded,
                  onTap: () {
                    Navigator.pop(context); // 다이얼로그 닫기
                    Navigator.pop(this.context); // 퀴즈 화면 닫기
                  },
                ),
              ]
            : [
                ChunkyButton(
                  label: '다음 섬으로',
                  icon: Icons.sailing_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    _switchLevel(nextLevel);
                  },
                ),
                SizedBox(height: 10),
                ChunkyButton(
                  label: '다시 하기',
                  height: 52,
                  topColor: AppColors.mapSand,
                  bottomColor: Color(0xFFF3DDAF),
                  textColor: AppColors.woodDark,
                  onTap: () {
                    Navigator.pop(context);
                    _switchLevel(level);
                  },
                ),
              ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clockSize = math.min(270.0, MediaQuery.of(context).size.width - 90);

    return Scaffold(
      backgroundColor: AppColors.mapSea,
      body: IslandSeaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTopBar(),
                SizedBox(height: 4),
                _buildIslandTabs(),
                SizedBox(height: 14),
                _buildQuestionCard(),
                SizedBox(height: 16),
                _buildClock(clockSize),
                SizedBox(height: 8),
                _buildMascotRow(),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: _buildActionButton(),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final island = _island;
    return IslandTopBar(
      title: '${island.level.number}번 ${island.name}',
      leading: Image.asset(
        island.asset,
        width: 36,
        height: 36,
        errorBuilder: (_, _, _) => SizedBox(width: 36),
      ),
      trailing: _ScoreChests(score: _session.score, total: questionsPerLevel),
    );
  }

  /// 섬 번호 탭 (지도와 같은 기준으로 잠금)
  Widget _buildIslandTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final level in QuizLevel.values)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: _IslandTab(
              island: TreasureIsland.of(level),
              selected: level == _session.currentLevel,
              locked: !_isOpen(level),
              completed: _completedLevels.contains(level.number),
              onTap: () => _switchLevel(level),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    final question = _session.currentQuestion;
    if (question == null) return SizedBox();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 32),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.mapSand,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.woodLight, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDark.withValues(alpha: 0.35),
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '이 시간을 만들어봐요!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.wood,
            ),
          ),
          SizedBox(height: 4),
          Text(
            question.answerText,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: _island.badgeColor,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClock(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: AnalogClock(
        key: _clockKey,
        initialTime: ClockTime(hour: 12, minute: 0),
        notifyInitialTime: false,
        onTimeChanged: (time) {
          setState(() {
            _session.setAnswer(time);
          });
        },
        showGuideline: true,
        showMinuteNumbers: _session.currentLevel.index >= 2,
        theme: _selectedTheme, // 선택된 테마 적용
      ),
    );
  }

  Widget _buildMascotRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Jjakkagi(
            pose: _mascotPose,
            height: 96,
            onTap: () => TtsService.speak(_mascotLine),
          ),
          SizedBox(width: 6),
          Flexible(child: IslandSpeechBubble(text: _mascotLine)),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (!_session.showResult) {
      final canCheck = _session.userAnswer != null && !_isSavingAnswer;
      return ChunkyButton(
        label: '정답 확인',
        icon: Icons.check_rounded,
        onTap: canCheck ? _checkAnswer : null,
      );
    }

    if (_session.isCorrect) {
      final levelDone = _session.score >= questionsPerLevel;
      return ChunkyButton(
        label: _isSavingAnswer
            ? '별 저장 중'
            : levelDone
            ? '보물상자 열기'
            : '다음 문제',
        icon: levelDone ? Icons.redeem_rounded : Icons.arrow_forward_rounded,
        topColor: Color(0xFF4CD964),
        bottomColor: Color(0xFF1FA34A),
        onTap: _isSavingAnswer
            ? null
            : levelDone
            ? _showLevelCompleteDialog
            : _nextQuestion,
      );
    }

    return ChunkyButton(
      label: '다시 해볼게',
      icon: Icons.refresh_rounded,
      topColor: AppColors.mapGlow,
      bottomColor: AppColors.mapStar,
      textColor: AppColors.woodDark,
      onTap: _retryQuestion,
    );
  }
}

/// 이번 섬에서 맞힌 문제 수를 별 5칸으로 표시
class _ScoreChests extends StatelessWidget {
  const _ScoreChests({required this.score, required this.total});

  final int score;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$total문제 중 $score문제 맞힘',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (var i = 0; i < 3; i++) _star(i < score)],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (var i = 3; i < total; i++) _star(i < score)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _star(bool filled) {
    return Icon(
      Icons.star_rounded,
      size: 15,
      color: filled
          ? AppColors.mapStar
          : AppColors.woodLight.withValues(alpha: 0.35),
    );
  }
}

class _IslandTab extends StatelessWidget {
  const _IslandTab({
    required this.island,
    required this.selected,
    required this.locked,
    required this.completed,
    required this.onTap,
  });

  final TreasureIsland island;
  final bool selected;
  final bool locked;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = locked
        ? '잠김'
        : completed
        ? '완료'
        : '열림';
    return Semantics(
      button: true,
      selected: selected,
      label: '${island.level.number}번 ${island.name} $state',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: selected ? 54 : 46,
          height: selected ? 54 : 46,
          decoration: BoxDecoration(
            color: locked ? AppColors.mapLock : island.badgeColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.mapGlow : Colors.white,
              width: selected ? 4 : 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              locked
                  ? Icon(Icons.lock_rounded, color: Colors.white, size: 20)
                  : Text(
                      '${island.level.number}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
              if (completed)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Icon(
                    Icons.star_rounded,
                    size: 20,
                    color: AppColors.mapStar,
                    shadows: [Shadow(color: AppColors.woodDark, blurRadius: 2)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 섬 탐험 완료 보물상자 다이얼로그
class _TreasureDialog extends StatelessWidget {
  const _TreasureDialog({
    required this.title,
    required this.message,
    required this.score,
    required this.total,
    required this.bonuses,
    required this.reward,
    required this.badgeColor,
    required this.actions,
  });

  final String title;
  final String message;
  final int score;
  final int total;
  final List<String> bonuses;
  final Reward? reward;
  final Color badgeColor;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final reward = this.reward;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.mapSand,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.woodLight, width: 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Jjakkagi(pose: MascotPose.treasure, height: 120),
            SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: badgeColor,
              ),
            ),
            SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < total; i++)
                  Icon(
                    Icons.star_rounded,
                    size: 30,
                    color: i < score
                        ? AppColors.mapStar
                        : AppColors.woodLight.withValues(alpha: 0.35),
                  ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              message.keepWords,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.woodDark,
                height: 1.4,
              ),
            ),
            for (final bonus in bonuses) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.mapGlow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.mapStar, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 20,
                      color: AppColors.treasureOrangeDeep,
                    ),
                    SizedBox(width: 4),
                    Text(
                      bonus,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.woodDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (reward != null) ...[
              SizedBox(height: 14),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.mapStar, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(reward.icon, size: 36, color: reward.iconColor),
                    SizedBox(width: 10),
                    Text(
                      '${reward.name} 받았어요!',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.woodDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 18),
            ...actions,
          ],
        ),
      ),
    );
  }
}

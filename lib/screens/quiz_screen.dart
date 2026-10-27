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

  // 섬 완료 처리 중 (중복 방지)
  var _completing = false;

  // 시계 읽기 문제의 보기
  List<ClockTime> _readOptions = [];
  final _random = math.Random();

  TreasureIsland get _island => TreasureIsland.of(_session.currentLevel);

  QuizTask get _task => _session.currentTask;

  @override
  void initState() {
    super.initState();
    _session = QuizSession(questionsPerLevel: questionsPerLevel);
    _session.start(level: widget.initialLevel);
    _prepareTask();
    _mascotLine = VoiceLines.islandIntro(widget.initialLevel);
    _loadTheme();
    _loadCompletedLevels();
    _initTts();
    _speakCurrentQuestion(intro: true);
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

  /// 지금 문제를 안내하는 째깍이 대사
  String get _promptLine {
    if (_session.isBoss) return VoiceLines.bossIntro;
    return switch (_task) {
      QuizTask.setHands => _idleLine,
      QuizTask.readClock => VoiceLines.readPrompt,
      QuizTask.digitalSet => VoiceLines.digitalPrompt,
    };
  }

  /// 소리로 읽어 줄 문장. 섬에 막 도착했으면 섬 이야기를 들려준다.
  void _speakCurrentQuestion({bool intro = false}) {
    final question = _session.currentQuestion;
    if (question == null) return;
    final line = intro
        ? VoiceLines.islandIntro(_session.currentLevel)
        : _session.isBoss
        ? VoiceLines.bossIntro
        : switch (_task) {
            QuizTask.setHands => VoiceLines.quizQuestion(question),
            QuizTask.readClock => VoiceLines.readPrompt,
            QuizTask.digitalSet => VoiceLines.digitalPrompt,
          };
    final token = ++_questionToken;
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted && token == _questionToken) TtsService.speak(line);
    });
  }

  /// 문제 방식에 맞게 준비 (시계 읽기면 보기 3개 만들기)
  void _prepareTask() {
    final question = _session.currentQuestion;
    _readOptions = question != null && _task == QuizTask.readClock
        ? readClockOptions(question, _random.nextInt)
        : [];
  }

  void _resetClock() {
    _clockKey.currentState?.setTime(ClockTime(hour: 12, minute: 0));
  }

  void _nextQuestion() {
    setState(() {
      _session.nextQuestion();
      _prepareTask();
      _resetClock();
      _mascotPose = MascotPose.point;
      _mascotLine = _promptLine;
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
      _completing = false;
      _session.switchLevel(level);
      _prepareTask();
      _resetClock();
      _mascotPose = MascotPose.point;
      _mascotLine = VoiceLines.islandIntro(level);
    });
    _speakCurrentQuestion(intro: true);
  }

  void _retryQuestion() {
    setState(() {
      _session.retryQuestion();
      _resetClock();
      _mascotPose = MascotPose.point;
      _mascotLine = _promptLine;
    });
  }

  /// 바늘 맞추기 / 디지털 시계 문제 채점
  Future<void> _checkAnswer() async {
    final question = _session.currentQuestion;
    final answer = _session.userAnswer;
    if (_isSavingAnswer || answer == null || question == null) {
      return;
    }
    final wasBoss = _session.isBoss;
    final result = _session.answer(answer);
    await _afterAnswer(
      result,
      wasBoss: wasBoss,
      hint: ClockHint.forAnswer(
        answer,
        ClockTime(hour: question.hour, minute: question.minute),
      ),
    );
  }

  /// 시계 읽기 문제: 보기를 고르면 바로 채점
  Future<void> _chooseOption(ClockTime choice) async {
    if (_isSavingAnswer || _session.showResult) return;
    final wasBoss = _session.isBoss;
    final result = _session.answerChoice(choice);
    await _afterAnswer(result, wasBoss: wasBoss, hint: VoiceLines.readHint);
  }

  Future<void> _afterAnswer(
    QuizAnswerResult result, {
    required bool wasBoss,
    required String hint,
  }) async {
    setState(() => _isSavingAnswer = result.isCorrect);

    if (result.isCorrect) {
      _setMascot(
        MascotPose.cheer,
        wasBoss
            ? VoiceLines.bossCleared
            : VoiceLines.correct(
                result.earnedStars,
                _session.showCombo ? _session.comboMessage : '',
              ),
      );
      TtsService.speak(_mascotLine);
      await RewardService.addStars(result.earnedStars + (wasBoss ? 2 : 0));
      HapticHelper.heavyImpact();
    } else {
      _setMascot(MascotPose.think, hint);
      TtsService.speak(hint);
      HapticHelper.vibrate();
    }

    if (!mounted) return;
    setState(() => _isSavingAnswer = false);
  }

  void _showLevelCompleteDialog() async {
    // 보물상자 열기를 두 번 눌러 별을 두 번 받거나 창이 두 개 뜨지 않게
    if (_completing) return;
    setState(() => _completing = true);

    final level = _session.currentLevel;
    final island = _island;
    final perfect = _session.isPerfect;
    final mistakes = _session.mistakes;

    // 레벨 완료 기록 (처음 깬 섬이면 첫 탐험 보너스)
    final firstClear = await RewardService.completeLevel(level.number);
    if (firstClear) {
      await RewardService.addStars(RewardService.firstClearBonusStars);
    }

    // 한 번도 틀리지 않았을 때만 만점 보너스
    if (perfect) {
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
            : perfect
            ? '한 번도 안 틀리고 $questionsPerLevel문제를 다 맞췄어요!'
            : '$questionsPerLevel문제를 모두 풀었어요! (틀린 횟수 $mistakes번)',
        score: (questionsPerLevel - mistakes).clamp(1, questionsPerLevel),
        total: questionsPerLevel,
        bonuses: [
          if (firstClear) '첫 탐험 보너스 별 ${RewardService.firstClearBonusStars}개',
          if (perfect) '만점 보너스 별 3개',
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
        asset: _island.background,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTopBar(),
                SizedBox(height: 4),
                _buildQuestionSteps(),
                SizedBox(height: 14),
                _buildQuestionCard(),
                SizedBox(height: 16),
                _buildClock(clockSize),
                SizedBox(height: 8),
                _buildMascotRow(),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: _task == QuizTask.readClock && !_session.showResult
                      ? _buildReadOptions()
                      : _buildActionButton(),
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
    );
  }

  /// 이 섬의 문제 진행 (1~5번째 문제)
  Widget _buildQuestionSteps() {
    return _QuestionSteps(
      done: _session.score,
      total: questionsPerLevel,
      color: _island.badgeColor,
    );
  }

  Widget _buildQuestionCard() {
    final question = _session.currentQuestion;
    if (question == null) return SizedBox();
    final boss = _session.isBoss;

    final (String label, Widget body) = switch (_task) {
      QuizTask.setHands => (
        '이 시간을 만들어봐요!',
        Text(
          question.answerText,
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: boss ? AppColors.treasureOrangeDeep : _island.badgeColor,
            height: 1.15,
          ),
        ),
      ),
      QuizTask.digitalSet => (
        '디지털 시계랑 똑같이 맞춰요!',
        _DigitalDisplay(text: digitalTimeText(question.hour, question.minute)),
      ),
      QuizTask.readClock => (
        '시계가 가리키는 시각은?',
        Text(
          '아래에서 골라요',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: boss ? AppColors.treasureOrangeDeep : _island.badgeColor,
            height: 1.2,
          ),
        ),
      ),
    };

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 32),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: boss
            ? LinearGradient(colors: [AppColors.mapGlow, AppColors.mapStar])
            : null,
        color: boss ? null : AppColors.mapSand,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: boss ? AppColors.treasureOrangeDeep : AppColors.woodLight,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.woodDark.withValues(alpha: 0.35),
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (boss)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.treasureOrangeDeep,
                  size: 22,
                ),
                SizedBox(width: 4),
                Text(
                  '보스 문제',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.treasureOrangeDeep,
                  ),
                ),
              ],
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.wood,
            ),
          ),
          SizedBox(height: 4),
          body,
        ],
      ),
    );
  }

  /// 시계 읽기 보기 3개
  Widget _buildReadOptions() {
    return Column(
      children: [
        for (final option in _readOptions) ...[
          ChunkyButton(
            label: clockTimeText(option),
            height: 56,
            topColor: Colors.white,
            bottomColor: AppColors.mapSand,
            textColor: AppColors.woodDark,
            onTap: () => _chooseOption(option),
          ),
          SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildClock(double size) {
    final question = _session.currentQuestion;
    if (_task == QuizTask.readClock && question != null) {
      return SizedBox(
        width: size,
        height: size,
        child: AnalogClock(
          key: ValueKey('read-${_session.currentLevel}-${_session.score}'),
          initialTime: ClockTime(hour: question.hour, minute: question.minute),
          interactive: false,
          notifyInitialTime: false,
          showGuideline: false,
          showMinuteNumbers: _session.currentLevel.index >= 2,
          theme: _selectedTheme,
        ),
      );
    }
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
        onTap: _isSavingAnswer || _completing
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

/// 이 섬에서 몇 번째 문제인지 보여 주는 단계 표시
class _QuestionSteps extends StatelessWidget {
  const _QuestionSteps({
    required this.done,
    required this.total,
    required this.color,
  });

  final int done;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final current = done.clamp(0, total - 1);
    return Semantics(
      label: '$total문제 중 ${current + 1}번째 문제',
      excludeSemantics: true,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 40),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i <= done
                          ? color
                          : AppColors.woodLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              _step(i),
            ],
          ],
        ),
      ),
    );
  }

  Widget _step(int i) {
    final isDone = i < done;
    final isCurrent = i == done;
    final size = isCurrent ? 34.0 : 28.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.mapStar
            : isCurrent
            ? color
            : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone || isCurrent ? Colors.white : AppColors.woodLight,
          width: isCurrent ? 3 : 2,
        ),
      ),
      child: isDone
          ? Icon(Icons.star_rounded, color: Colors.white, size: 18)
          : Text(
              '${i + 1}',
              style: TextStyle(
                fontSize: isCurrent ? 16 : 13,
                fontWeight: FontWeight.w900,
                color: isCurrent ? Colors.white : AppColors.wood,
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

/// 디지털 시계 표시 (LCD 느낌)
class _DigitalDisplay extends StatelessWidget {
  const _DigitalDisplay({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 2),
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF243B35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.woodDark, width: 3),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          color: Color(0xFF7CFFB2),
          fontFeatures: [FontFeature.tabularFigures()],
          shadows: [Shadow(color: Color(0xFF7CFFB2), blurRadius: 10)],
          height: 1.1,
        ),
      ),
    );
  }
}

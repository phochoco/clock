import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/clock_time.dart';
import '../models/quiz_level.dart';
import '../models/clock_theme.dart';
import '../widgets/analog_clock.dart';
import '../utils/colors.dart';
import '../widgets/island_ui.dart';
import '../utils/clock_answer_validator.dart';
import '../utils/haptic.dart';
import '../services/time_attack_service.dart';
import '../services/reward_service.dart';
import '../services/theme_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/mesh_background.dart';

class TimeAttackScreen extends StatefulWidget {
  const TimeAttackScreen({super.key});

  @override
  State<TimeAttackScreen> createState() => _TimeAttackScreenState();
}

class _TimeAttackScreenState extends State<TimeAttackScreen> {
  // 게임 상태
  int _timeLeft = 60; // 남은 시간 (초)
  int _score = 0; // 현재 점수
  int _highScore = 0; // 최고 기록
  int _combo = 0; // 연속 정답
  bool _isGameOver = false;

  // 문제 관련
  QuizQuestion? _currentQuestion;
  ClockTime? _userAnswer;

  // 타이머
  Timer? _timer;

  // 시계 테마
  ClockTheme? _theme;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final highScore = await TimeAttackService.getHighScore();
    final theme = await ThemeService.getSelectedTheme();

    setState(() {
      _highScore = highScore;
      _theme = theme;
    });
  }

  void _startGame() {
    _generateQuestion();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _gameOver();
      }
    });
  }

  void _generateQuestion() {
    final random = Random();

    // 콤보에 따른 동적 난이도 조절 (Dynamic Escalation)
    QuizLevel level;
    if (_combo < 3) {
      // 콤보 0~2: 레벨 1 (정각, 30분)
      level = random.nextBool() ? QuizLevel.level1 : QuizLevel.level2;
    } else if (_combo < 7) {
      // 콤보 3~6: 레벨 2~3 (15/45분 포함)
      final levelIndex = random.nextInt(2) + 1; // 1 or 2
      level = QuizLevel.values[levelIndex];
    } else if (_combo < 15) {
      // 콤보 7~14: 레벨 3~4 (5분 단위 포함)
      final levelIndex = random.nextInt(2) + 2; // 2 or 3
      level = QuizLevel.values[levelIndex];
    } else {
      // 콤보 15 이상: 레벨 4~5 (1분 단위 포함, 최고 난이도)
      final levelIndex = random.nextInt(2) + 3; // 3 or 4
      level = QuizLevel.values[levelIndex];
    }

    setState(() {
      _currentQuestion = handsQuestion(level);
      _userAnswer = null;
    });
  }

  void _checkAnswer() {
    if (_isGameOver || _userAnswer == null || _currentQuestion == null) return;

    final correctTime = ClockTime(
      hour: _currentQuestion!.hour,
      minute: _currentQuestion!.minute,
    );

    final correct = ClockAnswerValidator.isCorrect(_userAnswer!, correctTime);

    if (correct) {
      _onCorrectAnswer();
    } else {
      _onWrongAnswer();
    }
  }

  void _onCorrectAnswer() {
    HapticHelper.heavyImpact();

    // 시간은 60초로 고정 (정답마다 시간이 늘어 끝나지 않던 문제)
    // 답을 비워서 다음 문제가 나오기 전 "정답 확인"을 또 눌러도 점수가 두 번 오르지 않게
    setState(() {
      _score++;
      _combo++;
      _userAnswer = null;
    });

    // 다음 문제
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted && !_isGameOver) {
        _generateQuestion();
      }
    });
  }

  void _onWrongAnswer() {
    HapticHelper.vibrate();

    setState(() {
      _combo = 0; // 콤보 리셋
    });
  }

  void _gameOver() async {
    if (_isGameOver) return;
    _timer?.cancel();

    setState(() {
      _isGameOver = true;
    });

    // 최고 기록 저장
    await TimeAttackService.saveHighScore(_score);

    // 별 보상 (2문제당 1개)
    final stars = _starsForScore(_score);
    if (stars > 0) {
      await RewardService.addStars(stars);
    }

    // 게임 오버 다이얼로그
    if (!mounted) return;
    _showGameOverDialog();
  }

  /// 맞힌 문제 2개마다 별 1개
  static int _starsForScore(int score) => score ~/ 2;

  void _showGameOverDialog() {
    final stars = _starsForScore(_score);
    final isNewRecord = _score > _highScore;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => IslandDialog(
        top: Jjakkagi(
          pose: stars > 0 ? MascotPose.cheer : MascotPose.think,
          height: 110,
        ),
        title: isNewRecord ? '신기록이야!' : '시간 끝!',
        message: isNewRecord && _highScore > 0
            ? '60초 동안 $_score문제를 맞췄어요! (이전 기록 $_highScore문제)'
            : '60초 동안 $_score문제를 맞췄어요!',
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: stars > 0 ? AppColors.mapGlow : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.mapStar, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                color: AppColors.treasureOrangeDeep,
                size: 24,
              ),
              SizedBox(width: 6),
              Text(
                stars > 0 ? '별 $stars개를 받았어요!' : '2문제를 맞히면 별을 받아요!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.woodDark,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ChunkyButton(
            label: '다시 도전',
            icon: Icons.refresh_rounded,
            onTap: () {
              Navigator.pop(dialogContext);
              _restartGame();
            },
          ),
          SandChunkyButton(
            label: '놀이 모드로',
            onTap: () {
              Navigator.pop(dialogContext); // 다이얼로그 닫기
              Navigator.pop(context); // 화면 닫기
            },
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    setState(() {
      _timeLeft = 60;
      _score = 0;
      _combo = 0;
      _isGameOver = false;
    });

    _loadData();
    _startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mapSea,
      extendBodyBehindAppBar: true,
      appBar: islandAppBar('타임 어택'),
      body: _theme == null
          ? Center(child: CircularProgressIndicator())
          : MeshBackground(
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildHeader(),
                      SizedBox(height: 24),
                      _buildClock(),
                      SizedBox(height: 24),
                      _buildQuestion(),
                      SizedBox(height: 24),
                      _buildCheckButton(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return GlassContainer(
      padding: EdgeInsets.all(16),
      borderRadius: 16,
      opacity: 0.6,
      child: Column(
        children: [
          // 타이머
          Text(
            '⏰ $_timeLeft초',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _timeLeft <= 10 ? Colors.red : AppColors.hourRed,
            ),
          ),
          SizedBox(height: 8),
          // 점수
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('현재', style: TextStyle(color: AppColors.textLight)),
                  Text(
                    '$_score',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text('최고', style: TextStyle(color: AppColors.textLight)),
                  Text(
                    '$_highScore',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.minuteBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 콤보
          if (_combo >= 3)
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '🔥 $_combo연속!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClock() {
    return SizedBox(
      width: 280,
      height: 280,
      child: AnalogClock(
        // 실제 시각이 아니라 12시에서 시작 (손대기 전엔 정답 확인이 꺼져 있게)
        initialTime: _userAnswer ?? handsStartTime,
        notifyInitialTime: false,
        interactive: true,
        showGuideline: false,
        showMinuteNumbers: false,
        theme: _theme,
        onTimeChanged: (time) {
          setState(() {
            _userAnswer = time;
          });
        },
      ),
    );
  }

  Widget _buildQuestion() {
    if (_currentQuestion == null) return SizedBox();

    return GlassContainer(
      padding: EdgeInsets.all(20),
      borderRadius: 16,
      opacity: 0.8,
      child: Text(
        _currentQuestion!.answerText,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCheckButton() {
    return ChunkyButton(
      label: '정답 확인',
      icon: Icons.check_rounded,
      onTap: _userAnswer == null ? null : _checkAnswer,
    );
  }
}

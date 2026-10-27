import 'dart:async';
import 'package:flutter/material.dart';
import '../models/clock_time.dart';
import '../models/quiz_level.dart';
import '../models/clock_theme.dart';
import '../widgets/analog_clock.dart';
import '../utils/colors.dart';
import '../widgets/island_ui.dart';
import '../utils/clock_answer_validator.dart';
import '../utils/haptic.dart';
import '../services/daily_challenge_service.dart';
import '../services/reward_service.dart';
import '../services/theme_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/mesh_background.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  // 챌린지 상태
  bool _isCompleted = false;
  int _currentQuestionIndex = 0;
  int _streak = 0;

  // 문제 리스트 (3개 고정)
  List<QuizQuestion> _questions = [];
  ClockTime? _userAnswer;

  // 시계 테마
  ClockTheme? _theme;

  // 타이머
  Timer? _countdownTimer;
  bool _finishing = false; // 완료 처리 중
  int _timeUntilReset = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final completed = await DailyChallengeService.isCompletedToday();
    final streak = await DailyChallengeService.getStreak();
    final theme = await ThemeService.getSelectedTheme();

    // 불러오는 사이 화면을 나갔으면 타이머를 만들지 않는다
    if (!mounted) return;
    setState(() {
      _isCompleted = completed;
      _streak = streak;
      _theme = theme;

      if (!completed) {
        _generateQuestions();
      } else {
        _timeUntilReset = DailyChallengeService.getTimeUntilReset();
      }
    });
    _startCountdown();
  }

  void _generateQuestions() {
    // 레벨 3, 4, 5 문제 각 1개씩
    _questions = [
      handsQuestion(QuizLevel.level3),
      handsQuestion(QuizLevel.level4),
      handsQuestion(QuizLevel.level5),
    ];
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeUntilReset = DailyChallengeService.getTimeUntilReset();
      });
    });
  }

  void _checkAnswer() {
    // 마지막 문제를 두 번 눌러 별을 두 번 받지 않게
    if (_finishing || _isCompleted || _userAnswer == null) return;

    final currentQuestion = _questions[_currentQuestionIndex];
    final correctTime = ClockTime(
      hour: currentQuestion.hour,
      minute: currentQuestion.minute,
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

    if (_currentQuestionIndex < _questions.length - 1) {
      // 다음 문제
      setState(() {
        _currentQuestionIndex++;
        _userAnswer = null;
      });
    } else {
      // 챌린지 완료
      _completeChallenge();
    }
  }

  void _onWrongAnswer() {
    HapticHelper.vibrate();

    // 오답이지만 다시 시도 가능 (제한 없음)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('다시 시도해보세요!'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _completeChallenge() async {
    if (_finishing) return;
    _finishing = true;
    await DailyChallengeService.completeChallenge();
    final newStreak = await DailyChallengeService.getStreak();

    // 기본 보상
    int stars = 5;

    // 연속 출석 보너스
    if (newStreak >= 30) {
      stars += 10;
    } else if (newStreak >= 7) {
      stars += 5;
    } else if (newStreak >= 3) {
      stars += 2;
    }

    await RewardService.addStars(stars);

    if (!mounted) return;
    setState(() {
      _isCompleted = true;
      _streak = newStreak;
    });

    _showCompletionDialog(stars, newStreak);
  }

  void _showCompletionDialog(int stars, int streak) {
    String? bonusMessage;
    if (streak >= 30) {
      bonusMessage = '30일 연속 보너스 별 10개';
    } else if (streak >= 7) {
      bonusMessage = '7일 연속 보너스 별 5개';
    } else if (streak >= 3) {
      bonusMessage = '3일 연속 보너스 별 2개';
    }

    Widget chip(String text) => Container(
      margin: EdgeInsets.only(top: 6),
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
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.woodDark,
            ),
          ),
        ],
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => IslandDialog(
        top: Jjakkagi(pose: MascotPose.cheer, height: 110),
        title: '오늘의 도전 성공!',
        message: '$streak일째 이어서 도전했어요!',
        body: Column(
          children: [
            chip('별 $stars개를 받았어요!'),
            if (bonusMessage != null) chip(bonusMessage),
          ],
        ),
        actions: [
          ChunkyButton(
            label: '확인',
            icon: Icons.check_rounded,
            onTap: () {
              Navigator.pop(dialogContext); // 다이얼로그 닫기
              Navigator.pop(context); // 화면 닫기
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours시간 $minutes분';
    } else if (minutes > 0) {
      return '$minutes분 $secs초';
    } else {
      return '$secs초';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mapSea,
      extendBodyBehindAppBar: true,
      appBar: islandAppBar('데일리 챌린지'),
      body: _theme == null
          ? Center(child: CircularProgressIndicator())
          : MeshBackground(
              child: _isCompleted
                  ? _buildCompletedView()
                  : _buildChallengeView(),
            ),
    );
  }

  Widget _buildCompletedView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 100, color: AppColors.success),
            SizedBox(height: 24),
            Text(
              '오늘 챌린지 완료!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 16),
            GlassContainer(
              padding: EdgeInsets.all(20),
              borderRadius: 16,
              opacity: 0.8,
              child: Column(
                children: [
                  Text(
                    '🔥 $_streak일 연속 출석',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '다음 챌린지까지',
                    style: TextStyle(fontSize: 16, color: AppColors.textLight),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _formatTime(_timeUntilReset),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.hourRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeView() {
    final currentQuestion = _questions[_currentQuestionIndex];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildClock(),
            SizedBox(height: 24),
            _buildQuestion(currentQuestion),
            SizedBox(height: 24),
            _buildCheckButton(),
          ],
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
          // 진행도
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final completed = index < _currentQuestionIndex;
              final current = index == _currentQuestionIndex;

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 60,
                height: 8,
                decoration: BoxDecoration(
                  color: completed || current
                      ? AppColors.hourRed
                      : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          SizedBox(height: 12),
          Text(
            '${_currentQuestionIndex + 1} / 3',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '🔥 $_streak일 연속',
            style: TextStyle(fontSize: 16, color: AppColors.textLight),
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

  Widget _buildQuestion(QuizQuestion question) {
    return GlassContainer(
      padding: EdgeInsets.all(20),
      borderRadius: 16,
      opacity: 0.8,
      child: Text(
        question.answerText,
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

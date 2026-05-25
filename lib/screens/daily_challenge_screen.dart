import 'dart:async';
import 'package:flutter/material.dart';
import '../models/clock_time.dart';
import '../models/quiz_level.dart';
import '../models/clock_theme.dart';
import '../widgets/analog_clock.dart';
import '../utils/colors.dart';
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

    setState(() {
      _isCompleted = completed;
      _streak = streak;
      _theme = theme;

      if (!completed) {
        _generateQuestions();
        _startCountdown();
      } else {
        _timeUntilReset = DailyChallengeService.getTimeUntilReset();
        _startCountdown();
      }
    });
  }

  void _generateQuestions() {
    // 레벨 3, 4, 5 문제 각 1개씩
    _questions = [
      QuizQuestion.random(QuizLevel.level3),
      QuizQuestion.random(QuizLevel.level4),
      QuizQuestion.random(QuizLevel.level5),
    ];
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _timeUntilReset = DailyChallengeService.getTimeUntilReset();
      });
    });
  }

  void _checkAnswer() {
    if (_userAnswer == null) return;

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

    setState(() {
      _isCompleted = true;
      _streak = newStreak;
    });

    _showCompletionDialog(stars, newStreak);
  }

  void _showCompletionDialog(int stars, int streak) {
    String bonusMessage = '';
    if (streak >= 30) {
      bonusMessage = '🎉 30일 연속! +10 보너스!';
    } else if (streak >= 7) {
      bonusMessage = '🔥 7일 연속! +5 보너스!';
    } else if (streak >= 3) {
      bonusMessage = '✨ 3일 연속! +2 보너스!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          '🎊 챌린지 완료!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '⭐ +$stars 별 획득!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '🔥 $streak일 연속 출석',
                    style: TextStyle(fontSize: 18, color: AppColors.textDark),
                  ),
                  if (bonusMessage.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      bonusMessage,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.hourRed,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 화면 닫기
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.hourRed),
            child: Text('확인', style: TextStyle(color: Colors.white)),
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
      backgroundColor: AppColors.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '데일리 챌린지',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textDark),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
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
        initialTime: _userAnswer,
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
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _userAnswer == null ? null : _checkAnswer,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.hourRed,
          disabledBackgroundColor: AppColors.borderLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          '정답 확인',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

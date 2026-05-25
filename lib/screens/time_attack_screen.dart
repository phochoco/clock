import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/clock_time.dart';
import '../models/quiz_level.dart';
import '../models/clock_theme.dart';
import '../widgets/analog_clock.dart';
import '../utils/colors.dart';
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
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _gameOver();
        }
      });
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
      _currentQuestion = QuizQuestion.random(level);
      _userAnswer = null;
    });
  }

  void _checkAnswer() {
    if (_userAnswer == null || _currentQuestion == null) return;

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

    setState(() {
      _score++;
      _combo++;

      // 기본 보너스 시간
      _timeLeft += 5;

      // 연속 정답 보너스
      if (_combo == 3) {
        _timeLeft += 2;
      } else if (_combo == 5) {
        _timeLeft += 3;
      } else if (_combo == 10) {
        _timeLeft += 5;
      }

      // 최대 시간 제한 (120초)
      if (_timeLeft > 120) _timeLeft = 120;
    });

    // 다음 문제
    Future.delayed(Duration(milliseconds: 500), () {
      if (!_isGameOver) {
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
    _timer?.cancel();

    setState(() {
      _isGameOver = true;
    });

    // 최고 기록 저장
    await TimeAttackService.saveHighScore(_score);

    // 별 보상 (10문제당 1개)
    final stars = _score ~/ 10;
    if (stars > 0) {
      await RewardService.addStars(stars);
    }

    // 게임 오버 다이얼로그
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    final stars = _score ~/ 10;
    final isNewRecord = _score > _highScore;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isNewRecord ? '🎉 신기록!' : '⏰ 시간 종료!',
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
            Text(
              '점수: $_score',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            if (isNewRecord)
              Text(
                '이전 기록: $_highScore',
                style: TextStyle(fontSize: 16, color: AppColors.textLight),
              ),
            SizedBox(height: 16),
            if (stars > 0)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⭐ +$stars 별 획득!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 화면 닫기
            },
            child: Text('홈으로'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restartGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.hourRed),
            child: Text('다시 도전', style: TextStyle(color: Colors.white)),
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
      backgroundColor: AppColors.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '타임 어택',
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

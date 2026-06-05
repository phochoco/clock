import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/clock_time.dart';
import '../models/quiz_level.dart';
import '../models/quiz_session.dart';
import '../models/reward.dart';
import '../models/clock_theme.dart';
import '../services/reward_service.dart';
import '../services/theme_service.dart';
import '../services/tts_service.dart';
import '../utils/colors.dart';
import '../utils/haptic.dart';
import '../widgets/analog_clock.dart';
import '../widgets/mesh_background.dart';

/// 퀴즈 모드 화면
/// 5단계 레벨 시스템으로 시계 읽기 연습
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.initialLevel = QuizLevel.level1});

  final QuizLevel initialLevel;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int questionsPerLevel = 5; // 레벨당 문제 수

  late final QuizSession _session;
  var _isSavingAnswer = false;
  var _questionToken = 0;
  final GlobalKey<AnalogClockState> _clockKey = GlobalKey();

  // 선택된 테마
  ClockTheme _selectedTheme = ClockThemeList.basic;

  // 오디오 플레이어
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _session = QuizSession(questionsPerLevel: questionsPerLevel);
    _session.start(level: widget.initialLevel);
    _loadTheme();
    _initTts();
    _speakCurrentQuestion();
  }

  Future<void> _initTts() async {
    await TtsService.initialize();
  }

  @override
  void dispose() {
    TtsService.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final theme = await ThemeService.getSelectedTheme();
    if (!mounted) return;
    setState(() {
      _selectedTheme = theme;
    });
  }

  void _speakCurrentQuestion() {
    final question = _session.currentQuestion;
    if (question == null) return;
    final token = ++_questionToken;
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted && token == _questionToken) {
        TtsService.speak('${question.answerText}을 만들어봐요!');
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _session.nextQuestion();
      _clockKey.currentState?.setTime(ClockTime(hour: 12, minute: 0));
    });
    _speakCurrentQuestion();
  }

  void _switchLevel(QuizLevel level) {
    setState(() {
      _session.switchLevel(level);
      _clockKey.currentState?.setTime(ClockTime(hour: 12, minute: 0));
    });
    _speakCurrentQuestion();
  }

  void _retryQuestion() {
    setState(() {
      _session.retryQuestion();
      _clockKey.currentState?.setTime(ClockTime(hour: 12, minute: 0));
    });
  }

  Future<void> _checkAnswer() async {
    if (_isSavingAnswer ||
        _session.userAnswer == null ||
        _session.currentQuestion == null) {
      return;
    }

    final result = _session.answer(_session.userAnswer!);
    setState(() => _isSavingAnswer = result.isCorrect);

    if (result.isCorrect) {
      await RewardService.addStars(result.earnedStars);
      await _audioPlayer.play(AssetSource('good/good.mp3'));
      HapticHelper.heavyImpact();
    } else {
      HapticHelper.vibrate();
    }

    if (!mounted) return;
    setState(() => _isSavingAnswer = false);
  }

  void _showLevelCompleteDialog() async {
    // 레벨 완료 기록
    await RewardService.completeLevel(_session.currentLevel.number);

    // 완벽한 클리어 보너스 (5/5 정답)
    if (_session.score == questionsPerLevel) {
      await RewardService.addStars(3); // 보너스 별 3개
    }

    // 보물 획득
    final reward = RewardList.getRewardForLevel(_session.currentLevel.number);
    if (reward != null) {
      await RewardService.unlockReward(reward.id);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🎉 레벨 완료!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$questionsPerLevel문제 중 ${_session.score}문제를 맞췄습니다!',
              textAlign: TextAlign.center,
            ),
            if (reward != null) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(reward.icon, size: 48, color: reward.iconColor),
                    SizedBox(height: 8),
                    Text(
                      '${reward.name} 받았어요!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 현재 레벨 다시 시작
              setState(() {
                _session.switchLevel(_session.currentLevel);
                _clockKey.currentState?.setTime(ClockTime(hour: 12, minute: 0));
              });
              _speakCurrentQuestion();
            },
            child: Text('다시 하기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final nextLevel = _session.currentLevel.next;
              if (nextLevel != null) {
                setState(() {
                  _session.switchLevel(nextLevel);
                  _clockKey.currentState?.setTime(
                    ClockTime(hour: 12, minute: 0),
                  );
                });
                _speakCurrentQuestion();
              } else {
                // 마지막 레벨 완료 - 특별 축하 메시지
                _showAllLevelsCompleteDialog();
              }
            },
            child: Text('다음 레벨'),
          ),
        ],
      ),
    );
  }

  void _showAllLevelsCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            Text('🎊', style: TextStyle(fontSize: 60)),
            SizedBox(height: 8),
            Text(
              '모든 레벨 완료!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '축하합니다!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '레벨 1부터 레벨 5까지\n모두 성공하였습니다!',
              style: TextStyle(fontSize: 16, color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('🎁', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 8),
                  Text(
                    '모든 무료 시계를\n열었습니다!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 퀴즈 화면 닫기
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.appleBlue,
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text(
              '확인',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTopBar(),
                SizedBox(height: 20),
                _buildLevelSelector(),
                SizedBox(height: 20),
                _buildQuestionArea(),
                SizedBox(height: 20),
                if (!_session.showResult) _buildCheckButton(),
                if (_session.showResult) _buildResultArea(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, size: 28),
            color: AppColors.textDark,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              '퀴즈 도전',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_session.score} / $questionsPerLevel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: QuizLevel.values.length,
        itemBuilder: (context, index) {
          final level = QuizLevel.values[index];
          final isSelected = level == _session.currentLevel;

          return GestureDetector(
            onTap: () => _switchLevel(level),
            child: Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.appleBlue : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Lv.${level.number}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionArea() {
    if (_session.currentQuestion == null) return SizedBox();

    return Column(
      children: [
        // 문제 텍스트
        Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '이 시간을 만들어봐요!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 12),
              Text(
                _session.currentQuestion!.answerText,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.appleBlue,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 30),

        // 시계
        SizedBox(
          width: 280,
          height: 280,
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
        ),
      ],
    );
  }

  Widget _buildCheckButton() {
    final canCheck = _session.userAnswer != null && !_isSavingAnswer;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: canCheck ? _checkAnswer : null,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: canCheck ? AppColors.minuteBlue : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
            boxShadow: canCheck
                ? [
                    BoxShadow(
                      color: AppColors.minuteBlue.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              '정답 확인',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: canCheck ? Colors.white : Colors.grey[500],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: _session.isCorrect
          ? // 정답일 때: 메시지와 버튼을 하나의 박스로 통합
            Container(
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // 상단: 정답 메시지 영역 (모두 한 줄로)
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 22),
                        SizedBox(width: 6),
                        Text(
                          '정답이에요!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          '⭐ +${_session.lastEarnedStars}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        // 콤보 메시지도 같은 줄에
                        if (_session.showCombo) ...[
                          SizedBox(width: 6),
                          Text(
                            _session.comboMessage,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 하단: 다음 버튼
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: GestureDetector(
                      onTap: _isSavingAnswer
                          ? null
                          : () {
                              // 5문제 완료 체크
                              if (_session.score >= questionsPerLevel) {
                                // 레벨 완료!
                                _showLevelCompleteDialog();
                              } else {
                                // 다음 문제
                                _nextQuestion();
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _isSavingAnswer ? '별 저장 중' : '다음 문제',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : // 오답일 때: 기존 방식 유지
            Column(
              children: [
                Text(
                  '다시 한번 해볼까요? 😊',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    // 오답일 때: 다시 시도 (결과만 숨김 + 시계 리셋)
                    _retryQuestion();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '다시 시도',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/clock_time.dart';
import '../models/quiz_level.dart';
import '../models/reward.dart';
import '../models/clock_theme.dart';
import '../services/reward_service.dart';
import '../services/theme_service.dart';
import '../services/tts_service.dart';
import '../utils/colors.dart';
import '../utils/haptic.dart';
import '../widgets/analog_clock.dart';

/// 퀴즈 모드 화면
/// 5단계 레벨 시스템으로 시계 읽기 연습
class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);
  
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int questionsPerLevel = 5; // 레벨당 문제 수
  
  QuizLevel _currentLevel = QuizLevel.level1;
  QuizQuestion? _currentQuestion;
  QuizQuestion? _previousQuestion; // 이전 문제 저장 (중복 방지용)
  ClockTime? _userAnswer;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _totalQuestions = 0;
  final GlobalKey<AnalogClockState> _clockKey = GlobalKey();
  
  // 콤보 시스템
  int _combo = 0;
  String _comboMessage = '';
  bool _showCombo = false;
  
  // 선택된 테마
  ClockTheme _selectedTheme = ClockThemeList.basic;
  
  // 오디오 플레이어
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  @override
  void initState() {
    super.initState();
    _loadTheme();
    _initTts();
    _generateQuestion();
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
    setState(() {
      _selectedTheme = theme;
    });
  }
  
  void _generateQuestion() {
    QuizQuestion newQuestion;
    int attempts = 0;
    const maxAttempts = 10; // 무한 루프 방지
    
    // 이전 문제와 다른 문제가 나올 때까지 반복
    do {
      newQuestion = QuizQuestion.random(_currentLevel);
      attempts++;
    } while (
      _previousQuestion != null &&
      newQuestion.hour == _previousQuestion!.hour &&
      newQuestion.minute == _previousQuestion!.minute &&
      attempts < maxAttempts
    );
    
    setState(() {
      _previousQuestion = _currentQuestion; // 현재 문제를 이전 문제로 저장
      _currentQuestion = newQuestion;
      _userAnswer = null;
      _showResult = false;
      _isCorrect = false;
      _showCombo = false; // 콤보 메시지 숨기기
    });
    
    // 문제 읽어주기 (화면 갱신 후 실행)
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        TtsService.speak('${newQuestion.answerText}을 만들어보세요!');
      }
    });
  }
  
  void _checkAnswer() async {
    if (_userAnswer == null || _currentQuestion == null) return;
    
    // 정답 시간을 ClockTime으로 변환
    final correctTime = ClockTime(
      hour: _currentQuestion!.hour,
      minute: _currentQuestion!.minute,
    );
    
    // 시침 각도로 비교 (±15도 허용 = 약 30분 오차)
    final userHourAngle = _userAnswer!.hourAngle;
    final correctHourAngle = correctTime.hourAngle;
    
    var hourAngleDiff = (userHourAngle - correctHourAngle).abs();
    if (hourAngleDiff > 180) {
      hourAngleDiff = 360 - hourAngleDiff;
    }
    final hourMatch = hourAngleDiff <= 15.0;
    
    print('User hour angle: $userHourAngle, Correct hour angle: $correctHourAngle, Hour diff: $hourAngleDiff');
    
    // 분침 각도로 비교
    var userMinuteAngle = _userAnswer!.minuteAngle;
    var correctMinuteAngle = correctTime.minuteAngle;
    
    // 각도 정규화 (0-360 범위로)
    userMinuteAngle = userMinuteAngle % 360;
    if (userMinuteAngle < 0) userMinuteAngle += 360;
    correctMinuteAngle = correctMinuteAngle % 360;
    if (correctMinuteAngle < 0) correctMinuteAngle += 360;
    
    // 각도 차이 계산 (360도 순환 고려)
    var angleDiff = (userMinuteAngle - correctMinuteAngle).abs();
    if (angleDiff > 180) {
      angleDiff = 360 - angleDiff;
    }
    
    print('User minute angle: $userMinuteAngle, Correct minute angle: $correctMinuteAngle, Minute diff: $angleDiff');
    
    // ±10도 허용 (약 ±1.7분)
    final minuteMatch = angleDiff <= 10.0;
    
    final correct = hourMatch && minuteMatch;
    
    setState(() {
      _showResult = true;
      _isCorrect = correct;
      _totalQuestions++;
      if (correct) {
        _score++;
        
        // 정답 음성 재생 (MP3)
        _audioPlayer.play(AssetSource('good/good.mp3'));
        
        // 콤보 증가
        _combo++;
        
        // 별 획득 (기본 1개)
        int starsEarned = 1;
        
        // 콤보에 따른 메시지 및 보너스 별
        if (_combo == 2) {
          _comboMessage = 'Good! 🎉';
          _showCombo = true;
        } else if (_combo == 3) {
          _comboMessage = 'Great! 🌟';
          _showCombo = true;
          starsEarned = 2; // 보너스 별
        } else if (_combo >= 5) {
          _comboMessage = 'Perfect! 🔥';
          _showCombo = true;
          starsEarned = 3; // 더 많은 보너스
        }
        
        // 별 저장
        RewardService.addStars(starsEarned);
        
        HapticHelper.heavyImpact();
      } else {
        // 오답 시 콤보 리셋
        _combo = 0;
        _showCombo = false;
        HapticHelper.vibrate();
      }
    });
  }
  
  // 획득한 별 개수 계산
  int _getStarsEarned() {
    if (_combo >= 5) return 3;
    if (_combo >= 3) return 2;
    return 1;
  }
  
  void _showLevelCompleteDialog() async {
    // 레벨 완료 기록
    await RewardService.completeLevel(_currentLevel.number);
    
    // 완벽한 클리어 보너스 (5/5 정답)
    if (_score == questionsPerLevel) {
      await RewardService.addStars(3); // 보너스 별 3개
    }
    
    // 보물 획득
    final reward = RewardList.getRewardForLevel(_currentLevel.number);
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
              '$questionsPerLevel문제 중 $_score문제를 맞췄습니다!',
              textAlign: TextAlign.center,
            ),
            if (reward != null) ...[
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      reward.emoji,
                      style: TextStyle(fontSize: 48),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${reward.name} 획득!',
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
                _score = 0;
                _totalQuestions = 0;
                _generateQuestion();
              });
            },
            child: Text('다시 하기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final nextLevel = _currentLevel.next;
              if (nextLevel != null) {
                setState(() {
                  _currentLevel = nextLevel;
                  _score = 0;
                  _totalQuestions = 0;
                  _generateQuestion();
                });
              } else {
                // 마지막 레벨 완료 - 특별 축하 메시지
                Navigator.pop(context); // 레벨 완료 다이얼로그 닫기
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
            Text(
              '🎊',
              style: TextStyle(fontSize: 60),
            ),
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
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentYellow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '🎁',
                    style: TextStyle(fontSize: 48),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '모든 무료 테마가\n해금되었습니다!',
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
              backgroundColor: AppColors.hourRed,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentMint.withOpacity(0.3),
              AppColors.accentPink.withOpacity(0.3),
            ],
          ),
        ),
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
                if (!_showResult) _buildCheckButton(),
                if (_showResult) _buildResultArea(),
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
              '$_score / $questionsPerLevel',
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
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: QuizLevel.values.length,
        itemBuilder: (context, index) {
          final level = QuizLevel.values[index];
          final isSelected = level == _currentLevel;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentLevel = level;
                _generateQuestion();
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentPink : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
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
    if (_currentQuestion == null) return SizedBox();
    
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '이 시간을 만들어보세요!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 12),
              Text(
                _currentQuestion!.answerText,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.hourRed,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 30),
        
        // 시계
        Container(
          width: 280,
          height: 280,
          child: AnalogClock(
            key: _clockKey,
            initialTime: ClockTime(hour: 12, minute: 0),
            onTimeChanged: (time) {
              setState(() {
                _userAnswer = time;
              });
            },
            showGuideline: true,
            showMinuteNumbers: _currentLevel.index >= 2,
            theme: _selectedTheme, // 선택된 테마 적용
          ),
        ),
      ],
    );
  }
  
  Widget _buildCheckButton() {
    final canCheck = _userAnswer != null;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: canCheck ? _checkAnswer : null,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: canCheck ? AppColors.accentMint : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
            boxShadow: canCheck
                ? [
                    BoxShadow(
                      color: AppColors.accentMint.withOpacity(0.4),
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
      child: _isCorrect
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
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 22,
                        ),
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
                          '⭐ +${_getStarsEarned()}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        // 콤보 메시지도 같은 줄에
                        if (_showCombo) ...[
                          SizedBox(width: 6),
                          Text(
                            '$_comboMessage',
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
                      onTap: () {
                        // 5문제 완료 체크
                        if (_score >= questionsPerLevel) {
                          // 레벨 완료!
                          _showLevelCompleteDialog();
                        } else {
                          // 다음 문제
                          _generateQuestion();
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
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '다음 문제',
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
                    setState(() {
                      _showResult = false;
                      _userAnswer = null;
                    });
                    // 시계를 초기 위치(12:00)로 리셋
                    _clockKey.currentState?.setTime(ClockTime(hour: 12, minute: 0));
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.accentYellow,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentYellow.withOpacity(0.4),
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

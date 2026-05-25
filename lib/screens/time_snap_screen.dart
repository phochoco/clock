import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/colors.dart';
import '../utils/haptic.dart';
import '../widgets/glass_container.dart';
import '../widgets/mesh_background.dart';
import '../widgets/analog_clock.dart';
import '../models/clock_time.dart';
import '../models/clock_theme.dart';
import '../services/theme_service.dart';
import '../services/reward_service.dart';

class TimeSnapScreen extends StatefulWidget {
  const TimeSnapScreen({super.key});

  @override
  State<TimeSnapScreen> createState() => _TimeSnapScreenState();
}

class _TimeSnapScreenState extends State<TimeSnapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  ClockTime _targetTime = ClockTime(hour: 3, minute: 0);
  ClockTime _currentTime = ClockTime(hour: 12, minute: 0);

  bool _isPlaying = false;
  bool _isResult = false;
  String _judgmentText = '';
  Color _judgmentColor = Colors.white;
  int _combo = 0;
  int _score = 0;

  ClockTheme _selectedTheme = ClockThemeList.basic;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadTheme();

    // 빙글빙글 고속 회전 애니메이션 컨트롤러 (약 2.5초에 1바퀴=12시간)
    _spinController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2500),
    );

    _spinAnimation =
        Tween<double>(begin: 0, end: 12 * 60).animate(
          CurvedAnimation(parent: _spinController, curve: Curves.linear),
        )..addListener(() {
          if (_isPlaying) {
            // 총 분(minute)으로 환산된 값을 시/분으로 변환
            final totalMinutes = _spinAnimation.value.floor();
            final h = (totalMinutes ~/ 60) % 12;
            final m = totalMinutes % 60;
            setState(() {
              _currentTime = ClockTime(hour: h == 0 ? 12 : h, minute: m);
            });
          }
        });

    _startNewRound();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final theme = await ThemeService.getSelectedTheme();
    if (mounted) {
      setState(() {
        _selectedTheme = theme;
      });
    }
  }

  void _startNewRound() {
    final random = Random();
    int hour = random.nextInt(12) + 1;
    // 0분 또는 30분 단위 (난이도 조절)
    int minute = random.nextBool() ? 0 : 30;

    setState(() {
      _targetTime = ClockTime(hour: hour, minute: minute);
      _currentTime = ClockTime(hour: 12, minute: 0);
      _isResult = false;
      _judgmentText = '준비...';
      _judgmentColor = AppColors.textLight;
    });

    // 약간 대기 후 자동 시작
    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _judgmentText = '';
        });
        _spinController.repeat(); // 무한 회전
      }
    });
  }

  void _onStopPressed() {
    if (!_isPlaying) return;

    _spinController.stop();
    setState(() {
      _isPlaying = false;
      _isResult = true;
      _checkJudgment();
    });
  }

  void _checkJudgment() {
    // 목표 시간과 멈춘 시간의 분(minute) 단위 총 차이 계산
    int targetTotalMin = (_targetTime.hour % 12) * 60 + _targetTime.minute;
    int currentTotalMin = (_currentTime.hour % 12) * 60 + _currentTime.minute;

    // 12시간 체계에서의 최단 거리 계산 (차이가 12시간=720분을 넘는 경우 보정)
    int diff = (targetTotalMin - currentTotalMin).abs();
    if (diff > 360) diff = 720 - diff;

    // 판정 로직
    if (diff <= 5) {
      // Perfect: 오차 5분 이내 (거의 정확함)
      _judgmentText = 'PERFECT!!';
      _judgmentColor = Colors.amber;
      _audioPlayer.play(AssetSource('good/good.mp3'));
      HapticHelper.heavyImpact();
      _combo++;
      _score += 50 + (_combo * 10);
      _awardStars(3);
    } else if (diff <= 15) {
      // Great: 오차 15분 이내
      _judgmentText = 'GREAT!';
      _judgmentColor = AppColors.success;
      HapticHelper.mediumImpact();
      _combo++;
      _score += 30;
      _awardStars(1);
    } else if (diff <= 30) {
      // Good: 오차 30분 이내
      _judgmentText = 'GOOD';
      _judgmentColor = AppColors.minuteBlue;
      HapticHelper.lightImpact();
      _combo = 0; // 콤보 끊김
      _score += 10;
    } else {
      // Miss: 오차 30분 초과
      _judgmentText = 'MISS...';
      _judgmentColor = AppColors.hourRed;
      HapticHelper.vibrate();
      _combo = 0;
    }

    // 다음 라운드 자동 시작
    Future.delayed(Duration(milliseconds: 2000), () {
      if (mounted) {
        _startNewRound();
      }
    });
  }

  void _awardStars(int amount) {
    if (amount > 0) {
      RewardService.addStars(amount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clockSize = (MediaQuery.of(context).size.width * 0.75)
        .clamp(240.0, 320.0)
        .toDouble();
    int targetHour12 = _targetTime.hour % 12;
    if (targetHour12 == 0) targetHour12 = 12;
    String minStr = _targetTime.minute.toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '빙글빙글 찰칵!',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: 0,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textDark),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 점수/콤보 상단 바
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '점수: $_score',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (_combo > 1)
                      AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber, width: 2),
                        ),
                        child: Text(
                          '$_combo COMBO 🔥',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[800],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // 목표 시간 패널 (헤드업 디스플레이)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GlassContainer(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  borderRadius: 20,
                  width: double.infinity,
                  child: Column(
                    children: [
                      Text(
                        '목표 시간에 바늘을 멈추세요!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '$targetHour12:$minStr',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          letterSpacing: 2,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(flex: 1, child: SizedBox()),

              // 판정 텍스트 (시계 위/배경 아래 겹치게)
              SizedBox(
                height: 50,
                child: AnimatedOpacity(
                  opacity: _isResult || _judgmentText == '준비...' ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 200),
                  child: Text(
                    _judgmentText,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: _judgmentColor,
                      fontStyle: FontStyle.italic,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 회전하는 시계 위젯 (수동 모드로 Animated 시간 강제 주입)
              Center(
                child: SizedBox(
                  width: clockSize,
                  height: clockSize,
                  child: AnalogClock(
                    initialTime: _currentTime,
                    interactive: false, // 손으로 못 움직이게
                    showGuideline: true,
                    showMinuteNumbers: true,
                    theme: _selectedTheme,
                  ),
                ),
              ),

              Expanded(flex: 1, child: SizedBox()),

              // 찰칵! 거대한 STOP 버튼
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: GestureDetector(
                  onTap: _onStopPressed,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 100),
                    width: double.infinity,
                    height: 76,
                    decoration: BoxDecoration(
                      color: _isPlaying
                          ? AppColors.hourRed
                          : AppColors.hourRed.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(38),
                      boxShadow: _isPlaying
                          ? [
                              BoxShadow(
                                color: AppColors.hourRed.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ]
                          : [],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Text(
                        'S T O P !',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/clock_time.dart';
import '../models/clock_theme.dart';
import '../services/theme_service.dart';
import '../utils/colors.dart';
import '../widgets/analog_clock.dart';
import '../widgets/digital_display.dart';

/// 학습 모드 (Playground) 화면
/// 자유롭게 시계를 조작하며 원리를 익히는 화면
class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({Key? key}) : super(key: key);
  
  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  ClockTime _currentTime = ClockTime.now();
  bool _showDigital = true;
  bool _showMinuteNumbers = false;
  ClockTheme? _theme;
  final GlobalKey<AnalogClockState> _clockKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final theme = await ThemeService.getSelectedTheme();
    setState(() {
      _theme = theme;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgCream,
              AppColors.bgPeach.withOpacity(0.5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 상단 바
              _buildTopBar(),
              
              SizedBox(height: 20),
              
              // 디지털 시계 표시
              if (_showDigital)
                DigitalDisplay(time: _currentTime),
              
              SizedBox(height: 20),
              
              // 시계
              Expanded(
                child: Center(
                  child: Container(
                    width: 350,
                    height: 350,
                    child: _theme == null
                        ? Center(child: CircularProgressIndicator())
                        : AnalogClock(
                            key: _clockKey,
                            initialTime: _currentTime,
                            onTimeChanged: (time) {
                              setState(() {
                                _currentTime = time;
                              });
                            },
                            showGuideline: true,
                            showMinuteNumbers: _showMinuteNumbers,
                            theme: _theme,
                          ),
                  ),
                ),
              ),
              
              // 설명 텍스트
              _buildHelpText(),
              
              SizedBox(height: 20),
              
              // 컨트롤 버튼
              _buildControls(),
              
              SizedBox(height: 20),
            ],
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
          // 뒤로가기 버튼
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, size: 28),
            color: AppColors.textDark,
            onPressed: () => Navigator.pop(context),
          ),
          
          Expanded(
            child: Text(
              '시계 배우기',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          
          // 설정 버튼
          PopupMenuButton<String>(
            icon: Icon(Icons.settings_rounded, size: 28, color: AppColors.textDark),
            onSelected: (value) {
              setState(() {
                if (value == 'digital') {
                  _showDigital = !_showDigital;
                } else if (value == 'minutes') {
                  _showMinuteNumbers = !_showMinuteNumbers;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'digital',
                child: Row(
                  children: [
                    Icon(
                      _showDigital ? Icons.check_box : Icons.check_box_outline_blank,
                      color: AppColors.minuteBlue,
                    ),
                    SizedBox(width: 8),
                    Text('디지털 시계 표시'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'minutes',
                child: Row(
                  children: [
                    Icon(
                      _showMinuteNumbers ? Icons.check_box : Icons.check_box_outline_blank,
                      color: AppColors.minuteBlue,
                    ),
                    SizedBox(width: 8),
                    Text('분 숫자 표시'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildHelpText() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.hourRed,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '짧은 바늘 = 시간',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.hourRed,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.minuteBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '긴 바늘 = 분',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.minuteBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            '빠른 시간 설정',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 12),
          // 현재 시간 버튼
          Center(
            child: _buildJumpButton('🕐 현재 시간', () {
              _clockKey.currentState?.resetToCurrentTime();
              setState(() {
                _currentTime = ClockTime.now();
              });
            }, isPrimary: true),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildJumpButton('정각', () {
                final newTime = ClockTime(hour: _currentTime.hour, minute: 0);
                _clockKey.currentState?.setTime(newTime);
                setState(() {
                  _currentTime = newTime;
                });
              }),
              _buildJumpButton('30분', () {
                final newTime = ClockTime(hour: _currentTime.hour, minute: 30);
                _clockKey.currentState?.setTime(newTime);
                setState(() {
                  _currentTime = newTime;
                });
              }),
              _buildJumpButton('15분', () {
                final newTime = ClockTime(hour: _currentTime.hour, minute: 15);
                _clockKey.currentState?.setTime(newTime);
                setState(() {
                  _currentTime = newTime;
                });
              }),
              _buildJumpButton('45분', () {
                final newTime = ClockTime(hour: _currentTime.hour, minute: 45);
                _clockKey.currentState?.setTime(newTime);
                setState(() {
                  _currentTime = newTime;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildJumpButton(String label, VoidCallback onTap, {bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.hourRed : AppColors.accentLavender,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (isPrimary ? AppColors.hourRed : AppColors.accentLavender).withOpacity(0.4),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isPrimary ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

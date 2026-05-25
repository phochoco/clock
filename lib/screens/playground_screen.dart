import 'package:flutter/material.dart';
import '../models/clock_time.dart';
import '../models/clock_theme.dart';
import '../services/theme_service.dart';
import '../utils/colors.dart';
import '../widgets/analog_clock.dart';
import '../widgets/digital_display.dart';
import '../widgets/glass_container.dart';
import '../widgets/mesh_background.dart';

/// 학습 모드 (Playground) 화면
/// 자유롭게 시계를 조작하며 원리를 익히는 화면
class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

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
    final clockSize = (MediaQuery.of(context).size.width - 32)
        .clamp(260.0, 350.0)
        .toDouble();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 상단 바
              _buildTopBar(),

              SizedBox(height: 20),

              // 디지털 시계 표시
              if (_showDigital) DigitalDisplay(time: _currentTime),

              SizedBox(height: 20),

              // 시계
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: clockSize,
                    height: clockSize,
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
            icon: Icon(
              Icons.settings_rounded,
              size: 28,
              color: AppColors.textDark,
            ),
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
                      _showDigital
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
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
                      _showMinuteNumbers
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        padding: EdgeInsets.all(16),
        borderRadius: 20,
        opacity: 0.5,
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
            child: _buildJumpButton(
              '현재 시간',
              () {
                _clockKey.currentState?.resetToCurrentTime();
                setState(() {
                  _currentTime = ClockTime.now();
                });
              },
              isPrimary: true,
              icon: Icons.access_time_filled,
            ),
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

  Widget _buildJumpButton(
    String label,
    VoidCallback onTap, {
    bool isPrimary = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: isPrimary ? double.infinity : null,
      child: GlassContainer(
        onTap: onTap,
        height: 50,
        padding: EdgeInsets.zero, // 이중 박스 방지를 위해 내부 패딩 제거
        borderRadius: 16,
        opacity: isPrimary ? 0.3 : 0.6, // 투명도 조절
        child: Container(
          // GlassContainer 내부에 컬러 레이어를 덧씌움
          padding: EdgeInsets.symmetric(
            horizontal: isPrimary ? 32 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColors.hourRed.withValues(alpha: 0.9)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: isPrimary ? Colors.white : AppColors.textDark,
                  size: 18,
                ),
                SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: isPrimary ? 16 : 14,
                  fontWeight: FontWeight.w700,
                  color: isPrimary ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

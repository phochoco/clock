import 'package:flutter/material.dart';
import '../models/clock_time.dart';
import '../models/clock_theme.dart';
import '../services/theme_service.dart';
import '../utils/colors.dart';
import '../widgets/analog_clock.dart';
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
              _buildTopBar(),

              SizedBox(height: 8),

              if (_showDigital) _buildTimeReadout(),

              SizedBox(height: 14),

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
                            showGuideline: false,
                            showMinuteNumbers: _showMinuteNumbers,
                            theme: ClockThemeList.basic,
                          ),
                  ),
                ),
              ),

              _buildHelpText(),

              SizedBox(height: 16),

              _buildControls(),

              SizedBox(height: 18),
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
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),

          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_horiz_rounded,
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
                      color: AppColors.appleBlue,
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
                      color: AppColors.appleBlue,
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

  Widget _buildTimeReadout() {
    final hour = _currentTime.hour12.toString().padLeft(2, '0');
    final minute = _currentTime.minute.toString().padLeft(2, '0');

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        opacity: 0.78,
        blurRadius: 18,
        borderRadius: 28,
        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '지금 만든 시간',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textLight,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        hour,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          color: AppColors.appleRed,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          ':',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Text(
                        minute,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          color: AppColors.appleBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              _currentTime.isAM ? 'AM' : 'PM',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpText() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        borderRadius: 24,
        opacity: 0.78,
        blurRadius: 18,
        child: Column(
          children: [
            Text(
              '바늘을 손가락으로 돌려 보세요',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.appleRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '짧은 바늘 = 시간',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.appleRed,
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
                    color: AppColors.appleBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '긴 바늘 = 분',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.appleBlue,
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
            '바로 맞춰 보기',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textLight,
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
        borderRadius: 25,
        opacity: isPrimary ? 0.92 : 0.78,
        blurRadius: 18,
        child: Container(
          // GlassContainer 내부에 컬러 레이어를 덧씌움
          padding: EdgeInsets.symmetric(
            horizontal: isPrimary ? 32 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isPrimary ? AppColors.appleBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
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

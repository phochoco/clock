import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/clock_time.dart';
import '../models/clock_theme.dart';
import '../utils/haptic.dart';
import 'clock_painter.dart';

/// 인터랙티브 아날로그 시계 위젯
/// Geared Movement와 원형 제스처 인식 구현
class AnalogClock extends StatefulWidget {
  final ClockTime? initialTime;
  final Function(ClockTime)? onTimeChanged;
  final bool interactive;
  final bool showGuideline;
  final bool showMinuteNumbers;
  final ClockTheme? theme; // 테마 추가
  
  const AnalogClock({
    Key? key,
    this.initialTime,
    this.onTimeChanged,
    this.interactive = true,
    this.showGuideline = true,
    this.showMinuteNumbers = false,
    this.theme,
  }) : super(key: key);
  
  @override
  State<AnalogClock> createState() => AnalogClockState();
}

class AnalogClockState extends State<AnalogClock> with SingleTickerProviderStateMixin {
  late double _minuteAngle;
  late double _hourAngle;
  double _secondAngle = 0.0;
  int _lastHapticQuarter = -1;
  Timer? _secondTimer;
  bool _isManualMode = false; // 수동 모드 플래그
  
  // 별 깜빡임 애니메이션
  late AnimationController _flickerController;
  late Animation<double> _flickerAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // 깜빡임 애니메이션 초기화
    _flickerController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _flickerAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _flickerController, curve: Curves.easeInOut),
    );
    
    // 현재 시간으로 초기화
    final now = ClockTime.now();
    _minuteAngle = now.minuteAngle;
    _hourAngle = now.hourAngle;
    _secondAngle = now.secondAngle;
    
    // 첫 프레임 후 현재 시간을 알림
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onTimeChanged != null && mounted) {
        widget.onTimeChanged!(ClockTime.now());
      }
    });
    
    // 1초마다 업데이트
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_isManualMode) {
          // 수동 모드: 초침만 업데이트
          setState(() {
            _secondAngle = (_secondAngle + 6) % 360;
          });
        } else {
          // 자동 모드: 현재 시간으로 전체 업데이트
          final currentTime = ClockTime.now();
          setState(() {
            _minuteAngle = currentTime.minuteAngle;
            _hourAngle = currentTime.hourAngle;
            _secondAngle = currentTime.secondAngle;
          });
          
          // 현재 시간을 직접 알림
          if (widget.onTimeChanged != null) {
            widget.onTimeChanged!(currentTime);
          }
        }
      }
    });
  }
  
  @override
  void dispose() {
    _secondTimer?.cancel();
    _flickerController.dispose(); // 애니메이션 컨트롤러 정리
    super.dispose();
  }
  
  /// 외부에서 시간 설정 (빠른 시간 설정 버튼용)
  void setTime(ClockTime time) {
    setState(() {
      _isManualMode = true; // 수동 모드로 전환
      _minuteAngle = time.minuteAngle;
      _hourAngle = time.hourAngle;
      _secondAngle = time.secondAngle;
    });
  }
  
  /// 현재 시간으로 리셋 (자동 모드로 복원)
  void resetToCurrentTime() {
    setState(() {
      _isManualMode = false; // 자동 모드로 전환
      final now = ClockTime.now();
      _minuteAngle = now.minuteAngle;
      _hourAngle = now.hourAngle;
      _secondAngle = now.secondAngle;
    });
    
    // 현재 시간을 즉시 알림
    if (widget.onTimeChanged != null) {
      widget.onTimeChanged!(ClockTime.now());
    }
  }
  
  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    // initialTime 업데이트를 무시
    // 사용자가 시계를 조작하는 중에는 누적 각도를 유지해야 함
  }
  
  /// 원형 제스처 처리 (atan2 기반)
  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    if (!widget.interactive) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final position = details.localPosition;
    
    // 중심점으로부터의 상대 좌표
    final dx = position.dx - center.dx;
    final dy = position.dy - center.dy;
    
    // atan2를 사용한 각도 계산 (라디안 -> 도)
    // -90도 오프셋: 12시 방향을 0도로 만들기 위함
    double currentAngle = atan2(dy, dx) * 180 / pi + 90;
    if (currentAngle < 0) currentAngle += 360;
    
    // 1분 단위로 스냅 (6도 = 1분)
    // 각도를 6도 단위로 반올림
    double snappedAngle = (currentAngle / 6).round() * 6.0;
    if (snappedAngle >= 360) snappedAngle = 0;
    
    // 이전 각도와 비교하여 누적 각도 계산
    double previousNormalized = _minuteAngle % 360;
    if (previousNormalized < 0) previousNormalized += 360;
    
    // 각도 차이 계산 (360도 경계 처리)
    double delta = snappedAngle - previousNormalized;
    if (delta > 180) delta -= 360;  // 시계 반대 방향으로 큰 점프
    if (delta < -180) delta += 360; // 시계 방향으로 큰 점프
    
    setState(() {
      _isManualMode = true; // 수동 모드로 전환
      // 누적 각도 업데이트
      _minuteAngle += delta;
      
      // Geared Movement: 분침 360도 회전 = 시침 30도 회전
      // 분침 각도를 12로 나누면 시침 각도
      _hourAngle = _minuteAngle / 12.0;
    });
    
    // 햅틱 피드백 (5분 단위마다)
    HapticHelper.lightImpact();
    
    // 콜백 호출
    _notifyTimeChanged();
  }
  
  /// 12, 3, 6, 9 지점에서 햅틱 피드백
  void _triggerHapticAtQuarters() {
    final quarter = (_minuteAngle / 90).floor();
    if (quarter != _lastHapticQuarter) {
      HapticHelper.lightImpact();
      _lastHapticQuarter = quarter;
      
      // 정각(12시 방향)에서는 중간 강도 피드백
      if (_minuteAngle < 5 || _minuteAngle > 355) {
        HapticHelper.mediumImpact();
      }
    }
  }
  
  /// 시간 변경 콜백
  void _notifyTimeChanged() {
    if (widget.onTimeChanged != null) {
      final time = ClockTime.fromMinuteAngle(_minuteAngle);
      widget.onTimeChanged!(time);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // 테마가 없으면 기본 테마 사용
    final theme = widget.theme ?? ClockThemeList.basic;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        
        return GestureDetector(
          behavior: HitTestBehavior.opaque, // 터치 영역 확대
          onPanStart: (details) => _handlePanUpdate(
            DragUpdateDetails(
              globalPosition: details.globalPosition,
              localPosition: details.localPosition,
              delta: Offset.zero,
              primaryDelta: 0,
            ),
            size,
          ),
          onPanUpdate: (details) => _handlePanUpdate(details, size),
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.theme?.backgroundGradient,
              color: widget.theme?.backgroundGradient == null ? widget.theme?.backgroundColor : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _flickerAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ClockPainter(
                    hourAngle: _hourAngle,
                    minuteAngle: _minuteAngle,
                    secondAngle: _secondAngle,
                    showGuideline: widget.showGuideline,
                    showMinuteNumbers: widget.showMinuteNumbers,
                    theme: widget.theme,
                    flickerValue: _flickerAnimation.value, // 애니메이션 값 전달
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

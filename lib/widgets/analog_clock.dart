import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final bool notifyInitialTime;
  final ClockTheme? theme; // 테마 추가

  const AnalogClock({
    super.key,
    this.initialTime,
    this.onTimeChanged,
    this.interactive = true,
    this.showGuideline = true,
    this.showMinuteNumbers = false,
    this.notifyInitialTime = true,
    this.theme,
  });

  @override
  State<AnalogClock> createState() => AnalogClockState();
}

class AnalogClockState extends State<AnalogClock>
    with SingleTickerProviderStateMixin {
  late double _minuteAngle;
  late double _hourAngle;
  double _secondAngle = 0.0;
  int _lastHapticQuarter = -1;
  Timer? _secondTimer;
  bool _isManualMode = false; // 수동 모드 플래그

  // 별 깜빡임 애니메이션
  late AnimationController _flickerController;
  late Animation<double> _flickerAnimation;

  // 비동기 로드된 테마 배경 이미지
  ui.Image? _backgroundImage;

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

    // 현재 시간으로 초기화 (initialTime이 있으면 해당 시간 사용)
    final now = widget.initialTime ?? ClockTime.now();
    _minuteAngle = now.minuteAngle;
    _hourAngle = now.hourAngle;
    _secondAngle = now.secondAngle;

    if (widget.initialTime != null) {
      _isManualMode = true; // 지정된 시작 시간이 있으면 수동 모드로 고정
    }

    if (widget.notifyInitialTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.onTimeChanged != null && mounted) {
          widget.onTimeChanged!(now);
        }
      });
    }

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

    // 배경 이미지 로드 시도
    _loadBackgroundImage(widget.theme?.backgroundImage);
  }

  /// 이미지 에셋을 비동기로 로드하여 ui.Image 로 변환
  Future<void> _loadBackgroundImage(String? path) async {
    if (path == null) {
      if (mounted) setState(() => _backgroundImage = null);
      return;
    }
    try {
      final ByteData data = await rootBundle.load(path);
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _backgroundImage = fi.image;
        });
      }
    } catch (e) {
      debugPrint('Failed to load background image: $e');
      if (mounted) setState(() => _backgroundImage = null);
    }
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

    // 테마 이미지가 변경되었는지 확인하고 다시 로드
    if (widget.theme?.backgroundImage != oldWidget.theme?.backgroundImage) {
      _loadBackgroundImage(widget.theme?.backgroundImage);
    }

    // 만약 interactive가 false(자동 회전/타임스냅 게임)일 경우 또는 외부에서 강제로 initialTime을 주입하는 경우
    // 내부 시곗바늘 각도를 동기화합니다.
    if (widget.initialTime != null &&
        widget.initialTime != oldWidget.initialTime) {
      setState(() {
        _minuteAngle = widget.initialTime!.minuteAngle;
        _hourAngle = widget.initialTime!.hourAngle;
        _secondAngle = widget.initialTime!.secondAngle;
      });
    }
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
    if (delta > 180) delta -= 360; // 시계 반대 방향으로 큰 점프
    if (delta < -180) delta += 360; // 시계 방향으로 큰 점프

    setState(() {
      _isManualMode = true; // 수동 모드로 전환
      // 누적 각도 업데이트
      _minuteAngle += delta;

      // Geared Movement: 분침 360도 회전 = 시침 30도 회전
      // 분침 각도를 12로 나누면 시침 각도
      _hourAngle = _minuteAngle / 12.0;
    });

    _triggerHapticAtQuarters();

    // 콜백 호출
    _notifyTimeChanged();
  }

  /// 12, 3, 6, 9 지점에서 햅틱 피드백
  void _triggerHapticAtQuarters() {
    final normalizedMinuteAngle = (_minuteAngle % 360 + 360) % 360;
    final quarter = (normalizedMinuteAngle / 90).floor();
    if (quarter != _lastHapticQuarter) {
      HapticHelper.lightImpact();
      _lastHapticQuarter = quarter;

      // 정각(12시 방향)에서는 중간 강도 피드백
      if (normalizedMinuteAngle < 5 || normalizedMinuteAngle > 355) {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

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
              color: widget.theme?.backgroundGradient == null
                  ? (widget.theme?.backgroundColor ?? Colors.white)
                  : null,
              border: Border.all(
                color: Color(0xFFE8D5C4), // 베이지 테두리
                width: 8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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
                    backgroundImage: _backgroundImage, // 로드된 이미지 타겟
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

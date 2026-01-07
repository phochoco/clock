import 'package:flutter/material.dart';
import '../models/clock_time.dart';
import '../utils/colors.dart';

/// 디지털 시계 표시 위젯
/// 시간은 빨강, 분은 파랑으로 색상 코딩
class DigitalDisplay extends StatelessWidget {
  final ClockTime time;
  final bool show12Hour;
  
  const DigitalDisplay({
    Key? key,
    required this.time,
    this.show12Hour = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final hour = show12Hour ? time.hour12 : time.hour;
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = time.minute.toString().padLeft(2, '0');
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 오전/오후 표시 (12시간 형식일 때)
          if (show12Hour) ...[
            Text(
              time.isAM ? '오전' : '오후',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 12),
          ],
          
          // 시간 (빨강)
          Text(
            hourStr,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: AppColors.hourRed,
              height: 1.0,
            ),
          ),
          
          // 구분자
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                height: 1.0,
              ),
            ),
          ),
          
          // 분 (파랑)
          Text(
            minuteStr,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: AppColors.minuteBlue,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

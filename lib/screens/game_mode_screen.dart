import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'quiz_screen.dart';
import 'time_attack_screen.dart';
import 'daily_challenge_screen.dart';

/// 게임 모드 선택 화면
class GameModeScreen extends StatelessWidget {
  const GameModeScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        title: Text(
          '🎮 게임 모드',
          style: TextStyle(color: Color(0xFF5A3E2B)),
        ),
        iconTheme: IconThemeData(color: Color(0xFF5A3E2B)),
        backgroundColor: AppColors.bgCream,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 퀴즈 도전
              _buildModeCard(
                context,
                icon: Icons.quiz_rounded,
                title: '퀴즈 도전',
                description: '5단계 레벨을 클리어하고\n보물을 획득하세요!',
                color: AppColors.accentPink,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QuizScreen()),
                  );
                },
              ),
              
              SizedBox(height: 16),
              
              // 타임 어택
              _buildModeCard(
                context,
                icon: Icons.timer_rounded,
                title: '⏱️ 타임 어택',
                description: '60초 안에 최대한 많은\n문제를 풀어보세요!',
                color: Color(0xFFFF6B6B),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TimeAttackScreen()),
                  );
                },
              ),
              
              SizedBox(height: 16),
              
              // 데일리 챌린지
              _buildModeCard(
                context,
                icon: Icons.calendar_today_rounded,
                title: '🌟 데일리 챌린지',
                description: '매일 새로운 문제 3개!\n보너스 별을 받으세요!',
                color: Color(0xFFFFD700),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DailyChallengeScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 50,
              color: Colors.white,
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A2F20), // 진한 갈색 - 가시성 향상
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B4A32), // 중간 갈색 - 가시성 향상
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/glass_container.dart';
import '../widgets/mesh_background.dart';
import 'quiz_screen.dart';
import 'time_attack_screen.dart';
import 'daily_challenge_screen.dart';
import 'story_mode_screen.dart';
import 'time_snap_screen.dart';

/// 게임 모드 선택 화면
class GameModeScreen extends StatelessWidget {
  const GameModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      extendBodyBehindAppBar: true, // 앱바 뒤로 배경 확장
      appBar: AppBar(
        title: Text(
          '게임 모드',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: 0,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textDark),
        backgroundColor: Colors.transparent, // 투명 앱바
        elevation: 0,
        centerTitle: true,
      ),
      body: MeshBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            children: [
              // 퀴즈 도전
              _buildModeCard(
                context,
                icon: Icons.quiz_rounded,
                title: '퀴즈 도전',
                description: '5단계 레벨을 클리어하고\n보물을 획득하세요!',
                color: AppColors.minuteBlue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QuizScreen()),
                  );
                },
              ),

              SizedBox(height: 24),

              // 시계 마을 대모험 (스토리 모드)
              _buildModeCard(
                context,
                icon: Icons.auto_stories_rounded,
                title: '시계 마을 대모험',
                description: '캐릭터와 함께 하루 일과를\n따라가며 시간을 배워요!',
                color: AppColors.success,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StoryModeScreen()),
                  );
                },
              ),
              SizedBox(height: 24),

              // 빙글빙글 타임 스냅 (오락식 타이밍 게임)
              _buildModeCard(
                context,
                icon: Icons.camera_alt_rounded,
                title: '빙글빙글 타임 스냅',
                description: '돌아가는 바늘을 목표 시간에\n정확히 멈춰라! (리듬 게임)',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TimeSnapScreen()),
                  );
                },
              ),

              SizedBox(height: 24),

              // 타임 어택
              _buildModeCard(
                context,
                icon: Icons.timer_rounded,
                title: '타임 어택',
                description: '60초 안에 최대한 많은\n문제를 풀어보세요!',
                color: AppColors.hourRed,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TimeAttackScreen()),
                  );
                },
              ),

              SizedBox(height: 24),

              // 데일리 챌린지
              _buildModeCard(
                context,
                icon: Icons.calendar_today_rounded,
                title: '데일리 챌린지',
                description: '매일 새로운 문제 3개!\n보너스 별을 받으세요!',
                color: AppColors.warning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DailyChallengeScreen(),
                    ),
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
    return GlassContainer(
      onTap: onTap,
      width: double.infinity,
      padding: EdgeInsets.all(24),
      borderRadius: 24,
      opacity: 0.4,
      child: Stack(
        children: [
          Row(
            children: [
              // 아이콘 컨테이너
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: color),
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: 0,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textLight,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              // 네비게이션 화살표
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight.withValues(alpha: 0.5),
                size: 32,
              ),
            ],
          ),
          // 카드 상단 장식 빛 번짐
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 40,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

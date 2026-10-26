import 'package:flutter/material.dart';
import '../models/quiz_level.dart';
import '../services/reward_service.dart';
import '../utils/korean_text.dart';
import '../utils/colors.dart';
import '../widgets/island_ui.dart';
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
      backgroundColor: AppColors.mapSea,
      extendBodyBehindAppBar: true, // 앱바 뒤로 배경 확장
      appBar: islandAppBar('놀이 모드'),
      body: MeshBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            children: [
              Row(
                children: [
                  Jjakkagi(pose: MascotPose.wave, height: 90),
                  Flexible(child: IslandSpeechBubble(text: '오늘은 어떤 놀이를 할까?')),
                ],
              ),
              SizedBox(height: 16),

              // 퀴즈 도전 (지도에서 다음 차례인 섬)
              _buildModeCard(
                context,
                icon: Icons.quiz_rounded,
                title: '섬 퀴즈',
                description: '지도의 다음 섬 문제를 풀고 별을 모아요!',
                color: AppColors.minuteBlue,
                onTap: () async {
                  final completed = await RewardService.getCompletedLevels();
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuizScreen(
                        initialLevel: nextLevelToPlay(completed.toSet()),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 24),

              // 시계 마을 대모험 (스토리 모드)
              _buildModeCard(
                context,
                icon: Icons.auto_stories_rounded,
                title: '시계 마을 대모험',
                description: '캐릭터와 함께 하루 일과를 따라가며 시간을 배워요!',
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
                description: '돌아가는 바늘을 목표 시간에 멈춰요!',
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
                description: '60초 동안 시계 문제를 풀어봐요!',
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
                description: '매일 새 문제 3개를 풀고 보너스 별을 받아요!',
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
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      borderRadius: 24,
      opacity: 0.4,
      child: Stack(
        children: [
          Row(
            children: [
              // 아이콘 컨테이너
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      description.keepWords,
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
        ],
      ),
    );
  }
}

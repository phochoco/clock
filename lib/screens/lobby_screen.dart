import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/colors.dart';
import '../services/ad_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/mesh_background.dart';
import 'playground_screen.dart';
import 'game_mode_screen.dart';
import 'reward_screen.dart';

/// 메인 로비 화면
/// 학습 모드, 퀴즈 모드, 보상방 진입점
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  BannerAd? _bannerAd;
  late final AnimationController _motionController;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 8),
    )..repeat();
    _loadBannerAd();
  }

  Future<void> _loadBannerAd() async {
    try {
      final ad = await AdService.loadBannerAd();
      if (mounted) {
        setState(() {
          _bannerAd = ad;
        });
      }
    } catch (e) {
      debugPrint('배너 광고 로드 실패: $e');
      // 5초 후 재시도
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) _loadBannerAd();
      });
    }
  }

  @override
  void dispose() {
    _motionController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: MeshBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              // Allow content to take at least full screen height
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _buildGuardianInfoButton(),
                    SizedBox(height: 20),

                    // 프리미엄 타이틀
                    _buildTitle(),

                    SizedBox(height: 50),

                    // 메인 글래스모피즘 버튼들
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 학습 모드 버튼
                            _buildMainGlassButton(
                              context,
                              icon: Icons.school_rounded,
                              label: '시계 배우기',
                              subtitle: '바늘을 돌려 시간 찾기',
                              color: AppColors.minuteBlue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaygroundScreen(),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 30),

                            // 게임 모드 버튼
                            _buildMainGlassButton(
                              context,
                              icon: Icons.videogame_asset_rounded,
                              label: '게임 모드',
                              subtitle: '퀴즈로 별 모으기',
                              color: AppColors.hourRed,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GameModeScreen(),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 30),

                            // 보상방 버튼
                            _buildMainGlassButton(
                              context,
                              icon: Icons.diamond_rounded,
                              label: '내 보물상자',
                              subtitle: '테마 꾸미기와 별 모음',
                              color: AppColors.warning, // Golden Amber
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RewardScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 배너 광고 (글래스보드 느낌으로 감싸기)
                    if (_bannerAd != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: GlassContainer(
                          width: _bannerAd!.size.width.toDouble() + 16,
                          height: _bannerAd!.size.height.toDouble() + 16,
                          padding: EdgeInsets.zero,
                          borderRadius: 16,
                          child: Center(
                            child: SizedBox(
                              width: _bannerAd!.size.width.toDouble(),
                              height: _bannerAd!.size.height.toDouble(),
                              child: AdWidget(ad: _bannerAd!),
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuardianInfoButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          tooltip: '보호자 안내',
          icon: Icon(
            Icons.shield_outlined,
            color: AppColors.textLight,
            size: 28,
          ),
          onPressed: _showGuardianInfoDialog,
        ),
      ),
    );
  }

  void _showGuardianInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.minuteBlue),
            SizedBox(width: 8),
            Text('보호자 안내'),
          ],
        ),
        content: Text(
          '학습 기록과 별, 선택한 테마는 기기에만 저장됩니다.\n\n'
          '광고는 Google AdMob을 사용하며 어린이 대상 및 일반 등급 광고 설정을 적용합니다. '
          '보상형 광고는 보호자가 확인한 뒤 함께 이용해주세요.\n\n'
          '문의: yeajunss@naver.com',
          style: TextStyle(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        _buildAnimatedTitleIcon(),
        SizedBox(height: 24),

        // 프리미엄 타이포그래피 앱 타이틀
        Text(
          '째깍 보물섬',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            color: AppColors.textDark,
          ),
        ),

        SizedBox(height: 8),

        Text(
          '바늘을 돌려 시간 보물을 찾아요',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedTitleIcon() {
    return AnimatedBuilder(
      animation: _motionController,
      builder: (context, child) {
        final t = _motionController.value;
        return SizedBox(
          width: 132,
          height: 116,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _buildFloatingSparkle(
                t,
                phase: 0.05,
                radius: 44,
                angle: -0.9,
                color: AppColors.warning,
                size: 20,
              ),
              _buildFloatingSparkle(
                t,
                phase: 0.35,
                radius: 52,
                angle: 0.55,
                color: AppColors.minuteBlue,
                size: 18,
              ),
              _buildFloatingSparkle(
                t,
                phase: 0.65,
                radius: 48,
                angle: 2.55,
                color: AppColors.hourRed,
                size: 16,
              ),
              Transform.scale(
                scale: 1 + math.sin(t * math.pi * 2) * 0.025,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.86),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.minuteBlue.withValues(alpha: 0.18),
                        blurRadius: 22,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 64,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingSparkle(
    double t, {
    required double phase,
    required double radius,
    required double angle,
    required Color color,
    required double size,
  }) {
    final wave = math.sin((t + phase) * math.pi * 2);
    final dx = math.cos(angle + t * math.pi * 0.35) * radius;
    final dy = math.sin(angle + t * math.pi * 0.35) * radius * 0.68;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: 0.55 + wave.abs() * 0.35,
        child: Transform.scale(
          scale: 0.88 + wave.abs() * 0.18,
          child: Icon(Icons.auto_awesome_rounded, color: color, size: size),
        ),
      ),
    );
  }

  Widget _buildMainGlassButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final buttonWidth = math.min(MediaQuery.of(context).size.width - 48, 340.0);

    return GlassContainer(
      onTap: onTap,
      width: buttonWidth,
      height: 98,
      padding: EdgeInsets.symmetric(horizontal: 24),
      borderRadius: 28,
      opacity: 0.35, // 기존 버튼보다 살짝 불투명하게 (가독성)
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘 래퍼 (색상 효과)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 36, color: color),
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 화살표 지시자
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textLight.withValues(alpha: 0.5),
            size: 32,
          ),
        ],
      ),
    );
  }
}

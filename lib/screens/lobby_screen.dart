import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/clock_theme.dart';
import '../models/clock_time.dart';
import '../utils/colors.dart';
import '../services/ad_service.dart';
import '../widgets/analog_clock.dart';
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
                    SizedBox(height: 8),

                    _buildTitle(),

                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMainGlassButton(
                              context,
                              icon: Icons.schedule_rounded,
                              label: '시계 배우기',
                              subtitle: '바늘을 맞춰 시간을 익혀요',
                              color: AppColors.appleBlue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaygroundScreen(),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 14),

                            _buildMainGlassButton(
                              context,
                              icon: Icons.bolt_rounded,
                              label: '퀴즈',
                              subtitle: '짧은 문제로 정확도를 높여요',
                              color: AppColors.appleRed,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GameModeScreen(),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: 14),

                            _buildMainGlassButton(
                              context,
                              icon: Icons.grid_view_rounded,
                              label: '컬렉션',
                              subtitle: '모은 시계 페이스를 살펴봐요',
                              color: AppColors.appleYellow,
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

                    SizedBox(height: 28),
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
            size: 24,
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
            Icon(Icons.shield_outlined, color: AppColors.appleBlue),
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
        SizedBox(height: 8),
        Text(
          '오늘의 연습',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
            color: AppColors.textLight,
          ),
        ),
        SizedBox(height: 10),

        Text(
          '째깍',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            color: AppColors.textDark,
          ),
        ),

        SizedBox(height: 10),

        Text(
          '바늘을 맞춰 시간을 익혀요.',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            color: AppColors.textLight,
          ),
        ),
        SizedBox(height: 26),
        _buildAnimatedTitleIcon(),
      ],
    );
  }

  Widget _buildAnimatedTitleIcon() {
    return AnimatedBuilder(
      animation: _motionController,
      builder: (context, child) {
        final t = _motionController.value;
        return Transform.scale(
          scale: 1 + math.sin(t * math.pi * 2) * 0.012,
          child: SizedBox(
            width: 250,
            height: 250,
            child: AnalogClock(
              initialTime: ClockTime(hour: 10, minute: 10),
              interactive: false,
              showGuideline: false,
              showMinuteNumbers: false,
              notifyInitialTime: false,
              theme: ClockThemeList.basic,
            ),
          ),
        );
      },
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
    final buttonWidth = math.min(MediaQuery.of(context).size.width - 40, 360.0);

    return GlassContainer(
      onTap: onTap,
      width: buttonWidth,
      height: 76,
      padding: EdgeInsets.symmetric(horizontal: 18),
      borderRadius: 28,
      opacity: 0.76,
      blurRadius: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
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
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textLight.withValues(alpha: 0.72),
            size: 26,
          ),
        ],
      ),
    );
  }
}

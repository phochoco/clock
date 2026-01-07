import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/colors.dart';
import '../services/ad_service.dart';
import 'playground_screen.dart';
import 'game_mode_screen.dart';
import 'reward_screen.dart';

/// 메인 로비 화면
/// 학습 모드, 퀴즈 모드, 보상방 진입점
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({Key? key}) : super(key: key);
  
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  BannerAd? _bannerAd;
  
  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }
  
  Future<void> _loadBannerAd() async {
    final ad = await AdService.loadBannerAd();
    setState(() {
      _bannerAd = ad;
    });
  }
  
  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgCream,
              AppColors.bgPeach,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 40),
              
              // 타이틀
              _buildTitle(),
              
              SizedBox(height: 60),
              
              // 메인 버튼들
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 학습 모드 버튼
                      _buildMainButton(
                        context,
                        icon: Icons.school_rounded,
                        label: '시계 배우기',
                        color: AppColors.accentMint,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaygroundScreen(),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 24),
                      
                      // 게임 모드 버튼 (통합)
                      _buildMainButton(
                        context,
                        icon: Icons.games_rounded,
                        label: '게임 모드',
                        color: AppColors.accentPink,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GameModeScreen(),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 24),
                      
                      // 보상방 버튼
                      _buildMainButton(
                        context,
                        icon: Icons.card_giftcard_rounded,
                        label: '내 보물상자',
                        color: AppColors.accentYellow,
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
              
              // 배너 광고
              if (_bannerAd != null)
                Container(
                  alignment: Alignment.center,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTitle() {
    return Column(
      children: [
        // 시계 이모지
        Text(
          '🕐',
          style: TextStyle(fontSize: 80),
        ),
        SizedBox(height: 16),
        
        // 앱 타이틀
        Text(
          '시계 배우기',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        
        SizedBox(height: 8),
        
        Text(
          '재미있게 시계를 읽어요!',
          style: TextStyle(
            fontSize: 18,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMainButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

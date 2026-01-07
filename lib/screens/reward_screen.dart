import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/reward.dart';
import '../models/clock_theme.dart';
import '../services/reward_service.dart';
import '../services/theme_service.dart';
import '../services/ad_service.dart';

/// 보상방 화면
/// 획득한 아이템과 업적 표시
class RewardScreen extends StatefulWidget {
  const RewardScreen({Key? key}) : super(key: key);
  
  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  List<String> _unlockedRewards = [];
  int _completedLevelCount = 0;
  int _unlockedRewardCount = 0;
  int _totalStars = 0; // 별 개수 추가
  String _selectedThemeId = 'basic_clock';
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0: 보물상자, 1: 별 상점
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    final unlockedRewards = await RewardService.getUnlockedRewards();
    final completedLevelCount = await RewardService.getCompletedLevelCount();
    final unlockedRewardCount = await RewardService.getUnlockedRewardCount();
    final totalStars = await RewardService.getTotalStars(); // 별 개수 로드
    final selectedThemeId = await ThemeService.getSelectedThemeId();
    
    setState(() {
      _unlockedRewards = unlockedRewards;
      _completedLevelCount = completedLevelCount;
      _unlockedRewardCount = unlockedRewardCount;
      _totalStars = totalStars; // 별 개수 저장
      _selectedThemeId = selectedThemeId;
      _isLoading = false;
    });
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
              AppColors.accentYellow.withOpacity(0.3),
              AppColors.accentLavender.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildTopBar(context),
                    SizedBox(height: 20),
                    _buildStats(),
                    _buildAdButton(),
                    SizedBox(height: 20),
                    _buildTabBar(),
                    SizedBox(height: 20),
                    Expanded(
                      child: _selectedTabIndex == 0
                          ? _buildRewardGrid()
                          : _buildStoreGrid(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
  
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            '내 보물상자',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(width: 48), // 뒤로가기 버튼과 균형 맞추기
        ],
      ),
    );
  }
  
  Widget _buildStats() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(20),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('🏆', '레벨', '$_completedLevelCount'),
          _buildStatItem('⭐', '별', '$_totalStars'),
          _buildStatItem('🎁', '보상', '$_unlockedRewardCount'),
        ],
      ),
    );
  }
  
  // 광고 보고 별 받기 버튼
  Widget _buildAdButton() {
    return FutureBuilder<int>(
      future: AdService.getRemainingRewardedAds(),
      builder: (context, snapshot) {
        final remaining = snapshot.data ?? 0;
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: ElevatedButton(
            onPressed: remaining > 0 ? _watchRewardedAd : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentYellow,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_filled, size: 28, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  remaining > 0 ? '광고 보고 별 10개 받기 ($remaining/3)' : '오늘 모두 시청했어요!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // 보상형 광고 시청
  Future<void> _watchRewardedAd() async {
    final canWatch = await AdService.canWatchRewardedAd();
    if (!canWatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오늘 광고를 모두 시청했어요! 내일 다시 오세요!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final rewarded = await AdService.showRewardedAd();
    
    if (rewarded) {
      await AdService.incrementRewardedAdCount();
      await RewardService.addStars(10);
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⭐ 별 10개를 획득했어요!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('광고를 끝까지 시청해주세요!'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(
          emoji,
          style: TextStyle(fontSize: 32),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRewardGrid() {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: RewardList.all.length,
      itemBuilder: (context, index) {
        final reward = RewardList.all[index];
        final unlocked = _unlockedRewards.contains(reward.id);
        final isSelected = _selectedThemeId == reward.themeId;
        
        return GestureDetector(
          onTap: unlocked ? () => _showRewardDialog(reward) : null,
          child: Container(
            decoration: BoxDecoration(
              color: unlocked ? Colors.white : Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
              border: isSelected
                  ? Border.all(color: AppColors.accentYellow, width: 3)
                  : null,
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  unlocked ? reward.emoji : '🔒',
                  style: TextStyle(fontSize: 60),
                ),
                SizedBox(height: 12),
                Text(
                  reward.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: unlocked ? AppColors.textDark : Colors.grey[600],
                  ),
                ),
                if (!unlocked) ...[ 
                  SizedBox(height: 4),
                  Text(
                    '잠김',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
                if (isSelected) ...[
                  SizedBox(height: 4),
                  Text(
                    '사용 중',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentYellow,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showRewardDialog(Reward reward) {
    final theme = ClockThemeList.getThemeById(reward.themeId);
    final isSelected = _selectedThemeId == reward.themeId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${reward.emoji} ${reward.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                gradient: theme.backgroundGradient,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: Center(
                child: Text(
                  reward.emoji,
                  style: TextStyle(fontSize: 50),
                ),
              ),
            ),
            SizedBox(height: 16),
            if (isSelected)
              Text(
                '현재 사용 중인 시계입니다',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.accentYellow,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                '이 시계로 변경하시겠습니까?',
                style: TextStyle(fontSize: 14),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          if (!isSelected)
            TextButton(
              onPressed: () async {
                await ThemeService.selectTheme(reward.themeId);
                setState(() {
                  _selectedThemeId = reward.themeId;
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${reward.name}(으)로 변경되었습니다!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text('변경하기'),
            ),
        ],
      ),
    );
  }
  
  /// 탭바 (보물상자 / 별 상점)
  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _selectedTabIndex == 0
                      ? LinearGradient(
                          colors: [AppColors.accentYellow, AppColors.accentYellow.withOpacity(0.7)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🎁',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '보물상자',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 0 ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _selectedTabIndex == 1
                      ? LinearGradient(
                          colors: [AppColors.accentLavender, AppColors.accentLavender.withOpacity(0.7)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '⭐',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '별 상점',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _selectedTabIndex == 1 ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 별 상점 그리드
  Widget _buildStoreGrid() {
    final premiumThemes = ClockThemeList.premiumThemes;
    
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: premiumThemes.length,
      itemBuilder: (context, index) {
        final theme = premiumThemes[index];
        final isUnlocked = _unlockedRewards.contains(theme.id);
        final canAfford = _totalStars >= theme.starCost;
        
        return GestureDetector(
          onTap: () => _showPurchaseDialog(theme, isUnlocked, canAfford),
          child: Container(
            decoration: BoxDecoration(
              gradient: theme.backgroundGradient ?? LinearGradient(
                colors: [theme.backgroundColor, theme.backgroundColor],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
              border: isUnlocked
                  ? Border.all(color: AppColors.success, width: 3)
                  : null,
            ),
            child: Stack(
              children: [
                // 테마 미리보기
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 시계 아이콘
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        child: Center(
                          child: Text(
                            _getThemeIcon(theme.id),
                            style: TextStyle(fontSize: 40),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        theme.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.id == 'golden_clock' || theme.id == 'moonlight_clock'
                              ? Colors.white
                              : AppColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      // 가격 또는 상태
                      if (isUnlocked)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '보유 중',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: canAfford
                                ? AppColors.accentYellow
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('⭐', style: TextStyle(fontSize: 14)),
                              SizedBox(width: 4),
                              Text(
                                '${theme.starCost}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // 잠금 아이콘
                if (!isUnlocked && !canAfford)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// 테마별 아이콘 가져오기
  String _getThemeIcon(String themeId) {
    switch (themeId) {
      case 'golden_clock':
        return '👑';
      case 'moonlight_clock':
        return '🌙';
      case 'crystal_clock':
        return '💎';
      case 'circus_clock':
        return '🎪';
      default:
        return '🕐';
    }
  }
  
  /// 구매 확인 다이얼로그
  void _showPurchaseDialog(ClockTheme theme, bool isUnlocked, bool canAfford) {
    if (isUnlocked) {
      // 이미 보유 중인 테마 - 적용하기
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${theme.name}'),
          content: Text('이 테마를 적용하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ThemeService.selectTheme(theme.id);
                setState(() => _selectedThemeId = theme.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${theme.name}(으)로 변경되었습니다!')),
                );
              },
              child: Text('적용하기'),
            ),
          ],
        ),
      );
      return;
    }
    
    if (!canAfford) {
      // 별 부족
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('별이 부족합니다'),
          content: Text('${theme.name}을(를) 구매하려면 별 ${theme.starCost}개가 필요합니다.\n현재 보유: $_totalStars개'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('확인'),
            ),
          ],
        ),
      );
      return;
    }
    
    // 구매 확인
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🌟 ${theme.name} 구매'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('이 테마를 구매하시겠습니까?'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('⭐', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Text(
                  '${theme.starCost}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentYellow,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentYellow,
            ),
            onPressed: () async {
              // 별 차감
              final success = await RewardService.spendStars(theme.starCost);
              if (success) {
                // 테마 해금
                await RewardService.unlockReward(theme.id);
                await _loadData();
                Navigator.pop(context);
                
                // 성공 메시지
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('🎉 구매 완료!'),
                    content: Text('${theme.name}을(를) 획득했습니다!'),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('확인'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Text('구매하기'),
          ),
        ],
      ),
    );
  }
}

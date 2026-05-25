import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/reward.dart';
import '../models/clock_theme.dart';
import '../services/reward_service.dart';
import '../services/theme_service.dart';
import '../services/ad_service.dart';
import '../widgets/glass_container.dart';
import '../widgets/mesh_background.dart';
import '../widgets/analog_clock.dart';
import '../models/clock_time.dart';

/// 보상방 화면
/// 획득한 아이템과 업적 표시
class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

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
  int _selectedTabIndex = 0; // 0: 보물상자, 1: 테마 열기

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
      backgroundColor: AppColors.bgPrimary,
      body: MeshBackground(
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
    final int totalThemes = ClockThemeList.all.length; // 모든 테마(무료+유료) 기준
    final double progress = totalThemes > 0
        ? _unlockedRewardCount / totalThemes
        : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        padding: EdgeInsets.all(20),
        borderRadius: 20,
        opacity: 0.8,
        child: Column(
          children: [
            // 기존 3가지 메인 스탯
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.emoji_events_rounded,
                  Colors.amber,
                  '레벨',
                  '$_completedLevelCount',
                ),
                _buildStatItem(
                  Icons.star_rounded,
                  Colors.amber,
                  '별',
                  '$_totalStars',
                ),
                _buildStatItem(
                  Icons.redeem_rounded,
                  Colors.redAccent,
                  '보상',
                  '$_unlockedRewardCount',
                ),
              ],
            ),
            SizedBox(height: 20),
            // 새로 추가된 도감 수집률 바
            Row(
              children: [
                Icon(
                  Icons.collections_bookmark_rounded,
                  color: AppColors.secondary,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  '도감 달성률',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Spacer(),
                Text(
                  '$_unlockedRewardCount / $totalThemes ( ${(progress * 100).toInt()}% )',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            ),
          ],
        ),
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
              backgroundColor: AppColors.warning,
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
                  remaining > 0
                      ? '보호자와 광고 보고 별 10개 받기 ($remaining/3)'
                      : '오늘 모두 시청했어요!',
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
    final confirmed = await _confirmGuardianAdViewing();
    if (!mounted) return;
    if (!confirmed) return;

    final canWatch = await AdService.canWatchRewardedAd();
    if (!mounted) return;
    if (!canWatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오늘 광고를 모두 시청했어요! 내일 다시 오세요!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 광고 준비 상태 확인
    if (!AdService.isRewardedAdReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('광고를 불러오는 중입니다. 잠시 후 다시 시도해주세요!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final rewarded = await AdService.showRewardedAd();
    if (!mounted) return;

    if (rewarded) {
      await AdService.incrementRewardedAdCount();
      await RewardService.addStars(10);
      await _loadData();
      if (!mounted) return;

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

  Future<bool> _confirmGuardianAdViewing() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('보호자와 함께 보기'),
        content: Text('보상형 광고가 재생됩니다. 어린이가 혼자 광고를 누르지 않도록 보호자와 함께 진행해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('광고 보기'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildStatItem(
    IconData icon,
    Color color,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(icon, size: 36, color: color),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.textLight)),
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
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      physics: BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7, // 뱃지 및 상태 텍스트로 인한 오버플로우 방지를 위해 더 길쭉하게 배치
      ),
      itemCount: RewardList.all.length,
      itemBuilder: (context, index) {
        final reward = RewardList.all[index];
        final unlocked = _unlockedRewards.contains(reward.id);
        final isSelected = _selectedThemeId == reward.themeId;
        final rarity = _getThemeRarity(reward.themeId);

        return GestureDetector(
          onTap: unlocked ? () => _showRewardDialog(reward) : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 뒤쪽 황금빛 후광 효과 (전설 등급 한정)
              if (unlocked && rarity == '전설')
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.6),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              // 유리 거치대 (Glass Podium)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: AppColors.warning, width: 3)
                        : null,
                  ),
                  child: GlassContainer(
                    opacity: unlocked ? 0.3 : 0.8,
                    borderRadius: 20,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 시계 렌더링 또는 자물쇠 아이콘
                        unlocked
                            ? _buildClockPreview(reward)
                            : Icon(
                                Icons.lock_rounded,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                        SizedBox(height: 16),
                        // 테마 이름
                        Text(
                          reward.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: unlocked
                                ? AppColors.textDark
                                : Colors.grey[500],
                          ),
                        ),
                        // 희귀도 뱃지 또는 잠김 표시
                        SizedBox(height: 6),
                        if (unlocked)
                          _buildRarityBadge(rarity)
                        else
                          Text(
                            '잠김',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),

                        // 장착 중 텍스트
                        if (isSelected) ...[
                          SizedBox(height: 8),
                          Text(
                            '사용 중',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 테마 아이디 기반 임시 희귀도 판별 보조함수
  String _getThemeRarity(String themeId) {
    if (themeId == 'golden_clock' ||
        themeId == 'circus_clock' ||
        themeId == 'crystal_clock') {
      return '전설';
    } else if (themeId == 'space_clock' ||
        themeId == 'night_clock' ||
        themeId == 'music_clock') {
      return '희귀';
    } else {
      return '일반';
    }
  }

  // 희귀도 뱃지 UI 생성
  Widget _buildRarityBadge(String rarity) {
    Color badgeColor;
    if (rarity == '전설') {
      badgeColor = Colors.amber;
    } else if (rarity == '희귀') {
      badgeColor = Colors.purpleAccent;
    } else {
      badgeColor = Colors.blueGrey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        rarity,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  // 시계 미리보기 축소판 렌더링
  Widget _buildClockPreview(Reward reward) {
    final theme = ClockThemeList.getThemeById(reward.themeId);
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        gradient: theme.backgroundGradient,
        shape: BoxShape.circle,
        image: theme.backgroundImage != null
            ? DecorationImage(
                image: AssetImage(theme.backgroundImage!),
                fit: BoxFit.cover,
              )
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: theme.backgroundImage == null
          ? Center(child: Icon(reward.icon, size: 35, color: reward.iconColor))
          : null,
    );
  }

  void _showRewardDialog(Reward reward) {
    final theme = ClockThemeList.getThemeById(reward.themeId);
    final isSelected = _selectedThemeId == reward.themeId;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // 반투명 배경 유지
        pageBuilder: (BuildContext context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black.withValues(alpha: 0.85),
            body: SafeArea(
              child: Column(
                children: [
                  // 상단 닫기 기능
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),

                  Spacer(),

                  // 메인 풀스크린 시계 (인터랙션 가능)
                  Text(
                    '미리보기 (바늘을 움직여 보세요!)',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: AnalogClock(
                        initialTime: ClockTime(hour: 10, minute: 10),
                        interactive: true,
                        showMinuteNumbers: true,
                        showGuideline: false,
                        theme: theme,
                      ),
                    ),
                  ),

                  Spacer(),

                  // 하단 장착 UI
                  GlassContainer(
                    opacity: 0.2,
                    borderRadius: 30,
                    padding: EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              reward.icon,
                              color: reward.iconColor,
                              size: 32,
                            ),
                            SizedBox(width: 12),
                            Text(
                              reward.name,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        if (isSelected)
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 48,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.warning,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '현재 사용 중인 시계입니다',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              padding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 48,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () async {
                              await ThemeService.selectTheme(reward.themeId);
                              if (!mounted || !context.mounted) return;
                              setState(() {
                                _selectedThemeId = reward.themeId;
                              });
                              Navigator.pop(context); // 풀스크린 닫기
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${reward.name}(으)로 변경되었습니다!'),
                                  backgroundColor: AppColors.success,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Text(
                              '이 시계로 설정하기',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: 25,
        opacity: 0.7,
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
                            colors: [
                              AppColors.warning,
                              AppColors.warning.withValues(alpha: 0.7),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.redeem_rounded,
                        size: 20,
                        color: _selectedTabIndex == 0
                            ? Colors.white
                            : AppColors.textDark.withValues(alpha: 0.4),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '보물상자',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _selectedTabIndex == 0
                              ? Colors.white
                              : AppColors.textDark.withValues(alpha: 0.4),
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
                            colors: [
                              AppColors.minuteBlue,
                              AppColors.minuteBlue.withValues(alpha: 0.7),
                            ],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: _selectedTabIndex == 1
                            ? Colors.white
                            : AppColors.textDark.withValues(alpha: 0.4),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '테마 열기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _selectedTabIndex == 1
                              ? Colors.white
                              : AppColors.textDark.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 별로 여는 테마 그리드
  Widget _buildStoreGrid() {
    // 테스트를 위해 리버스해서 최신 추가된 테마가 상단에 보이도록 임시 처리
    final premiumThemes = ClockThemeList.premiumThemes.reversed.toList();

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
              gradient: ClockThemeList.candy.backgroundGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 시계 아이콘 또는 이미지
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.3),
                                image: theme.backgroundImage != null
                                    ? DecorationImage(
                                        image: AssetImage(
                                          theme.backgroundImage!,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: theme.backgroundImage == null
                                  ? Center(
                                      child: _buildThemeIcon(
                                        theme.id,
                                        isUnlocked: isUnlocked,
                                      ),
                                    )
                                  : null,
                            ),
                            if (!isUnlocked)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 5.0,
                                    sigmaY: 5.0,
                                  ),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.transparent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          theme.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ClockThemeList.candy.hourHandColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        // 가격 또는 상태
                        if (isUnlocked)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
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
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: canAfford
                                  ? AppColors.warning
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
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
                ),
                // 잠금 아이콘
                if (!isUnlocked && !canAfford)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock, color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 테마별 아이콘 컴포넌트 가져오기
  Widget _buildThemeIcon(String themeId, {bool isUnlocked = true}) {
    IconData icon;
    Color color;
    switch (themeId) {
      case 'golden_clock':
        icon = Icons.workspace_premium_rounded;
        color = Colors.amber;
        break;
      case 'moonlight_clock':
        icon = Icons.dark_mode_rounded;
        color = Colors.indigoAccent;
        break;
      case 'crystal_clock':
        icon = Icons.diamond_rounded;
        color = Colors.cyanAccent;
        break;
      case 'circus_clock':
        icon = Icons.celebration_rounded;
        color = Colors.pinkAccent;
        break;
      default:
        icon = Icons.schedule_rounded;
        color = Colors.blueGrey;
    }
    return Icon(
      icon,
      size: 40,
      color: isUnlocked ? color : Colors.grey.withValues(alpha: 0.5),
    );
  }

  /// 테마 열기 확인 다이얼로그
  void _showPurchaseDialog(ClockTheme theme, bool isUnlocked, bool canAfford) {
    if (isUnlocked) {
      // 이미 보유 중인 테마 - 적용하기
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(theme.name),
          content: Text('이 테마를 적용하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ThemeService.selectTheme(theme.id);
                if (!mounted || !dialogContext.mounted) return;
                setState(() => _selectedThemeId = theme.id);
                Navigator.pop(dialogContext);
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
          content: Text(
            '${theme.name}을(를) 열려면 별 ${theme.starCost}개가 필요합니다.\n현재 보유: $_totalStars개',
          ),
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

    // 테마 열기 확인
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('🌟 ${theme.name} 열기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('별을 사용해 이 테마를 열까요?'),
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
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () async {
              // 별 차감
              final success = await RewardService.spendStars(theme.starCost);
              if (success) {
                // 테마 해금
                await RewardService.unlockReward(theme.id);
                await _loadData();
                if (!mounted || !dialogContext.mounted) return;
                Navigator.pop(dialogContext); // 닫기 (열기 확인)

                // 가챠 언락 애니메이션 실행
                _showUnlockAnimation(theme);
              }
            },
            child: Text('별로 열기'),
          ),
        ],
      ),
    );
  }

  void _showUnlockAnimation(ClockTheme theme) {
    bool isRevealed = false;
    bool timerStarted = false;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (!timerStarted) {
              timerStarted = true;
              // 1.5초 후 자동으로 상자 열림
              Future.delayed(Duration(milliseconds: 1500), () {
                if (mounted && context.mounted) {
                  setState(() {
                    isRevealed = true;
                  });
                }
              });
            }

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isRevealed ? '🎉 획득 성공! 🎉' : '두근두근...',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.amber, blurRadius: 10)],
                      ),
                    ),
                    SizedBox(height: 40),

                    // 언락 애니메이션 요소
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 1500),
                      switchInCurve: Curves.elasticOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                      child: isRevealed
                          ? Column(
                              key: ValueKey('revealed'),
                              children: [
                                // 테마 렌더링
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: theme.backgroundColor,
                                    gradient: theme.backgroundGradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withValues(
                                          alpha: 0.8,
                                        ),
                                        blurRadius: 50,
                                        spreadRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.workspace_premium_rounded,
                                      size: 100,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  theme.name,
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            )
                          : TweenAnimationBuilder<double>(
                              key: ValueKey('mystery'),
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: Duration(milliseconds: 1500),
                              builder: (context, value, child) {
                                // 흔들기 각도 계산 (가속되는 진동)
                                final angle =
                                    sin(value * 30) *
                                    0.1 *
                                    value; // 시간이 갈수록 세게 흔들림
                                return Transform.rotate(
                                  angle: angle,
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.indigoAccent,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.secondary.withValues(
                                        alpha: 0.8,
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.help_outline_rounded,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                    ),

                    SizedBox(height: 60),
                    AnimatedOpacity(
                      opacity: isRevealed ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 500),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: isRevealed
                            ? () => Navigator.pop(context)
                            : null,
                        child: Text(
                          '보물상자에 넣기',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

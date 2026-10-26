import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/clock_theme.dart';
import '../models/clock_time.dart';
import '../models/quiz_level.dart';
import '../models/reward.dart';
import '../services/reward_service.dart';
import '../services/theme_service.dart';
import '../utils/colors.dart';
import '../utils/korean_text.dart';
import '../widgets/analog_clock.dart';
import '../widgets/clock_theme_icon.dart';
import '../widgets/island_ui.dart';
import '../widgets/treasure_map.dart';

/// 내 시계들 화면
/// 섬을 깨서 받은 시계와 별로 여는 시계를 모아 보고 고르는 보물 창고
class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

enum _ClockStatus { inUse, owned, islandReward, forSale }

class _RewardScreenState extends State<RewardScreen> {
  List<String> _unlockedRewards = [];
  int _totalStars = 0;
  String _selectedThemeId = 'basic_clock';
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0: 모은 시계, 1: 별로 열기

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final unlockedRewards = await RewardService.getUnlockedRewards();
    final totalStars = await RewardService.getTotalStars();
    final selectedThemeId = await ThemeService.getSelectedThemeId();

    if (!mounted) return;
    setState(() {
      _unlockedRewards = unlockedRewards;
      _totalStars = totalStars;
      _selectedThemeId = selectedThemeId;
      _isLoading = false;
    });
  }

  bool _owns(ClockTheme theme) => _unlockedRewards.contains(theme.id);

  _ClockStatus _statusOf(ClockTheme theme) {
    if (theme.id == _selectedThemeId) return _ClockStatus.inUse;
    if (_owns(theme)) return _ClockStatus.owned;
    return theme.isPremium ? _ClockStatus.forSale : _ClockStatus.islandReward;
  }

  /// 섬 보상 시계를 주는 섬 (무료 시계만)
  TreasureIsland? _islandFor(ClockTheme theme) {
    final reward = RewardList.all.where((r) => r.themeId == theme.id);
    if (reward.isEmpty || reward.first.levelRequired < 1) return null;
    return TreasureIsland.of(QuizLevel.values[reward.first.levelRequired - 1]);
  }

  List<ClockTheme> get _collectionThemes => [
    ...ClockThemeList.freeThemes,
    ...ClockThemeList.premiumThemes.where(_owns),
  ];

  List<ClockTheme> get _shopThemes =>
      [...ClockThemeList.premiumThemes]
        ..sort((a, b) => a.starCost.compareTo(b.starCost));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mapSea,
      body: IslandSeaBackground(
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    IslandTopBar(
                      title: '내 시계들',
                      trailing: _StarPill(stars: _totalStars),
                    ),
                    SizedBox(height: 12),
                    _buildCollectionHeader(),
                    SizedBox(height: 14),
                    _buildTabs(),
                    SizedBox(height: 12),
                    Expanded(child: _buildGrid()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCollectionHeader() {
    final total = ClockThemeList.all.length;
    final owned = ClockThemeList.all.where(_owns).length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Jjakkagi(pose: MascotPose.treasure, height: 86),
          SizedBox(width: 4),
          Expanded(
            child: Container(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: _sandPanel(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '모은 시계',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.woodDark,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '$owned / $total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.treasureOrangeDeep,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: owned / total,
                      minHeight: 12,
                      backgroundColor: AppColors.woodLight.withValues(
                        alpha: 0.25,
                      ),
                      valueColor: AlwaysStoppedAnimation(AppColors.mapStar),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '섬을 탐험하면 시계를 받고, 모은 별로 새 시계를 열 수 있어요.'.keepWords,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.wood,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.mapSand,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.woodLight, width: 2.5),
        ),
        child: Row(
          children: [
            _tab(0, Icons.inventory_2_rounded, '모은 시계'),
            _tab(1, Icons.star_rounded, '별로 열기'),
          ],
        ),
      ),
    );
  }

  Widget _tab(int index, IconData icon, String label) {
    final selected = _selectedTabIndex == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () => setState(() => _selectedTabIndex = index),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: 46,
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.treasureOrange,
                        AppColors.treasureOrangeDeep,
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(23),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected ? Colors.white : AppColors.wood,
                ),
                SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : AppColors.wood,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final themes = _selectedTabIndex == 0 ? _collectionThemes : _shopThemes;
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
      physics: BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) => _buildCard(themes[index]),
    );
  }

  Widget _buildCard(ClockTheme theme) {
    final status = _statusOf(theme);
    final inUse = status == _ClockStatus.inUse;
    final locked =
        status == _ClockStatus.islandReward || status == _ClockStatus.forSale;

    return Semantics(
      button: true,
      label: '${theme.name}, ${_statusLabel(theme, status)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _onCardTap(theme, status),
        child: Container(
          padding: EdgeInsets.fromLTRB(10, 14, 10, 12),
          decoration: _sandPanel(
            borderColor: inUse ? AppColors.treasureOrange : null,
            borderWidth: inUse ? 4 : 2.5,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClockThemeIcon(
                          theme: theme,
                          size: 104,
                          locked: status == _ClockStatus.islandReward,
                        ),
                        if (status == _ClockStatus.islandReward) _LockBadge(),
                      ],
                    ),
                  ),
                  SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      theme.name,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: locked ? AppColors.wood : AppColors.woodDark,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  _buildStatusChip(theme, status),
                ],
              ),
              if (inUse)
                Positioned(
                  top: -6,
                  right: -2,
                  child: Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.treasureOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(ClockTheme theme, _ClockStatus status) {
    switch (status) {
      case _ClockStatus.inUse:
        return '사용 중';
      case _ClockStatus.owned:
        return '고를 수 있음';
      case _ClockStatus.islandReward:
        return '${_islandFor(theme)?.name ?? '섬'} 보상';
      case _ClockStatus.forSale:
        return '별 ${theme.starCost}개';
    }
  }

  Widget _buildStatusChip(ClockTheme theme, _ClockStatus status) {
    switch (status) {
      case _ClockStatus.inUse:
        return _Chip(
          icon: Icons.check_circle_rounded,
          label: '사용 중',
          color: Colors.white,
          background: AppColors.treasureOrange,
        );
      case _ClockStatus.owned:
        return _Chip(
          icon: Icons.touch_app_rounded,
          label: '고르기',
          color: AppColors.woodDark,
          background: Colors.white,
        );
      case _ClockStatus.islandReward:
        final island = _islandFor(theme);
        return _Chip(
          icon: Icons.sailing_rounded,
          label: island == null ? '섬 보상' : '${island.level.number}번 섬 보상',
          color: AppColors.wood,
          background: AppColors.woodLight.withValues(alpha: 0.18),
        );
      case _ClockStatus.forSale:
        final canAfford = _totalStars >= theme.starCost;
        return _Chip(
          icon: Icons.star_rounded,
          label: canAfford
              ? '${theme.starCost}'
              : '${theme.starCost} · ${theme.starCost - _totalStars}개 더',
          color: AppColors.woodDark,
          iconColor: AppColors.treasureOrangeDeep,
          background: canAfford
              ? AppColors.mapGlow
              : AppColors.woodLight.withValues(alpha: 0.18),
        );
    }
  }

  void _onCardTap(ClockTheme theme, _ClockStatus status) {
    switch (status) {
      case _ClockStatus.inUse:
      case _ClockStatus.owned:
        _showPreviewDialog(theme);
      case _ClockStatus.islandReward:
        _showIslandRewardDialog(theme);
      case _ClockStatus.forSale:
        if (_totalStars >= theme.starCost) {
          _showPurchaseDialog(theme);
        } else {
          _showNeedStarsDialog(theme);
        }
    }
  }

  Future<void> _useTheme(ClockTheme theme) async {
    await ThemeService.selectTheme(theme.id);
    if (!mounted) return;
    setState(() => _selectedThemeId = theme.id);
  }

  /// 가진 시계 미리보기 (바늘을 움직여 볼 수 있음)
  void _showPreviewDialog(ClockTheme theme) {
    final inUse = theme.id == _selectedThemeId;
    showDialog(
      context: context,
      builder: (dialogContext) => IslandDialog(
        top: SizedBox(
          width: 220,
          height: 220,
          child: AnalogClock(
            initialTime: ClockTime(hour: 10, minute: 10),
            interactive: true,
            showMinuteNumbers: true,
            showGuideline: false,
            theme: theme,
          ),
        ),
        title: theme.name,
        message: inUse ? '지금 쓰고 있는 시계예요.' : '바늘을 움직여 보고 마음에 들면 골라요!',
        actions: [
          ChunkyButton(
            label: inUse ? '지금 쓰는 시계' : '이 시계 쓰기',
            icon: Icons.check_rounded,
            onTap: inUse
                ? null
                : () async {
                    await _useTheme(theme);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
          ),
          SandChunkyButton(
            label: '닫기',
            onTap: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  void _showIslandRewardDialog(ClockTheme theme) {
    final island = _islandFor(theme);
    showDialog(
      context: context,
      builder: (dialogContext) => IslandDialog(
        top: Stack(
          alignment: Alignment.center,
          children: [
            ClockThemeIcon(theme: theme, size: 120, locked: true),
            _LockBadge(),
          ],
        ),
        title: theme.name,
        message: island == null
            ? '섬을 탐험하면 받을 수 있어요!'
            : '${island.level.number}번 ${island.name}을 탐험하면 받을 수 있어요!',
        actions: [
          SandChunkyButton(
            label: '알겠어요',
            onTap: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  void _showNeedStarsDialog(ClockTheme theme) {
    final missing = theme.starCost - _totalStars;
    showDialog(
      context: context,
      builder: (dialogContext) => IslandDialog(
        top: Jjakkagi(pose: MascotPose.think, height: 110),
        title: '별이 조금 부족해요',
        message: '${theme.name}을 열려면 별 $missing개가 더 필요해. 섬 퀴즈와 놀이로 별을 모아 보자!',
        actions: [
          SandChunkyButton(
            label: '알겠어요',
            onTap: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(ClockTheme theme) {
    showDialog(
      context: context,
      builder: (dialogContext) => IslandDialog(
        top: ClockThemeIcon(theme: theme, size: 130),
        title: '${theme.name} 열기',
        body: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, color: AppColors.mapStar, size: 30),
            SizedBox(width: 4),
            Text(
              '${theme.starCost}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.woodDark,
              ),
            ),
            SizedBox(width: 10),
            Text(
              '가진 별 $_totalStars개',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.wood,
              ),
            ),
          ],
        ),
        actions: [
          ChunkyButton(
            label: '별 ${theme.starCost}개로 열기',
            icon: Icons.lock_open_rounded,
            onTap: () async {
              final success = await RewardService.spendStars(theme.starCost);
              if (!success) return;
              await RewardService.unlockReward(theme.id);
              await _loadData();
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              _showUnlockAnimation(theme);
            },
          ),
          SandChunkyButton(
            label: '나중에',
            onTap: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  /// 보물상자가 흔들리다 열리며 새 시계가 나오는 연출
  void _showUnlockAnimation(ClockTheme theme) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (dialogContext, _, _) => _UnlockReveal(
        theme: theme,
        onUse: () async {
          await _useTheme(theme);
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        },
        onKeep: () => Navigator.pop(dialogContext),
      ),
    );
  }

  BoxDecoration _sandPanel({Color? borderColor, double borderWidth = 2.5}) {
    return BoxDecoration(
      color: AppColors.mapSand,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: borderColor ?? AppColors.woodLight,
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.woodDark.withValues(alpha: 0.3),
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

class _StarPill extends StatelessWidget {
  const _StarPill({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '가진 별 $stars개',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(6, 4, 10, 4),
        decoration: BoxDecoration(
          color: AppColors.mapSand,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.woodLight, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, color: AppColors.mapStar, size: 22),
            SizedBox(width: 2),
            Text(
              '$stars',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.woodDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.woodLight.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor ?? color),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.mapLock,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Icon(Icons.lock_rounded, color: Colors.white, size: 22),
    );
  }
}

class _UnlockReveal extends StatefulWidget {
  const _UnlockReveal({
    required this.theme,
    required this.onUse,
    required this.onKeep,
  });

  final ClockTheme theme;
  final VoidCallback onUse;
  final VoidCallback onKeep;

  @override
  State<_UnlockReveal> createState() => _UnlockRevealState();
}

class _UnlockRevealState extends State<_UnlockReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;
  var _revealed = false;

  @override
  void initState() {
    super.initState();
    _shake =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1400))
          ..forward().whenComplete(() {
            if (mounted) setState(() => _revealed = true);
          });
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _revealed ? '새 시계를 얻었어요!' : '두근두근...',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [Shadow(color: AppColors.mapStar, blurRadius: 12)],
                ),
              ),
              SizedBox(height: 28),
              SizedBox(
                height: 220,
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 700),
                  switchInCurve: Curves.elasticOut,
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: _revealed
                      ? Container(
                          key: ValueKey('clock'),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.mapGlow.withValues(alpha: 0.8),
                                blurRadius: 50,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClockThemeIcon(theme: widget.theme, size: 200),
                        )
                      : AnimatedBuilder(
                          key: ValueKey('chest'),
                          animation: _shake,
                          builder: (context, child) {
                            final v = _shake.value;
                            return Transform.rotate(
                              angle: math.sin(v * 34) * 0.12 * v,
                              child: child,
                            );
                          },
                          child: Image.asset(
                            'assets/images/map/locked_chest.png',
                            height: 190,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16),
              AnimatedOpacity(
                opacity: _revealed ? 1 : 0,
                duration: Duration(milliseconds: 400),
                child: Column(
                  children: [
                    Text(
                      widget.theme.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.mapGlow,
                      ),
                    ),
                    SizedBox(height: 20),
                    ChunkyButton(
                      label: '바로 쓰기',
                      icon: Icons.check_rounded,
                      onTap: _revealed ? widget.onUse : null,
                    ),
                    SizedBox(height: 10),
                    SandChunkyButton(label: '내 시계에 넣기', onTap: widget.onKeep),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AdMob 광고 관리 서비스
class AdService {
  // 광고 단위 ID
  static const String _rewardedAdUnitId = 'ca-app-pub-7214081640200790/3417247585';
  static const String _bannerAdUnitId = 'ca-app-pub-7214081640200790/3629000574';
  
  // 보상형 광고 일일 제한
  static const int _maxRewardedAdsPerDay = 3;
  static const String _rewardedAdCountKey = 'rewarded_ad_count';
  static const String _lastAdDateKey = 'last_ad_date';
  
  static BannerAd? _bannerAd;
  static RewardedAd? _rewardedAd;
  
  /// AdMob 초기화
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }
  
  /// 배너 광고 로드
  static Future<BannerAd?> loadBannerAd() async {
    final adSize = AdSize.banner;
    
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: adSize,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('배너 광고 로드 성공');
        },
        onAdFailedToLoad: (ad, error) {
          print('배너 광고 로드 실패: $error');
          ad.dispose();
        },
      ),
    );
    
    await _bannerAd!.load();
    return _bannerAd;
  }
  
  /// 보상형 광고 로드
  static Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('보상형 광고 로드 성공');
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('보상형 광고 로드 실패: $error');
          _rewardedAd = null;
        },
      ),
    );
  }
  
  /// 보상형 광고 표시
  static Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) {
      await loadRewardedAd();
      // 로드 대기
      await Future.delayed(Duration(seconds: 1));
    }
    
    if (_rewardedAd == null) {
      return false;
    }
    
    bool rewarded = false;
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // 다음 광고 미리 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('보상형 광고 표시 실패: $error');
        ad.dispose();
        _rewardedAd = null;
      },
    );
    
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('보상 획득: ${reward.amount} ${reward.type}');
        rewarded = true;
      },
    );
    
    return rewarded;
  }
  
  /// 오늘 시청한 보상형 광고 횟수 확인
  static Future<int> getTodayRewardedAdCount() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastAdDateKey);
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    if (lastDate != today) {
      // 날짜가 바뀌면 카운트 초기화
      await prefs.setString(_lastAdDateKey, today);
      await prefs.setInt(_rewardedAdCountKey, 0);
      return 0;
    }
    
    return prefs.getInt(_rewardedAdCountKey) ?? 0;
  }
  
  /// 보상형 광고 시청 횟수 증가
  static Future<void> incrementRewardedAdCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = await getTodayRewardedAdCount();
    await prefs.setInt(_rewardedAdCountKey, count + 1);
  }
  
  /// 오늘 더 볼 수 있는지 확인
  static Future<bool> canWatchRewardedAd() async {
    final count = await getTodayRewardedAdCount();
    return count < _maxRewardedAdsPerDay;
  }
  
  /// 남은 광고 시청 횟수
  static Future<int> getRemainingRewardedAds() async {
    final count = await getTodayRewardedAdCount();
    return (_maxRewardedAdsPerDay - count).clamp(0, _maxRewardedAdsPerDay);
  }
  
  /// 배너 광고 해제
  static void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }
  
  /// 보상형 광고 해제
  static void disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
  
  /// 모든 광고 해제
  static void disposeAll() {
    disposeBannerAd();
    disposeRewardedAd();
  }
}

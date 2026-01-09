import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/lobby_screen.dart';
import 'services/ad_service.dart';

void main() async {
  // 세로 모드 고정 (선택사항)
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 앱을 먼저 시작하고, AdMob 초기화는 백그라운드에서 처리
  runApp(const MyClockApp());
  
  // AdMob 초기화 (백그라운드)
  _initializeAds();
}

// AdMob 초기화를 백그라운드에서 처리
Future<void> _initializeAds() async {
  try {
    await AdService.initialize();
    
    // 보상형 광고 미리 로드
    AdService.loadRewardedAd();
  } catch (e) {
    print('AdMob 초기화 실패: $e');
  }
}

class MyClockApp extends StatelessWidget {
  const MyClockApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '째깍 보물섬',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'AppleSDGothicNeo', // iOS 기본 폰트
        scaffoldBackgroundColor: Color(0xFFFFF9E6),
      ),
      home: const LobbyScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/lobby_screen.dart';
import 'services/ad_service.dart';

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  
  // 세로 모드 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // AdMob 초기화 (앱 시작 전에 완료)
  try {
    await AdService.initialize();
    print('AdMob 초기화 완료');
    
    // 보상형 광고 미리 로드
    AdService.loadRewardedAd();
  } catch (e) {
    print('AdMob 초기화 실패: $e');
  }
  
  // 앱 시작
  runApp(const MyClockApp());
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

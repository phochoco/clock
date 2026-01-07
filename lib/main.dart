import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'screens/lobby_screen.dart';
import 'services/ad_service.dart';

void main() async {
  // 세로 모드 고정 (선택사항)
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // AdMob 초기화
  await AdService.initialize();
  
  // iOS ATT 권한 요청
  if (Platform.isIOS) {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  }
  
  // 보상형 광고 미리 로드
  AdService.loadRewardedAd();
  
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/lobby_screen.dart';

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 모드 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 앱 시작
  runApp(const MyClockApp());
}

class MyClockApp extends StatelessWidget {
  const MyClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '째깍 보물섬',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF0A84FF),
        fontFamily: 'AppleSDGothicNeo', // iOS 기본 폰트
        scaffoldBackgroundColor: Color(0xFFF8FAFC),
      ),
      home: const LobbyScreen(),
    );
  }
}

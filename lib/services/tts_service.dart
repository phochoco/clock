import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  /// TTS 초기화
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // 한국어 설정
    await _flutterTts.setLanguage("ko-KR");
    
    // 고품질 보이스 설정 (자연스러운 목소리)
    await _setNaturalVoice();
    
    // 속도 및 피치 설정 (어린이에게 적절한 속도)
    await _flutterTts.setSpeechRate(0.5); // 0.0 ~ 1.0 (0.5가 보통)
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // iOS 설정: 음소거 모드에서도 소리 나게 설정 (선택사항)
    await _flutterTts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
      ],
    );

    _isInitialized = true;
  }

  /// 자연스러운 보이스 설정 (iOS: Yuna, Android: 고품질)
  static Future<void> _setNaturalVoice() async {
    try {
      final voices = await _flutterTts.getVoices;
      if (voices == null || voices.isEmpty) return;

      Map<String, String>? selectedVoice;

      if (Platform.isIOS) {
        // iOS: Yuna (가장 자연스러운 한국어), 없으면 Sora
        // List<dynamic>으로 반환되므로 캐스팅 필요
        try {
          for (var voice in voices) {
            Map<String, String> v = Map<String, String>.from(voice);
            if (v['locale'] == 'ko-KR') {
              if (v['name']!.contains('Yuna')) {
                selectedVoice = v;
                break; // Yuna 찾으면 즉시 중단 (최우선)
              }
              if (v['name']!.contains('Sora')) {
                 // Yuna가 없을 경우를 대비해 Sora를 후보로 둡니다.
                 // 루프를 계속 돌며 Yuna를 찾습니다.
                 if (selectedVoice == null || !selectedVoice['name']!.contains('Yuna')) {
                   selectedVoice = v;
                 }
              }
            }
          }
        } catch (e) {
          print('Error parsing iOS voices: $e');
        }
      } else if (Platform.isAndroid) {
        // Android: ko-kr locale 중 고품질/여성 보이스 선호
        try {
          for (var voice in voices) {
             Map<String, String> v = Map<String, String>.from(voice);
             if (v['locale'] == 'ko-KR') {
               // 기본적으로 첫 번째 한국어 보이스 선택
               selectedVoice ??= v;
               
               // 특정 고품질 엔진 식별자가 포함된 경우 교체 (예: Google TTS 고품질)
               if (v['name']!.toLowerCase().contains('daily') || // Samsung Daily 등 자연스러운 톤
                   v['name']!.toLowerCase().contains('high')) {  // High quality
                 selectedVoice = v;
               }
             }
          }
        } catch (e) {
          print('Error parsing Android voices: $e');
        }
      }

      if (selectedVoice != null) {
        print('Selected Voice: ${selectedVoice['name']}');
        await _flutterTts.setVoice(selectedVoice);
      }
    } catch (e) {
      print('Error setting natural voice: $e');
    }
  }

  /// 텍스트 읽기
  static Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    await _flutterTts.stop(); // 기존 음성 중단
    await _flutterTts.speak(text);
  }

  /// 읽기 중단
  static Future<void> stop() async {
    await _flutterTts.stop();
  }
}

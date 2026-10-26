import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 째깍이 목소리
///
/// 미리 녹음한 음성(assets/voice, ElevenLabs로 생성)이 있는 문장은 그 파일을 재생하고,
/// 없는 문장만 기기 TTS로 읽는다. 문장과 파일은 manifest.json으로 연결된다.
class TtsService {
  static final FlutterTts _flutterTts = FlutterTts();
  static final AudioPlayer _voicePlayer = AudioPlayer();
  static bool _isInitialized = false;
  static Map<String, String>? _voiceFiles;

  /// 녹음 파일을 찾는 열쇠: 문장에서 한글·숫자·영문만 남긴다
  /// (띄어쓰기, 문장부호, 이모지, 줄바꿈용 결합자 차이는 무시)
  static String voiceKey(String text) =>
      text.replaceAll(RegExp(r'[^0-9A-Za-z\uAC00-\uD7A3]'), '');

  static Future<Map<String, String>> _loadVoiceFiles() async {
    if (_voiceFiles != null) return _voiceFiles!;
    try {
      final raw = await rootBundle.loadString('assets/voice/manifest.json');
      _voiceFiles = Map<String, String>.from(json.decode(raw) as Map);
    } catch (e) {
      debugPrint('Voice manifest not loaded: $e');
      _voiceFiles = {};
    }
    return _voiceFiles!;
  }

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
    await _flutterTts
        .setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ]);

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
                if (selectedVoice == null ||
                    !selectedVoice['name']!.contains('Yuna')) {
                  selectedVoice = v;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing iOS voices: $e');
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
              if (v['name']!.toLowerCase().contains(
                    'daily',
                  ) || // Samsung Daily 등 자연스러운 톤
                  v['name']!.toLowerCase().contains('high')) {
                // High quality
                selectedVoice = v;
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing Android voices: $e');
        }
      }

      if (selectedVoice != null) {
        debugPrint('Selected Voice: ${selectedVoice['name']}');
        await _flutterTts.setVoice(selectedVoice);
      }
    } catch (e) {
      debugPrint('Error setting natural voice: $e');
    }
  }

  /// 텍스트 읽기
  static Future<void> speak(String text) async {
    await stop(); // 기존 음성 중단

    final file = (await _loadVoiceFiles())[voiceKey(text)];
    if (file != null) {
      await _voicePlayer.play(AssetSource('voice/$file'));
      return;
    }
    debugPrint('No recorded voice, using device TTS: $text');

    if (!_isInitialized) await initialize();

    // 시간 TTS 교정 (N시를 고유어 발음표기로 명시적 변환)
    String fixedText = _fixPronunciation(text);

    await _flutterTts.speak(fixedText);
  }

  /// 0분일 때 숫자를 고유어로 치환하여 '팔시' 등으로 잘못 읽는 것을 방지
  static String _fixPronunciation(String text) {
    String result = text;
    result = result.replaceAll('12시', '열두 시');
    result = result.replaceAll('11시', '열한 시');
    result = result.replaceAll('10시', '열 시');
    result = result.replaceAll('9시', '아홉 시');
    result = result.replaceAll('8시', '여덟 시');
    result = result.replaceAll('7시', '일곱 시');
    result = result.replaceAll('6시', '여섯 시');
    result = result.replaceAll('5시', '다섯 시');
    result = result.replaceAll('4시', '네 시');
    result = result.replaceAll('3시', '세 시');
    result = result.replaceAll('2시', '두 시');
    result = result.replaceAll('1시', '한 시');
    return result;
  }

  /// 읽기 중단
  static Future<void> stop() async {
    await _voicePlayer.stop();
    if (_isInitialized) await _flutterTts.stop();
  }
}

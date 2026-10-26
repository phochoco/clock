import 'dart:math';

import '../models/quiz_level.dart';

/// 째깍이가 소리 내어 말하는 문장 모음
///
/// 여기 있는 문장은 미리 녹음한 음성 파일(assets/voice)로 재생된다.
/// 문장을 바꾸거나 새로 추가하면 tool/voice로 음성을 다시 만들어야 한다.
class VoiceLines {
  const VoiceLines._();

  // 퀴즈
  static String quizQuestion(QuizQuestion question) {
    final particle = question.minute == 0 ? '를' : '을';
    return '${question.answerText}$particle 만들어 봐요!';
  }

  static const quizIdle = '바늘을 돌려서 맞춰 봐!';

  // 문제 방식별 안내
  static const readPrompt = '시계가 가리키는 시각을 골라 봐!';

  static const readHint = '긴 바늘이 가리키는 곳부터 살펴봐!';

  static const digitalPrompt = '디지털 시계랑 똑같이 바늘을 맞춰 봐!';

  static const bossIntro = '황금성의 보스 문제야! 이것만 풀면 보물이야!';

  static const bossCleared = '보스 문제를 풀었어! 별 두 개를 더 줄게!';

  /// 섬에 도착했을 때 째깍이가 들려주는 이야기 (섬 순서대로)
  static const islandIntros = [
    '야자수 해변에 도착했어! 정각을 맞춰서 보물 동굴 문을 열자!',
    '버섯 숲 요정들이 시간을 잃어버렸대! 시계를 읽어서 도와주자!',
    '화산이 부글부글! 디지털 시계도 보고 5분 단위로 맞춰 보자!',
    '꽁꽁 얼음섬이야! 펭귄 친구들에게 1분까지 정확히 알려 주자!',
    '드디어 황금성이야! 마지막 보스 문제까지 풀면 보물이 기다려!',
  ];

  static String islandIntro(QuizLevel level) => islandIntros[level.index];

  static String arrivedAt(String islandName) => '$islandName에 도착했어!';

  static String exploreFirst(String islandName) => '$islandName부터 탐험해 줘!';

  static String correct(int stars, String comboMessage) {
    final combo = comboMessage.isEmpty ? '' : ' $comboMessage';
    return '정답이야! 별 $stars개!$combo';
  }

  static String islandComplete(String islandName) => '$islandName 탐험 완료!';

  static const allIslandsComplete = '모든 섬을 탐험했어요!';

  // 로비
  static const lobbyStart = '함께 보물섬으로 떠나자!';

  static const lobbyAllDone = '모든 섬을 탐험했어! 다시 가 볼까?';

  static String lobbySailTo(String islandName) => '$islandName으로 떠나자!';

  // 칭찬 (정답 효과음 대신)
  static const praises = ['와! 참 잘했어요!', '우와, 정답이에요!', '최고예요! 정말 잘했어요!'];

  static String randomPraise() => praises[Random().nextInt(praises.length)];

  static const snapPerfect = '퍼펙트! 딱 맞췄어요!';

  // 스토리 모드
  static const storyRetry = '아직 아니에요. 다시 한 번 맞춰볼까요?';

  static const storyComplete = '우와! 시계 마을 대모험을 무사히 마쳤어요! 축하해요!';
}

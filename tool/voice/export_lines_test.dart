// 째깍이가 말하는 모든 문장을 tool/voice/lines.json으로 내보낸다.
// 실행: flutter test tool/voice/export_lines_test.dart
// 그다음 python3 tool/voice/generate.py 로 음성 파일을 만든다.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myclock/models/clock_time.dart';
import 'package:myclock/models/quiz_level.dart';
import 'package:myclock/models/quiz_session.dart';
import 'package:myclock/screens/story_mode_screen.dart';
import 'package:myclock/services/voice_lines.dart';
import 'package:myclock/utils/clock_hint.dart';
import 'package:myclock/widgets/treasure_map.dart';

void main() {
  test('export voice lines', () {
    final lines = <String>{};
    final islands = TreasureIsland.all.map((i) => i.name).toList();

    // 퀴즈 문제 (모든 시각)
    for (var hour = 0; hour < 12; hour++) {
      for (var minute = 0; minute < 60; minute++) {
        lines.add(
          VoiceLines.quizQuestion(
            QuizQuestion(hour: hour, minute: minute, level: QuizLevel.level4),
          ),
        );
      }
    }

    // 오답 힌트 (긴 바늘이 틀린 경우, 짧은 바늘만 틀린 경우)
    for (var hour = 0; hour < 12; hour++) {
      for (var minute = 0; minute < 60; minute++) {
        final correct = ClockTime(hour: hour, minute: minute);
        lines.add(
          ClockHint.forAnswer(
            ClockTime(hour: hour, minute: (minute + 20) % 60),
            correct,
          ),
        );
        lines.add(
          ClockHint.forAnswer(
            ClockTime(hour: (hour + 3) % 12, minute: minute),
            correct,
          ),
        );
      }
    }

    // 정답 반응: 실제 퀴즈 세션으로 연속 정답 콤보를 만들어 본다
    final session = QuizSession(questionsPerLevel: 10)..start();
    for (var i = 0; i < 8; i++) {
      final q = session.currentQuestion!;
      final result = session.answer(ClockTime(hour: q.hour, minute: q.minute));
      lines.add(
        VoiceLines.correct(
          result.earnedStars,
          session.showCombo ? session.comboMessage : '',
        ),
      );
      session.nextQuestion();
    }

    lines.add(VoiceLines.quizIdle);
    lines.addAll([
      VoiceLines.readPrompt,
      VoiceLines.readHint,
      VoiceLines.digitalPrompt,
      VoiceLines.bossIntro,
      VoiceLines.bossCleared,
      ...VoiceLines.islandIntros,
    ]);
    lines.add(VoiceLines.allIslandsComplete);
    for (final name in islands) {
      lines.add(VoiceLines.arrivedAt(name));
      lines.add(VoiceLines.exploreFirst(name));
      lines.add(VoiceLines.islandComplete(name));
      lines.add(VoiceLines.lobbySailTo(name));
    }

    lines.add(VoiceLines.lobbyStart);
    lines.add(VoiceLines.lobbyAllDone);

    for (final chapter in storyChapters) {
      lines.add(chapter.narration);
    }
    lines.addAll(VoiceLines.praises);
    lines.add(VoiceLines.snapPerfect);
    lines.add(VoiceLines.storyRetry);
    lines.add(VoiceLines.storyComplete);

    final file = File('tool/voice/lines.json');
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(lines.toList()..sort()),
    );
    // ignore: avoid_print
    print('exported ${lines.length} lines');
  });
}

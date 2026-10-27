import '../utils/clock_answer_validator.dart';
import 'clock_time.dart';
import 'quiz_level.dart';

class QuizAnswerResult {
  const QuizAnswerResult({required this.isCorrect, required this.earnedStars});

  final bool isCorrect;
  final int earnedStars;
}

class QuizSession {
  QuizSession({
    QuizQuestionGenerator? questionGenerator,
    this.questionsPerLevel = 5,
  }) : _questionGenerator = questionGenerator ?? QuizQuestionGenerator();

  final QuizQuestionGenerator _questionGenerator;
  final int questionsPerLevel;

  QuizLevel currentLevel = QuizLevel.level1;
  QuizQuestion? currentQuestion;
  ClockTime? userAnswer;
  bool showResult = false;
  bool isCorrect = false;
  int score = 0;
  int combo = 0;
  String comboMessage = '';
  bool showCombo = false;
  int lastEarnedStars = 0;

  /// 이번 섬에서 틀린 횟수 (틀리면 다시 풀어서 결국 5문제를 다 맞히므로 만점 판단은 이것으로)
  int mistakes = 0;

  bool get isPerfect => mistakes == 0;

  /// 지금 문제의 방식 (문제를 낼 때 정해서 정답을 맞혀도 바뀌지 않는다)
  QuizTask currentTask = QuizTask.setHands;

  /// 황금성 마지막 보스 문제인지
  bool isBoss = false;

  void start({QuizLevel level = QuizLevel.level1}) {
    currentLevel = level;
    _resetProgress();
    _generateQuestion();
  }

  void switchLevel(QuizLevel level) {
    currentLevel = level;
    _resetProgress();
    _generateQuestion();
  }

  void setAnswer(ClockTime time) {
    userAnswer = time;
  }

  QuizAnswerResult answer(ClockTime time) {
    userAnswer = time;
    final question = currentQuestion;
    if (question == null) {
      return const QuizAnswerResult(isCorrect: false, earnedStars: 0);
    }

    final correctTime = ClockTime(hour: question.hour, minute: question.minute);
    return _record(ClockAnswerValidator.isCorrect(time, correctTime));
  }

  /// 시계 읽기 문제: 고른 보기가 정확히 같은 시각인지 (1분 차이 보기도 있어서 오차 없이)
  QuizAnswerResult answerChoice(ClockTime choice) {
    userAnswer = choice;
    final question = currentQuestion;
    if (question == null) {
      return const QuizAnswerResult(isCorrect: false, earnedStars: 0);
    }
    return _record(
      choice.hour % 12 == question.hour % 12 &&
          choice.minute == question.minute,
    );
  }

  QuizAnswerResult _record(bool correct) {
    showResult = true;
    isCorrect = correct;
    lastEarnedStars = 0;

    if (correct) {
      score++;
      combo++;
      lastEarnedStars = _starsForCombo(combo);
      comboMessage = _messageForCombo(combo);
      showCombo = comboMessage.isNotEmpty;
    } else {
      mistakes++;
      combo = 0;
      comboMessage = '';
      showCombo = false;
    }

    return QuizAnswerResult(isCorrect: correct, earnedStars: lastEarnedStars);
  }

  void nextQuestion() {
    _generateQuestion();
  }

  void retryQuestion() {
    userAnswer = null;
    showResult = false;
    isCorrect = false;
    lastEarnedStars = 0;
  }

  /// 이번 섬에서 이미 낸 시각 (같은 문제가 두 번 나오지 않게)
  final Set<int> _askedTimes = {};

  void _resetProgress() {
    _askedTimes.clear();
    mistakes = 0;
    userAnswer = null;
    showResult = false;
    isCorrect = false;
    score = 0;
    combo = 0;
    comboMessage = '';
    showCombo = false;
    lastEarnedStars = 0;
    currentQuestion = null;
  }

  void _generateQuestion() {
    // 맞힌 문제 수 = 지금 몇 번째 문제인지
    currentTask = quizTaskFor(currentLevel, score);
    isBoss = isBossQuestion(currentLevel, score, questionsPerLevel);
    currentQuestion = _questionGenerator.next(
      currentLevel,
      previous: currentQuestion,
      avoid: {
        ..._askedTimes,
        // 바늘을 돌리는 문제는 시계가 12시에서 시작하고 ±1분은 정답으로 치므로
        // 12시 정각과 그 앞뒤 1분은 내지 않는다
        if (currentTask != QuizTask.readClock) ...[0, 1, 719],
      },
    );
    final q = currentQuestion!;
    _askedTimes.add((q.hour % 12) * 60 + q.minute);
    userAnswer = null;
    showResult = false;
    isCorrect = false;
    showCombo = false;
    lastEarnedStars = 0;
  }

  int _starsForCombo(int combo) {
    if (combo >= 5) return 3;
    if (combo >= 3) return 2;
    return 1;
  }

  String _messageForCombo(int combo) {
    if (combo >= 5) return '완벽해요! 🔥';
    if (combo == 3) return '멋져요! 🌟';
    if (combo == 2) return '좋아요! 🎉';
    return '';
  }
}

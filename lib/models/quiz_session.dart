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
    final correct = ClockAnswerValidator.isCorrect(time, correctTime);

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

  void _resetProgress() {
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
    currentQuestion = _questionGenerator.next(
      currentLevel,
      previous: currentQuestion,
    );
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

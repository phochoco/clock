import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/glass_container.dart';
import '../widgets/mesh_background.dart';
import '../widgets/analog_clock.dart';
import '../models/clock_time.dart';
import '../models/clock_theme.dart';
import '../services/theme_service.dart';
import '../services/reward_service.dart';
import '../services/tts_service.dart';
import '../utils/clock_answer_validator.dart';
import '../utils/haptic.dart';
import 'package:audioplayers/audioplayers.dart';

// 스토리 모드의 챕터 모델
class StoryChapter {
  final int hour;
  final int minute;
  final String title;
  final String narration;
  final IconData icon;

  const StoryChapter({
    required this.hour,
    required this.minute,
    required this.title,
    required this.narration,
    required this.icon,
  });
}

class StoryModeScreen extends StatefulWidget {
  const StoryModeScreen({super.key});

  @override
  State<StoryModeScreen> createState() => _StoryModeScreenState();
}

class _StoryModeScreenState extends State<StoryModeScreen> {
  // 스토리 챕터 정의
  final List<StoryChapter> _chapters = const [
    StoryChapter(
      hour: 7,
      minute: 0,
      title: '아침 기상',
      narration: '아함~ 아침이 밝았어요! 7시에 일어날 시간이에요. 시계를 7시로 맞춰줄래요?',
      icon: Icons.wb_sunny_rounded,
    ),
    StoryChapter(
      hour: 8,
      minute: 30,
      title: '유치원 가는 길',
      narration: '친구들을 만나러 유치원에 가요. 8시 30분 버스를 타야 해요! 시계를 돌려볼까요?',
      icon: Icons.directions_bus_rounded,
    ),
    StoryChapter(
      hour: 12,
      minute: 30,
      title: '맛있는 점심',
      narration: '꼬르륵, 배가 고파요. 12시 30분은 점심 시간이에요!',
      icon: Icons.restaurant_rounded,
    ),
    StoryChapter(
      hour: 15,
      minute: 0,
      title: '신나는 놀이터',
      narration: '유치원이 끝났어요! 3시에 놀이터에서 놀기로 했어요. 3시로 맞춰주세요!',
      icon: Icons.park_rounded,
    ),
    StoryChapter(
      hour: 21,
      minute: 0,
      title: '꿈나라로',
      narration: '하루가 끝났어요. 9시는 쿨쿨 잠잘 시간이에요. 9시로 시계를 맞추고 자러 가요!',
      icon: Icons.nights_stay_rounded,
    ),
  ];

  int _currentChapterIndex = 0;
  ClockTime? _userAnswer;
  bool _showResult = false;
  bool _isCorrect = false;
  final GlobalKey<AnalogClockState> _clockKey = GlobalKey();

  ClockTheme _selectedTheme = ClockThemeList.basic;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _initTts();
    _playNarration();
  }

  Future<void> _loadTheme() async {
    final theme = await ThemeService.getSelectedTheme();
    setState(() {
      _selectedTheme = theme;
    });
  }

  Future<void> _initTts() async {
    await TtsService.initialize();
  }

  void _playNarration() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        TtsService.speak(_chapters[_currentChapterIndex].narration);
      }
    });
  }

  @override
  void dispose() {
    TtsService.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _checkAnswer() async {
    if (_userAnswer == null) return;
    final currentChapter = _chapters[_currentChapterIndex];
    final correctTime = ClockTime(
      hour: currentChapter.hour,
      minute: currentChapter.minute,
    );

    final correct = ClockAnswerValidator.isCorrect(_userAnswer!, correctTime);

    setState(() {
      _showResult = true;
      _isCorrect = correct;
      if (correct) {
        _audioPlayer.play(AssetSource('good/good.mp3'));
        HapticHelper.heavyImpact();
      } else {
        HapticHelper.vibrate();
        TtsService.speak('아직 아니에요. 다시 한 번 맞춰볼까요?');
      }
    });
  }

  void _nextChapter() {
    setState(() {
      if (_currentChapterIndex < _chapters.length - 1) {
        _currentChapterIndex++;
        _showResult = false;
        _userAnswer = null;
        _clockKey.currentState?.resetToCurrentTime();
        _playNarration();
      } else {
        // 모든 챕터 완료
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() async {
    TtsService.speak('우와! 시계 마을 대모험을 무사히 마쳤어요! 축하해요!');

    // 이전에 깬 적이 있는지 확인
    final alreadyCompleted = await RewardService.isStoryModeCompleted();

    // 스토리 모드 클리어 보상 지급 (내부에서 중복 방지됨)
    await RewardService.completeStoryMode();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.stars_rounded, color: Colors.amber, size: 32),
            SizedBox(width: 8),
            Text('모험 완료!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          alreadyCompleted
              ? '시계 마을 대모험을 또 끝냈어요!\n정말 대단해요!'
              : '시계 마을 대모험을 모두 끝냈어요!\n\n완료 보상으로 별 100개가 지급되었습니다!',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // exit story mode
            },
            child: Text('마을로 돌아가기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clockSize = (MediaQuery.of(context).size.width - 48)
        .clamp(240.0, 300.0)
        .toDouble();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '시계 마을 대모험',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: 0,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textDark),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: MeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 진행률 바
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: List.generate(_chapters.length, (index) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        decoration: BoxDecoration(
                          color: index <= _currentChapterIndex
                              ? AppColors.success
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // 내러티브 카드
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: GlassContainer(
                  padding: EdgeInsets.all(24),
                  borderRadius: 24,
                  opacity: 0.8,
                  child: Row(
                    children: [
                      Icon(
                        _chapters[_currentChapterIndex].icon,
                        size: 48,
                        color: AppColors.hourRed,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _chapters[_currentChapterIndex].title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.minuteBlue,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _chapters[_currentChapterIndex].narration,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textDark,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.minuteBlue,
                          size: 28,
                        ),
                        onPressed: _playNarration,
                      ),
                    ],
                  ),
                ),
              ),

              Spacer(),

              // 시계 영역
              SizedBox(
                height: clockSize,
                width: clockSize,
                child: AnalogClock(
                  key: _clockKey,
                  theme: _selectedTheme,
                  interactive: !_showResult || !_isCorrect,
                  notifyInitialTime: false,
                  onTimeChanged: (time) {
                    setState(() {
                      _userAnswer = time;
                      if (_showResult && !_isCorrect) {
                        _showResult = false;
                      }
                    });
                  },
                ),
              ),

              Spacer(),

              // 하단 버튼/결과 창
              Padding(
                padding: EdgeInsets.all(24),
                child: _showResult
                    ? _buildResultCard()
                    : SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _userAnswer == null ? null : _checkAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.minuteBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                            shadowColor: AppColors.minuteBlue.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          child: Text(
                            '확인하기',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_isCorrect) {
      return GlassContainer(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        borderRadius: 20,
        opacity: 0.9,
        // color: AppColors.success.withValues(alpha: 0.2),  GlassContainer doesn't have color directly
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  '참 잘했어요!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _nextChapter,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _currentChapterIndex < _chapters.length - 1 ? '다음 이야기' : '완료하기',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return GlassContainer(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        borderRadius: 20,
        opacity: 0.9,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  '다시 해볼까요?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _showResult = false;
                });
              },
              child: Text(
                '다시하기',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

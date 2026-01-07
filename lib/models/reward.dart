/// 보물 아이템 모델
class Reward {
  final String id;
  final String name;
  final String emoji;
  final int levelRequired; // 획득에 필요한 레벨
  final String themeId; // 연결된 테마 ID
  
  const Reward({
    required this.id,
    required this.name,
    required this.emoji,
    required this.levelRequired,
    required this.themeId,
  });
  
  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'levelRequired': levelRequired,
      'themeId': themeId,
    };
  }
  
  /// JSON에서 생성
  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      levelRequired: json['levelRequired'] as int,
      themeId: json['themeId'] as String,
    );
  }
}

/// 사용 가능한 모든 보물 목록
class RewardList {
  static const List<Reward> all = [
    Reward(
      id: 'basic_clock',
      name: '기본 시계',
      emoji: '🕐',
      levelRequired: 0, // 처음부터 해금
      themeId: 'basic_clock',
    ),
    Reward(
      id: 'rainbow_clock',
      name: '무지개 시계',
      emoji: '🌈',
      levelRequired: 1,
      themeId: 'rainbow_clock',
    ),
    Reward(
      id: 'star_clock',
      name: '별빛 시계',
      emoji: '⭐',
      levelRequired: 2,
      themeId: 'star_clock',
    ),
    Reward(
      id: 'flower_clock',
      name: '꽃 시계',
      emoji: '🌸',
      levelRequired: 3,
      themeId: 'flower_clock',
    ),
    Reward(
      id: 'art_clock',
      name: '그림 시계',
      emoji: '🎨',
      levelRequired: 4,
      themeId: 'art_clock',
    ),
    Reward(
      id: 'music_clock',
      name: '음악 시계',
      emoji: '🎵',
      levelRequired: 5,
      themeId: 'music_clock',
    ),
  ];
  
  /// 레벨에 해당하는 보물 찾기
  static Reward? getRewardForLevel(int level) {
    try {
      return all.firstWhere((reward) => reward.levelRequired == level);
    } catch (e) {
      return null;
    }
  }
}

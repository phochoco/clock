import 'package:flutter/material.dart';

/// 보물 아이템 모델
class Reward {
  final String id;
  final String name;
  final IconData icon; // emoji -> icon
  final Color iconColor; // 추가: 아이콘 색상
  final int levelRequired; // 획득에 필요한 레벨
  final String themeId; // 연결된 테마 ID

  const Reward({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.levelRequired,
    required this.themeId,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon.codePoint, // int로 저장
      'iconColor': iconColor.toARGB32(),
      'levelRequired': levelRequired,
      'themeId': themeId,
    };
  }

  /// JSON에서 생성
  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      iconColor: Color(json['iconColor'] as int),
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
      icon: Icons.schedule_rounded,
      iconColor: Colors.blueGrey,
      levelRequired: 0, // 처음부터 해금
      themeId: 'basic_clock',
    ),
    Reward(
      id: 'rainbow_clock',
      name: '무지개 시계',
      icon: Icons.palette_rounded,
      iconColor: Colors.purpleAccent,
      levelRequired: 1,
      themeId: 'rainbow_clock',
    ),
    Reward(
      id: 'star_clock',
      name: '별빛 시계',
      icon: Icons.star_rounded,
      iconColor: Colors.amber,
      levelRequired: 2,
      themeId: 'star_clock',
    ),
    Reward(
      id: 'flower_clock',
      name: '꽃 시계',
      icon: Icons.local_florist_rounded,
      iconColor: Colors.pinkAccent,
      levelRequired: 3,
      themeId: 'flower_clock',
    ),
    Reward(
      id: 'art_clock',
      name: '그림 시계',
      icon: Icons.color_lens_rounded,
      iconColor: Colors.lightBlue,
      levelRequired: 4,
      themeId: 'art_clock',
    ),
    Reward(
      id: 'music_clock',
      name: '음악 시계',
      icon: Icons.music_note_rounded,
      iconColor: Colors.deepPurple,
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

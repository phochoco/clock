import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/clock_theme.dart';

/// 시계 테마 저장 및 관리 서비스
class ThemeService {
  static const String _selectedThemeKey = 'selected_theme';
  
  /// 현재 선택된 테마 ID 가져오기
  static Future<String> getSelectedThemeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedThemeKey) ?? 'basic_clock';
  }
  
  /// 현재 선택된 테마 가져오기
  static Future<ClockTheme> getSelectedTheme() async {
    final themeId = await getSelectedThemeId();
    return ClockThemeList.getThemeById(themeId);
  }
  
  /// 테마 선택
  static Future<void> selectTheme(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedThemeKey, themeId);
  }
}

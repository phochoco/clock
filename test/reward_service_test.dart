import 'package:flutter_test/flutter_test.dart';
import 'package:myclock/models/clock_theme.dart';
import 'package:myclock/services/reward_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('completeLevel reports only the first clear of an island', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await RewardService.completeLevel(1), isTrue);
    expect(await RewardService.completeLevel(1), isFalse);
    expect(await RewardService.completeLevel(2), isTrue);
  });

  test('star-shop prices climb from 100 to 250', () {
    final prices = ClockThemeList.premiumThemes.map((t) => t.starCost).toList()
      ..sort();
    expect(prices.first, 100);
    expect(prices.last, 250);
    expect(prices.toSet().length, prices.length);
  });
}

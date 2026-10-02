import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_track/models/user_settings.dart';

void main() {
  group('UserSettings.calculateTarget', () {
    test('calculates target for 60kg person (60 * 32 = 1920)', () {
      expect(UserSettings.calculateTarget(60), 1920);
    });

    test('calculates target for 70kg person (70 * 32 = 2240)', () {
      expect(UserSettings.calculateTarget(70), 2240);
    });

    test('calculates target for 50kg person (50 * 32 = 1600)', () {
      expect(UserSettings.calculateTarget(50), 1600);
    });

    test('calculates target for 80.5kg person (80.5 * 32 = 2576)', () {
      expect(UserSettings.calculateTarget(80.5), 2576);
    });

    test('rounds correctly for fractional weights', () {
      // 62.3 * 32 = 1993.6 → rounds to 1994
      expect(UserSettings.calculateTarget(62.3), 1994);
    });

    test('handles very light weight', () {
      expect(UserSettings.calculateTarget(30), 960);
    });

    test('handles heavy weight', () {
      expect(UserSettings.calculateTarget(120), 3840);
    });
  });

  group('UserSettings.copyWith', () {
    late UserSettings original;

    setUp(() {
      original = UserSettings(
        weightKg: 60,
        dailyTargetMl: 1920,
        wakeTimeHour: 7,
        wakeTimeMinute: 0,
        sleepTimeHour: 23,
        sleepTimeMinute: 0,
        reminderIntervalMinutes: 120,
      );
    });

    test('copies with no changes returns equivalent values', () {
      final copy = original.copyWith();
      expect(copy.weightKg, 60);
      expect(copy.dailyTargetMl, 1920);
      expect(copy.wakeTimeHour, 7);
      expect(copy.wakeTimeMinute, 0);
      expect(copy.sleepTimeHour, 23);
      expect(copy.sleepTimeMinute, 0);
      expect(copy.reminderIntervalMinutes, 120);
    });

    test('copies with weight change', () {
      final copy = original.copyWith(weightKg: 75);
      expect(copy.weightKg, 75);
      expect(copy.dailyTargetMl, 1920); // Not auto-recalculated
    });

    test('copies with new daily target', () {
      final copy = original.copyWith(dailyTargetMl: 2000);
      expect(copy.dailyTargetMl, 2000);
      expect(copy.weightKg, 60);
    });

    test('copies with new reminder interval', () {
      final copy = original.copyWith(reminderIntervalMinutes: 60);
      expect(copy.reminderIntervalMinutes, 60);
    });
  });
}

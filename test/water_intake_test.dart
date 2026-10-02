import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:aqua_track/models/water_log.dart';
import 'package:aqua_track/providers/water_intake_provider.dart';
import 'dart:io';

/// Helper to set up Hive for tests with a temporary directory
Future<Box<WaterLog>> setUpHiveBox() async {
  final tempDir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(tempDir.path);
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(WaterLogAdapter());
  }
  // Use a unique box name per test to avoid conflicts
  final boxName = 'test_water_logs_${DateTime.now().microsecondsSinceEpoch}';
  return await Hive.openBox<WaterLog>(boxName);
}

void main() {
  group('WaterIntakeNotifier', () {
    late Box<WaterLog> box;
    late WaterIntakeNotifier notifier;

    setUp(() async {
      box = await setUpHiveBox();
      notifier = WaterIntakeNotifier(box);
    });

    tearDown(() async {
      await box.clear();
      await box.close();
    });

    group('addLog', () {
      test('adds a log and increases state', () async {
        expect(notifier.state.length, 0);
        await notifier.addLog(200);
        expect(notifier.state.length, 1);
        expect(notifier.state.first.amountMl, 200);
      });

      test('multiple logs accumulate', () async {
        await notifier.addLog(100);
        await notifier.addLog(200);
        await notifier.addLog(300);
        expect(notifier.state.length, 3);
      });
    });

    group('getTodayTotal', () {
      test('returns 0 when no logs', () {
        expect(notifier.getTodayTotal(), 0);
      });

      test('sums today logs correctly', () async {
        await notifier.addLog(100);
        await notifier.addLog(250);
        await notifier.addLog(150);
        expect(notifier.getTodayTotal(), 500);
      });

      test('excludes yesterday logs', () async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        await notifier.addLogAt(500, yesterday);
        await notifier.addLog(200);
        expect(notifier.getTodayTotal(), 200);
      });
    });

    group('getLastNDays', () {
      test('returns N entries', () {
        final days = notifier.getLastNDays(7);
        expect(days.length, 7);
      });

      test('returns 30 entries for 30 days', () {
        final days = notifier.getLastNDays(30);
        expect(days.length, 30);
      });

      test('last entry is today', () {
        final now = DateTime.now();
        final days = notifier.getLastNDays(7);
        final lastDay = days.last;
        expect(lastDay.date.year, now.year);
        expect(lastDay.date.month, now.month);
        expect(lastDay.date.day, now.day);
      });

      test('first entry is 6 days ago for 7-day range', () {
        final now = DateTime.now();
        final sixDaysAgo = now.subtract(const Duration(days: 6));
        final days = notifier.getLastNDays(7);
        final firstDay = days.first;
        expect(firstDay.date.year, sixDaysAgo.year);
        expect(firstDay.date.month, sixDaysAgo.month);
        expect(firstDay.date.day, sixDaysAgo.day);
      });

      test('correctly aggregates logs per day', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day, 10, 0);
        final yesterday = today.subtract(const Duration(days: 1));
        final twoDaysAgo = today.subtract(const Duration(days: 2));

        await notifier.addLogAt(100, today);
        await notifier.addLogAt(200, today.add(const Duration(hours: 1)));
        await notifier.addLogAt(500, yesterday);
        await notifier.addLogAt(300, twoDaysAgo);
        await notifier.addLogAt(150, twoDaysAgo.add(const Duration(hours: 2)));

        final days = notifier.getLastNDays(7);

        // today (last entry) = 100 + 200 = 300
        expect(days[6].totalMl, 300);
        // yesterday = 500
        expect(days[5].totalMl, 500);
        // two days ago = 300 + 150 = 450
        expect(days[4].totalMl, 450);
        // earlier days = 0
        expect(days[0].totalMl, 0);
        expect(days[1].totalMl, 0);
        expect(days[2].totalMl, 0);
        expect(days[3].totalMl, 0);
      });

      test('includes targetMl in DailyIntake when provided', () {
        final days = notifier.getLastNDays(7, targetMl: 2000);
        for (final day in days) {
          expect(day.targetMl, 2000);
        }
      });
    });

    group('DailyIntake.percentage', () {
      test('calculates percentage correctly', () {
        final intake = DailyIntake(date: DateTime.now(), totalMl: 1500, targetMl: 2000);
        expect(intake.percentage, 75.0);
      });

      test('returns 0 when target is 0', () {
        final intake = DailyIntake(date: DateTime.now(), totalMl: 1500, targetMl: 0);
        expect(intake.percentage, 0);
      });

      test('handles over 100%', () {
        final intake = DailyIntake(date: DateTime.now(), totalMl: 2500, targetMl: 2000);
        expect(intake.percentage, 125.0);
      });

      test('returns 0 when no intake', () {
        final intake = DailyIntake(date: DateTime.now(), totalMl: 0, targetMl: 2000);
        expect(intake.percentage, 0.0);
      });
    });

    group('findBestDay', () {
      test('returns null for empty list', () {
        expect(WaterIntakeNotifier.findBestDay([]), null);
      });

      test('returns null when all days are zero', () {
        final days = [
          DailyIntake(date: DateTime.now(), totalMl: 0),
          DailyIntake(date: DateTime.now().subtract(const Duration(days: 1)), totalMl: 0),
        ];
        expect(WaterIntakeNotifier.findBestDay(days), null);
      });

      test('finds the day with highest intake', () {
        final now = DateTime.now();
        final days = [
          DailyIntake(date: now.subtract(const Duration(days: 2)), totalMl: 1500),
          DailyIntake(date: now.subtract(const Duration(days: 1)), totalMl: 2500),
          DailyIntake(date: now, totalMl: 1800),
        ];
        final best = WaterIntakeNotifier.findBestDay(days);
        expect(best, isNotNull);
        expect(best!.totalMl, 2500);
      });
    });

    group('deleteLog', () {
      test('removes a specific log', () async {
        await notifier.addLog(100);
        await notifier.addLog(200);
        expect(notifier.state.length, 2);

        final logId = notifier.state.first.id;
        await notifier.deleteLog(logId);
        expect(notifier.state.length, 1);
      });
    });

    group('clearAll', () {
      test('removes all logs', () async {
        await notifier.addLog(100);
        await notifier.addLog(200);
        await notifier.addLog(300);
        expect(notifier.state.length, 3);

        await notifier.clearAll();
        expect(notifier.state.length, 0);
        expect(notifier.getTodayTotal(), 0);
      });
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/water_log.dart';

const _uuid = Uuid();

/// Provider for the WaterLog Hive box
final waterLogBoxProvider = Provider<Box<WaterLog>>((ref) {
  throw UnimplementedError('waterLogBoxProvider must be overridden at startup');
});

/// Aggregated daily intake data
class DailyIntake {
  final DateTime date;
  final int totalMl;
  final int targetMl;

  DailyIntake({
    required this.date,
    required this.totalMl,
    this.targetMl = 0,
  });

  double get percentage => targetMl > 0 ? (totalMl / targetMl * 100).clamp(0, 999) : 0;
}

/// Provider that manages water intake logs
class WaterIntakeNotifier extends StateNotifier<List<WaterLog>> {
  final Box<WaterLog> _box;

  WaterIntakeNotifier(this._box) : super(_box.values.toList());

  /// Add a new water log entry
  Future<void> addLog(int amountMl) async {
    final log = WaterLog(
      id: _uuid.v4(),
      amountMl: amountMl,
      timestamp: DateTime.now(),
    );
    await _box.put(log.id, log);
    state = _box.values.toList();
  }

  /// Add a water log with a specific timestamp (for testing / backfill)
  Future<void> addLogAt(int amountMl, DateTime timestamp) async {
    final log = WaterLog(
      id: _uuid.v4(),
      amountMl: amountMl,
      timestamp: timestamp,
    );
    await _box.put(log.id, log);
    state = _box.values.toList();
  }

  /// Get today's total intake in ml
  int getTodayTotal() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return state
        .where((log) =>
            !log.timestamp.isBefore(todayStart))
        .fold(0, (sum, log) => sum + log.amountMl);
  }

  /// Get today's logs sorted by time (most recent first)
  List<WaterLog> getTodayLogs() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final logs = state
        .where((log) => !log.timestamp.isBefore(todayStart))
        .toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  /// Get aggregated daily intake for the last N days
  List<DailyIntake> getLastNDays(int n, {int targetMl = 0}) {
    final now = DateTime.now();
    final List<DailyIntake> result = [];

    for (int i = n - 1; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));
      final nextDate = date.add(const Duration(days: 1));
      final total = state
          .where((log) =>
              !log.timestamp.isBefore(date) &&
              log.timestamp.isBefore(nextDate))
          .fold(0, (sum, log) => sum + log.amountMl);
      result.add(DailyIntake(date: date, totalMl: total, targetMl: targetMl));
    }

    return result;
  }

  /// Get aggregated daily intake for ALL days that have logs
  List<DailyIntake> getAllDays({int targetMl = 0}) {
    if (state.isEmpty) return [];

    // Find the earliest log date
    DateTime earliest = state.first.timestamp;
    for (final log in state) {
      if (log.timestamp.isBefore(earliest)) {
        earliest = log.timestamp;
      }
    }

    final now = DateTime.now();
    final startDate = DateTime(earliest.year, earliest.month, earliest.day);
    final endDate = DateTime(now.year, now.month, now.day);
    final dayCount = endDate.difference(startDate).inDays + 1;

    return getLastNDays(dayCount, targetMl: targetMl);
  }

  /// Find the best day (highest intake) from a list of DailyIntake
  static DailyIntake? findBestDay(List<DailyIntake> days) {
    if (days.isEmpty) return null;
    DailyIntake best = days.first;
    for (final day in days) {
      if (day.totalMl > best.totalMl) {
        best = day;
      }
    }
    return best.totalMl > 0 ? best : null;
  }

  /// Delete a specific log by ID
  Future<void> deleteLog(String id) async {
    await _box.delete(id);
    state = _box.values.toList();
  }

  /// Clear all water logs
  Future<void> clearAll() async {
    await _box.clear();
    state = [];
  }
}

final waterIntakeProvider =
    StateNotifierProvider<WaterIntakeNotifier, List<WaterLog>>((ref) {
  final box = ref.watch(waterLogBoxProvider);
  return WaterIntakeNotifier(box);
});

/// Convenience provider for today's total
final todayTotalProvider = Provider<int>((ref) {
  ref.watch(waterIntakeProvider);
  return ref.read(waterIntakeProvider.notifier).getTodayTotal();
});

/// Convenience provider for last 7 days
final last7DaysProvider = Provider<List<DailyIntake>>((ref) {
  ref.watch(waterIntakeProvider);
  return ref.read(waterIntakeProvider.notifier).getLastNDays(7);
});

/// Convenience provider for last 30 days
final last30DaysProvider = Provider<List<DailyIntake>>((ref) {
  ref.watch(waterIntakeProvider);
  return ref.read(waterIntakeProvider.notifier).getLastNDays(30);
});

/// Convenience provider for today's progress percentage
final todayProgressProvider = Provider<double>((ref) {
  final todayTotal = ref.watch(todayTotalProvider);
  // We need settings to know the target — import handled by the consumer
  return todayTotal.toDouble();
});

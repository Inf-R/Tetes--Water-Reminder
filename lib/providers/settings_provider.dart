import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_settings.dart';
import '../services/notification_service.dart';

/// Provider for the UserSettings Hive box
final settingsBoxProvider = Provider<Box<UserSettings>>((ref) {
  throw UnimplementedError('settingsBoxProvider must be overridden at startup');
});

/// Provider that reads/writes UserSettings
class SettingsNotifier extends StateNotifier<UserSettings?> {
  final Box<UserSettings> _box;

  SettingsNotifier(this._box) : super(_box.get('settings'));

  bool get isOnboarded => state != null;

  Future<void> saveSettings(UserSettings settings) async {
    await _box.put('settings', settings);
    state = settings;
    
    // Reschedule notifications with new settings
    await NotificationService().scheduleReminders(settings);
  }

  Future<void> updateSettings({
    double? weightKg,
    int? dailyTargetMl,
    int? wakeTimeHour,
    int? wakeTimeMinute,
    int? sleepTimeHour,
    int? sleepTimeMinute,
    int? reminderIntervalMinutes,
  }) async {
    if (state == null) return;
    final updated = state!.copyWith(
      weightKg: weightKg,
      dailyTargetMl: dailyTargetMl,
      wakeTimeHour: wakeTimeHour,
      wakeTimeMinute: wakeTimeMinute,
      sleepTimeHour: sleepTimeHour,
      sleepTimeMinute: sleepTimeMinute,
      reminderIntervalMinutes: reminderIntervalMinutes,
    );
    await saveSettings(updated);
  }

  Future<void> clearSettings() async {
    await _box.delete('settings');
    state = null;
    
    // Cancel all notifications on reset
    await NotificationService().cancelAll();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, UserSettings?>((ref) {
  final box = ref.watch(settingsBoxProvider);
  return SettingsNotifier(box);
});

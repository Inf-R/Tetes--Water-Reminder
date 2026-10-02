import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 0)
class UserSettings extends HiveObject {
  @HiveField(0)
  double weightKg;

  @HiveField(1)
  int dailyTargetMl;

  @HiveField(2)
  int wakeTimeHour;

  @HiveField(3)
  int wakeTimeMinute;

  @HiveField(4)
  int sleepTimeHour;

  @HiveField(5)
  int sleepTimeMinute;

  @HiveField(6)
  int reminderIntervalMinutes;

  UserSettings({
    required this.weightKg,
    required this.dailyTargetMl,
    required this.wakeTimeHour,
    required this.wakeTimeMinute,
    required this.sleepTimeHour,
    required this.sleepTimeMinute,
    this.reminderIntervalMinutes = 120,
  });

  /// Auto-calculate daily target from weight: weightKg * 32
  static int calculateTarget(double weightKg) {
    return (weightKg * 32).round();
  }

  UserSettings copyWith({
    double? weightKg,
    int? dailyTargetMl,
    int? wakeTimeHour,
    int? wakeTimeMinute,
    int? sleepTimeHour,
    int? sleepTimeMinute,
    int? reminderIntervalMinutes,
  }) {
    return UserSettings(
      weightKg: weightKg ?? this.weightKg,
      dailyTargetMl: dailyTargetMl ?? this.dailyTargetMl,
      wakeTimeHour: wakeTimeHour ?? this.wakeTimeHour,
      wakeTimeMinute: wakeTimeMinute ?? this.wakeTimeMinute,
      sleepTimeHour: sleepTimeHour ?? this.sleepTimeHour,
      sleepTimeMinute: sleepTimeMinute ?? this.sleepTimeMinute,
      reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
    );
  }
}

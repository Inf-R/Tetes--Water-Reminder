import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/user_settings.dart';

/// Service for scheduling water reminder notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification plugin and timezone data
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    // Get the device's IANA timezone name via native platform call
    // (e.g. "Asia/Jakarta", "America/New_York" — NOT abbreviations like "WIB")
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      developer.log(
        'Device IANA timezone: $timeZoneName',
        name: 'NotificationService',
      );
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      developer.log(
        'Failed to resolve device timezone: $e — falling back to UTC',
        name: 'NotificationService',
      );
      tz.setLocalLocation(tz.UTC);
    }

    developer.log(
      'tz.local is now: ${tz.local.name} (current time: ${tz.TZDateTime.now(tz.local)})',
      name: 'NotificationService',
    );

    // Android initialization settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // User tapped notification - could navigate to home screen
    // For now, just opening the app is enough
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions() async {
    if (!_initialized) await init();

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return false;

    // Request POST_NOTIFICATIONS permission (Android 13+)
    bool? granted = await androidPlugin.requestNotificationsPermission();

    // Request exact alarm permission (Android 12+)
    // Note: This may require user to go to system settings on some devices
    bool? exactAlarmGranted =
        await androidPlugin.requestExactAlarmsPermission();

    return (granted ?? false) && (exactAlarmGranted ?? true);
  }

  /// Schedule daily repeating reminders based on user settings
  ///
  /// Strategy: Use `matchDateTimeComponents: DateTimeComponents.time` to
  /// schedule notifications that repeat daily at specific times.
  /// This is simpler than scheduling 7 days ahead and re-scheduling weekly.
  Future<void> scheduleReminders(UserSettings settings) async {
    if (!_initialized) await init();

    // Cancel all existing notifications first
    await cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    final wakeHour = settings.wakeTimeHour;
    final wakeMinute = settings.wakeTimeMinute;
    final sleepHour = settings.sleepTimeHour;
    final sleepMinute = settings.sleepTimeMinute;
    final intervalMinutes = settings.reminderIntervalMinutes;

    // Calculate wake and sleep times in minutes from midnight
    final wakeTimeMinutes = wakeHour * 60 + wakeMinute;
    final sleepTimeMinutes = sleepHour * 60 + sleepMinute;

    developer.log(
      'Scheduling reminders: wake=$wakeHour:${wakeMinute.toString().padLeft(2, "0")}, '
      'sleep=$sleepHour:${sleepMinute.toString().padLeft(2, "0")}, '
      'interval=${intervalMinutes}min, now=$now, tz=${tz.local.name}',
      name: 'NotificationService',
    );

    // Generate all reminder times
    final reminderTimes = <tz.TZDateTime>[];
    int currentMinutes = wakeTimeMinutes;

    while (currentMinutes <= sleepTimeMinutes) {
      final hour = currentMinutes ~/ 60;
      final minute = currentMinutes % 60;

      var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If this time has already passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      reminderTimes.add(scheduledTime);
      currentMinutes += intervalMinutes;
    }

    // Schedule each reminder
    const androidDetails = AndroidNotificationDetails(
      'water_reminders',
      'Water Reminders',
      channelDescription: 'Reminds you to drink water throughout the day',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);

    for (int i = 0; i < reminderTimes.length; i++) {
      final time = reminderTimes[i];

      developer.log(
        'Scheduling notification ID=$i at $time (${time.timeZoneName})',
        name: 'NotificationService',
      );

      await _notifications.zonedSchedule(
        i, // Unique ID for each reminder slot
        '💧 Time to hydrate!',
        'Drink some water to stay healthy and energized.',
        time,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // Verify: log all pending notification requests
    await _logPendingNotifications();
  }

  /// Log all pending notifications for diagnostic purposes
  Future<void> _logPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    developer.log(
      '--- Pending notification requests: ${pending.length} ---',
      name: 'NotificationService',
    );
    for (final req in pending) {
      developer.log(
        '  ID=${req.id}, title="${req.title}", body="${req.body}"',
        name: 'NotificationService',
      );
    }
    developer.log(
      '--- End pending notifications ---',
      name: 'NotificationService',
    );
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) await init();

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return false;

    return await androidPlugin.areNotificationsEnabled() ?? false;
  }
}

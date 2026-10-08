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
  Future<void>? _initializing;
  Future<void> _scheduling = Future<void>.value();

  void _trace(String message, {bool stack = false}) {
    developer.log('${DateTime.now().toIso8601String()} $message',
        name: 'NotificationService', stackTrace: stack ? StackTrace.current : null);
  }

  /// Initialize the notification plugin and timezone data
  Future<void> init() => _initialized
      ? Future<void>.value()
      : (_initializing ??= _initOnce().whenComplete(() => _initializing = null));

  Future<void> _initOnce() async {
    _trace('init started');
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
    _trace('init completed');
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
  Future<void> scheduleReminders(UserSettings settings, {String source = 'unknown'}) {
    _trace('scheduleReminders requested by $source', stack: true);
    // Serialize overlapping startup/settings/reset operations so stale jobs
    // cannot cancel a newer schedule after it finishes.
    final job = _scheduling.catchError((Object _) {}).then((_) async {
      if (!_initialized) await init();
      await _scheduleReminders(settings, source);
    });
    _scheduling = job;
    return job;
  }

  Future<void> _scheduleReminders(UserSettings settings, String source) async {
    _trace('scheduleReminders BEGIN source=$source');
    // Cancel all existing notifications first
    await _cancelAll(source: 'scheduleReminders/$source');

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
    await _logPendingNotifications('after schedule/$source');
    _trace('scheduleReminders END source=$source');
  }

  /// Snapshot on resume: compare with the last scheduling snapshot and
  /// adb's alarm/notification dumps to distinguish app cancellation from OS.
  Future<void> logPendingNotifications(String reason) async {
    if (!_initialized) await init();
    await _logPendingNotifications(reason);
  }

  Future<void> _logPendingNotifications(String reason) async {
    final pending = await _notifications.pendingNotificationRequests();
    developer.log(
      '${DateTime.now().toIso8601String()} [$reason] --- Pending notification requests: ${pending.length} ---',
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
  Future<void> cancelAll({String source = 'unknown'}) {
    _trace('cancelAll requested by $source', stack: true);
    final job = _scheduling.catchError((Object _) {}).then((_) async {
      await _cancelAll(source: source);
    });
    _scheduling = job;
    return job;
  }

  Future<void> _cancelAll({required String source}) async {
    _trace('cancelAll BEGIN source=$source', stack: true);
    await _notifications.cancelAll();
    await _logPendingNotifications('after cancelAll/$source');
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

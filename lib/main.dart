import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/user_settings.dart';
import 'models/water_log.dart';
import 'providers/settings_provider.dart';
import 'providers/water_intake_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_shell.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(WaterLogAdapter());

  // Open boxes
  final settingsBox = await Hive.openBox<UserSettings>('user_settings');
  final waterLogBox = await Hive.openBox<WaterLog>('water_logs');

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // Reschedule notifications if user already onboarded
  // (handles app restart and device reboot)
  if (settingsBox.isNotEmpty) {
    final settings = settingsBox.values.first;
    await notificationService.scheduleReminders(settings);
  }

  runApp(
    ProviderScope(
      overrides: [
        settingsBoxProvider.overrideWithValue(settingsBox),
        waterLogBoxProvider.overrideWithValue(waterLogBox),
      ],
      child: const AquaTrackApp(),
    ),
  );
}

class AquaTrackApp extends ConsumerWidget {
  const AquaTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isOnboarded = settings != null;

    return MaterialApp(
      title: 'AquaTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isOnboarded ? const MainShell() : const OnboardingScreen(),
    );
  }
}

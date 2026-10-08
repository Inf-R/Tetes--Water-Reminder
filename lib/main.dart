import 'dart:async';
import 'dart:developer' as developer;

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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AquaTrackBootstrap());
}

/// Render a Flutter frame before touching storage or the notification plugin.
/// The real provider scope is only created after both boxes are open.
class AquaTrackBootstrap extends StatefulWidget {
  const AquaTrackBootstrap({super.key});

  @override
  State<AquaTrackBootstrap> createState() => _AquaTrackBootstrapState();
}

class _AquaTrackBootstrapState extends State<AquaTrackBootstrap>
    with WidgetsBindingObserver {
  Box<UserSettings>? _settingsBox;
  Box<WaterLog>? _waterLogBox;
  Object? _error;
  late final Stopwatch _startup = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_bootstrap());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    developer.log('${DateTime.now().toIso8601String()} lifecycle=$state',
        name: 'AquaTrackBootstrap');
    // Flutter/Dart is suspended while backgrounded; snapshot on resume.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.resumed) {
      if (_settingsBox != null) {
        unawaited(NotificationService()
            .logPendingNotifications('lifecycle=$state')
            .catchError((Object error, StackTrace stack) {
          developer.log('Pending snapshot failed', name: 'AquaTrackBootstrap',
              error: error, stackTrace: stack);
        }));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() => _error = null);
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserSettingsAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(WaterLogAdapter());

      final settingsBox = await Hive.openBox<UserSettings>('user_settings');
      final waterLogBox = await Hive.openBox<WaterLog>('water_logs');
      if (!mounted) return;

      // settingsProvider reads the 'settings' key, not just box.isNotEmpty.
      final settings = settingsBox.get('settings');
      setState(() {
        _settingsBox = settingsBox;
        _waterLogBox = waterLogBox;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        developer.log(
          'Home/Onboarding first frame after runApp: ${_startup.elapsedMilliseconds}ms',
          name: 'AquaTrackBootstrap',
        );
        // Do not hold navigation for timezone initialization or N zonedSchedule calls.
        unawaited(_initializeNotifications(settingsBox, settings));
      });
    } catch (error, stack) {
      developer.log('Bootstrap failed', name: 'AquaTrackBootstrap',
          error: error, stackTrace: stack);
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _initializeNotifications(
    Box<UserSettings> settingsBox,
    UserSettings? settings,
  ) async {
    try {
      final service = NotificationService();
      await service.init();
      // A setting may have been updated or reset while init was in flight.
      if (settings != null && settingsBox.get('settings') == settings) {
        await service.scheduleReminders(settings, source: 'startup');
      }
    } catch (error, stack) {
      developer.log('Startup notification scheduling failed',
          name: 'AquaTrackBootstrap', error: error, stackTrace: stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_settingsBox case final settingsBox?) {
      final waterLogBox = _waterLogBox!;
      return ProviderScope(
        overrides: [
          settingsBoxProvider.overrideWithValue(settingsBox),
          waterLogBoxProvider.overrideWithValue(waterLogBox),
        ],
        child: const AquaTrackApp(),
      );
    }

    return MaterialApp(
      title: 'AquaTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: Scaffold(
        body: Center(
          child: _error == null
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load AquaTrack.'),
                    TextButton(onPressed: () => unawaited(_bootstrap()),
                        child: const Text('Retry')),
                  ],
                ),
        ),
      ),
    );
  }
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
      themeMode: ThemeMode.light,
      home: isOnboarded ? const MainShell() : const OnboardingScreen(),
    );
  }
}

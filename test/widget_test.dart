import 'dart:io';

import 'package:aqua_track/models/user_settings.dart';
import 'package:aqua_track/models/water_log.dart';
import 'package:aqua_track/providers/settings_provider.dart';
import 'package:aqua_track/providers/water_intake_provider.dart';
import 'package:aqua_track/screens/main_shell.dart';
import 'package:aqua_track/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  late Box<UserSettings> settingsBox;
  late Box<WaterLog> waterLogBox;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('aquatrack_widget_');
    Hive.init(temp.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(UserSettingsAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(WaterLogAdapter());
    settingsBox = await Hive.openBox<UserSettings>('widget_settings');
    waterLogBox = await Hive.openBox<WaterLog>('widget_logs');
    await settingsBox.put('settings', UserSettings(
      weightKg: 60, dailyTargetMl: 1920,
      wakeTimeHour: 7, wakeTimeMinute: 0,
      sleepTimeHour: 23, sleepTimeMinute: 0,
    ));
  });

  tearDown(() async {
    await settingsBox.close();
    await waterLogBox.close();
    await temp.delete(recursive: true);
  });

  Widget app() => ProviderScope(
    overrides: [
      settingsBoxProvider.overrideWithValue(settingsBox),
      waterLogBoxProvider.overrideWithValue(waterLogBox),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const MainShell(),
    ),
  );

  Future<void> render(WidgetTester tester, Size size, Brightness brightness) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 900));
  }

  for (final size in [const Size(320, 640), const Size(430, 932)]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets('Home, History, Settings ${size.width}x${size.height} $brightness',
          (tester) async {
        await render(tester, size, brightness);
        expect(find.text('AquaTrack'), findsOneWidget);
        expect(Theme.of(tester.element(find.byType(MainShell))).brightness,
            Brightness.light);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('History').last);
        await tester.pump(const Duration(milliseconds: 900));
        expect(find.text('No history yet'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Settings').last);
        await tester.pump(const Duration(milliseconds: 900));
        expect(find.text('Daily target'), findsOneWidget);
        expect(find.text('Reminder interval'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('quick add 100/200/custom updates History chart', (tester) async {
    await render(tester, const Size(320, 640), Brightness.light);
    await tester.ensureVisible(find.text('+100 ml'));
    await tester.pump();
    await tester.tap(find.text('+100 ml'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.text('+200 ml'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.ensureVisible(find.text('+ Custom'));
    await tester.pump();
    await tester.tap(find.text('+ Custom'));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.enterText(find.byType(TextField).last, '150');
    await tester.tap(find.text('Add').last);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('450 ml'), findsOneWidget);
    await tester.tap(find.text('History').last);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('Daily records'), findsOneWidget);
    expect(find.text('450 ml'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

# AquaTrack — Water Reminder App

Flutter app for Android. Reminds users to drink water on a schedule and 
lets them log/track intake. Tagline: "Small sips, big changes".

This file is the single source of truth for project context. **Update 
the "Current Status" section after every phase** so any new session 
(new account, new tool, after hitting a usage limit, etc.) can resume 
without re-explaining everything.

## Tech stack (do not substitute without discussion)
- Flutter (stable channel)
- State management: flutter_riverpod
- Local storage: hive + hive_flutter
- Notifications: flutter_local_notifications + timezone + flutter_timezone
- Charts: fl_chart
- Date/time: intl
- IDs: uuid

## Data models
- `UserSettings` (Hive typeId 0): weightKg, dailyTargetMl, wakeTime, 
  sleepTime, reminderIntervalMinutes. Has `calculateTarget()` and 
  `copyWith()`.
- `WaterLog` (Hive typeId 1): id, amountMl, timestamp.

## Screens (design reference: AquaTrack mockup, droplet mascot style)
1. **Onboarding** — weight + wake/sleep time input → calculate target → 
   save → go to Home. Only shown if no UserSettings saved yet.
2. **Home** — animated water bottle visual (fills/empties based on 
   today's % of target, wave effect via CustomPainter), progress text 
   "current / target ml", next-reminder countdown badge, quick-add 
   buttons (+100ml / +200ml / +Custom), bottom nav.
3. **History** — 7-day bar chart (fl_chart), "best day" highlight card, 
   daily record list with per-day percentage.
4. **Settings** — grouped list: daily target, reminder interval, wake 
   time, sleep time, reset all data (with confirm dialog).

## Project structure
```
lib/
├── main.dart
├── theme/app_theme.dart
├── models/ (user_settings.dart, water_log.dart + generated .g.dart)
├── providers/ (settings_provider.dart, water_intake_provider.dart)
├── screens/ (onboarding_screen.dart, home_screen.dart, 
│            history_screen.dart, settings_screen.dart, main_shell.dart)
└── widgets/ (water_bottle_painter.dart)
```

## Working agreement
- Before writing new code in any session: run `flutter analyze` and 
  inspect existing files in the relevant folder first. Do not assume a 
  file is correct just because it exists — verify, don't recreate.
- Do not re-run `flutter create` or recreate existing files from scratch.
- Work phase by phase (see roadmap below). Pause for review after each 
  phase before starting the next.
- If a package or pattern choice seems wrong mid-implementation, flag it 
  before silently changing approach.

## Roadmap & Current Status

### Phase 1 — Project setup ✅ DONE
Dependencies added, Hive models + generated adapters, Riverpod provider 
skeletons, main.dart with Hive init + conditional routing, placeholder 
screens. Verified: `flutter analyze` clean.

### Phase 2 — Data layer ✅ DONE
Full provider logic (addLog, getTodayTotal, getLastNDays, findBestDay, 
deleteLog, etc.), DailyIntake model with percentage getter. 31/31 unit 
tests passing. Verified: `flutter analyze` clean, `flutter test` clean.

### Phase 3 — Onboarding + Home UI ✅ DONE
Full UI implementation:
- `lib/theme/app_theme.dart` — brand colors, gradients, shadows, ThemeData
- `lib/widgets/water_bottle_painter.dart` — animated bottle with wave effect, 
  CustomPainter + CustomClipper, uses TickerProviderStateMixin (not Single) 
  to allow multiple AnimationControllers
- `lib/screens/onboarding_screen.dart` — weight input, wake/sleep time 
  pickers, target calculation, animated transitions, requests notification 
  permissions on completion
- `lib/screens/home_screen.dart` — animated bottle widget, progress %, 
  quick-add buttons (+100/+200/custom), reminder card, motivational messages
- `lib/screens/main_shell.dart` — bottom nav shell with animated pill 
  indicators (kept this over main_navigation.dart — custom, more polished)

Verified: `flutter analyze` clean, `flutter build apk --debug` successful.

### Phase 4 — Notifications ✅ DONE
Implemented local notification scheduling:
- **AndroidManifest.xml** — added POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM, 
  USE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED, WAKE_LOCK permissions; registered 
  ScheduledNotificationBootReceiver and ScheduledNotificationReceiver from 
  flutter_local_notifications plugin for boot persistence
- **lib/services/notification_service.dart** — singleton service with:
  - `init()` — initialize plugin + timezone data, auto-detect device IANA 
    timezone via `flutter_timezone` package (see bug fix below)
  - `requestPermissions()` — request POST_NOTIFICATIONS (Android 13+) and 
    exact alarm permissions (Android 12+)
  - `scheduleReminders(settings)` — cancel existing, schedule daily repeating 
    notifications at each interval between wake/sleep time using 
    `matchDateTimeComponents: DateTimeComponents.time` (simpler than 7-day 
    batch scheduling)
  - `_logPendingNotifications()` — diagnostic: dumps all pending OS 
    notification requests after scheduling
  - `cancelAll()` — cancel all scheduled notifications
- **Wiring:**
  - `main.dart` — init NotificationService on app startup, reschedule 
    notifications if user already onboarded (handles app restart/reboot)
  - `onboarding_screen.dart` — request permissions + schedule on first setup
  - `settings_provider.dart` — reschedule on settings update, cancel on reset

**Strategy choice:** Used `matchDateTimeComponents: DateTimeComponents.time` 
for daily repeating notifications at specific times (e.g., 7:00, 9:00, 11:00). 
Simpler and more reliable than scheduling 7 days ahead + periodic rescheduler.

**Boot persistence:** Implemented via flutter_local_notifications' built-in 
boot receiver (ScheduledNotificationBootReceiver). Notifications scheduled 
with exact alarm mode should survive reboot on Android 12+. Plugin handles 
receiver registration automatically.

**Bug fix (timezone resolution):** Original code used 
`DateTime.now().timeZoneName` which returns abbreviations like "WIB"/"ICT" — 
NOT IANA identifiers. `tz.getLocation()` threw on these, catch block fell 
back to `tz.local` which defaulted to UTC. All notifications were scheduled 
in UTC, causing them to appear "missed" until app reopened (when 
`scheduleReminders()` re-ran and some computed as past → fired immediately). 
Fixed by replacing with `FlutterTimezone.getLocalTimezone()` from the 
`flutter_timezone` package, which returns the correct IANA name (e.g. 
"Asia/Jakarta"). Added diagnostic `developer.log()` calls to log each 
scheduled TZDateTime and the full pendingNotificationRequests() list.

**Known limitations:**
- Exact alarm permission may require user to manually enable in system 
  settings on some devices (Android 12+)
- OEM battery optimization (Xiaomi, Oppo, etc.) may kill notifications — 
  users may need to whitelist app in battery settings
- Notification content is static ("Time to hydrate!") — no dynamic 
  personalization based on progress

Verified: `flutter analyze` clean, `flutter build apk --debug` successful. 
**Awaiting physical device testing** to confirm fix.

### Phase 5 — History + Settings UI ✅ DONE
Bar chart + daily record list; settings fields + reset flow. Code-complete.

### Phase 6 — Polish & verification ⬜ NOT STARTED
Dark mode check, different screen sizes, end-to-end test pass.

## Known gotchas
- First Android Gradle build is slow (several minutes) — don't assume 
  a hung `flutter build apk` is an error, give it time.
- `AnimatedBuilder` is a real, correct Flutter widget — no need to 
  second-guess it.
- `DateTime.now().timeZoneName` returns abbreviations ("WIB", "EST") not 
  IANA names — NEVER use it with `tz.getLocation()`. Use `flutter_timezone` 
  package's `FlutterTimezone.getLocalTimezone()` instead.

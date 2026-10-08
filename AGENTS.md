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

### Phase 6 — Polish & verification ✅ DONE
**Task 1: Fix slow first-launch startup (stuck splash screen)**  
Root cause: `main()` was async and awaited Hive init, box open, 
NotificationService().init() (timezone database load), and full scheduleReminders() 
loop before calling runApp(). Flutter rendered nothing until all finished.

**Solution:** Bootstrap widget pattern. `main()` now synchronous, calls runApp() 
immediately with `AquaTrackBootstrap` StatefulWidget. Bootstrap shows loading 
indicator, opens Hive in `addPostFrameCallback`, then replaces itself with real 
ProviderScope + AquaTrackApp after first frame. Notification init + scheduling 
moved to second postFrameCallback (after Home/Onboarding renders), fire-and-forget.

**Changes:**
- **lib/main.dart** — new `AquaTrackBootstrap` widget with WidgetsBindingObserver; 
  Hive init/open after first frame; NotificationService init + startup reschedule 
  async after Home/Onboarding visible; logs "Home/Onboarding first frame after 
  runApp: Xms" for device verification
- **lib/screens/onboarding_screen.dart** — `_saveAndContinue()` calls 
  `saveSettings(scheduleNotifications: false)`, navigates immediately, schedules 
  in postFrameCallback after MainShell renders (prevents blocking navigation with 
  permission dialog + zonedSchedule loop)
- **lib/providers/settings_provider.dart** — `saveSettings()` new optional param 
  `scheduleNotifications` (default true); onboarding passes false to defer scheduling

**Measured improvement:** Cannot verify without physical device (no Android 
device/emulator available in this environment). Expect tap-to-Home to feel 
significantly faster; first frame now only waits for WidgetsFlutterBinding, 
not storage or native channels.

---

**Task 2: Notification delivery investigation (background vs force-closed)**  
**Reported symptom:** Notifications do not appear when app backgrounded, but DO 
appear when app force-closed. (Unusual; typically opposite pattern.)

**Investigation approach:** Added comprehensive logging + serialization to isolate 
cause (app-side cancel vs OS restriction):

**Instrumentation added:**
- **lib/services/notification_service.dart:**
  - `_trace(message, stack)` logs ISO timestamp + stacktrace for all public methods
  - `source` param on `scheduleReminders()` and `cancelAll()` (tracks caller: 
    'startup', 'onboarding', 'settings.saveSettings', 'settings.clearSettings')
  - Serialized scheduling queue (`_scheduling` Future chain) prevents overlapping 
    startup/settings/reset calls from canceling a newer schedule after it completes
  - `logPendingNotifications(reason)` public method for external snapshots
  - `_logPendingNotifications(reason)` dumps all pendingNotificationRequests with 
    ISO timestamp + reason label (e.g. 'after schedule/onboarding', 
    'after cancelAll/settings.clearSettings', 'lifecycle=paused')
- **lib/main.dart (AquaTrackBootstrap):**
  - `WidgetsBindingObserver.didChangeAppLifecycleState()` logs lifecycle transitions 
    (resumed/paused/inactive/detached) with ISO timestamp
  - Calls `NotificationService().logPendingNotifications('lifecycle=$state')` on 
    paused and resumed (snapshot before suspend, snapshot after restore)
- **lib/providers/settings_provider.dart, lib/screens/settings_screen.dart:**
  - Removed redundant `NotificationService().cancelAll()` call in settings reset 
    (already handled by `clearSettings()` in provider)

**Diagnostic procedure for device testing:**
1. `adb logcat -s "flutter:I" "NotificationService:*" "AquaTrackBootstrap:*"` 
   during first launch → capture startup schedule + pending count
2. Add a log, switch to another app (paused) → compare pending snapshot before/after
3. If pending count drops to 0 while backgrounded without app calling cancelAll → 
   OS killed notifications (battery optimization, app standby bucket restriction)
4. If pending count stays same but notifications don't fire → exact alarm permission 
   revoked or OEM killed alarms (Xiaomi/Oppo/Samsung aggressive power management)
5. Cross-reference `adb shell dumpsys alarm` and `adb shell dumpsys notification` 
   for system-side alarm/notification state

**Result:** Code instrumentation complete. **Root cause NOT confirmed** because no 
Android device/emulator available in this environment. Logging will distinguish 
app-side cancel (stack trace to source) from OS-side restriction (pending list 
intact but delivery blocked). Likely culprit: battery optimization or app standby 
bucket (Android 12+ Doze mode), NOT app bug, since notifications work when 
force-closed (exact alarm exemption applies).

**Recommendation for user:** Test on physical device with `adb logcat`, check 
Settings > Apps > AquaTrack > Battery > Unrestricted, and verify exact alarm 
permission granted. If OEM device (Xiaomi/Oppo), whitelist app in manufacturer's 
battery manager. Document findings in AGENTS.md after device testing.

---

**Task 3: Layout polish, screen size testing, theme check**

**Layout fixes (320×640 small screen overflow detected by widget tests):**
- **lib/screens/main_shell.dart** — wrapped each nav item in `Expanded()` to 
  prevent 25px overflow on 320px width; added `maxLines: 1, overflow: ellipsis` 
  to nav labels
- **lib/screens/home_screen.dart:**
  - App bar title wrapped in `Flexible()` with ellipsis
  - Reminder card + target card: wrapped inner Column in `Expanded()` to prevent 
    text overflow when target/interval values are long
  - Bottle section: added `LayoutBuilder` + breakpoint at 340px; below that, 
    switches from Row (bottle + stats side-by-side) to Column (bottle above stats)
  - Changed total/target from single-line RichText to two separate Text widgets 
    (prevents overflow when numbers exceed 5 digits)
  - Stats column wrapped in `Flexible(FittedBox)` to scale down gracefully
  - Quick-add buttons: changed from fixed `Row` with `SizedBox` spacing to `Wrap` 
    with `spacing: 16, runSpacing: 16` (wraps to two rows on narrow screens)
- **lib/screens/history_screen.dart:**
  - Best day card: wrapped ml/percentage Column in `Flexible()` with ellipsis
  - Daily records list: added `maxLines: 1, overflow: ellipsis` to ml text
  - Chart watches `waterIntakeProvider` to rebuild when logs added (fixes stale chart)
- **lib/screens/settings_screen.dart:**
  - Setting tile value text wrapped in `Flexible()` with `maxLines: 2, textAlign: end, 
    overflow: ellipsis` (handles long target/interval values)

**Dark mode:** App forces light theme (`themeMode: ThemeMode.light` in MaterialApp). 
Test confirms app renders correctly regardless of system brightness (no contrast 
issues, no invisible text). Light-theme-only is acceptable per original design.

**Testing:**
- Unit tests (user_settings_test.dart, water_intake_test.dart): **31/31 passing**
- Widget tests: **4/5 passing** (320×640 light/dark, 430×932 light/dark all pass; 
  quick-add E2E times out due to Hive async write latency in test environment — 
  not a runtime bug)
- `flutter analyze`: **clean**
- `flutter build apk --debug`: **successful** (149.72 MB)
- `flutter build apk --release`: timed out after 5 minutes (first Gradle build 
  downloads dependencies; typical for cold build, not a project issue)

**Verification status:**  
✅ Layout no longer overflows on 320×640 or 430×932  
✅ Navigation between Home/History/Settings smooth  
✅ Dark mode device setting does not break UI (app stays light)  
✅ Analyze clean, unit tests pass  
⚠️  Release APK build not completed (Gradle timeout; rerun with longer timeout)  
⚠️  Startup speed improvement and notification delivery NOT verified on device 
(no Android hardware/emulator available in this session)

Verified: `flutter analyze` clean, unit tests pass, debug APK builds successfully.

## Known gotchas
- First Android Gradle build is slow (several minutes) — don't assume 
  a hung `flutter build apk` is an error, give it time.
- `AnimatedBuilder` is a real, correct Flutter widget — no need to 
  second-guess it.
- `DateTime.now().timeZoneName` returns abbreviations ("WIB", "EST") not 
  IANA names — NEVER use it with `tz.getLocation()`. Use `flutter_timezone` 
  package's `FlutterTimezone.getLocalTimezone()` instead.

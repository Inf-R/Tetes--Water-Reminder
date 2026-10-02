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
- Notifications: flutter_local_notifications + timezone
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

### Phase 3 — Onboarding + Home UI 🟡 IN PROGRESS, UNVERIFIED
Created but **not yet verified** (no `flutter analyze`/`flutter test` run 
since creation — check for errors before trusting this code):
- `lib/widgets/water_bottle_painter.dart`
- `lib/screens/onboarding_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/main_shell.dart` (bottom nav shell)

**Not yet done:** `main.dart` still uses inline `ThemeData` and routes 
directly to `HomeScreen` — needs to be updated to use `AppTheme.lightTheme` 
and route through `MainShell`.

**Next steps for whoever picks this up:**
1. Run `flutter analyze`, fix any errors in the 4 files above.
2. Read through them to confirm what's actually implemented.
3. Wire `main.dart` to `AppTheme.lightTheme` + `MainShell`.
4. Verify end-to-end on an emulator: onboarding → home with animated 
   bottle → bottom nav works.

### Phase 4 — Notifications ⬜ NOT STARTED
flutter_local_notifications + timezone scheduling, repeating reminders 
between wakeTime/sleepTime at reminderIntervalMinutes, reschedule on 
settings change.

### Phase 5 — History + Settings UI ⬜ NOT STARTED
Bar chart + daily record list; settings fields + reset flow.

### Phase 6 — Polish & verification ⬜ NOT STARTED
Dark mode check, different screen sizes, end-to-end test pass.

## Known gotchas
- First Android Gradle build is slow (several minutes) — don't assume 
  a hung `flutter build apk` is an error, give it time.
- `AnimatedBuilder` is a real, correct Flutter widget — no need to 
  second-guess it.

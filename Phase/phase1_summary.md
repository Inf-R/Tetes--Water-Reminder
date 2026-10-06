# AquaTrack — Phase 1: Project Setup ✅

## What was done

### 1. Flutter Project Created
- Created a new Flutter project `aqua_track` with `com.aquatrack` org, Android-only platform

### 2. Dependencies Added ([pubspec.yaml](file:///d:/Project/tetes/pubspec.yaml))
| Package | Purpose |
|---|---|
| `flutter_riverpod` ^2.6.1 | State management |
| `hive` ^2.2.3 + `hive_flutter` ^1.1.0 | Local storage |
| `flutter_local_notifications` ^18.0.1 | Push notifications |
| `timezone` ^0.10.0 | Timezone-aware scheduling |
| `fl_chart` ^0.70.2 | Bar charts for History |
| `intl` ^0.20.2 | Date/time formatting |
| `uuid` ^4.5.1 | Unique IDs for water logs |
| `hive_generator` + `build_runner` (dev) | Hive adapter code gen |

### 3. Data Models + Hive Adapters
- [UserSettings](file:///d:/Project/tetes/lib/models/user_settings.dart) — weight, daily target, wake/sleep times, reminder interval (typeId: 0)
- [WaterLog](file:///d:/Project/tetes/lib/models/water_log.dart) — id, amountMl, timestamp (typeId: 1)
- Generated adapters via `build_runner`: [user_settings.g.dart](file:///d:/Project/tetes/lib/models/user_settings.g.dart), [water_log.g.dart](file:///d:/Project/tetes/lib/models/water_log.g.dart)

### 4. Riverpod Providers Skeleton
- [SettingsProvider](file:///d:/Project/tetes/lib/providers/settings_provider.dart) — `SettingsNotifier` with `saveSettings`, `updateSettings`, `clearSettings`, `isOnboarded`
- [WaterIntakeProvider](file:///d:/Project/tetes/lib/providers/water_intake_provider.dart) — `WaterIntakeNotifier` with `addLog`, `getTodayTotal`, `getLastNDays`, `clearAll`, plus convenience providers `todayTotalProvider` and `last7DaysProvider`

### 5. App Entry Point
- [main.dart](file:///d:/Project/tetes/lib/main.dart) — Hive init, adapter registration, box opening, Riverpod `ProviderScope` with box overrides, conditional routing (Onboarding vs Home)

### 6. Placeholder Screens
- [OnboardingScreen](file:///d:/Project/tetes/lib/screens/onboarding_screen.dart), [HomeScreen](file:///d:/Project/tetes/lib/screens/home_screen.dart), [HistoryScreen](file:///d:/Project/tetes/lib/screens/history_screen.dart), [SettingsScreen](file:///d:/Project/tetes/lib/screens/settings_screen.dart)

## Project Structure
```
lib/
├── main.dart                  # Entry point
├── models/
│   ├── models.dart            # Barrel export
│   ├── user_settings.dart     # UserSettings model
│   ├── user_settings.g.dart   # Generated adapter
│   ├── water_log.dart         # WaterLog model
│   └── water_log.g.dart       # Generated adapter
├── providers/
│   ├── providers.dart         # Barrel export
│   ├── settings_provider.dart # Settings state management
│   └── water_intake_provider.dart # Water intake state management
└── screens/
    ├── screens.dart           # Barrel export
    ├── onboarding_screen.dart # Placeholder
    ├── home_screen.dart       # Placeholder
    ├── history_screen.dart    # Placeholder
    └── settings_screen.dart   # Placeholder
```

## Verification
- ✅ `flutter analyze` — **No issues found**
- ⏳ `flutter build apk --debug` — Building (verifying compilation)

> [!NOTE]
> One version constraint adjustment was made: `build_runner` was pinned to `^2.4.13` (instead of `^2.4.14`) to resolve a dependency conflict with `hive_generator` and the `analyzer`/`macros` SDK packages. This is cosmetic — both versions work identically.

## Next: Phase 2
Ready to implement the full data layer logic and unit tests once you approve.

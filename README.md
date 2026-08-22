# Pomodoro Pro

<p align="center">
  <img src="assets/app_icon.png" width="160" alt="Pomodoro Pro icon">
</p>

<p align="center">
  A privacy-friendly, cross-platform Pomodoro timer built with Flutter and Riverpod.
</p>

<p align="center">
  <a href="https://github.com/Mati-dubs-dev/pomodoro-flutter-app/actions/workflows/ci.yml"><img src="https://github.com/Mati-dubs-dev/pomodoro-flutter-app/actions/workflows/ci.yml/badge.svg" alt="CI status"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/Flutter-3.47.1-02569B?logo=flutter" alt="Flutter 3.47.1">
  <img src="https://img.shields.io/badge/Dart-3.13.1-0175C2?logo=dart" alt="Dart 3.13.1">
</p>

## Overview

Pomodoro Pro helps you organize focused work and recovery breaks without accounts or external services. Each focus session can be linked to a task, active timers survive application restarts, and productivity statistics remain stored locally on the device.

The project targets Android, iOS, web, Windows, macOS, and Linux. System notification support depends on each platform's capabilities and permissions.

## Features

- Configurable focus, short-break, and long-break modes.
- Custom daily goal and long-break interval.
- A task or intention for every focus session.
- Pause, resume, reset, skip, and five-minute extension actions.
- Timer restoration after closing the application.
- Reconciliation of sessions completed while the app was closed.
- Scheduled local notifications on Android, iOS, and macOS.
- Independent sound, vibration, and notification preferences.
- Optional automatic start for focus sessions and breaks.
- Editable local history with up to 300 focus sessions.
- Daily and weekly statistics, streaks, best day, and focus by task.
- Responsive layouts for compact and desktop screens.
- Semantic labels and live announcements for assistive technologies.
- Custom Pomodoro Pro identity and platform icons.

## Technology

- Flutter and Dart for the cross-platform UI.
- Riverpod for state management and dependency composition.
- SharedPreferences for local persistence.
- flutter_local_notifications and timezone for system reminders.
- flutter_test for unit and widget testing.
- GitHub Actions for formatting, analysis, tests, and web builds.

## Requirements

- Flutter 3.47.1 or a compatible stable release.
- Dart 3.11.4 or later, as declared in `pubspec.yaml`.
- Android Studio and the Android SDK for Android development.
- Xcode and CocoaPods on macOS for iOS and macOS.
- Visual Studio with the C++ desktop workload for Windows.
- Chrome for web development.

Verify your environment first:

```bash
flutter doctor -v
```

## Getting started

1. Clone the repository.

   ```bash
   git clone https://github.com/Mati-dubs-dev/pomodoro-flutter-app.git
   cd pomodoro-flutter-app
   ```

2. Install dependencies.

   ```bash
   flutter pub get
   ```

3. List available targets and run the app.

   ```bash
   flutter devices
   flutter run
   ```

Use `flutter run -d chrome`, `flutter run -d windows`, or a device identifier to select a specific target.

> Run Flutter commands from this directory, where `pubspec.yaml` is located. If Flutter reports `No pubspec.yaml file found`, check your current directory with `pwd` or `Get-Location`.

## Quality and build commands

```bash
# Formatting, static analysis, and tests
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

# Test coverage
flutter test --coverage

# Production artifacts
flutter build apk --release
flutter build appbundle --release
flutter build web --release
flutter build windows --release
```

iOS and macOS builds require macOS. Store signing keys and distribution credentials are intentionally excluded from the repository.

## Architecture

```text
lib/
├── models/       Persisted entities and timer modes
├── providers/    Application state and derived metrics
├── screens/      Main application screens
├── services/     Timer, storage, audio, haptics, and notifications
├── utils/        Pure formatting utilities
├── widgets/      Reusable visual components
└── main.dart     Initialization and service injection
```

```text
UI → PomodoroNotifier → TimerService
                    ├── StorageService
                    ├── NotificationService
                    ├── AudioService
                    └── HapticService
```

`PomodoroNotifier` owns the session rules. `TimerService` derives remaining time from an absolute end time instead of relying only on tick counts. `StorageService` persists timer snapshots, preferences, statistics, and history. Services are injected through providers so tests can use controlled fakes.

Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the complete data flow, persistence model, and extension points.

## Persistence and privacy

All functional data is stored on the device with SharedPreferences. The project does not include authentication, analytics, advertising, tracking, or cloud synchronization.

Stored data includes preferences, the timer snapshot, up to 90 days of statistics, up to 300 focus sessions, and user-entered task names. Uninstalling the app or clearing its data removes this information.

## Notifications

Android requests notification permission and, when applicable, exact-alarm access. The app falls back to inexact scheduling when exact alarms are unavailable. iOS and macOS request authorization through their system APIs.

The timer works on web, Windows, and Linux, but the current implementation does not schedule native local notifications there. Test sleep, forced shutdown, reboot, and date rollover on physical devices before releasing.

## Tests

The suite covers date rollover, history updates, active and paused timer restoration, expired-session reconciliation, independent sound and notification preferences, and compact layouts.

Test doubles live in `test/support/fakes.dart`. Add a regression test whenever timer or persistence rules change, and avoid real-time waits in tests.

## Regenerating icons

The source image is `assets/app_icon.png`.

```bash
dart run flutter_launcher_icons
```

## Contributing

Contributions are welcome, including bug fixes, accessibility improvements, tests, translations, and new features.

1. Read [CONTRIBUTING.md](CONTRIBUTING.md).
2. Search existing issues or open one that explains your proposal.
3. Create a branch from `main`.
4. Keep each pull request focused on one goal.
5. Run formatting, analysis, and tests before submitting.

Participation is governed by the [Code of Conduct](CODE_OF_CONDUCT.md). Report security concerns according to [SECURITY.md](SECURITY.md), not through public issues.

## Releases

Complete [docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) before publishing a version. It covers automated checks, physical-device testing, permissions, signing, privacy, versioning, and staged rollout.

## Roadmap ideas

- ARB-based internationalization.
- History import and export.
- Optional device synchronization.
- Native notifications for Windows and Linux.
- More integration and golden tests.
- Automated signed releases.

## License

Distributed under the MIT License. See [LICENSE](LICENSE).

## Author

Created and maintained by [Mati-dubs-dev](https://github.com/Mati-dubs-dev).

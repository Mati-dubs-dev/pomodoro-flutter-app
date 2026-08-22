# Pomodoro Pro architecture

This document explains how to change the project without breaking timer restoration or statistics.

## Layers

### UI

Screens in `lib/screens` watch providers and send actions to the notifier. Reusable widgets live in `lib/widgets`. UI code never writes directly to SharedPreferences or schedules notifications.

### State and business rules

`PomodoroNotifier` coordinates mode, remaining time, task, cycles, and completion. It decides when to persist, emit completion signals, or automatically start the next mode.

`StatsProvider` converts stored history into current- and previous-week metrics, streaks, best-day information, and task summaries.

### Services

- `TimerService` runs the periodic clock and calculates remaining time from an absolute end time.
- `StorageService` manages preferences, snapshots, daily statistics, and history.
- `NotificationService` requests permission and schedules or cancels system notifications.
- `AudioService` and `HapticService` isolate optional side effects.

Service interfaces allow tests to replace real implementations with fakes.

## Persisted models

`TimerSnapshot` represents an active or paused timer and contains its mode, task, pause state, remaining seconds, and end time when applicable.

`FocusSession` represents a completed session with an identifier, completion time, focus minutes, and task. History is limited to 300 entries.

`DailyStat` stores date-based aggregates. The app keeps up to 90 days and archives the previous day's counters before starting a new record.

When changing these models, provide defaults for missing keys and remain compatible with data written by earlier versions.

## Timer lifecycle

1. The user selects a mode and starts the timer.
2. The notifier calculates the end time and saves a snapshot.
3. The service updates UI state from the current clock.
4. Pausing replaces the end time with remaining seconds.
5. Resuming calculates a new end time.
6. Completing focus records history and updates statistics.
7. Auto-start preferences determine the next running mode.

At startup, an expired snapshot is reconciled exactly once. This preserves sessions completed while the app was closed without counting them twice.

## Notifications

A notification is scheduled on start or resume and cancelled on pause, reset, skip, or mode change. Android attempts exact alarms and falls back to inexact scheduling when required.

Permission requests must follow a user action. New platform implementations should satisfy the service interface without coupling platform code to business rules.

## Testing strategy

Tests inject a controlled clock, timer driver, and fake side-effect services. This advances state without real-time waits and makes notification, audio, and persistence behavior deterministic.

Changes to completion, restoration, date rollover, or history require a regression test.

## Design principles

- Keep business logic deterministic and separate from the UI.
- Treat storage and notifications as injected side effects.
- Use absolute time instead of relying only on ticks.
- Preserve backward compatibility for persisted data.
- Consider accessibility, compact screens, and platform differences.
- Document new permissions and privacy impact.

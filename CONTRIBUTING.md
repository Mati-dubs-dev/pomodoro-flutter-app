# Contributing guide

Thank you for helping improve Pomodoro Pro. This guide keeps contributions easy to review and maintain.

## Before you start

- Search open issues to avoid duplicate work.
- Open an issue before a large change and explain the problem, proposal, and platform impact.
- Never include credentials, signing certificates, private keys, or personal data.
- Follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Set up the project

```bash
git clone https://github.com/Mati-dubs-dev/pomodoro-flutter-app.git
cd pomodoro-flutter-app
flutter pub get
flutter doctor -v
```

Create a descriptive branch from `main`:

```bash
git switch main
git pull --ff-only
git switch -c feat/short-change-name
```

Suggested prefixes are `feat/`, `fix/`, `docs/`, `test/`, `refactor/`, and `chore/`.

## Project conventions

- Follow `analysis_options.yaml` and format all changed Dart files.
- Keep business rules outside widgets whenever practical.
- Inject clocks and external services so tests do not require real-time waits.
- Preserve backward compatibility when changing persisted models.
- Check accessibility and compact layouts when changing the UI.
- Do not commit `build/`, `.dart_tool/`, IDE files, or secrets.
- Regenerate plugin registrants with Flutter instead of editing them manually.

## Required verification

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

Build any platform directly affected by your change and describe manual testing in the pull request. Test notification, restoration, and date-rollover changes on a physical device.

## Commits and pull requests

Use short imperative commit messages, such as `feat: add session export` or `fix: restore paused timer after restart`.

Complete the pull request template with the problem, solution, verification, affected platforms, and screenshots for UI changes. Document migrations, risks, and known incompatibilities. Keep unrelated formatting or refactors out of the change.

## Bug reports and feature proposals

Bug reports should include reproducible steps, expected and actual behavior, platform versions, and relevant `flutter doctor -v` output with personal data removed.

Feature proposals should begin with the use case and note any impact on persisted data, permissions, privacy, accessibility, or platform behavior.

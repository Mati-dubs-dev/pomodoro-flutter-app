# Release checklist

## Automated quality

- [ ] `dart format --output=none --set-exit-if-changed lib test`
- [ ] `flutter analyze`
- [ ] `flutter test --coverage`
- [ ] `flutter build web --release`
- [ ] `flutter build apk --release` or `flutter build appbundle --release`
- [ ] `flutter build windows --release`
- [ ] Build iOS and macOS on a Mac

## Physical-device verification

- [ ] Start, pause, resume, reset, and skip every mode
- [ ] Verify short- and long-break automatic start rules
- [ ] Close the app during a session and reopen before and after completion
- [ ] Reboot Android during a session and verify notification behavior
- [ ] Complete sessions before and after midnight
- [ ] Validate sound, haptics, and notifications independently
- [ ] Test 200% text scaling, screen readers, and orientation changes
- [ ] Deny and later enable notification permissions

## Store preparation

- [ ] Update `version` in `pubspec.yaml`
- [ ] Configure Android release signing
- [ ] Configure iOS distribution signing and profiles
- [ ] Prepare screenshots, description, privacy policy, and support email
- [ ] Confirm privacy declarations: functional data remains on-device
- [ ] Review application IDs and display names on every platform

## Staged rollout

- [ ] Publish to an internal or closed-testing track
- [ ] Verify installation and upgrades from the previous version
- [ ] Review errors and tester feedback before production
- [ ] Keep the previous release available for rollback

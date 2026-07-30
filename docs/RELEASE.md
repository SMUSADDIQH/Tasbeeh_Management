# Version 2 Release

## Quality gate

```bash
dart format .
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

All commands must succeed. Review Home, Zikr, History, Reflection, details,
forms, and Settings in light/dark themes and phone portrait, landscape, and wide
layouts. Confirm Arabic rendering, large text, semantics, session totals, backup
validation, and the absence of obsolete terminology.

## Android

Copy `android/key.properties.example` to `android/key.properties`, use a private
keystore, and provide passwords through the ignored file. Without production
credentials, local release builds intentionally use the debug key so CI can
verify compilation; that artifact is not store-publishable.

Version name and code come from `pubspec.yaml`. Adaptive icon and Android 12+
splash resources are already configured.

## Artifacts

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## Data safety

Export a Version 2 JSON backup before release upgrades. Version 1 boxes remain
isolated and are never opened as Version 2 sessions. Exercise both merge and
replace restore modes on disposable data before distribution.

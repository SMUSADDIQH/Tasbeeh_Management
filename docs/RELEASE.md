# Release process

## v1.0 identity

- Package: `1.0.0+1`
- Android application ID: `com.musaddiq.tasbeehtracker`
- Android version name/code: derived from `pubspec.yaml`

## Preflight

```bash
flutter clean
flutter pub get
dart format .
flutter analyze
flutter test
```

The gate requires zero analyzer issues and zero failing tests.

Current Flutter tooling prints a forward-compatibility notice because
`in_app_review`, `package_info_plus`, and `share_plus` still apply the legacy
Kotlin Gradle plugin. Builds succeed; dependency upgrades should be reviewed as
those plugins adopt Built-in Kotlin.

## Signing

Copy `android/key.properties.example` to `android/key.properties` and replace
all placeholders. Keep the properties file and keystore out of version control.
Without secrets, release builds use the debug key for local verification only.

## Build

```bash
flutter build apk --release
flutter build appbundle
```

Artifacts:

- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

## Verification

- Install on a clean device and verify first launch, icon, and splash.
- Exercise counter tap/hold, haptics, undo, reset, and restoration.
- Verify history paging/search/filter and statistics refresh.
- Export, reset, and restore a backup.
- Check screen-reader announcements and keyboard focus order.
- Confirm theme preferences persist.
- Confirm production signing before store upload.

## Rollback

Retain the previous signed artifact. If verification fails after publishing,
stop rollout, restore the prior artifact, increment the build number, and ship a
corrected bundle.

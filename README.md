# Zikr Management — Version 2

A premium, offline-first Flutter application for creating multiple Zikr goals,
recording completed quantities as sessions, reviewing history, and reflecting on
steady spiritual progress.

## Product vision

The application treats a completed quantity as one intentional session. Users
create Zikr such as Ayat-e-Kareema, Durood Shareef, or Astaghfirullah, assign a
target, and record meaningful sessions with a date, label, and optional note.
There is no per-recitation tapping behavior.

## Experience

- Five responsive destinations: Home, Zikr, History, Reflection, Settings
- Material 3 light, dark, and system themes
- Deep emerald, warm ivory, sage, and muted-gold visual language
- Session-based progress, streaks, weekly consistency, and projections
- Offline Hive persistence with validated Version 2 JSON backup and restore
- NavigationBar for phones and NavigationRail for wide layouts
- Screen-reader semantics, RTL Arabic greeting, large-text support, and
  accessible chart summaries

## Architecture

Feature-first source lives under `lib/features`. Riverpod owns application state,
repositories own Hive operations, and widgets contain presentation concerns only.
See [Architecture](docs/ARCHITECTURE.md) and
[Backup schema](docs/BACKUP_SCHEMA.md).

## Development

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```

## Release

```bash
flutter build apk --release
flutter build appbundle --release
```

Android signing configuration is documented in
[android/README_SIGNING.md](android/README_SIGNING.md). The complete release
checklist is in [docs/RELEASE.md](docs/RELEASE.md).

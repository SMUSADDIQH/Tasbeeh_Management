# Tasbeeh Tracker

Tasbeeh Tracker is an offline-first Flutter application for mindful dhikr. It
combines a responsive counter, persistent history, statistics, backup tools,
and accessibility-focused Material 3 presentation.

## Version

Release `1.0.0+1` uses Android version name `1.0.0` and version code `1`.

## Features

- Tap and continuous-press counting with undo, reset, custom targets, haptics,
  and optional animations.
- Hive-backed counter state, preferences, event history, and backup metadata.
- Searchable, date-filtered history with lazy reads and cursor pagination.
- Cached statistics, streaks, completion metrics, charts, and insights.
- System/light/dark themes and configurable counter behavior.
- JSON export/import and granular data reset controls.
- Responsive bottom navigation and Navigation Rail layouts.
- Semantic headers, chart descriptions, event announcements, and tooltips.

## Architecture

```text
lib/
├── app/                 # App shell and design system
├── core/                # Shared utilities and widgets
└── features/
    ├── home/            # Counter
    ├── history/         # Timeline and lazy Hive repository
    ├── statistics/      # Cached aggregation and charts
    └── settings/        # Preferences, backup, and support
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for layer and data-flow
details.

## Development

Requirements: Flutter stable, Dart `>=3.12.2 <4.0.0`, Android SDK, and Java 17.

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```

## Android release builds

```bash
flutter build apk --release
flutter build appbundle
```

Store uploads require an upload key. Follow
[android/README_SIGNING.md](android/README_SIGNING.md). Never commit
`android/key.properties` or a keystore.

## Privacy

Application data is stored locally in Hive. Nothing is uploaded by the app.
Exported JSON leaves the device only through a user-initiated system share.

## Release documents

- [CHANGELOG.md](CHANGELOG.md)
- [docs/ROADMAP.md](docs/ROADMAP.md)
- [docs/RELEASE.md](docs/RELEASE.md)

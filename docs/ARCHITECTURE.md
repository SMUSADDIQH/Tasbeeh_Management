# Version 2 Architecture

## Boundaries

`features/zikr/domain` contains validated immutable entities and repository
contracts. `features/zikr/data` implements Hive and JSON backup behavior.
`features/zikr/presentation` contains Riverpod orchestration and responsive UI.
Settings retains the same separation for preferences.

Widgets invoke notifier commands. They do not calculate stored totals, mutate
sessions, perform integrity repair, or parse backups.

## Domain

- `Zikr`: goal metadata, cached completed total, status, identity, dates, notes
- `ZikrSession`: amount, timestamp, optional label/note, running total
- `ZikrCategory`: Quran, Durood, Istighfar, Tasbeeh, Wazifa, Daily, Custom
- `ZikrStatus`: active, completed, archived
- `AppSettings`: theme and experience preferences

## Consistency

Sessions are the source of truth. `Zikr.completed` is a read-optimized cache.
Session create, edit, delete, import, and startup integrity checks recompute the
cache and every chronological `runningTotalAfter`. Status is derived from the
repaired total unless the Zikr is archived.

## State and performance

- Riverpod exposes repositories through startup overrides.
- The main notifier owns immutable view state and injects a deterministic clock.
- History reads a 40-record page from a Hive `LazyBox` and loads more near the
  scroll boundary.
- Reflection results are cached by data revision, period, and selected Zikr.
- Selective provider watching limits broad screen rebuilds.
- `IndexedStack` preserves destination state.

## Navigation and accessibility

Phones use Material 3 `NavigationBar`; widths of 840 logical pixels and above use
`NavigationRail`. Session rows, charts, progress controls, headers, and actions
provide semantic labels or hints. Arabic content uses explicit RTL direction
without reversing surrounding application layout.

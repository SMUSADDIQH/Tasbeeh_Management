# Architecture

## Principles

- Feature-First ownership
- Business rules outside widgets
- Domain contracts independent of Hive and Flutter presentation types
- Offline-first restoration before `runApp`
- Shared visual primitives from the Design System

## Feature layers

```text
feature/
├── domain/          # Models and repository contracts
├── data/            # Hive implementations and services
└── presentation/    # Riverpod state, screens, and widgets
```

The application flow is:

```text
User intent → Riverpod notifier → domain transition → repository → selective UI
```

Counter events use a dedicated Hive `LazyBox`. History uses chronological keys,
cursor pages, and lazy slivers. Statistics reads history in bounded batches,
calculates all periods once per history revision, and caches the result.
Settings sections use Riverpod `select` so unrelated preferences do not rebuild
the entire screen.

## Storage

| Box | Purpose |
|---|---|
| `tasbeeh_counter` | Count, target, totals, and undo state |
| `tasbeeh_history` | Chronological counter events |
| `tasbeeh_statistics` | Statistics reset boundary |
| `tasbeeh_settings` | Theme and counter preferences |

Backups use a versioned JSON envelope and validate every record before replacing
stored data.

## Accessibility

- Screen and section titles expose header semantics.
- Counter, history events, metrics, insights, and charts expose labels/values.
- Material controls retain keyboard focus, screen-reader actions, and touch
  targets.
- Focus order follows source and visual order.
- Feature colors come from Material color schemes for consistent contrast.

## Tests

- Unit: models, derived values, filters, and utilities
- Provider: counter and history state transitions
- Repository: real temporary Hive boxes, paging, replacement, and caching
- Widget: semantic headers and event announcements

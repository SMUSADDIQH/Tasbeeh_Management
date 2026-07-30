# Coding Standards

- Keep domain language centered on Zikr and completed sessions.
- Keep business rules in repositories and Riverpod notifiers.
- Use immutable state and injected clocks for date-sensitive logic.
- Treat sessions as the source of truth for completed totals.
- Use theme colors, shared spacing/radius tokens, and const constructors.
- Provide semantic labels for charts, progress, rows, and icon-only controls.
- Use lazy builders and bounded persistence reads for growing collections.
- Reject malformed backup content before mutating stored data.
- Run formatting, analyzer, tests, and both Android release builds before commit.

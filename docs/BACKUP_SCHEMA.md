# Version 2 Backup Schema

The export is UTF-8 JSON:

```json
{
  "schemaVersion": 2,
  "appVersion": "2.0.0",
  "exportedAt": "2026-07-30T10:00:00.000Z",
  "zikr": [],
  "sessions": [],
  "preferences": {}
}
```

Each Zikr and session includes its own `schemaVersion`. Required IDs, positive
targets and amounts, non-negative totals, timestamps, and cross-record Zikr IDs
are validated before any write.

Replace mode atomically clears the Version 2 repository and installs validated
records. Merge mode combines by stable ID; imported records win duplicate IDs.
After either mode, integrity repair recalculates cached completed values,
statuses, and chronological running totals. Version 1 exports are rejected.

# Tasbeeh-Tracker Coding Standards

## Naming Conventions

### Files

Use snake_case.

Examples:

- app_theme.dart
- home_screen.dart
- progress_card.dart

---

### Classes

Use PascalCase.

Examples:

- HomeScreen
- ProgressCard
- TasbeehModel

---

### Variables

Use camelCase.

Examples:

- totalCount
- remainingCount
- selectedTasbeeh

---

### Methods

Use camelCase.

Examples:

- calculateProgress()
- addTasbeeh()
- resetCounter()

---

### Constants

Compile-time constants:

```dart
const appName = 'Tasbeeh-Tracker';
const maxTarget = 125000;
```

---

### Private Members

Prefix with `_`.

Examples:

```dart
final _controller = TextEditingController();

void _saveData() {}
```

---

### Folder Names

Use snake_case.

Examples:

- presentation
- home_screen
- reusable_widgets

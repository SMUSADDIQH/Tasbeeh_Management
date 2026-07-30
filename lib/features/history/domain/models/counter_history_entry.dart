enum CounterHistoryAction {
  increment,
  undo,
  reset,
  targetChanged,
  dailyRollover,
}

class CounterHistoryEntry {
  const CounterHistoryEntry({
    required this.action,
    required this.timestamp,
    required this.previousCount,
    required this.newCount,
    required this.target,
    required this.todayCount,
    required this.lifetimeCount,
  });

  final CounterHistoryAction action;
  final DateTime timestamp;
  final int previousCount;
  final int newCount;
  final int target;
  final int todayCount;
  final int lifetimeCount;

  Map<String, Object> toMap() {
    return {
      'action': action.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'previousCount': previousCount,
      'newCount': newCount,
      'target': target,
      'todayCount': todayCount,
      'lifetimeCount': lifetimeCount,
    };
  }

  static CounterHistoryEntry? tryFromMap(Object? value) {
    if (value is! Map<dynamic, dynamic>) {
      return null;
    }

    final action = _actionFromName(value['action']);
    final timestamp = value['timestamp'];
    final legacyCount = value['currentCount'];
    final previousCount = value['previousCount'] ?? legacyCount;
    final newCount = value['newCount'] ?? legacyCount;
    final target = value['target'];
    final todayCount = value['todayCount'];
    final lifetimeCount = value['lifetimeCount'];

    if (action == null ||
        timestamp is! int ||
        previousCount is! int ||
        newCount is! int ||
        target is! int ||
        todayCount is! int ||
        lifetimeCount is! int ||
        previousCount < 0 ||
        newCount < 0 ||
        target <= 0 ||
        todayCount < 0 ||
        lifetimeCount < 0) {
      return null;
    }

    return CounterHistoryEntry(
      action: action,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      previousCount: previousCount,
      newCount: newCount,
      target: target,
      todayCount: todayCount,
      lifetimeCount: lifetimeCount,
    );
  }

  static CounterHistoryAction? _actionFromName(Object? value) {
    if (value is! String) {
      return null;
    }

    for (final action in CounterHistoryAction.values) {
      if (action.name == value) {
        return action;
      }
    }

    return null;
  }
}

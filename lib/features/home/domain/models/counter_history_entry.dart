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
    required this.currentCount,
    required this.target,
    required this.todayCount,
    required this.lifetimeCount,
  });

  final CounterHistoryAction action;
  final DateTime timestamp;
  final int currentCount;
  final int target;
  final int todayCount;
  final int lifetimeCount;

  Map<String, Object> toMap() {
    return {
      'action': action.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'currentCount': currentCount,
      'target': target,
      'todayCount': todayCount,
      'lifetimeCount': lifetimeCount,
    };
  }

  static CounterHistoryEntry? tryFromMap(Object? value) {
    if (value is! Map<dynamic, dynamic>) {
      return null;
    }

    final actionName = value['action'];
    final timestamp = value['timestamp'];
    final currentCount = value['currentCount'];
    final target = value['target'];
    final todayCount = value['todayCount'];
    final lifetimeCount = value['lifetimeCount'];

    if (actionName is! String ||
        timestamp is! int ||
        currentCount is! int ||
        target is! int ||
        todayCount is! int ||
        lifetimeCount is! int ||
        currentCount < 0 ||
        target <= 0 ||
        todayCount < 0 ||
        lifetimeCount < 0) {
      return null;
    }

    final action = CounterHistoryAction.values
        .where((candidate) => candidate.name == actionName)
        .firstOrNull;
    if (action == null) {
      return null;
    }

    return CounterHistoryEntry(
      action: action,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
      currentCount: currentCount,
      target: target,
      todayCount: todayCount,
      lifetimeCount: lifetimeCount,
    );
  }
}

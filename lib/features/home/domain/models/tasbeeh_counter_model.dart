import 'counter_history_entry.dart';

class TasbeehCounterModel {
  const TasbeehCounterModel({
    required this.tasbeehName,
    required this.currentCount,
    required this.target,
    required this.todayCount,
    required this.lifetimeCount,
    required this.countDate,
    required this.history,
    this.lastUpdated,
    this.undoCurrentCount,
    this.undoTodayCount,
    this.undoLifetimeCount,
    this.undoLastUpdated,
  });

  factory TasbeehCounterModel.initial(DateTime now) {
    return TasbeehCounterModel(
      tasbeehName: 'SubhanAllah',
      currentCount: 0,
      target: 100,
      todayCount: 0,
      lifetimeCount: 0,
      countDate: _dateKey(now),
      history: const [],
    );
  }

  factory TasbeehCounterModel.fromMap(Map<dynamic, dynamic> map) {
    return TasbeehCounterModel(
      tasbeehName: map['tasbeehName'] as String? ?? 'SubhanAllah',
      currentCount: _nonNegativeInt(map['currentCount']),
      target: _positiveInt(map['target'], fallback: 100),
      todayCount: _nonNegativeInt(map['todayCount']),
      lifetimeCount: _nonNegativeInt(map['lifetimeCount']),
      countDate: map['countDate'] as String? ?? '',
      history: _historyFromMap(map['history']),
      lastUpdated: _dateTimeFromMilliseconds(map['lastUpdated']),
      undoCurrentCount: _nullableNonNegativeInt(map['undoCurrentCount']),
      undoTodayCount: _nullableNonNegativeInt(map['undoTodayCount']),
      undoLifetimeCount: _nullableNonNegativeInt(map['undoLifetimeCount']),
      undoLastUpdated: _dateTimeFromMilliseconds(map['undoLastUpdated']),
    );
  }

  final String tasbeehName;
  final int currentCount;
  final int target;
  final int todayCount;
  final int lifetimeCount;
  final String countDate;
  final List<CounterHistoryEntry> history;
  final DateTime? lastUpdated;
  final int? undoCurrentCount;
  final int? undoTodayCount;
  final int? undoLifetimeCount;
  final DateTime? undoLastUpdated;

  int get remaining => (target - currentCount).clamp(0, target);

  double get progress => (currentCount / target).clamp(0, 1);

  int get progressPercent => (progress * 100).round();

  bool get canUndo => undoCurrentCount != null;

  bool isForDate(DateTime date) => countDate == _dateKey(date);

  TasbeehCounterModel copyWith({
    String? tasbeehName,
    int? currentCount,
    int? target,
    int? todayCount,
    int? lifetimeCount,
    String? countDate,
    List<CounterHistoryEntry>? history,
    DateTime? lastUpdated,
    int? undoCurrentCount,
    int? undoTodayCount,
    int? undoLifetimeCount,
    DateTime? undoLastUpdated,
    bool clearLastUpdated = false,
    bool clearUndo = false,
  }) {
    return TasbeehCounterModel(
      tasbeehName: tasbeehName ?? this.tasbeehName,
      currentCount: currentCount ?? this.currentCount,
      target: target ?? this.target,
      todayCount: todayCount ?? this.todayCount,
      lifetimeCount: lifetimeCount ?? this.lifetimeCount,
      countDate: countDate ?? this.countDate,
      history: history ?? this.history,
      lastUpdated: clearLastUpdated ? null : lastUpdated ?? this.lastUpdated,
      undoCurrentCount: clearUndo
          ? null
          : undoCurrentCount ?? this.undoCurrentCount,
      undoTodayCount: clearUndo ? null : undoTodayCount ?? this.undoTodayCount,
      undoLifetimeCount: clearUndo
          ? null
          : undoLifetimeCount ?? this.undoLifetimeCount,
      undoLastUpdated: clearUndo
          ? null
          : undoLastUpdated ?? this.undoLastUpdated,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'tasbeehName': tasbeehName,
      'currentCount': currentCount,
      'target': target,
      'todayCount': todayCount,
      'lifetimeCount': lifetimeCount,
      'countDate': countDate,
      'history': history.map((entry) => entry.toMap()).toList(),
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
      'undoCurrentCount': undoCurrentCount,
      'undoTodayCount': undoTodayCount,
      'undoLifetimeCount': undoLifetimeCount,
      'undoLastUpdated': undoLastUpdated?.millisecondsSinceEpoch,
    };
  }

  static String dateKey(DateTime date) => _dateKey(date);

  static String _dateKey(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month}-${local.day}';
  }

  static DateTime? _dateTimeFromMilliseconds(Object? value) {
    return value is int ? DateTime.fromMillisecondsSinceEpoch(value) : null;
  }

  static int _nonNegativeInt(Object? value) {
    return value is int && value >= 0 ? value : 0;
  }

  static int _positiveInt(Object? value, {required int fallback}) {
    return value is int && value > 0 ? value : fallback;
  }

  static int? _nullableNonNegativeInt(Object? value) {
    return value is int && value >= 0 ? value : null;
  }

  static List<CounterHistoryEntry> _historyFromMap(Object? value) {
    if (value is! List<dynamic>) {
      return const [];
    }

    return List.unmodifiable(
      value
          .map(CounterHistoryEntry.tryFromMap)
          .whereType<CounterHistoryEntry>(),
    );
  }
}

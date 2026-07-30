import 'package:hive/hive.dart';

import '../../../history/domain/models/counter_history_entry.dart';
import '../../../history/domain/repositories/history_repository.dart';
import '../../../home/data/repositories/counter_repository.dart';
import '../../domain/models/statistics_models.dart';
import '../../domain/repositories/statistics_repository.dart';

class CachedStatisticsRepository implements StatisticsRepository {
  CachedStatisticsRepository(
    this._historyRepository,
    this._counterRepository,
    this._metadataBox,
  );

  static const _resetAtKey = 'resetAt';

  final HistoryRepository _historyRepository;
  final CounterRepository _counterRepository;
  final Box<dynamic> _metadataBox;

  StatisticsData? _cachedData;
  int _cachedRevision = -1;

  @override
  DateTime? get resetAt {
    final value = _metadataBox.get(_resetAtKey);
    return value is int ? DateTime.fromMillisecondsSinceEpoch(value) : null;
  }

  @override
  Future<StatisticsData> load({bool forceRefresh = false}) async {
    final revision = _historyRepository.revision;
    if (!forceRefresh && _cachedData != null && _cachedRevision == revision) {
      return _cachedData!;
    }

    final resetBoundary = resetAt;
    final entries = (await _historyRepository.fetchAll())
        .where(
          (entry) =>
              resetBoundary == null || !entry.timestamp.isBefore(resetBoundary),
        )
        .toList();
    final counter = _counterRepository.load();
    final data = _calculate(entries, counter?.lifetimeCount ?? 0);
    _cachedData = data;
    _cachedRevision = revision;
    return data;
  }

  @override
  Future<void> setResetAt(DateTime? resetAt) async {
    if (resetAt == null) {
      await _metadataBox.delete(_resetAtKey);
    } else {
      await _metadataBox.put(_resetAtKey, resetAt.millisecondsSinceEpoch);
    }
    _cachedData = null;
    _cachedRevision = -1;
  }

  StatisticsData _calculate(
    List<CounterHistoryEntry> entries,
    int lifetimeCount,
  ) {
    final now = DateTime.now();
    final today = _day(now);
    final daily = <DateTime, _DailyAggregate>{};

    for (final entry in entries) {
      final date = _day(entry.timestamp);
      final aggregate = daily.putIfAbsent(date, _DailyAggregate.new);
      aggregate
        ..count = entry.todayCount
        ..target = entry.target;
      if (entry.action == CounterHistoryAction.increment &&
          entry.previousCount < entry.target &&
          entry.newCount >= entry.target) {
        aggregate.targetsCompleted++;
      }
    }

    final ranges = <StatisticsPeriod, _DateRange>{
      StatisticsPeriod.today: _DateRange(today, _nextDay(today)),
      StatisticsPeriod.yesterday: _DateRange(
        today.subtract(const Duration(days: 1)),
        today,
      ),
      StatisticsPeriod.thisWeek: _DateRange(
        today.subtract(Duration(days: today.weekday - 1)),
        _nextDay(today),
      ),
      StatisticsPeriod.thisMonth: _DateRange(
        DateTime(today.year, today.month),
        DateTime(today.year, today.month + 1),
      ),
      StatisticsPeriod.thisYear: _DateRange(
        DateTime(today.year),
        DateTime(today.year + 1),
      ),
      StatisticsPeriod.lifetime: const _DateRange(null, null),
    };

    final streaks = _streaks(daily, today);
    final metrics = <StatisticsPeriod, StatisticsMetrics>{};
    for (final period in StatisticsPeriod.values) {
      final periodDaily = Map<DateTime, _DailyAggregate>.fromEntries(
        daily.entries.where((entry) => ranges[period]!.contains(entry.key)),
      );
      metrics[period] = _metrics(
        periodDaily,
        currentStreak: streaks.$1,
        longestStreak: streaks.$2,
        lifetimeTotal: period == StatisticsPeriod.lifetime
            ? lifetimeCount
            : null,
      );
    }

    final sevenDayCounts = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return DailyCountPoint(date: date, count: daily[date]?.count ?? 0);
    });
    final monthlyCounts = List.generate(today.day, (index) {
      final date = DateTime(today.year, today.month, index + 1);
      return DailyCountPoint(date: date, count: daily[date]?.count ?? 0);
    });
    final weeklyTrend = List.generate(8, (index) {
      final currentWeekStart = today.subtract(
        Duration(days: today.weekday - 1),
      );
      final weekStart = currentWeekStart.subtract(
        Duration(days: (7 - index) * 7),
      );
      final weekEnd = weekStart.add(const Duration(days: 7));
      final count = daily.entries
          .where(
            (entry) =>
                !entry.key.isBefore(weekStart) && entry.key.isBefore(weekEnd),
          )
          .fold<int>(0, (sum, entry) => sum + entry.value.count);
      return WeeklyCountPoint(weekStart: weekStart, count: count);
    });

    final activeDays = daily.values.where((value) => value.count > 0).length;
    final completedDays = daily.values
        .where((value) => value.count >= value.target)
        .length;
    final completion = CompletionBreakdown(
      completed: completedDays,
      notCompleted: (activeDays - completedDays).clamp(0, activeDays),
    );

    return StatisticsData(
      metrics: Map.unmodifiable(metrics),
      sevenDayCounts: List.unmodifiable(sevenDayCounts),
      monthlyCounts: List.unmodifiable(monthlyCounts),
      weeklyTrend: List.unmodifiable(weeklyTrend),
      completion: completion,
      insights: List.unmodifiable(_insights(daily, today)),
    );
  }

  StatisticsMetrics _metrics(
    Map<DateTime, _DailyAggregate> daily, {
    required int currentStreak,
    required int longestStreak,
    int? lifetimeTotal,
  }) {
    final active = daily.values.where((value) => value.count > 0).toList();
    final total =
        lifetimeTotal ?? active.fold<int>(0, (sum, day) => sum + day.count);
    final completed = active.where((day) => day.count >= day.target).length;

    return StatisticsMetrics(
      totalCount: total,
      averageDailyCount: active.isEmpty ? 0 : total / active.length,
      highestDailyCount: active.isEmpty
          ? 0
          : active.map((day) => day.count).reduce((a, b) => a > b ? a : b),
      lowestDailyCount: active.isEmpty
          ? 0
          : active.map((day) => day.count).reduce((a, b) => a < b ? a : b),
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      completionPercentage: active.isEmpty
          ? 0
          : completed / active.length * 100,
      targetsCompleted: active.fold<int>(
        0,
        (sum, day) => sum + day.targetsCompleted,
      ),
    );
  }

  (int, int) _streaks(Map<DateTime, _DailyAggregate> daily, DateTime today) {
    final activeDates = daily.entries
        .where((entry) => entry.value.count > 0)
        .map((entry) => entry.key)
        .toSet();
    if (activeDates.isEmpty) {
      return (0, 0);
    }

    final sorted = activeDates.toList()..sort();
    var longest = 1;
    var running = 1;
    for (var index = 1; index < sorted.length; index++) {
      if (sorted[index].difference(sorted[index - 1]).inDays == 1) {
        running++;
        if (running > longest) {
          longest = running;
        }
      } else {
        running = 1;
      }
    }

    var current = 0;
    var cursor = activeDates.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    while (activeDates.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return (current, longest);
  }

  List<String> _insights(Map<DateTime, _DailyAggregate> daily, DateTime today) {
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final previousWeekStart = currentWeekStart.subtract(
      const Duration(days: 7),
    );
    final currentWeek = _sumRange(daily, currentWeekStart, _nextDay(today));
    final previousWeek = _sumRange(daily, previousWeekStart, currentWeekStart);
    final comparison = previousWeek == 0
        ? null
        : ((currentWeek - previousWeek) / previousWeek * 100).round();

    final activeEntries =
        daily.entries.where((entry) => entry.value.count > 0).toList()
          ..sort((a, b) => b.value.count.compareTo(a.value.count));
    final bestDay = activeEntries.isEmpty
        ? null
        : _weekdayName(activeEntries.first.key.weekday);
    final average = activeEntries.isEmpty
        ? 0
        : activeEntries.fold<int>(0, (sum, entry) => sum + entry.value.count) /
              activeEntries.length;

    return [
      if (comparison != null)
        'You counted ${comparison.abs()}% '
            '${comparison >= 0 ? 'more' : 'less'} than last week.',
      if (bestDay != null) 'Your best day was $bestDay.',
      'You are averaging ${average.round()} counts/day.',
    ];
  }

  int _sumRange(
    Map<DateTime, _DailyAggregate> daily,
    DateTime start,
    DateTime end,
  ) {
    return daily.entries
        .where((entry) => !entry.key.isBefore(start) && entry.key.isBefore(end))
        .fold<int>(0, (sum, entry) => sum + entry.value.count);
  }

  String _weekdayName(int weekday) {
    return const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][weekday - 1];
  }

  DateTime _day(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  DateTime _nextDay(DateTime date) {
    return DateTime(date.year, date.month, date.day + 1);
  }
}

class _DailyAggregate {
  int count = 0;
  int target = 1;
  int targetsCompleted = 0;
}

class _DateRange {
  const _DateRange(this.start, this.end);

  final DateTime? start;
  final DateTime? end;

  bool contains(DateTime date) {
    return (start == null || !date.isBefore(start!)) &&
        (end == null || date.isBefore(end!));
  }
}

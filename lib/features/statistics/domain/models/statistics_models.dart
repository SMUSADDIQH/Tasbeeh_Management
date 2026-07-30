enum StatisticsPeriod {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  thisYear,
  lifetime,
}

class StatisticsMetrics {
  const StatisticsMetrics({
    required this.totalCount,
    required this.averageDailyCount,
    required this.highestDailyCount,
    required this.lowestDailyCount,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionPercentage,
    required this.targetsCompleted,
  });

  final int totalCount;
  final double averageDailyCount;
  final int highestDailyCount;
  final int lowestDailyCount;
  final int currentStreak;
  final int longestStreak;
  final double completionPercentage;
  final int targetsCompleted;
}

class DailyCountPoint {
  const DailyCountPoint({required this.date, required this.count});

  final DateTime date;
  final int count;
}

class WeeklyCountPoint {
  const WeeklyCountPoint({required this.weekStart, required this.count});

  final DateTime weekStart;
  final int count;
}

class CompletionBreakdown {
  const CompletionBreakdown({
    required this.completed,
    required this.notCompleted,
  });

  final int completed;
  final int notCompleted;

  int get total => completed + notCompleted;

  double get percentage => total == 0 ? 0 : completed / total;
}

class StatisticsData {
  const StatisticsData({
    required this.metrics,
    required this.sevenDayCounts,
    required this.monthlyCounts,
    required this.weeklyTrend,
    required this.completion,
    required this.insights,
  });

  final Map<StatisticsPeriod, StatisticsMetrics> metrics;
  final List<DailyCountPoint> sevenDayCounts;
  final List<DailyCountPoint> monthlyCounts;
  final List<WeeklyCountPoint> weeklyTrend;
  final CompletionBreakdown completion;
  final List<String> insights;
}

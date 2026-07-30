import '../models/statistics_models.dart';

abstract interface class StatisticsRepository {
  DateTime? get resetAt;

  Future<StatisticsData> load({bool forceRefresh = false});

  Future<void> setResetAt(DateTime? resetAt);
}

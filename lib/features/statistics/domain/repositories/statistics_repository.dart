import '../models/statistics_models.dart';

abstract interface class StatisticsRepository {
  Future<StatisticsData> load({bool forceRefresh = false});
}

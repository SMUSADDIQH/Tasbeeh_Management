import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/statistics_models.dart';
import '../../domain/repositories/statistics_repository.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  throw UnimplementedError(
    'statisticsRepositoryProvider must be overridden at application startup.',
  );
});

final statisticsProvider =
    StateNotifierProvider<StatisticsNotifier, StatisticsState>((ref) {
      return StatisticsNotifier(ref.watch(statisticsRepositoryProvider))
        ..load();
    });

class StatisticsState {
  const StatisticsState({
    this.selectedPeriod = StatisticsPeriod.thisWeek,
    this.isLoading = true,
    this.data,
    this.errorMessage,
  });

  final StatisticsPeriod selectedPeriod;
  final bool isLoading;
  final StatisticsData? data;
  final String? errorMessage;

  StatisticsMetrics? get selectedMetrics => data?.metrics[selectedPeriod];

  StatisticsState copyWith({
    StatisticsPeriod? selectedPeriod,
    bool? isLoading,
    StatisticsData? data,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StatisticsState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class StatisticsNotifier extends StateNotifier<StatisticsState> {
  StatisticsNotifier(this._repository) : super(const StatisticsState());

  final StatisticsRepository _repository;
  int _requestId = 0;

  void selectPeriod(StatisticsPeriod period) {
    if (period != state.selectedPeriod) {
      state = state.copyWith(selectedPeriod: period);
    }
  }

  Future<void> load({bool forceRefresh = false}) async {
    final requestId = ++_requestId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final data = await _repository.load(forceRefresh: forceRefresh);
      if (requestId == _requestId) {
        state = state.copyWith(data: data, isLoading: false, clearError: true);
      }
    } on Object {
      if (requestId == _requestId) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Could not calculate statistics.',
        );
      }
    }
  }

  Future<void> refresh() => load(forceRefresh: true);
}

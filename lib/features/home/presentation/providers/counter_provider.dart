import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../history/domain/models/counter_history_entry.dart';
import '../../../history/domain/repositories/history_repository.dart';
import '../../../history/presentation/providers/history_repository_provider.dart';
import '../../data/repositories/counter_repository.dart';
import '../../domain/models/tasbeeh_counter_model.dart';

final counterRepositoryProvider = Provider<CounterRepository>((ref) {
  throw UnimplementedError(
    'counterRepositoryProvider must be overridden at application startup.',
  );
});

final counterProvider =
    StateNotifierProvider<CounterNotifier, TasbeehCounterModel>((ref) {
      return CounterNotifier(
        ref.watch(counterRepositoryProvider),
        ref.watch(historyRepositoryProvider),
      );
    });

class CounterNotifier extends StateNotifier<TasbeehCounterModel> {
  CounterNotifier(this._repository, this._historyRepository)
    : super(_repository.load() ?? TasbeehCounterModel.initial(DateTime.now())) {
    _normalizeToday();
    _scheduleDailyRollover();
  }

  final CounterRepository _repository;
  final HistoryRepository _historyRepository;
  Duration _continuousCountInterval = const Duration(milliseconds: 140);
  Timer? _continuousCountTimer;
  Timer? _dailyRolloverTimer;

  void increment() {
    _normalizeToday();
    final now = DateTime.now();
    final previous = state;

    final next = previous.copyWith(
      currentCount: previous.currentCount + 1,
      todayCount: previous.todayCount + 1,
      lifetimeCount: previous.lifetimeCount + 1,
      countDate: TasbeehCounterModel.dateKey(now),
      lastUpdated: now,
      undoCurrentCount: previous.currentCount,
      undoTodayCount: previous.todayCount,
      undoLifetimeCount: previous.lifetimeCount,
      undoLastUpdated: previous.lastUpdated,
    );
    state = next;
    _recordHistory(previous, next, CounterHistoryAction.increment, now);
    _persist();
  }

  void startContinuousCount() {
    if (_continuousCountTimer?.isActive ?? false) {
      return;
    }

    increment();
    _continuousCountTimer = Timer.periodic(
      _continuousCountInterval,
      (_) => increment(),
    );
  }

  void stopContinuousCount() {
    _continuousCountTimer?.cancel();
    _continuousCountTimer = null;
  }

  void setContinuousCountInterval(Duration interval) {
    _continuousCountInterval = interval;
    if (_continuousCountTimer?.isActive ?? false) {
      stopContinuousCount();
      startContinuousCount();
    }
  }

  void restore(TasbeehCounterModel counter) {
    stopContinuousCount();
    state = counter;
  }

  void undo() {
    if (!state.canUndo) {
      return;
    }

    final previous = state;
    final now = DateTime.now();
    final next = previous.copyWith(
      currentCount: previous.undoCurrentCount,
      todayCount: previous.undoTodayCount,
      lifetimeCount: previous.undoLifetimeCount,
      lastUpdated: previous.undoLastUpdated,
      clearLastUpdated: previous.undoLastUpdated == null,
      clearUndo: true,
    );
    state = next;
    _recordHistory(previous, next, CounterHistoryAction.undo, now);
    _persist();
  }

  void reset() {
    if (state.currentCount == 0) {
      return;
    }

    final previous = state;
    final now = DateTime.now();
    final next = previous.copyWith(
      currentCount: 0,
      lastUpdated: now,
      undoCurrentCount: previous.currentCount,
      undoTodayCount: previous.todayCount,
      undoLifetimeCount: previous.lifetimeCount,
      undoLastUpdated: previous.lastUpdated,
    );
    state = next;
    _recordHistory(previous, next, CounterHistoryAction.reset, now);
    _persist();
  }

  bool setCustomTarget(String value) {
    final target = int.tryParse(value.trim());
    if (target == null || target <= 0) {
      return false;
    }

    final previous = state;
    final now = DateTime.now();
    final next = previous.copyWith(target: target, lastUpdated: now);
    state = next;
    _recordHistory(previous, next, CounterHistoryAction.targetChanged, now);
    _persist();
    return true;
  }

  void _normalizeToday() {
    final now = DateTime.now();
    if (state.isForDate(now)) {
      return;
    }

    final previous = state;
    final next = previous.copyWith(
      todayCount: 0,
      countDate: TasbeehCounterModel.dateKey(now),
      clearUndo: true,
    );
    state = next;
    _recordHistory(previous, next, CounterHistoryAction.dailyRollover, now);
    _persist();
  }

  void _scheduleDailyRollover() {
    _dailyRolloverTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _dailyRolloverTimer = Timer(tomorrow.difference(now), () {
      _normalizeToday();
      _scheduleDailyRollover();
    });
  }

  void _persist() {
    unawaited(_repository.save(state));
  }

  void _recordHistory(
    TasbeehCounterModel previous,
    TasbeehCounterModel next,
    CounterHistoryAction action,
    DateTime timestamp,
  ) {
    final entry = CounterHistoryEntry(
      action: action,
      timestamp: timestamp,
      previousCount: previous.currentCount,
      newCount: next.currentCount,
      target: next.target,
      todayCount: next.todayCount,
      lifetimeCount: next.lifetimeCount,
    );
    unawaited(_historyRepository.append(entry));
  }

  @override
  void dispose() {
    stopContinuousCount();
    _dailyRolloverTimer?.cancel();
    super.dispose();
  }
}

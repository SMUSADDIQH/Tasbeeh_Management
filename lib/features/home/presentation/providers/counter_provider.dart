import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/counter_repository.dart';
import '../../domain/models/counter_history_entry.dart';
import '../../domain/models/tasbeeh_counter_model.dart';

final counterRepositoryProvider = Provider<CounterRepository>((ref) {
  throw UnimplementedError(
    'counterRepositoryProvider must be overridden at application startup.',
  );
});

final counterProvider =
    StateNotifierProvider<CounterNotifier, TasbeehCounterModel>((ref) {
      return CounterNotifier(ref.watch(counterRepositoryProvider));
    });

class CounterNotifier extends StateNotifier<TasbeehCounterModel> {
  CounterNotifier(this._repository)
    : super(_repository.load() ?? TasbeehCounterModel.initial(DateTime.now())) {
    _normalizeToday();
    _scheduleDailyRollover();
  }

  static const _continuousCountInterval = Duration(milliseconds: 140);

  final CounterRepository _repository;
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
    state = _recordHistory(next, CounterHistoryAction.increment, now);
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

  void undo() {
    if (!state.canUndo) {
      return;
    }

    final now = DateTime.now();
    final next = state.copyWith(
      currentCount: state.undoCurrentCount,
      todayCount: state.undoTodayCount,
      lifetimeCount: state.undoLifetimeCount,
      lastUpdated: state.undoLastUpdated,
      clearLastUpdated: state.undoLastUpdated == null,
      clearUndo: true,
    );
    state = _recordHistory(next, CounterHistoryAction.undo, now);
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
    state = _recordHistory(next, CounterHistoryAction.reset, now);
    _persist();
  }

  bool setCustomTarget(String value) {
    final target = int.tryParse(value.trim());
    if (target == null || target <= 0) {
      return false;
    }

    final now = DateTime.now();
    final next = state.copyWith(target: target, lastUpdated: now);
    state = _recordHistory(next, CounterHistoryAction.targetChanged, now);
    _persist();
    return true;
  }

  void _normalizeToday() {
    final now = DateTime.now();
    if (state.isForDate(now)) {
      return;
    }

    final next = state.copyWith(
      todayCount: 0,
      countDate: TasbeehCounterModel.dateKey(now),
      clearUndo: true,
    );
    state = _recordHistory(next, CounterHistoryAction.dailyRollover, now);
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

  TasbeehCounterModel _recordHistory(
    TasbeehCounterModel counter,
    CounterHistoryAction action,
    DateTime timestamp,
  ) {
    final entry = CounterHistoryEntry(
      action: action,
      timestamp: timestamp,
      currentCount: counter.currentCount,
      target: counter.target,
      todayCount: counter.todayCount,
      lifetimeCount: counter.lifetimeCount,
    );

    return counter.copyWith(history: [...counter.history, entry]);
  }

  @override
  void dispose() {
    stopContinuousCount();
    _dailyRolloverTimer?.cancel();
    super.dispose();
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/counter_repository.dart';
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

    state = previous.copyWith(
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

    state = state.copyWith(
      currentCount: state.undoCurrentCount,
      todayCount: state.undoTodayCount,
      lifetimeCount: state.undoLifetimeCount,
      lastUpdated: state.undoLastUpdated,
      clearLastUpdated: state.undoLastUpdated == null,
      clearUndo: true,
    );
    _persist();
  }

  void reset() {
    if (state.currentCount == 0) {
      return;
    }

    final previous = state;
    state = previous.copyWith(
      currentCount: 0,
      lastUpdated: DateTime.now(),
      undoCurrentCount: previous.currentCount,
      undoTodayCount: previous.todayCount,
      undoLifetimeCount: previous.lifetimeCount,
      undoLastUpdated: previous.lastUpdated,
    );
    _persist();
  }

  bool setCustomTarget(String value) {
    final target = int.tryParse(value.trim());
    if (target == null || target <= 0) {
      return false;
    }

    state = state.copyWith(target: target, lastUpdated: DateTime.now());
    _persist();
    return true;
  }

  void _normalizeToday() {
    final now = DateTime.now();
    if (state.isForDate(now)) {
      return;
    }

    state = state.copyWith(
      todayCount: 0,
      countDate: TasbeehCounterModel.dateKey(now),
      clearUndo: true,
    );
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

  @override
  void dispose() {
    stopContinuousCount();
    _dailyRolloverTimer?.cancel();
    super.dispose();
  }
}

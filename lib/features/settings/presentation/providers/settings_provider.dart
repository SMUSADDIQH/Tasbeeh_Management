import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../history/domain/repositories/history_repository.dart';
import '../../../history/presentation/providers/history_repository_provider.dart';
import '../../../home/data/repositories/counter_repository.dart';
import '../../../home/domain/models/tasbeeh_counter_model.dart';
import '../../../home/presentation/providers/counter_provider.dart';
import '../../../statistics/domain/repositories/statistics_repository.dart';
import '../../../statistics/presentation/providers/statistics_provider.dart';
import '../../data/services/backup_service.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError(
    'settingsRepositoryProvider must be overridden at application startup.',
  );
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final counterRepository = ref.watch(counterRepositoryProvider);
    final historyRepository = ref.watch(historyRepositoryProvider);
    final statisticsRepository = ref.watch(statisticsRepositoryProvider);
    final settingsRepository = ref.watch(settingsRepositoryProvider);
    return SettingsNotifier(
      settingsRepository,
      counterRepository,
      historyRepository,
      statisticsRepository,
      ref.read(counterProvider.notifier),
    );
  },
);

class SettingsState {
  const SettingsState({
    required this.settings,
    this.appVersion = '—',
    this.buildNumber = '—',
    this.isProcessingData = false,
  });

  final AppSettings settings;
  final String appVersion;
  final String buildNumber;
  final bool isProcessingData;

  SettingsState copyWith({
    AppSettings? settings,
    String? appVersion,
    String? buildNumber,
    bool? isProcessingData,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      appVersion: appVersion ?? this.appVersion,
      buildNumber: buildNumber ?? this.buildNumber,
      isProcessingData: isProcessingData ?? this.isProcessingData,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(
    this._settingsRepository,
    this._counterRepository,
    this._historyRepository,
    this._statisticsRepository,
    this._counterNotifier,
  ) : _backupService = BackupService(
        _counterRepository,
        _historyRepository,
        _settingsRepository,
        _statisticsRepository,
      ),
      super(SettingsState(settings: _settingsRepository.load())) {
    _applyCounterSpeed(state.settings.continuousCountSpeed);
    unawaited(_loadPackageInfo());
  }

  final SettingsRepository _settingsRepository;
  final CounterRepository _counterRepository;
  final HistoryRepository _historyRepository;
  final StatisticsRepository _statisticsRepository;
  final CounterNotifier _counterNotifier;
  final BackupService _backupService;

  Future<void> setTheme(AppThemePreference theme) {
    return _update(state.settings.copyWith(theme: theme));
  }

  bool setDefaultTarget(String value) {
    final target = int.tryParse(value.trim());
    if (target == null || target <= 0) {
      return false;
    }
    unawaited(_update(state.settings.copyWith(defaultTarget: target)));
    return true;
  }

  Future<void> setHapticFeedback(bool enabled) {
    return _update(state.settings.copyWith(hapticFeedbackEnabled: enabled));
  }

  Future<void> setCounterAnimation(bool enabled) {
    return _update(state.settings.copyWith(counterAnimationEnabled: enabled));
  }

  Future<void> setContinuousCountSpeed(ContinuousCountSpeed speed) async {
    _applyCounterSpeed(speed);
    await _update(state.settings.copyWith(continuousCountSpeed: speed));
  }

  Future<String> exportData() {
    return _withProcessing(_backupService.exportData);
  }

  Future<String?> importData(String source) async {
    try {
      final result = await _withProcessing(
        () => _backupService.importData(source),
      );
      state = state.copyWith(settings: result.settings);
      _applyCounterSpeed(result.settings.continuousCountSpeed);
      _counterNotifier.restore(result.counter);
      return null;
    } on FormatException catch (error) {
      return error.message;
    } on Object {
      return 'The backup could not be imported.';
    }
  }

  Future<void> resetHistory() {
    return _withProcessing(_historyRepository.clear);
  }

  Future<void> resetStatistics() {
    return _withProcessing(() async {
      final current =
          _counterRepository.load() ??
          TasbeehCounterModel.initial(DateTime.now());
      final resetCounter = current.copyWith(
        todayCount: 0,
        lifetimeCount: 0,
        countDate: TasbeehCounterModel.dateKey(DateTime.now()),
        clearUndo: true,
      );
      await _statisticsRepository.setResetAt(DateTime.now());
      await _counterRepository.save(resetCounter);
      _counterNotifier.restore(resetCounter);
    });
  }

  Future<void> resetEverything() async {
    await _withProcessing(() async {
      final defaults = AppSettings.defaults();
      final counter = TasbeehCounterModel.initial(
        DateTime.now(),
      ).copyWith(target: defaults.defaultTarget);
      await _historyRepository.clear();
      await _statisticsRepository.setResetAt(null);
      await _counterRepository.save(counter);
      await _settingsRepository.save(defaults);
      state = state.copyWith(settings: defaults);
      _applyCounterSpeed(defaults.continuousCountSpeed);
      _counterNotifier.restore(counter);
    });
  }

  Future<void> _update(AppSettings settings) async {
    state = state.copyWith(settings: settings);
    await _settingsRepository.save(settings);
  }

  void _applyCounterSpeed(ContinuousCountSpeed speed) {
    _counterNotifier.setContinuousCountInterval(speed.interval);
  }

  Future<T> _withProcessing<T>(Future<T> Function() action) async {
    state = state.copyWith(isProcessingData: true);
    try {
      return await action();
    } finally {
      state = state.copyWith(isProcessingData: false);
    }
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    state = state.copyWith(
      appVersion: info.version,
      buildNumber: info.buildNumber,
    );
  }
}

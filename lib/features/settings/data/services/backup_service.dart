import 'dart:convert';

import '../../../history/domain/models/counter_history_entry.dart';
import '../../../history/domain/repositories/history_repository.dart';
import '../../../home/data/repositories/counter_repository.dart';
import '../../../home/domain/models/tasbeeh_counter_model.dart';
import '../../../statistics/domain/repositories/statistics_repository.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class BackupResult {
  const BackupResult({required this.counter, required this.settings});

  final TasbeehCounterModel counter;
  final AppSettings settings;
}

class BackupService {
  BackupService(
    this._counterRepository,
    this._historyRepository,
    this._settingsRepository,
    this._statisticsRepository,
  );

  final CounterRepository _counterRepository;
  final HistoryRepository _historyRepository;
  final SettingsRepository _settingsRepository;
  final StatisticsRepository _statisticsRepository;

  Future<String> exportData() async {
    final counter =
        _counterRepository.load() ??
        TasbeehCounterModel.initial(DateTime.now());
    final history = await _historyRepository.fetchAll();
    final resetAt = _statisticsRepository.resetAt;

    return const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'counter': counter.toMap(),
      'history': history.map((entry) => entry.toMap()).toList(),
      'settings': _settingsRepository.load().toMap(),
      'statisticsResetAt': resetAt?.millisecondsSinceEpoch,
    });
  }

  Future<BackupResult> importData(String source) async {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
      throw const FormatException('Unsupported backup format.');
    }

    final counterMap = decoded['counter'];
    final settingsMap = decoded['settings'];
    final historyValues = decoded['history'];
    if (counterMap is! Map<String, dynamic> ||
        settingsMap is! Map<String, dynamic> ||
        historyValues is! List<dynamic>) {
      throw const FormatException('Backup data is incomplete.');
    }

    final counter = TasbeehCounterModel.fromMap(counterMap);
    final settings = AppSettings.fromMap(settingsMap);
    final history = historyValues
        .map(CounterHistoryEntry.tryFromMap)
        .whereType<CounterHistoryEntry>()
        .toList();
    if (history.length != historyValues.length) {
      throw const FormatException('Backup history is invalid.');
    }

    final resetValue = decoded['statisticsResetAt'];
    if (resetValue != null && resetValue is! int) {
      throw const FormatException('Statistics metadata is invalid.');
    }

    await _counterRepository.save(counter);
    await _historyRepository.replaceAll(history);
    await _settingsRepository.save(settings);
    await _statisticsRepository.setResetAt(
      resetValue is int
          ? DateTime.fromMillisecondsSinceEpoch(resetValue)
          : null,
    );

    return BackupResult(counter: counter, settings: settings);
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('Override settingsRepositoryProvider at startup.');
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref.watch(settingsRepositoryProvider)),
);

class SettingsState {
  const SettingsState({
    required this.settings,
    this.appVersion = '—',
    this.buildNumber = '—',
  });
  final AppSettings settings;
  final String appVersion;
  final String buildNumber;

  SettingsState copyWith({
    AppSettings? settings,
    String? appVersion,
    String? buildNumber,
  }) => SettingsState(
    settings: settings ?? this.settings,
    appVersion: appVersion ?? this.appVersion,
    buildNumber: buildNumber ?? this.buildNumber,
  );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._repository)
    : super(SettingsState(settings: _repository.load())) {
    unawaited(_loadInfo());
  }

  final SettingsRepository _repository;

  Future<void> setTheme(AppThemePreference value) =>
      _save(state.settings.copyWith(theme: value));
  Future<void> setHaptics(bool value) =>
      _save(state.settings.copyWith(hapticFeedbackEnabled: value));
  Future<void> setAnimations(bool value) =>
      _save(state.settings.copyWith(animationsEnabled: value));
  Future<void> setReminders(bool value) =>
      _save(state.settings.copyWith(remindersEnabled: value));
  Future<void> setDefaultLabel(String value) =>
      _save(state.settings.copyWith(defaultSessionLabel: value));
  Future<bool> setDefaultTarget(String value) async {
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) return false;
    await _save(state.settings.copyWith(defaultTarget: parsed));
    return true;
  }

  Future<void> reset() => _save(AppSettings.defaults());

  Future<void> _save(AppSettings settings) async {
    state = state.copyWith(settings: settings);
    await _repository.save(settings);
  }

  Future<void> _loadInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      state = state.copyWith(
        appVersion: info.version,
        buildNumber: info.buildNumber,
      );
    } on Object {
      // Package metadata can be unavailable in host-only tests.
    }
  }
}

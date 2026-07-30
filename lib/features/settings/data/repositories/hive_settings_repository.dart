import 'package:hive/hive.dart';

import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class HiveSettingsRepository implements SettingsRepository {
  HiveSettingsRepository(this._box);

  static const _settingsKey = 'preferences';

  final Box<dynamic> _box;

  @override
  AppSettings load() {
    final value = _box.get(_settingsKey);
    return value is Map<dynamic, dynamic>
        ? AppSettings.fromMap(value)
        : AppSettings.defaults();
  }

  @override
  Future<void> save(AppSettings settings) {
    return _box.put(_settingsKey, settings.toMap());
  }
}

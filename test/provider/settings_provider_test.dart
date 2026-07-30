import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeeh_tracker/features/settings/domain/models/app_settings.dart';
import 'package:tasbeeh_tracker/features/settings/presentation/providers/settings_provider.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('settings preferences persist through repository', () async {
    final repository = MemorySettingsRepository();
    final notifier = SettingsNotifier(repository);
    await notifier.setTheme(AppThemePreference.dark);
    await notifier.setHaptics(false);
    await notifier.setAnimations(false);
    await notifier.setDefaultLabel('Night');
    expect(await notifier.setDefaultTarget('2500'), isTrue);
    expect(repository.value.theme, AppThemePreference.dark);
    expect(repository.value.hapticFeedbackEnabled, isFalse);
    expect(repository.value.animationsEnabled, isFalse);
    expect(repository.value.defaultSessionLabel, 'Night');
    expect(repository.value.defaultTarget, 2500);
  });

  test('invalid default target is rejected', () async {
    final notifier = SettingsNotifier(MemorySettingsRepository());
    expect(await notifier.setDefaultTarget('0'), isFalse);
    expect(await notifier.setDefaultTarget('invalid'), isFalse);
  });
}

enum AppThemePreference { system, light, dark }

class AppSettings {
  const AppSettings({
    required this.theme,
    required this.defaultTarget,
    required this.hapticFeedbackEnabled,
    required this.animationsEnabled,
    required this.remindersEnabled,
    required this.defaultSessionLabel,
  });

  factory AppSettings.defaults() => const AppSettings(
    theme: AppThemePreference.system,
    defaultTarget: 1000,
    hapticFeedbackEnabled: true,
    animationsEnabled: true,
    remindersEnabled: false,
    defaultSessionLabel: 'After Fajr',
  );

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) => AppSettings(
    theme:
        AppThemePreference.values
            .where((item) => item.name == map['theme'])
            .firstOrNull ??
        AppThemePreference.system,
    defaultTarget: map['defaultTarget'] is int && map['defaultTarget'] > 0
        ? map['defaultTarget'] as int
        : 1000,
    hapticFeedbackEnabled: map['hapticFeedbackEnabled'] as bool? ?? true,
    animationsEnabled: map['animationsEnabled'] as bool? ?? true,
    remindersEnabled: map['remindersEnabled'] as bool? ?? false,
    defaultSessionLabel: map['defaultSessionLabel'] as String? ?? 'After Fajr',
  );

  final AppThemePreference theme;
  final int defaultTarget;
  final bool hapticFeedbackEnabled;
  final bool animationsEnabled;
  final bool remindersEnabled;
  final String defaultSessionLabel;

  AppSettings copyWith({
    AppThemePreference? theme,
    int? defaultTarget,
    bool? hapticFeedbackEnabled,
    bool? animationsEnabled,
    bool? remindersEnabled,
    String? defaultSessionLabel,
  }) => AppSettings(
    theme: theme ?? this.theme,
    defaultTarget: defaultTarget ?? this.defaultTarget,
    hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    animationsEnabled: animationsEnabled ?? this.animationsEnabled,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    defaultSessionLabel: defaultSessionLabel ?? this.defaultSessionLabel,
  );

  Map<String, Object> toMap() => {
    'theme': theme.name,
    'defaultTarget': defaultTarget,
    'hapticFeedbackEnabled': hapticFeedbackEnabled,
    'animationsEnabled': animationsEnabled,
    'remindersEnabled': remindersEnabled,
    'defaultSessionLabel': defaultSessionLabel,
  };
}
